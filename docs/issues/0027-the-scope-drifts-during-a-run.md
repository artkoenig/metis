---
status: active
branch: claude/offene-probleme-fivte0
pr:
---

# The scope drifts during a run

## Intent

A run's scope is the acceptance criteria written before implementation. In issue
0022's run it did not hold: most findings of each review round belonged to no
criterion at all, and several of them were repaired inside the run anyway.

| round | findings | of them, on no criterion |
| --- | --- | --- |
| 1 | 6 | 1 |
| 2 | 9 | 7 |
| 3 | 6 | 5 |

`README.md` grew by 76 lines in that run, most of which no criterion asked for.
Every such repair also cost a full further review round — roughly 75 model steps
and 4.5M cache-read tokens, measured in that issue — but the cost is the
symptom. The defect is that the scope moved while the run was in progress.

`AGENTS.md:134` already says a finding outside the issue's intent goes to the
human instead of being fixed, so the rule existed and was broken. It was broken
because nothing forces the question to be asked at the right moment: a finding
does not say which criterion it violates, so the classification happened
afterwards, inside the same judgment that had already decided to repair the
thing.

Wanted observable behaviour: the criteria written before implementation are the
criteria the run is judged by at its pull request, and nothing outside them is
repaired on the way — findings outside them become their own issues.

Acceptance criteria:

1. When the reviewer reports a finding, that finding names the acceptance
   criterion it violates, or states that it violates none.
2. When a finding violates no criterion, the run's diff contains no fix for it,
   and the record names the issue it was filed as. A finding without a
   reproduction is not a finding — the rulebook already dismisses it.
3. When a change falsifies a statement in this repository's own documentation,
   correcting that statement belongs to the change, and the correction is
   limited to the statements the change falsified — content that no criterion
   asks for is drift like any other.
4. When a run opens its pull request, the issue's acceptance criteria read
   word for word as they did before implementation began: a finding, a review
   round or any other feedback never adds, edits or reinterprets one.
5. `agents/reviewer.md` and `AGENTS.md` describe this and do not contradict
   each other.

## Plan

## Tasks

## Decisions

- The scope is fixed once implementation starts and no feedback changes it;
  findings outside it are filed as issues and never fixed in the running
  change. Source: the human's instruction after issue 0022's run.
- This narrows what the agent had written during that run, which allowed a
  document the change made wrong to be fixed without limit. Criterion 3 keeps
  the rulebook's standing rule — a change that makes a document wrong updates
  it in the same change — and bounds it to the falsified statements, because
  that unbounded version is what produced the 76 lines in `README.md`.
- Triage therefore loses a branch for these findings: filing is the only
  outcome, not one of three. `AGENTS.md:132`'s "fix now, dismiss with a
  recorded reason, or file for later" stays only for findings that do violate
  a criterion. Source: the same instruction.

## Log

- Round 1 (fresh context). 1 finding: `AGENTS.md`'s triage paragraph made
  filing the only, unconditional outcome for an off-criterion finding, which
  contradicted the bookkeeping rule that a documentation statement the change
  itself falsifies is still fixed in the same change (criterion 3) — the exact
  tension flagged in checkpoint 1. Violates criterion 5. Fixed now: the
  triage paragraph now carves out that one exception and points at the
  bookkeeping rule for its bound. No findings filed as their own issues this
  round.

- Filed after issue 0022's run, on the human's request, out of the token
  measurements taken during it, then sharpened by their instruction that no
  scope drift may happen at all — which moved this issue from "drift is
  expensive" to "drift does not happen".
- Two findings of that run's last round were handled the way this issue wants —
  filed as issues 0023 and 0024 instead of fixed — and that was the human's
  decision, not the workflow's. Making it the default is the point here.
- Findings dismissed in that run as a recorded cost, rather than filed, would
  be filed under this issue's rule: the "plugin root ships `docs/` to every
  consumer" item of round 2 is the example.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes: freeze the criteria at checkpoint 1,
  make every finding name a criterion or state it violates none, make filing
  the only outcome for an off-criterion finding, and bound the standing
  documentation-mirror rule to what the change itself falsified.
- What surprised me? The documentation-mirror exception in criterion 3 is not
  the same rule as "off-criterion findings get filed" in criterion 2 — a
  document the diff itself made false is still fixed in the same change, just
  bounded, while every other off-criterion finding is filed and left unfixed.
  Conflating the two would silently reopen the unbounded README-growth this
  issue exists to close.
- What am I assuming without having verified it? That this is a prose-only
  change to `AGENTS.md` and `agents/reviewer/agent.md` with nothing to run —
  no test suite or static analysis applies, so invariant 2 means there is
  nothing to write a failing test for, and review is the change's only check.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
