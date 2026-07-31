#!/usr/bin/env python3
"""What this session cost, from the session's own transcripts.

Run it from the project directory, with no arguments:

    python3 <path-to>/skills/cost/assets/token-cost.py

It reads the running session's transcript and the transcript of every
subagent that session dispatched, and prints one row per dispatch plus one
row for the main session: the agent type, what it was dispatched for, its
model steps and its raw token counts. Under every row it prints where that
row's cache-write went - grouped by the kind of thing that entered the
context, and as the individually most expensive items.

It creates and modifies nothing, and it reads no transcript but the current
session's. `CLAUDE_SESSION_ID` or `CLAUDE_CODE_SESSION_ID` says which session
that is; where neither names one, it reports that it cannot identify the
running session and exits non-zero instead of guessing a transcript.

What the numbers mean:

  steps         model calls, not transcript records. One call is written as
                one record per content block, and every one of those records
                repeats the call's usage figures; adding them up inflates
                both the steps and the tokens.
  cache-write   tokens written into the cache by a call - the material that
                entered the context since the previous call.
  cache-read    tokens read from the cache by a call - the context it carried.
  output        marked unreliable: within one call the records disagree (a
                placeholder beside the real count), so the largest value seen
                for a call is shown, prefixed with ~, and is not a count.
  measured      one call's whole cache-write, with a single item entering it.
  estimated     one call's cache-write split proportionally across the items
                that entered together.
"""

import json
import os
import re
import sys

TOP_ITEMS = 8

KIND_PROMPT = "the prompt and the baseline"
KIND_OWN_TEXT = "the agent's own output"
KIND_OWN_CALLS = "the agent's own tool calls"
KIND_USER = "later user messages"
KIND_HOOK = "hook and attachment output"


# --- reading the right transcripts ------------------------------------------

def home_dir():
    return os.environ.get("HOME") or os.path.expanduser("~")


def sanitisations(path):
    """The directory names Claude Code may have derived from a project path."""
    out = [path.replace("/", "-"), re.sub(r"[^A-Za-z0-9]", "-", path)]
    seen, uniq = set(), []
    for name in out:
        if name not in seen:
            seen.add(name)
            uniq.append(name)
    return uniq


def project_candidates():
    """The project directory and its parents, both as given and resolved."""
    start = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    paths, seen = [], set()
    for base in (start, os.path.realpath(start)):
        path = base
        while True:
            if path not in seen:
                seen.add(path)
                paths.append(path)
            parent = os.path.dirname(path)
            if parent == path:
                break
            path = parent
    return paths


def env_session_id():
    for key in ("CLAUDE_SESSION_ID", "CLAUDE_CODE_SESSION_ID"):
        value = os.environ.get(key)
        if value:
            return value
    return None


def projects_root():
    return os.path.join(home_dir(), ".claude", "projects")


def locate(session):
    """The directory under ~/.claude/projects holding this session's files.

    Only a directory carrying this session's own transcript counts. Nothing
    else identifies the running session, so nothing else is opened.
    """
    root = projects_root()
    for path in project_candidates():
        for name in sanitisations(path):
            directory = os.path.join(root, name)
            if os.path.isfile(os.path.join(directory, session + ".jsonl")):
                return directory
    return None


def read_records(path):
    records = []
    with open(path, "r") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except ValueError:
                continue
    return records


# --- the analysis -----------------------------------------------------------

def short(text, limit=60):
    text = " ".join(str(text).split())
    if len(text) > limit:
        text = text[: limit - 3] + "..."
    return text


def tool_summary(name, inp):
    if not isinstance(inp, dict):
        return ""
    if name == "Agent":
        agent = inp.get("subagent_type") or ""
        desc = inp.get("description") or ""
        return short((agent + ": " + desc).strip(": "))
    for key in ("command", "file_path", "path", "pattern", "url", "query",
                "description", "prompt"):
        value = inp.get(key)
        if isinstance(value, str) and value.strip():
            return short(value)
    return ""


def size_of(value):
    if value is None:
        return 0
    if isinstance(value, str):
        return len(value)
    try:
        return len(json.dumps(value))
    except (TypeError, ValueError):
        return len(str(value))


def attribute(pending, tokens, step):
    """Splits one call's cache-write across the items that entered before it."""
    if tokens <= 0 or not pending:
        return []
    if len(pending) == 1:
        item = dict(pending[0])
        item.update(tokens=tokens, step=step, measured=True)
        return [item]
    sizes = [max(int(p["size"]), 1) for p in pending]
    total = sum(sizes)
    shares = [tokens * size // total for size in sizes]
    order = sorted(range(len(pending)),
                   key=lambda i: (-(tokens * sizes[i] % total), i))
    for k in range(tokens - sum(shares)):
        shares[order[k % len(order)]] += 1
    items = []
    for share, p in zip(shares, pending):
        item = dict(p)
        item.update(tokens=share, step=step, measured=False)
        items.append(item)
    return items


def analyse(records):
    """Model calls and cache-write attribution for one transcript."""
    tools = {}
    steps, by_request, items = [], {}, []
    pending = []
    have_prompt = False

    for record in records:
        kind = record.get("type")

        if kind == "assistant":
            message = record.get("message") or {}
            usage = message.get("usage") or {}
            request = (record.get("requestId") or message.get("id")
                       or "call-%d" % (len(steps) + 1))
            write = int(usage.get("cache_creation_input_tokens") or 0)
            read = int(usage.get("cache_read_input_tokens") or 0)
            out = int(usage.get("output_tokens") or 0)
            call = by_request.get(request)
            if call is None:
                call = {"request": request, "n": len(steps) + 1,
                        "write": write, "read": read, "output": out}
                by_request[request] = call
                steps.append(call)
                items.extend(attribute(pending, write, call["n"]))
                pending = []
            else:
                # Every record of one call repeats its usage; where they
                # disagree the largest value seen is the only usable one.
                call["write"] = max(call["write"], write)
                call["read"] = max(call["read"], read)
                call["output"] = max(call["output"], out)
            content = message.get("content")
            if isinstance(content, str):
                pending.append({"kind": KIND_OWN_TEXT,
                                "label": "own output: " + short(content),
                                "size": len(content)})
                continue
            for block in content or []:
                if not isinstance(block, dict):
                    continue
                btype = block.get("type")
                if btype == "tool_use":
                    name = block.get("name") or "tool"
                    summary = tool_summary(name, block.get("input"))
                    if block.get("id"):
                        tools[block["id"]] = (name, summary)
                    label = "own tool call: " + name
                    if summary:
                        label += " " + summary
                    pending.append({"kind": KIND_OWN_CALLS, "label": label,
                                    "size": size_of(block.get("input"))})
                elif btype == "thinking":
                    thought = block.get("thinking") or ""
                    pending.append({"kind": KIND_OWN_TEXT,
                                    "label": "own thinking: " + short(thought, 40),
                                    "size": len(thought)})
                else:
                    text = block.get("text") or ""
                    pending.append({"kind": KIND_OWN_TEXT,
                                    "label": "own output: " + short(text),
                                    "size": len(text)})

        elif kind == "user":
            message = record.get("message") or {}
            content = message.get("content")
            if isinstance(content, str):
                pending.append(user_text_item(content, have_prompt))
                have_prompt = True
                continue
            for block in content or []:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_result":
                    name, summary = tools.get(block.get("tool_use_id"),
                                              ("tool", ""))
                    label = name + " result"
                    if summary:
                        label += ": " + summary
                    pending.append({"kind": name + " tool output",
                                    "label": label,
                                    "size": size_of(block.get("content"))})
                else:
                    text = block.get("text") or ""
                    pending.append(user_text_item(text, have_prompt))
                    have_prompt = True

        elif kind == "attachment":
            attachment = record.get("attachment") or {}
            name = (attachment.get("hookName") or attachment.get("type")
                    or "attachment")
            pending.append({"kind": KIND_HOOK,
                            "label": "attachment: " + short(name),
                            "size": size_of(attachment)})

    return {"steps": steps, "items": items}


def user_text_item(text, have_prompt):
    if not have_prompt:
        return {"kind": KIND_PROMPT, "label": "prompt: " + short(text),
                "size": len(text)}
    return {"kind": KIND_USER, "label": "user message: " + short(text),
            "size": len(text)}


def totals(analysis):
    write = sum(call["write"] for call in analysis["steps"])
    read = sum(call["read"] for call in analysis["steps"])
    output = sum(call["output"] for call in analysis["steps"])
    return len(analysis["steps"]), write, read, output


def groups(analysis):
    """Cache-write per kind of thing that entered the context."""
    order, seen = [], {}
    for item in analysis["items"]:
        if item["tokens"] <= 0:
            continue
        entry = seen.get(item["kind"])
        if entry is None:
            entry = {"kind": item["kind"], "tokens": 0, "measured": True}
            seen[item["kind"]] = entry
            order.append(entry)
        entry["tokens"] += item["tokens"]
        if not item["measured"]:
            entry["measured"] = False
    order.sort(key=lambda e: -e["tokens"])
    return order


def top_items(analysis, limit=TOP_ITEMS):
    items = [i for i in analysis["items"] if i["tokens"] > 0]
    items.sort(key=lambda i: (-i["tokens"], i["step"], i["label"]))
    return items[:limit]


# --- the dispatches ---------------------------------------------------------

def dispatch_index(main_records):
    """Agent tool calls of the main session, by tool-use id and by prompt."""
    by_id, by_prompt = {}, {}
    for record in main_records:
        if record.get("type") != "assistant":
            continue
        content = (record.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict) or block.get("type") != "tool_use":
                continue
            if block.get("name") != "Agent":
                continue
            inp = block.get("input") or {}
            info = {"agent": inp.get("subagent_type") or "",
                    "purpose": inp.get("description") or ""}
            if block.get("id"):
                by_id[block["id"]] = info
            prompt = inp.get("prompt")
            if isinstance(prompt, str) and prompt:
                by_prompt[prompt] = info
    return by_id, by_prompt


def first_user_text(records):
    for record in records:
        if record.get("type") != "user":
            continue
        content = (record.get("message") or {}).get("content")
        if isinstance(content, str):
            return content
        for block in content or []:
            if isinstance(block, dict) and block.get("type") == "text":
                return block.get("text") or ""
    return ""


def dispatch_rows(directory, session, main_records):
    by_id, by_prompt = dispatch_index(main_records)
    subagents = os.path.join(directory, session, "subagents")
    rows = []
    try:
        names = sorted(os.listdir(subagents))
    except OSError:
        return rows
    for name in names:
        if not name.endswith(".jsonl"):
            continue
        path = os.path.join(subagents, name)
        records = read_records(path)
        if not records:
            continue
        agent, purpose = "", ""
        meta_path = path[: -len(".jsonl")] + ".meta.json"
        if os.path.isfile(meta_path):
            try:
                with open(meta_path, "r") as handle:
                    meta = json.load(handle)
                agent = meta.get("agentType") or ""
                purpose = meta.get("description") or ""
                if not purpose:
                    info = by_id.get(meta.get("toolUseId"))
                    if info:
                        purpose = info["purpose"]
            except (ValueError, OSError):
                pass
        if not agent or not purpose:
            info = by_prompt.get(first_user_text(records))
            if info:
                agent = agent or info["agent"]
                purpose = purpose or info["purpose"]
        if not agent:
            for record in records:
                if record.get("attributionAgent"):
                    agent = record["attributionAgent"]
                    break
        rows.append(make_row(agent or "subagent",
                             purpose or short(first_user_text(records)),
                             analyse(records)))
    return rows


def make_row(agent, purpose, analysis):
    steps, write, read, output = totals(analysis)
    return {"agent": agent, "purpose": purpose, "steps": steps,
            "write": write, "read": read, "output": output,
            "analysis": analysis}


# --- printing ---------------------------------------------------------------

def number(value):
    return "{:,}".format(value)


def print_table(rows):
    head = ["agent", "dispatched for", "steps", "cache-write", "cache-read",
            "output (unreliable)"]
    body = [[row["agent"], row["purpose"], str(row["steps"]),
             number(row["write"]), number(row["read"]),
             "~" + number(row["output"])] for row in rows]
    widths = [max(len(head[i]), max(len(line[i]) for line in body))
              for i in range(len(head))]
    right = (2, 3, 4, 5)

    def render(cells):
        parts = []
        for i, cell in enumerate(cells):
            parts.append(cell.rjust(widths[i]) if i in right
                         else cell.ljust(widths[i]))
        return "  ".join(parts).rstrip()

    print(render(head))
    print("  ".join("-" * w for w in widths))
    for line in body:
        print(render(line))


def print_detail(row):
    title = row["agent"]
    if row["purpose"]:
        title += " - " + row["purpose"]
    print(title)
    print("  where its " + number(row["write"])
          + " cache-write tokens entered the context, by kind:")
    grouped = groups(row["analysis"])
    if not grouped:
        print("    (nothing the transcript attributes to an item)")
    for entry in grouped:
        print("    %-34s %14s  %s"
              % (short(entry["kind"], 34), number(entry["tokens"]),
                 "measured" if entry["measured"] else "estimated"))
    print("  the most expensive items:")
    items = top_items(row["analysis"])
    if not items:
        print("    (nothing the transcript attributes to an item)")
    for item in items:
        print("    step %-4d %14s  %-9s  %s"
              % (item["step"], number(item["tokens"]),
                 "measured" if item["measured"] else "estimated",
                 item["label"]))


def print_notes():
    print("Notes")
    print("  steps are model calls, not transcript records: one call is")
    print("  written as one record per content block, and each of those")
    print("  records repeats the call's token figures.")
    print("  output (~) is unreliable: within one call the records disagree")
    print("  (a placeholder beside the real count), so the largest value seen")
    print("  for a call is shown as a marked figure, not as a count.")
    print("  measured = one call's whole cache-write, with a single item")
    print("  entering the context before it.")
    print("  estimated = one call's cache-write split proportionally across")
    print("  the items that entered together.")


def main():
    session = env_session_id()
    if not session:
        sys.stderr.write(
            "token-cost: cannot identify the running session - neither "
            "CLAUDE_SESSION_ID nor CLAUDE_CODE_SESSION_ID names one. "
            "Reporting the newest transcript instead would report a session "
            "nobody asked about, so nothing is read.\n")
        return 1
    directory = locate(session)
    if directory is None:
        sys.stderr.write("token-cost: no transcript for session " + session
                         + " under " + projects_root() + "\n")
        return 1
    transcript = os.path.join(directory, session + ".jsonl")

    main_records = [r for r in read_records(transcript)
                    if not r.get("isSidechain")]
    rows = [make_row("main session", "the run itself", analyse(main_records))]
    rows.extend(dispatch_rows(directory, session, main_records))
    rows.sort(key=lambda row: (-row["read"], row["agent"], row["purpose"]))

    print("What this session cost - session " + session)
    print("%d dispatch(es) and the main session, read from the session's own "
          "transcripts." % (len(rows) - 1))
    print("")
    print_table(rows)
    print("")
    for row in rows:
        print_detail(row)
        print("")
    print_notes()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except BrokenPipeError:
        # The reader closed the pipe first - `| head` is the usual case.
        os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
        sys.exit(0)
