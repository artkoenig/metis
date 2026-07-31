---
name: trim
description: Measure and shrink the tool-schema cost every step of a repository's Claude Code sessions pays. Proposes a permissions.deny list for the tools this repository's sessions eagerly load but the human does not want, and writes the agreed list into .claude/settings.json. Run it once per repository, or whenever the loaded tool set has changed. Also trigger on "trim the tools", "cut the tool schema cost", "why are my sessions so expensive", or "deny list for tools".
user-invocable: true
---

# Trim

Every request in a session re-sends the schema of every eagerly loaded tool,
whether anything calls it or not — a tool nobody calls is still paid for at
every step. This skill measures what this repository's own sessions load,
proposes which of those tools to stop loading, and — once the human agrees —
writes that list into `.claude/settings.json`, where `permissions.deny`
removes a tool's schema from the request instead of merely blocking the call.

## How to run it

The command behind this skill is `trim-tools.py`, next to this page in
`assets/`, wherever this page sits — plugin cache, `~/.claude/skills`, a
checkout. It is a non-interactive script; the human-in-the-loop step below
is this page's job, not the script's.

1. **Propose.** From the project directory:

   ```
   python3 <this-skill>/assets/trim-tools.py propose .
   ```

   This starts one real, fresh headless `claude` session in the current
   directory and reads that session's own transcript. It prints the
   repository's current step-1 prompt size — `before: <N> tokens`, the
   `cache_creation` + `cache_read` + `input` tokens of that session's very
   first model call, tool schemas included — followed by one
   `deny: <ToolName> ...` line per tool it proposes denying. Only tools that
   session eagerly loaded are proposed, and never `Skill`, `Agent`, `Task`,
   `AskUserQuestion`, `ToolSearch`, `Read`, `Write`, `Edit`, `Glob`, `Grep` or
   `Bash` — the Metis workflow depends on all of these (`Task` is `Agent`'s
   name in the headless sessions `propose` itself spawns), so they are never
   offered, regardless of what a session loads. Nothing is written yet.

2. **Show the human, let them object.** Before writing anything, present the
   proposed list to the human — with `AskUserQuestion` if the list is short
   enough for it, otherwise as plain text — and let them remove any entry
   they want to keep. This is the point where a tool the human actually
   wants stays out of the deny list; the script itself never asks, it only
   proposes. Keep the `before:` figure from step 1 — the next step needs it.

3. **Apply.** With whatever the human left in the list (comma-separated, no
   spaces needed):

   ```
   python3 <this-skill>/assets/trim-tools.py apply . <BEFORE> <Tool1,Tool2,...>
   ```

   This writes the agreed tools into `.claude/settings.json` under
   `permissions.deny` — creating the file if it is absent, with
   `permissions.deny` as its only key; merging into it if it is present,
   leaving every other key and every existing `permissions.deny` entry
   untouched. It then starts one more real headless session with the list
   applied, reads that session's own transcript the same way, and prints
   `before: <N> tokens`, `after: <N> tokens` and `difference: <N> tokens`,
   followed by a line stating that the written list applies only to
   sessions started after this point — not to the session that ran the
   skill; nothing in the current, already-running session gets smaller.

4. **Record it.** Note the before/after/difference figures and which tools
   were denied — through the `issue` skill if this run is part of tracked
   work, the same way any other fact by exit code lands in the record.

## What it is not

Not automatic and not silent: nothing is written before the human has seen
the proposal and had the chance to object. Not a per-tool cost table either
— the skill measures the whole step-1 prompt before and after, not a figure
behind each tool name; a per-tool breakdown would need one headless run per
tool and would be wrong the moment a repository's MCP servers differ from
whichever one the table was built from.

`skills/trim/assets/test-trim-tools.sh` guards `trim-tools.py`; `test.sh`
runs that suite with the others.
