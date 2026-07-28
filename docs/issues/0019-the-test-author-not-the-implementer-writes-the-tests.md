---
status: done
branch: claude/offene-issues-3hysxf
pr: https://github.com/artkoenig/metis/pull/22
---

# The test-author, not the implementer, writes the tests

## Intent

Invariant 2 has the implementer write the tests for its own change — it
verifies its own reading of the intent, which is circular. Meanwhile the
test-author sat on the shelf unused: zero dispatches in eighteen issues,
and the one run whose criteria matched its trigger exactly (0017,
absence criteria) went by without it. The human settled it in
conversation: whether a change needs tests at all stays the agent's
judgment — but when tests are due, the test-author writes them, blind,
from the intent alone. With that role change comes the sharpening
discussed alongside it: criteria get tested at their edges, and an edge
the criteria leave open is a question, never a guess.

Wanted behaviour: the rulebook and the test-author's page say this, in
as few words as the current texts use, and no document still calls the
implementer the test writer.

Acceptance criteria:

1. The rulebook's invariant 2 states: whether a change has anything to
   run is the agent's call, and "nothing to run" stays a valid, stated
   outcome; when tests are due, the test-author writes them from the
   intent alone and sees them fail, and the implementer makes them pass
   without editing them.
2. The test-author's page drops the "shelf tool, not a default" framing
   and describes the default role; the rulebook's shelf list no longer
   carries a test-author entry.
3. The test-author's page mandates edge coverage: each criterion is
   tested at its boundaries as well as its centre, and an edge the
   criteria do not decide comes back as a question (`blocked`), never as
   a test with a guessed expectation.
4. `README.md` stays in step: its invariant summary and run diagram no
   longer name the implementer as the test writer.

## Plan

## Tasks

## Decisions

- Source of the role change: the human's answer, 2026-07-28 — "du
  entscheidest selbst, ob die Tests benötigt werden und wenn ja, dann
  soll der testauthor die Test schreiben." Judgment stays on *whether*;
  the *who* is now fixed. (by human)
- Edge-case mandate included in the same run: it changes only the same
  two texts and was part of the same conversation; the human asked
  whether specialising the test-author on red tests with edge cases
  makes sense and the answer ("edges of the given criteria, undecided
  edges come back as questions") drew no objection. (default,
  unanswered)
- Same branch constraint as 0016-0018: the session is pinned to
  `claude/offene-issues-3hysxf`; this run is the only one on the branch
  this time, so one issue = one branch = one PR holds again. (by agent)

## Log

- Edits, all prose: `AGENTS.md` (invariant 2 reworded, test-author out of
  the shelf list, run diagram gains the test-author step),
  `agents/test-author/agent.md` (default-role description, edge mandate
  in step 2), `agents/implementer/agent.md` (no longer writes tests,
  may not edit the handed ones), `agents/reviewer/agent.md` (check 3 now
  checks the test-author's blind reading, edges included), `README.md`
  (invariant summary and diagram).
- Cross-check that no document still calls the implementer the test
  writer: `grep -rn "tests first|writes the tests|own tests"` outside
  `docs/issues/` — remaining hits all name the test-author. Issue files
  stay untouched: they are history, not documentation to keep in step.
- Nothing to run: rulebook, agent pages, README. By the invariant this
  change itself lands, that is a stated outcome, not a gap — and the
  test-author is not dispatched for it. The review is the only check.
- The branch also carries one cherry-picked bookkeeping commit from the
  merged predecessor (62690a0, a 0016 retro correction that had missed
  PR 21) — no file this issue's criteria are about.
- Suite fact for the record (ran before the commit, now recorded per
  review finding 1): `bash test.sh`, 30 cases across the three suites,
  exit 0 — regression check only; no case covers these prose files.
- Review round 1 (fresh context, real `reviewer` subagent — registered
  in this session, unlike yesterday —, diff 535087a..HEAD): all four
  criteria met; 3 findings, none violating a criterion. Triage:
  (1) suite pass missing from the record → recorded above, record-only;
  (2) implementer description self-contradictory on the nothing-to-run
  path ("and the tests exist") → fixed: "and the test-author's tests
  exist — or the change has nothing to run"; (3) informational, the
  cherry-picked 0016 retro commit, disclosed to the human as a note.
  Fix 2 touches a file the criteria are about → repeat round due, no
  waiver. Trend: AC1-4 each 0, no-criterion 3 → total 3.
- Review round 2 (fresh context, whole intent, diff 535087a..HEAD): all
  four criteria met, zero criterion-violating findings; two
  informational notes (the disclosed 0016 retro cherry-pick; round-1 fix
  verified landed). Suite re-established independently: `bash test.sh`,
  30 cases, exit 0, regression-only scope. Trend: 3 → 0 actionable —
  converged.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — the human fixed the *who*
  (test-author writes, when tests are due) and left the *whether* to
  judgment; the criteria say exactly that plus the edge mandate from the
  same conversation.
- What surprised me? Beyond the named texts, three agent definitions
  would become wrong and must move in the same change (bookkeeping
  rule): the implementer's page ("writes the tests first"), the
  reviewer's check 3 ("the implementer wrote its own tests"), and the
  test-author's own framing. The criteria's "no document still calls the
  implementer the test writer" covers them.
- What am I assuming without having verified it? That this change has
  nothing to run — it is prose (rulebook, agent pages, README); per
  invariant 3 the fresh review is its only check. Which also means: no
  test-author dispatch for this run, by the very rule it lands.

### Before the PR

- Does this match what was asked? Yes — the who is fixed (test-author),
  the whether stays judgment, edges are mandated, and no document names
  the implementer as test writer any more; two fresh rounds confirmed
  all four criteria.
- What surprised me? Little — except my own round-1 miss: I claimed "the
  review is the only check" while leaving the suite fact out of the
  record; invariant 4 wants the exit code written down even when it only
  proves absence of regression.
- What am I assuming without having verified it? That the running
  session's stale copies (pre-change rulebook, synced at session start)
  cause no confusion before the merge — the next session loads the new
  texts fresh.

## Retro

- What got in the way: almost nothing — the registered `reviewer`
  subagent made this run smoother than yesterday's. My one slip was
  leaving the suite fact out of the record while claiming "the review is
  the only check"; round 1 caught it. The rule held; no rulebook change
  proposed.
- First run under the new invariant it lands: correctly no test-author
  dispatch (nothing to run). The real proof comes with the next change
  that has something to run — watch that run's record for how the
  test-author brief works in practice.
