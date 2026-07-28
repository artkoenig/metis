---
status: active
branch: retro-proposals
pr:
---

# Rulebook corrections from the first trial run

## Intent

The first run of Metis against a foreign project — `tome_of_battle`, four
acceptance criteria, three review rounds, PR #143 — closed successfully, and
in doing so exposed four places where a rule is narrower than the thing it is
meant to catch, plus one place where the issue file's own structure worked
against the reader. None of them broke that run; each of them would have,
under a slightly different shape of the same problem. Alongside them, issue
files need an ordering that the filesystem reproduces on its own.

Wording and file naming only. No agent gains a capability, and no condition
starts firing automatically — the shelf stays a shelf.

Acceptance criteria:

1. The *repetition* perception rule fires when the same acceptance criterion
   is missed twice in a row, whatever the finding, and not only when an
   identical failure repeats.
2. A fact established by exit code is reported as the command, what it
   covered, and the exit code; the adjective alone ("the suite is green")
   does not satisfy the invariant — in the rulebook and in every agent
   definition that instructs an agent to report such a fact.
3. The run states that a fix round is re-reviewed by a fresh context against
   the whole written intent, not against the finding it fixed — and the
   reviewer's own definition says so too, since it is the agent re-dispatched.
4. The shelf entry for the `test-author` subagent names the class of criteria
   it protects: criteria whose test could pass without exercising the
   behaviour — assertions about absence, about invariance, about something
   not happening.
5. `## Decisions` carries only what was settled and why; the running record
   of the run — observations, review rounds, failed attempts — has its own
   section, so a reader arriving mid-run reaches the load-bearing decisions
   without wading through process.
6. Issue files are named `NNN-slug.md`, zero-padded, the next number after
   the highest already filed, so `ls docs/issues/` lists them in the order
   they were opened.

## Plan

## Tasks

## Decisions

- Filed and implemented from the retro of the first foreign-repo trial run
  (`tome_of_battle`, branch `resolver-immutability`, PR #143). Its issue file
  is the source for criteria 1–5; criterion 6 came from the human.
- **Criterion 1 — source.** Acceptance criterion 3 of that run was missed in
  two consecutive review rounds, but never with an identical finding: round 1
  found a comment in `resolver.js` claiming a freeze that does not happen,
  round 2 a comment in `effectiveState.js` denying a write that does happen.
  Different file, opposite cause, so the rule as written did not fire and the
  run continued. The pattern was real nonetheless — *statements about
  immutability were harder to get right in that code than the code itself* —
  and a rule testing for identity of the finding can never see it.
- **Criterion 2 — source, and it did not come from the run.** The run
  reported "the evaluator E2E suite is green" and the human refused it: open
  bug issues exist that originate from failing behaviour, so a wholly green
  report is suspect. The report was accurate about the suite
  (`vitest run src/evaluator/e2e.testcatalog.test.js`, 104 cases, exit 0) and
  silent about its scope — and that suite is manifest-driven, so what it
  asserts is whatever the scenario manifests declare. The invariant was
  right; the reporting form was the gap.
- **Criterion 3 — source.** The run diagram showed a straight chain
  `implementer → reviewer → checkpoint 2`; the run took three rounds.
  Dispatching a *fresh* context for each was a judgment call, not a rule —
  and it was where the value came from: round 3 refuted a finding of round 2
  (two equality tests were held to be tautological; they were not, only the
  justification for them was wrong) and found problems on criteria rounds 1
  and 2 had already passed.
- **Criterion 4 — source.** The `test-author` was deliberately not
  dispatched, because the mechanics of the change were not settled until the
  code existed. The damage was exactly the one it exists to prevent: the
  implementer's first test for criterion 4 ran against an empty roster and
  asserted nothing. Cost: one review round. The decision to skip was
  defensible and would be made again; the shelf entry ("when independent
  verification is worth a dispatch") gave no purchase for making it well.
- **Criterion 5 — source.** That run's `## Decisions` grew past 100 lines and
  mixed three load-bearing decisions with the triage protocol of three review
  rounds. Whoever resumed at round 4 would read a great deal of process to
  reach three facts.
- **Criterion 6 — zero-padding deviates from what was asked, deliberately.**
  The human asked for continuous numbering "as in the old workflow", which
  used unpadded numbers (`80-slug/`). Unpadded numbers sort lexically as
  `10, 2, 80`, which defeats the stated purpose — automatic ordering in the
  filesystem. Purpose over precedent: three digits, zero-padded. Reversible,
  and cheap to change if the human prefers the old form.
- **Implemented by the caller rather than dispatched to an implementer.** The
  change is prose in the rulebook and the agent definitions, which the caller
  owns; there is no code and therefore no test to write first. The fresh
  context of invariant 3 is the part that does not follow from this and is
  still owed.

## Log

- Criteria 1–5 written from the trial run's Retro before any edit; criterion 6
  added when the human asked for numbered filenames, and the file itself
  renamed to `001-` in the same breath.
- Edited: `AGENTS.md` (invariant 4, repetition rule, shelf entry, the run's
  fix-round paragraph, bookkeeping), `README.md` (repetition rule),
  `docs/issues/TEMPLATE.md` (filename note, `## Decisions` narrowed, `## Log`
  added), `agents/reviewer/agent.md` (re-review premise, fact reporting, the
  report's opening), `agents/implementer/agent.md` (repetition rule, fact
  reporting, report list), `agents/test-author/agent.md` (description).
- **Owed:** the fresh-context review of this diff against this intent
  (invariant 3), before any PR.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes. Criteria 1–5 are the five learnings
  the human asked me to derive and then to implement directly; criterion 6 is
  their addition, with one deliberate deviation recorded above.
- **What surprised me?** That the sharpest of the five did not come from the
  run at all — criterion 2 exists because the human refused a report I had
  believed to be sound. The run's own retro had not noticed it.
- **What am I assuming without having verified it?** That no tooling parses
  issue filenames; `grep` over the repo found the convention stated only in
  `AGENTS.md`, and the bootstrap scripts never touch `docs/issues/`.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
