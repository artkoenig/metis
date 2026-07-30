---
status: backlog
branch:
pr:
---

# Findings outside the criteria buy another full round

## Intent

A review round costs roughly 75 model steps and 4.5M cache-read tokens
(measured in issue 0022). A round happens because the previous round's findings
produced a fix, so what gets fixed decides what a run costs. In issue 0022's
rounds, most findings belonged to no acceptance criterion at all:

| round | findings | of them, on no criterion |
| --- | --- | --- |
| 1 | 6 | 1 |
| 2 | 9 | 7 |
| 3 | 6 | 5 |

Several of the criterion-less ones were repaired inside the run — README prose
about coexistence costs, a skill page's wording — and each repair was new diff
for the next round to review in full. `AGENTS.md:134` already says such a
finding goes to the human instead of being fixed by default, so the rule was
there and was broken. It was broken because nothing in a finding says which
criterion it belongs to: the classification happened afterwards, in the same
judgment that had already decided to fix the thing.

Wanted observable behaviour: whether a finding is inside the change's intent is
visible in the finding itself, before anything is decided about it — and a
finding outside it leaves the run's diff alone.

Acceptance criteria:

1. When the reviewer reports a finding, that finding names the acceptance
   criterion it violates, or states that it violates none.
2. When a finding violates no criterion and is not a document this change
   itself made wrong, no fix for it appears in the run's diff, and the record
   says whether it was filed as its own issue or handed to the human.
3. When a round's findings are recorded, the trend table's row for findings on
   no criterion is filled from the reviewer's own classification, not from a
   later reading of the findings.
4. `agents/reviewer.md` and `AGENTS.md` describe this and do not contradict
   each other.

## Plan

## Tasks

## Decisions

- The exception in criterion 2 — a document the change itself made wrong is
  fixed in the run even when no criterion names it — comes from the agent's
  judgment during issue 0022 and is recorded there. It follows the rulebook's
  standing rule that a change which makes a document wrong updates it in the
  same change.

## Log

- Filed after issue 0022's run, on the human's request, out of the token
  measurements taken during it. The measurement that motivates it is the cost
  of a review round; the trend numbers come from that issue's own record.
- Two findings of that run's last round were handled the way this issue wants —
  filed as issues 0023 and 0024 instead of fixed — and that decision was the
  human's, not the workflow's. Making it the default is the point here.

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
