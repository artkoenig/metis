---
status: active
branch: claude/new-session-xeyz5n
pr:
---

# The self-check ignores the hooksPath step

## Intent

The session self-check (issue 0009) verifies skills, agents and the
rulebook — but not the fourth sync step: pointing the project's
`core.hooksPath` at metis's `.githooks`, which is what refuses a direct
push to the default branch. When that step is silently skipped (for
example, `CLAUDE_PROJECT_DIR` is not a git repository), the status still
says "no errors" — the same skipped-outcome-reported-as-success class the
0009 review kept finding, at the one step its self-check does not cover.

Reproduction (0009 review round 6): core run with `CLAUDE_PROJECT_DIR`
pointing at a non-git directory — the log shows no `hooksPath` line, fd 3
carries "no errors", and the push guard is absent.

Wanted behaviour: a session whose push guard did not get installed learns
that from the self-check status, not from an unguarded push later.

Acceptance criteria:

1. The status reflects the hooksPath outcome: set, or why not.
2. The test harness has a case for the skipped step.

## Plan

## Tasks

## Decisions

- Filed from 0009's review round 6, finding 2: outside 0009's criteria as
  written (they enumerate skills and agent links), so a follow-up rather
  than a fix in that run. (by agent)

## Log

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — two narrow criteria with a recorded
  reproduction from 0009 round 6; a core-script + harness change, dispatched
  to the implementer.
- What surprised me? Nothing yet.
- What am I assuming without having verified it? That "why not" can be a
  short reason in the status (e.g. "hooksPath skipped: project is not a git
  repository") without breaking the status sanitizer or the JSON emit — the
  implementer verifies against the harness.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
