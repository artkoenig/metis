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

1. The rulebook's stop rule states that a finding count that does not fall
   from one round to the next is non-convergence — no "smaller in weight
   or class" escape without asking the human.
2. The rulebook states a scope guard: a reviewer finding that lies outside
   the issue's intent — however reproducible — is escalated to the human
   (fix, dismiss, or file) instead of fixed by default.
3. Both stay in the perception style: no numeric budget, no fixed round
   limit; `README.md` stays in step where it repeats these rules.

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
