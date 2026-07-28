---
status: done
branch: claude/new-session-xeyz5n
pr: https://github.com/artkoenig/metis/pull/16
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
- The change lands in `AGENTS.md` only: the stop-rule paragraph in
  "Correcting course" and the triage paragraph in "The run". The rewritten
  README repeats neither rule (grep over stop/convergence/triage terms,
  zero hits), so criterion 3 is satisfied by that fact. Implemented in the
  main context — prose only, fresh review still runs (precedent 0005/0006).

## Log

- Grep over `README.md` for stop/convergence/repetition/triage/dismiss:
  no hits — the rewritten README does not repeat the rules this issue
  changes.
- Review round 1 (fresh context): no suite or analysis covers prose (the
  two shell suites pass, exit 0, but touch nothing in this diff) — this
  review is the change's only check. All three criteria met, reviewer
  verified the README/agents/skills silence with an independent grep and
  that the rule fires on the motivating 3 → 3 → 4 case at round 3. One
  minor finding, no criterion violated: the rule cited "(run 0013)",
  a tracker reference that dangles in foreign projects the rulebook is
  installed into. Escalated per the new scope guard; the human had no
  preference; default taken: clause deleted (the reviewer's own proposed
  resolution). No second round for the pure deletion — recorded as a
  judgment call. Trend: 1.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — the human's 3-round rule verbatim,
  the scope guard from their round-8 correction, README already silent on
  both.
- What surprised me? That the README needs no edit — the 0013 cut removed
  every restatement of these rules.
- What am I assuming without having verified it? That "finding count" means
  the reviewer's reported findings per round as the trend table counts
  them — the human's proposal did not define the counting unit; recorded
  as a default.

### Before the PR

- Does this match what was asked? Yes — the 3-round rule verbatim, the
  scope guard, README silent on both (reviewer verified all three).
- What surprised me? The scope guard bit on its own review round: the one
  finding was out of intent, so it went to the human per the new rule.
- What am I assuming without having verified it? That skipping a second
  review round for the clause deletion is safe: the fix is the reviewer's
  own proposed resolution, pure deletion, all criteria already met —
  recorded as a judgment call, not covered by a fresh round.

## Retro

Nothing got in the way; the run was one edit, one review round, one
escalation. Two things worth keeping: the scope guard proved itself on its
own review (the one finding was out of intent and went to the human instead
of being fixed by reflex), and the human's brevity instruction shaped the
run — short criteria, short rule text, one-sentence answers. Open thread
for a future rule change, not filed yet: "after a fix, the review repeats"
has no floor — this run skipped the repeat for a pure deletion the reviewer
itself proposed, recorded as a judgment call; if that happens again, the
rule should say when a repeat is waivable.
