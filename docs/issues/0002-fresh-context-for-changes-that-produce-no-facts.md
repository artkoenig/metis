---
status: done
branch: 0002-fresh-context-no-facts
pr: https://github.com/artkoenig/metis/pull/10
---

# The fresh context is not optional for a change that produces no facts

## Intent

Invariant 4 establishes facts by exit code — a suite, a linter, a type check.
Some changes produce none of those: the rulebook itself, the agent
definitions, the skills, an ADR, a README. Nothing runs against them, nothing
can fail, and no receipt exists at the end. For that class of change,
invariant 3 — the fresh context reading the diff against the written intent —
is not one safeguard among several. It is the only one.

Metis does not say so, and the omission has already cost something twice: in
the trial run the fresh context caught a wrong claim I had written into
`docs/evaluator-architecture.md` — the same defect I had sent back to the
implementer a round earlier — and on issue `001`, the rulebook change itself
shipped with no fresh reading at all, so six rule changes rest on a single
pair of eyes.

The rule follows from the asymmetry, not from a preference: where there is a
suite, skipping the review risks a defect the suite might still catch; where
there is no suite, skipping it risks a defect nothing catches.

Acceptance criteria:

1. `AGENTS.md` states that a change producing no facts by exit code — the
   rulebook, an agent definition, a skill, documentation — is reviewed by a
   fresh context before the PR, and that this one is not a judgment call.
2. The rule names why: with no suite and no static analysis, invariant 3 is
   the only check the change gets.
3. The `reviewer` agent's definition accounts for a diff with no suite to run,
   rather than opening its report with a fact it cannot establish.

## Plan

## Tasks

## Decisions

- **Source: the Retro of `001`**, which proposed the rule and did not
  implement it — the run that discovered the gap was itself the run that fell
  into it.
- **Not folded into `001`.** It arrived from that issue's retro, which is
  written after the PR; adding a criterion there would have meant reopening a
  change that was already merged. A new issue is the route the rulebook
  prescribes for work that does not serve the running intent.
- **Criterion 3 is a consequence, not a wish.** The reviewer is told to open
  its report with the suite and the static analysis by exit code. Given a diff
  of pure prose there is nothing to run, and an agent instructed to report a
  fact it cannot establish will invent a form of words for it. Whatever the
  fix, it has to leave the agent an honest way to say "nothing to run here".
- Criterion 1's phrase "not a judgment call" is stated through the reason
  alone ("this review is the only check the change gets: nothing else would
  catch what it misses"), not as the literal sentence. The review showed the
  literal sentence backfires: a guarantee scoped to one class reads as if
  the other classes were up for judgment, which contradicts the invariant
  frame. Invariant status already makes it non-optional. Source: review
  round 1, finding 2, and the simplicity rule.

## Log
- Review round 1 (fresh context, the only check this change gets — as the
  change itself states): all three criteria met. Four findings, none a
  criterion violation. Fixed now: the "never a judgment call" phrase
  replaced by its reason (finding 2, see Decisions); the run diagram and
  README now say "facts by exit code" where they promised a suite the
  reviewer cannot always have (finding 3, the documentation-mirror rule);
  the reviewer's "do not invent a substitute" reworded so a real ad-hoc
  check is reported as what it is, not withheld (finding 4). Filed for
  later: finding 1 — invariants 2 and 4 have nothing to bite on for a
  change without a suite — as issue 0007.
- Review round 2 (fresh context): criteria 1 and 2 met, criterion 3 met in
  letter but incomplete in meaning. Three findings, all the same class —
  places still demanding an unestablishable fact — and all fixed: the
  reviewer's check 3 (tests against the intent) got the honest no-tests
  path; "a skill" in the rulebook's class list became "a skill's page" (the
  bootstrap skill ships shell scripts, and those do produce facts); the
  reviewer's frontmatter description now carries the rule its body states.
  The round independently confirmed round 1's triage, including the
  "not a judgment call" decision and the filing of 0007.
- Review round 3 (fresh context): all three criteria met. Three findings,
  none against a criterion, all fixed and verified directly instead of a
  fourth round: issue 0007's copy of the class list updated to "a skill's
  page" and its criterion 1 extended to keep README's invariant mirror in
  step; the broken wrap in the rulebook's invariant 3 reflowed; the
  hyphens-as-dashes in this Log replaced. The round also swept the whole
  corpus for the class "demands an unestablishable fact": the two remaining
  members are exactly the ones 0007 covers.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes: the issue asks for three things — the
  rule in the rulebook, the reason named, and a reviewer definition that can
  honestly report "nothing to run". Runs 0004 and 0005 hit exactly this case
  and the reviewers each invented their own way of saying it.
- What surprised me? Nothing; run 0005 demonstrated the gap four times in a
  row.
- What am I assuming without having verified it? That the simplified texts
  from PR 9 are the base to edit — verified by pulling main after the merge.
  And that the rule belongs inside invariant 3 rather than as a new
  invariant: it sharpens an existing rule, it does not add one.

### Before the PR

- Does this match what was asked? Yes. The rulebook names the no-facts
  class and the reason the fresh review is its only check; the reviewer
  definition can say "nothing to run" honestly in its description, its
  checks and its report — and three review rounds exercised that path for
  real.
- What surprised me? The class kept turning up in places the criteria did
  not name: the reviewer's check 3, its description, the run diagrams, and
  the freshly filed 0007 itself. Closing a class one named place at a time
  is how 0005 went too.
- What am I assuming without having verified it? That invariants 2 and 4
  can stay as they are until 0007 lands — this run declared nothing about
  them because nothing true could be declared, and the rulebook does not
  yet bless that silence.

## Retro

The run confirmed 0005's lesson from the other side: a rule about a class
has to be checked everywhere the class occurs, not only where the criteria
point. Three of the criteria's three targets were met in round 1, yet the
class survived in four unnamed places. Worth considering for the review
habit: when a change introduces or names a class, the first round should
sweep the corpus for the class, not only the named files. The
round-findings table (issue 0006) would have shown the convergence shape
here clearly: 4 → 3 → 3 by count, but strictly shrinking in weight.
