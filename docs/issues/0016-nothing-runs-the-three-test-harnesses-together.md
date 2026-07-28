---
status: active
branch: claude/offene-issues-3hysxf
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

- This cloud session is pinned to the branch `claude/offene-issues-3hysxf`
  and may push nowhere else, so "one issue = one branch = one PR" cannot
  hold literally. Default taken: issues 0016, 0017 and 0018 are worked
  sequentially on this branch, one commit per issue, one PR for all three.
  (default, unanswered)
- The runner gets no test harness of its own: it is a few lines of glue,
  and a harness for the harness-runner starts a regress. Both directions
  of criterion 1 are shown by recorded commands instead — runner on the
  intact repo exits 0, runner on a scratch copy with one sabotaged suite
  exits non-zero. (default, unanswered)
- Runner named `test.sh` at the repo root, beside `test-install.sh`.
  (default, unanswered)

## Log

- Baseline before any change: all three suites pass individually (exit 0
  each).
- Runner written as `test.sh` (repo root): fixed list of the three suites,
  runs each, exits 0 only when all pass. "Test first" here is the two
  recorded command facts, per the decision above:
  - `bash test.sh` on the intact repo → exit 0, "PASS: all 3 suites".
  - `bash test.sh` in a scratch copy with `test-session-start-core.sh`
    replaced by `exit 1` → exit 1, "FAIL: 1 of 3 suite(s)".
- `skills/bootstrap/SKILL.md` "Keeping it honest" now names the runner
  (criterion 2). `README.md` enumerates no suites, so nothing to keep in
  step there.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — one command, all three suites,
  non-zero on any failure; the skill's "Keeping it honest" section names
  it. Baseline established first: all three suites pass individually
  (`bash test-install.sh` exit 0, `bash
  skills/bootstrap/assets/test-session-start-core.sh` exit 0, `bash
  skills/bootstrap/assets/test-session-start-loader.sh` exit 0).
- What surprised me? Nothing yet.
- What am I assuming without having verified it? That no fourth suite
  exists — checked by listing the repo root and `skills/bootstrap/assets/`;
  only the three named harnesses match the `test-*.sh` pattern.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
