---
status: backlog
branch:
pr:
---

# The installer dies mid-install on a broken settings.json

## Intent

`install.sh` checks its git preconditions before writing anything, but not
the settings file: a `.claude/settings.json` that is invalid JSON, or valid
JSON of an unexpected shape (`{"hooks": []}`, a non-dict entry under
`SessionStart`), makes the merge step fail after the hook file is already
written — with a raw Python traceback or a message that comes too late.
Nothing is lost and a re-run after fixing the file completes the install,
but the refusal is neither clean nor complete. Found by review rounds 2–4
of issue 0013 and shipped as a known edge by the human's default.

A second gap from the same review: the test harness always points
`METIS_SOURCE` at a local directory, so the installer's curl branch is
never exercised by the suite — a regression there would pass.

Wanted behaviour: the installer refuses cleanly before writing anything,
whatever shape the settings file is in, and the harness would catch a
broken curl branch.

Acceptance criteria:

1. With a `.claude/settings.json` that is invalid JSON, the installer exits
   non-zero with an `install.sh:`-prefixed message and has written nothing —
   no hook file, no settings change, no commit.
2. The same holds for valid JSON of unexpected shape: `{"hooks": []}` and a
   non-dict entry inside `hooks.SessionStart`.
3. The test harness covers both cases and exercises the curl branch of the
   source fetch (e.g. against a local HTTP server), all shown by exit code.

## Plan

## Tasks

## Decisions

## Log

## Checkpoints

### Before implementation

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
