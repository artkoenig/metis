---
status: backlog
branch:
pr:
---

# A session can register subagents from a pre-update clone

## Intent

The start hook clones or pulls metis and symlinks its agents into `~/.claude`,
so a session is supposed to run the current definitions. In issue 0028's run it
did not. The dispatched `reviewer` reported that the definition it had been
given lacked the record and blast-radius checks — the ones commit `2932063`
added — while the file it links to was already current: `diff
/root/.claude/metis/agents/reviewer/agent.md agents/reviewer/agent.md` is empty
and the clone stands at `2932063`. The session's own agent list still carries
the pre-`2932063` reviewer description, so the definitions were registered from
the clone as it stood before the hook updated it.

The consequence is not cosmetic. The rulebook now bounds what a dispatch may
hand over by the receiver's own page, so a stale registration silently changes
what the caller is allowed to send — and it silently drops whatever checks the
newer definition added, which is how a review round can miss what it was
extended to catch.

Wanted observable behaviour: the definition a session dispatches is the
definition in the clone the start hook left behind.

Acceptance criteria:

1. When the start hook updates the clone during a session's start, the
   subagent definitions that session dispatches are the updated ones — shown by
   dispatching an agent whose definition changed in that update and having it
   report a sentence only the new version contains.
2. When that cannot be made to hold — the registration happens before the hook
   can run — the session says so at start, in the same status line the
   self-check already prints, rather than leaving the discrepancy invisible.

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
