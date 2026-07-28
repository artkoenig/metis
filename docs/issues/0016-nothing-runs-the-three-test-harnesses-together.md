---
status: backlog
branch:
pr:
---

# Nothing runs the three test harnesses together

## Intent

The repo now carries three suites — `test-install.sh` (repo root),
`test-session-start-core.sh` and `test-session-start-loader.sh` (bootstrap
assets) — and nothing invokes them together: no CI, no top-level runner.
Each must be run by hand, so "the suite is green" costs three commands and
a change can honestly forget one. Noted by the 0010 implementer, promoted
to an issue by the 0010 review round 2 (the log said "filed" while nothing
was filed).

Wanted behaviour: one command runs every suite and exits non-zero if any
case fails.

Acceptance criteria:

1. A single command at the repo root runs all three suites and exits 0
   only when all pass; a failing case in any suite makes it exit non-zero.
2. The bootstrap skill's "Keeping it honest" section (the one place
   enumerating suites) names the runner.

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
