---
status: active
branch: claude/offene-issues-3hysxf
pr:
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

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
