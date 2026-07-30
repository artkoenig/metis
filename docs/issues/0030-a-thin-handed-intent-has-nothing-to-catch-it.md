---
status: backlog
branch:
pr:
---

# A thin handed intent has nothing to catch it

## Intent

Since issue 0028 the `reviewer` no longer fetches the written intent — the
caller copies it into the dispatch. That closed one hole and opened another: the
caller now decides what the reviewer reviews against. Copying the recorded text
word for word protects against rewording, but not against a record that is thin
to begin with — criteria too vague for a criterion to fail, or a change whose
real intent was never written down. The reviewer then reviews against almost
nothing and reports every criterion met, which reads exactly like a clean run.

Nothing catches this today. The obvious guard — letting the reviewer stop when
the intent is too thin — was written during 0028's run and removed again in its
round 2, for a reason that still holds: the stop sits before the exit-code
facts, so a reviewer that halts returns no suite and no static-analysis result
at all, and invariant 4 requires both. Any fix has to keep the facts coming.

Wanted observable behaviour: an intent too thin to review against is visible in
the review's output instead of passing as a clean run.

Acceptance criteria:

1. When the reviewer is handed criteria it cannot review against, its report
   says so as a finding, and the suite and static-analysis facts are still
   reported for that round.
2. When the reviewer is handed a criterion it can review against, nothing in
   that path changes — a review of a workable intent gains no new step and no
   new preamble.

## Plan

## Tasks

## Decisions

## Log

- Found by issue 0028's round-2 review, as finding 1: the halt sentence in the
  reviewer's premise served no criterion of 0028 and preceded check 1, so a
  halt would drop the one check invariant 4 requires. The
  sentence was removed and the underlying gap filed here, per the rule that a
  finding outside the running intent gets its own run.

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
