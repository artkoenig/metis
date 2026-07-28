# metis

> An AI agent workflow built on judgment, not rules — a few invariants,
> self-correction in the loop, and a human only where it matters.

**Metis** is the Greek titaness of practical wisdom, and in Greek the word
itself: the ability to do the right thing in the moment, rather than follow
a plan. That is this project's principle, not just its name.

## Why this exists

Metis replaces a much larger workflow: eleven subagents in a fixed pipeline
of spec grilling, architecture planning, clean-room review, issue slicing,
separated test authoring, implementation, a five-axis review with mechanical
gates and receipts, and an adjudicator. Every piece had a documented
rationale. Together, it collapsed under its own weight.

The diagnosis: **its complexity came from replacing judgment with
mechanics.** Almost every rule existed to remove a judgment call — a
triviality predicate instead of "this is small", counters instead of "this
isn't working", receipts instead of trust. In the end the rulebook needed its
own issue tracker, self-test suite and behavioral evals just to keep its own
rules consistent.

You cannot have both "few rules" and "no judgment calls". Metis chooses few
rules.

## The principle

**Judgment for process, mechanics for facts.**

Everything procedural — how much specification a change needs, whether to
plan first, whether to slice, which tools to use — is the agent's call.
Mechanics remain only where a *fact* must be established, because
self-assessment is unreliable there: "the test suite is green" is an exit
code, not a sentence.

And simplicity is the top rule: few rules, plain words, no machinery without
a need — in the workflow and in its texts.

## Self-correction is structural

An AI does not reliably notice its own mistakes from inside the context that
made them. So self-correction cannot be a rule ("catch your own errors"); it
is built into the structure, at three points:

1. **Intent is written down before anything is built.** Without recorded
   acceptance criteria there is nothing to detect drift against.
2. **A fresh context reviews the result.** A reviewer that sees only the
   diff and the written intent does not share the implementer's blind spot.
3. **Facts come from tools.** Test results, static analysis, exit codes —
   the only mechanics that survive.

## The invariants

Five things are always true, whatever process judgment picks:

1. The intent (acceptance criteria) is written before implementation.
2. The tests for those criteria are written before the code, and seen to
   fail — a change with nothing to run has none to write, and says so.
3. A fresh context reviews the diff against the intent before the PR, with a
   concrete reproduction per finding.
4. The suite and static analysis pass, shown by exit code and reported as
   the command and what it covered — never as "it's green". When nothing
   exists to run, that absence is the reported fact.
5. Observations, decisions, surprises and checkpoint answers are recorded as
   they happen — they must survive the session that made them.

Everything else is a tool on the shelf, not a step in a pipeline.

## Correcting course while running

**Perception instead of budgets.** No attempt counters, no round limits.
When the agent notices *repetition* (the same failure or missed criterion
twice), *surprise* (something behaves differently than documented), or
*regression* (a fix breaks something that worked) — it stops, records the
observation, and decides: change approach, or ask. And when even a changed
approach does not converge — the review findings neither fewer nor smaller
round over round — it stops and asks the human instead of running another
round.
After every review round the human sees the trend as a table: findings per
acceptance criterion per round, with totals.

**Two checkpoints.** Before implementation and before the PR, the agent
records answers to three questions: *Does this match what was asked? What
surprised me? What am I assuming without having verified it?*

**A retro after every run.** After the PR, the agent records what got in the
way and what should change. Those observations become rule-change proposals
for this repository — the workflow corrects itself through lived feedback,
not through an eval suite.

## The human's three steering points

1. Approve the acceptance criteria — only when the agent finds the idea
   genuinely unclear.
2. Decide anything irreversible or outward-facing.
3. Merge the pull request.

Everything in between is the agent's call — including when to reach for the
heavier tools: requirements grilling, an architecture plan, a clean-room
second opinion (skills), a separate test author (a subagent), slicing a large
change into steps (a task list, no tooling at all). Each is picked by
judgment, never fired by a condition.

## The minimal run

```
idea → issue with acceptance criteria   (grilling only if unclear)
     → implementer                      (plans, writes tests first, implements)
     → reviewer                         (facts by exit code + diff vs. intent,
                                         a concrete reproduction per finding)
     → commit, push, PR → human merges
```

Three or four subagents instead of eleven. One page of rules instead of a
constitution.

## Status

[`AGENTS.md`](AGENTS.md) is the one-page rulebook that puts the above into
operation — for a workflow, the text *is* the product. The subagents live in
[`agents/`](agents/): `implementer`, `reviewer`, `researcher`, and
`test-author` (a shelf tool). The shelf skills live in [`skills/`](skills/):
`grill`, `plan`, and `clean-room`. Two more skills live there, and neither is
a shelf tool. [`bootstrap`](skills/bootstrap/SKILL.md) wires a project up,
described below. [`issue`](skills/issue/SKILL.md) is the tracker itself:
every read and every write goes through one of its operations — you hand it
a decision, an observation, a new state, and it knows where that belongs.
Subagents included: the reviewer holds the `Skill` tool so it can orient
there instead of being handed a path.

## Wiring it in

The [`bootstrap`](skills/bootstrap/SKILL.md) skill wires a project's cloud
sessions to Metis. It installs a thin, stable *loader* hook (with its
settings entry) that clones or updates this repo and runs the sync logic
*from the clone*: symlinking `agents/` and `skills/` into `~/.claude`,
making `AGENTS.md` the global instructions, and pointing `core.hooksPath` at
[`.githooks/`](.githooks/) so a direct push to the default branch is
refused. Because the logic lives in the clone, workflow changes reach every
bootstrapped project on its next session start — no re-bootstrapping, no
drifting per-project copies (the predecessor's design flaw). In local
sessions the loader instead fast-forwards the user's own metis clone.
Installing the loader over the predecessor repo's hook is the migration —
same path, same settings entry, and the sync prunes the old symlinks itself.
This repo dogfoods the same loader in its own `.claude/hooks/`.

The sync also checks itself: it verifies its own outcome — every skill and
agent from the clone is reachable at its expected path, the rulebook is in
place — and hands a one-line status into the session's context. (The sync
logic has its own test harness next to it in `assets/`; the bootstrap
skill's page says how to run it.) The rulebook has each session open by
greeting the human and relaying that status. Local sessions never receive
one (the loader only updates the clone there); a cloud session missing one
had a hook failure. In both cases the session checks the links and the log
itself, and says so.

## The name

Zeus swallowed Metis because he could not control her cunning. This project
does the opposite.
