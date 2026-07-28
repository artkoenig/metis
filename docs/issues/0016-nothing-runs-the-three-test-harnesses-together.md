---
status: done
branch: claude/offene-issues-3hysxf
pr: https://github.com/artkoenig/metis/pull/21
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
- Because the three issues share one branch and one PR, `done` is set when
  this issue's work is complete on the branch; the `pr:` field is filled
  in when the shared PR opens. Otherwise two issues would be `active` at
  once, which the state rules forbid. (default, unanswered)

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
- Review round 1 (fresh context, diff 630832b..HEAD): zero findings. The
  reviewer reproduced both command facts independently, plus two more
  (two sabotaged suites → "FAIL: 2 of 3", missing suite file → exit 127
  counts as failure), and confirmed the no-fourth-suite assumption by
  `find`. Both criteria met. Trend: round 1 = 0 findings — converged,
  no repeat round due.

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

- Does this match what was asked? Yes — `bash test.sh` exit 0 runs all
  three suites; sabotage makes it exit 1; the skill names the runner.
  Review round 1 found nothing.
- What surprised me? The metis reviewer subagent is not a registered
  subagent type in this cloud harness; the review ran as a
  general-purpose agent given the reviewer definition verbatim — same
  fresh context, recorded here so the next session knows.
- What am I assuming without having verified it? That the human accepts
  one PR for three issues (recorded as a default in Decisions).

## Retro

- What got in the way: the metis `reviewer` was not a registered
  subagent type when the reviews ran — `Agent(subagent_type:
  "reviewer")` failed. Worked around by running a general-purpose agent
  with the reviewer definition pasted verbatim; same fresh context, but
  the definition can silently drift from the pasted copy. Resolved
  mid-session: the hook's links were fine all along ("4 agents
  reachable"), the harness just builds its subagent registry at session
  start before the links land and only picked them up on a later
  refresh. So: not a loader bug; a session whose early turns need the
  reviewer may still have to fall back to pasting the definition.
- The branch-pinned cloud session cannot honour "one issue = one branch
  = one PR" for a "fix all open issues" request. This run's default
  (sequential runs, one commit pair each, one shared PR, `done` at
  work-complete) worked; if bundled sessions recur, the rulebook could
  say so in one line.
- Flagged by the human after the run: the runs opened without showing
  the issues — title and numbered criteria as a table — before
  implementation, which "The run" requires; the tables only appeared in
  the closing summary. Agent error, not a rule gap; the rule stands.
  This note applies to all three runs of this session (0016-0018).
