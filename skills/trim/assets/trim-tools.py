#!/usr/bin/env python3
"""probe / propose / apply — the commands behind the "trim" skill (issue 0036).

Every step-1 request in a Claude Code session carries the schema of every
eagerly loaded tool, whether anything calls it or not. This script measures
that cost for one repository and, if asked, writes a deny list that removes
it from every request in every future session.

    python3 trim-tools.py probe <DIR>
        One real, single-turn headless `claude` call in DIR, then reads that
        new session's own transcript under ~/.claude/projects/ and prints
        "before: <N> tokens", where N is the transcript's first model call's
        cache_creation_input_tokens + cache_read_input_tokens + input_tokens
        — the whole step-1 prompt, tool schemas included. Writes nothing
        under DIR.

    python3 trim-tools.py propose <DIR>
        Runs one probe as above (so its "before: <N> tokens" line is also
        this command's first line), then prints one "deny: <ToolName> ..."
        line per tool that probe session showed as eagerly loaded (present
        in the session's own tool set, absent from its own
        "deferred_tools_delta" attachment) and that is not one of the
        protected tools the Metis workflow itself depends on (Skill, Agent,
        Task, AskUserQuestion, ToolSearch, Read, Write, Edit, Glob, Grep,
        Bash — "Task" is "Agent"'s name in a headless session). Writes
        nothing under DIR.

    python3 trim-tools.py apply <DIR> <BEFORE> <TOOL[,TOOL...]>
        Writes TOOL[,TOOL...] into DIR/.claude/settings.json under
        permissions.deny — creating the file if it is absent, with that as
        its only key; merging into it if it is present, leaving every other
        key and every existing permissions.deny entry untouched — then runs
        one more real probe in DIR with the list applied and prints
        "before: <BEFORE> tokens", "after: <N> tokens" and
        "difference: <BEFORE - N> tokens", followed by a line stating that
        the written list applies only to sessions started after this point,
        not to the session that ran the skill. BEFORE is a figure the
        caller already has from an earlier probe or propose call — apply
        does not re-measure "before" itself.

Locating a session's own transcript directory under ~/.claude/projects/ and
reading a transcript record's usage figures mirrors
skills/cost/assets/token-cost.py, which reads the same transcript format for
the session already running it; this script instead spawns brand-new probe
sessions of its own and reads each one's own transcript in turn, one call at
a time, distinguished by a fresh --session-id per call so that repeated
probes against the same DIR (propose's own probe, then apply's) can never be
confused with one another.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import uuid

PROBE_PROMPT = "Reply with exactly the single word: ready"

CLAUDE_BIN = os.environ.get("TRIM_CLAUDE_BIN", "claude")

PROTECTED = {"Skill", "Agent", "Task", "AskUserQuestion", "ToolSearch",
             "Read", "Write", "Edit", "Glob", "Grep", "Bash"}
# "Task" is the subagent-dispatch tool's name in a headless `claude -p`
# session — the only kind probe/propose ever spawn — even though the same
# tool is named "Agent" in an interactive session. Both names are kept:
# "Agent" costs nothing to keep and covers a future/different environment
# whose headless mode calls it that instead.

PROBE_TIMEOUT_S = 180


# --- locating and reading a probe session's own transcript -----------------
# (mirrors skills/cost/assets/token-cost.py's sanitisations()/locate())

def home_dir():
    return os.environ.get("HOME") or os.path.expanduser("~")


def projects_root():
    return os.path.join(home_dir(), ".claude", "projects")


def sanitisations(path):
    """The directory names Claude Code may have derived from a project path."""
    out = [path.replace("/", "-"), re.sub(r"[^A-Za-z0-9]", "-", path)]
    seen, uniq = set(), []
    for name in out:
        if name not in seen:
            seen.add(name)
            uniq.append(name)
    return uniq


def project_dir_for(directory):
    """The directory under ~/.claude/projects/ holding DIR's own sessions."""
    root = projects_root()
    candidates = [directory, os.path.realpath(directory)]
    seen = set()
    for base in candidates:
        for name in sanitisations(base):
            if name in seen:
                continue
            seen.add(name)
            d = os.path.join(root, name)
            if os.path.isdir(d):
                return d
    return None


def read_records(path):
    records = []
    with open(path, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except ValueError:
                continue
    return records


def step1_tokens(records):
    """The transcript's first model call's cache_creation + cache_read +
    input tokens — the whole step-1 prompt. Every record of one call
    repeats its usage; where they disagree the largest value seen is the
    only usable one (mirrors token-cost.py)."""
    first_request = None
    write = read = inp = 0
    for rec in records:
        if rec.get("type") != "assistant":
            continue
        message = rec.get("message") or {}
        req = rec.get("requestId") or message.get("id")
        if first_request is None:
            first_request = req
        if req != first_request:
            continue
        usage = message.get("usage") or {}
        write = max(write, int(usage.get("cache_creation_input_tokens") or 0))
        read = max(read, int(usage.get("cache_read_input_tokens") or 0))
        inp = max(inp, int(usage.get("input_tokens") or 0))
    return write + read + inp


def deferred_tool_names(records):
    """Tool names the session itself marked deferred — present as a name
    only, not sent as a schema in the step-1 prompt. Read from this
    session's own "deferred_tools_delta" attachment records."""
    names = set()
    for rec in records:
        if rec.get("type") != "attachment":
            continue
        att = rec.get("attachment") or {}
        if att.get("type") != "deferred_tools_delta":
            continue
        for n in att.get("addedNames") or []:
            names.add(n)
        for n in att.get("removedNames") or []:
            names.discard(n)
        for n in att.get("readdedNames") or []:
            names.add(n)
    return names


# --- running one real probe --------------------------------------------

def run_probe(directory, want_tools):
    """One real, single-turn headless `claude` call in `directory`, with a
    fresh --session-id so this call's own transcript can never be confused
    with an earlier probe's in the same directory. Returns
    (records, tools-or-None) — tools is the session's full tool inventory,
    read from the run's own "system"/"init" event, when want_tools is set.
    """
    session_id = str(uuid.uuid4())
    output_format = "stream-json" if want_tools else "json"
    cmd = [CLAUDE_BIN, "-p", PROBE_PROMPT,
           "--session-id", session_id,
           "--output-format", output_format]
    if want_tools:
        cmd.append("--verbose")
    try:
        proc = subprocess.run(cmd, cwd=directory, stdin=subprocess.DEVNULL,
                               capture_output=True, text=True,
                               timeout=PROBE_TIMEOUT_S)
    except FileNotFoundError:
        raise RuntimeError("no '%s' binary on PATH" % CLAUDE_BIN)
    except subprocess.TimeoutExpired:
        raise RuntimeError("claude did not finish within %ds in %s"
                            % (PROBE_TIMEOUT_S, directory))
    if proc.returncode != 0:
        detail = (proc.stderr or proc.stdout or "").strip()
        raise RuntimeError("claude exited %d in %s: %s"
                            % (proc.returncode, directory, detail[:2000]))

    tools = None
    if want_tools:
        for line in proc.stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            if obj.get("type") == "system" and obj.get("subtype") == "init":
                tools = obj.get("tools") or []

    pdir = project_dir_for(directory)
    if pdir is None:
        raise RuntimeError("no project directory under %s for %s"
                            % (projects_root(), directory))
    transcript = os.path.join(pdir, session_id + ".jsonl")
    # The CLI has already exited, so its transcript should be on disk; a
    # short retry only guards against a filesystem that has not caught up
    # yet, not against the file genuinely never appearing.
    for attempt in range(10):
        if os.path.isfile(transcript):
            break
        time.sleep(0.3)
    else:
        raise RuntimeError("no transcript file %s" % transcript)

    records = read_records(transcript)
    return records, tools


# --- settings.json ----------------------------------------------------------

def load_settings(path):
    if not os.path.isfile(path):
        return {}
    with open(path, "r") as fh:
        return json.load(fh)


def write_deny_list(directory, tools):
    """Merges `tools` into DIR/.claude/settings.json's permissions.deny,
    creating the file (with permissions.deny as its only key) if absent,
    leaving every other key and every existing deny entry untouched if
    present."""
    settings_dir = os.path.join(directory, ".claude")
    settings_path = os.path.join(settings_dir, "settings.json")
    os.makedirs(settings_dir, exist_ok=True)

    data = load_settings(settings_path)
    if not isinstance(data, dict):
        raise RuntimeError("%s does not hold a JSON object" % settings_path)

    permissions = data.get("permissions")
    if not isinstance(permissions, dict):
        permissions = {}
        data["permissions"] = permissions

    deny = permissions.get("deny")
    if not isinstance(deny, list):
        deny = []
    merged = list(deny)
    for tool in tools:
        if tool not in merged:
            merged.append(tool)
    permissions["deny"] = merged

    with open(settings_path, "w") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")

    return settings_path


# --- subcommands -------------------------------------------------------

def cmd_probe(directory):
    records, _ = run_probe(directory, want_tools=False)
    tokens = step1_tokens(records)
    print("before: %d tokens" % tokens)
    return 0


def cmd_propose(directory):
    records, tools = run_probe(directory, want_tools=True)
    tokens = step1_tokens(records)
    print("before: %d tokens" % tokens)

    if tools is None:
        raise RuntimeError(
            "the probe session reported no tool inventory (no system/init "
            "event with a 'tools' field) — cannot tell which tools were "
            "eagerly loaded")

    deferred = deferred_tool_names(records)
    eager = [t for t in tools if t not in deferred]
    proposal = sorted(t for t in eager if t not in PROTECTED)

    for name in proposal:
        print("deny: %s — eagerly loaded in this probe session, not one of "
              "the protected tools" % name)
    return 0


def cmd_apply(directory, before, tools_csv):
    tools = [t.strip() for t in tools_csv.split(",") if t.strip()]
    if not tools:
        raise RuntimeError("no tool names given to apply")

    settings_path = write_deny_list(directory, tools)

    records, _ = run_probe(directory, want_tools=False)
    after = step1_tokens(records)
    difference = before - after

    print("before: %d tokens" % before)
    print("after: %d tokens" % after)
    print("difference: %d tokens" % difference)
    print("Written to %s. This list applies only to sessions started after "
          "this point, not to the session that ran this skill."
          % settings_path)
    return 0


def main(argv):
    parser = argparse.ArgumentParser(
        description="probe/propose/apply for the trim skill (issue 0036)")
    sub = parser.add_subparsers(dest="command", required=True)

    p_probe = sub.add_parser("probe")
    p_probe.add_argument("dir")

    p_propose = sub.add_parser("propose")
    p_propose.add_argument("dir")

    p_apply = sub.add_parser("apply")
    p_apply.add_argument("dir")
    p_apply.add_argument("before")
    p_apply.add_argument("tools")

    args = parser.parse_args(argv)

    # Resolved once, right where a raw CLI argument enters the code, so that
    # every downstream use — sanitisation, the probe subprocess's cwd,
    # settings.json's path — works from one absolute directory and no
    # relative string (e.g. the "." SKILL.md itself documents) ever reaches
    # sanitisations() unresolved.
    directory = os.path.abspath(args.dir)

    try:
        if args.command == "probe":
            return cmd_probe(directory)
        if args.command == "propose":
            return cmd_propose(directory)
        if args.command == "apply":
            before = int(str(args.before).replace(",", "").replace("_", ""))
            return cmd_apply(directory, before, args.tools)
    except RuntimeError as exc:
        sys.stderr.write("trim-tools: %s\n" % exc)
        return 1
    except ValueError as exc:
        sys.stderr.write("trim-tools: %s\n" % exc)
        return 1

    parser.error("unknown command %r" % args.command)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
