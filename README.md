# metis

> An AI agent workflow built on judgment, not rules — a few invariants,
> self-correction in the loop, and a human only where it matters.

**Metis** is the Greek titaness of practical wisdom — the mother of Athena,
and in Greek the word itself: the ability to do the right thing in the
moment, rather than follow a plan. That is this project's principle, not
just its name.

## Why this exists

Metis is the successor to a much larger agentic development workflow — a
product-owner conversation orchestrating eleven subagents through a fixed
pipeline of spec grilling, architecture planning, clean-room review,
issue slicing, separated test authoring, implementation, a five-axis
review with mechanical gates and receipts, and an adjudicator. Every
piece of it had a documented rationale. Together, it collapsed under its
own weight.

The diagnosis: **that workflow's complexity came from replacing judgment
with mechanics.** Almost every rule existed to eliminate a judgment call —
a triviality predicate instead of "this is small", counters and budgets
instead of "this isn't working", receipts instead of trust, a decision
taxonomy instead of "write down what you decided". The clearest evidence
of over-engineering: the rulebook eventually needed its own issue
tracker, self-test suite, and behavioral evals *just to keep its own
rules consistent*.

You cannot have both "few rules" and "no judgment calls". Metis chooses
few rules.

## The principle

**Judgment for process, mechanics for facts.**

Everything procedural — how much specification a change needs, whether to
plan first, whether to slice the work, which tools to reach for — is left
to the agent's judgment. Mechanics remain only where a *fact* must be
established, because self-assessment is provably unreliable there: "the
test suite is green" is an exit code, not a sentence.

## Self-correction is structural, not aspirational

An AI does not reliably notice its own mistakes from inside the context
that made them — the same state that produced the error would have to
judge it. Self-correction therefore cannot be a rule ("catch your own
errors"); it has to be built into the structure, at exactly three
anchor points:

1. **Intent is written down before anything is built.** Without recorded
   acceptance criteria, nobody — AI or human — has anything to detect
   drift against.
2. **A fresh context reviews the result.** A reviewer that sees only the
   diff and the written intent does not share the implementer's blind
   spot. This is the one organ of self-correction that must exist.
3. **Facts come from tools, not self-assessment.** Test results, static
   analysis, exit codes. The only mechanics that survive.

## The invariants

Five things are always true, whatever process judgment picks:

1. The intent (acceptance criteria) is written before implementation.
2. A fresh context reviews the diff against that intent before the PR.
3. The test suite is green, established by exit code, before the PR.
4. Observations, decisions, and surprises are recorded in the issue —
   they must survive the session that made them.
5. Irreversible or outward-facing decisions go to the human.

Everything else is a tool on the shelf, not a step in a pipeline.

## Correcting course while running

**Perception rules instead of budgets.** No attempt counters, no round
limits. One rule: when you notice *repetition* (the same failure twice),
*surprise* (something behaves differently than the docs claim), or
*regression* (a fix breaks something that worked) — stop, write the
observation into the issue, and decide: change approach, or ask.

**Two checkpoints instead of a pipeline.** Before implementation and
before the PR, the agent answers three questions in the issue: *Does this
match what was asked? What surprised me? What am I assuming without
having verified it?* Not a gate — a forced moment of self-inspection at
the two points where course correction is still cheap.

**A retrospective after every run.** After the PR, the agent writes a few
sentences: what in the workflow got in the way, and what should change.
Those observations become concrete rule-change proposals for this
repository. The workflow is not kept consistent by an eval suite — it
corrects itself through lived feedback.

## The human's three steering points

1. Approve the acceptance criteria — only when the agent finds the idea
   genuinely unclear.
2. Decide anything irreversible or outward-facing.
3. Merge the pull request.

Everything in between is the agent's call — including when to reach for
the heavier tools: a full requirements-grilling session, an explicit
architecture plan, a clean-room second opinion, a separate test author,
slicing a large change into steps. They exist as skills invoked by
judgment, never as conditions that fire automatically.

## The minimal run

```
idea → issue with acceptance criteria   (grilling only if unclear)
     → implementer                      (plans, writes tests first, implements)
     → reviewer                         (suite green + diff vs. intent, with a
                                         concrete reproduction per finding)
     → commit, push, PR → human merges
```

Three or four subagents instead of eleven. One page of rules instead of a
constitution.

## Status

Early. [`AGENTS.md`](AGENTS.md) is the one-page rulebook that puts the
above into operation — for a workflow, the text *is* the product. Next:
the subagent definitions and the skills on the shelf.

## The name

Zeus swallowed Metis because he could not control her cunning. This
project does the opposite.
