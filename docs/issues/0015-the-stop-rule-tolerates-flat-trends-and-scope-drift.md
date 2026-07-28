---
status: backlog
branch:
pr:
---

# The stop rule tolerates flat trends and scope drift

## Intent

Run 0013 took eight review rounds. Two gaps in the rulebook let that
happen, both corrected mid-run by the human:

First, the two-tier stop rule's wording — "findings neither fewer nor
smaller in weight or class" — invites a self-serving reading: a flat count
trend (3 → 3 → 4) was called "converging by class" and the run kept going.
The human's correction: a flat trend already is non-convergence; the stop
should have come by round 3.

Second, the rulebook has no scope guard for review findings. Reviewers kept
probing ever-unlikelier pre-existing states; each fix invited the next
probe, and the run drifted far beyond the issue's intent. The human's
correction: a finding outside the issue's original scope warrants
escalation, not a fix round.

Wanted behaviour: a run with a flat finding trend stops and asks no later
than the round that shows it; a finding outside the issue's scope is taken
to the human instead of fixed.

Acceptance criteria:

1. The rulebook's stop rule: if the finding count has not decreased within
   3 consecutive review rounds, escalate to the human.
2. The rulebook states a scope guard: a reviewer finding that lies outside
   the issue's intent — however reproducible — is escalated to the human
   (fix, dismiss, or file) instead of fixed by default.
3. `README.md` stays in step where it repeats these rules.

## Plan

## Tasks

## Decisions

- The trend rule is numeric by the human's own call: no decrease within 3
  consecutive rounds → escalate. This deliberately replaces the
  "perception, not arithmetic" wording from issue 0006 for this rule.
  Source: the human's proposal, verbatim, before this run started.

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
