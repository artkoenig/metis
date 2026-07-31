---
status: backlog
branch:
pr:
---

# A criterion that cannot be mechanised still gets a case

## Intent

The `test-author`'s page tells it to write a case for every acceptance
criterion, and to return an undecided edge as a question rather than a guessed
expectation. It says nothing about a criterion whose *subject* is not
mechanisable — one asking whether prose means a particular thing.

Issue 0040's criterion 6 was such a criterion: *"`README.md` describes what an
installation receives in a way that matches criterion 2"*. Three review rounds
went to the one case built for it:

- round 1: the case passed on any README containing the word "update" — a
  README stating the opposite passed;
- round 2: the replacement passed on *"is not updated … never arrives …
  delete the plugin and add it back"* and failed on a pure reflow of the
  unchanged, correct sentence;
- round 3: the surviving word blocklist was disarmed by any denial word on the
  same line, which is the shape the real README's sentence has.

Each round was answered by removing machinery, and the run converged only once
the check was gone entirely. The criterion is now established by the
fresh-context review — which is what invariant 3 exists for, and which
confirmed it three times without difficulty.

Nothing was wrong with the criterion, and nothing was wrong with the rounds
that caught each defect. What was missing is the step before the first case:
asking whether a criterion can be decided by a program at all, and saying so
instead of producing a case that reads as coverage and is not.

Wanted observable behaviour: a criterion whose subject is prose meaning comes
back as a statement that it is not mechanisable, with the reason, before any
case is written for it.

Acceptance criteria:

1. The `test-author`'s page names the class — a criterion whose subject is the
   meaning of prose rather than an observable behaviour — and tells it to
   report the criterion as not mechanisable instead of writing a case for it.
2. The page says what the caller does with that answer: the criterion is
   established by the fresh-context review of invariant 3, and the issue's
   record says so, so nobody re-adds a case for it later.
3. The page distinguishes the class from a criterion that merely looks hard:
   a word question about prose — "does this text name X" — is mechanisable and
   still gets a case.

## Plan

## Tasks

## Decisions

## Log

- Found in the retro of issue 0040, and filed for its own run.

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
