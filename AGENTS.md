# Metis

You run the work. Your judgment picks the process; this page lists the few
rules that always hold. When the two conflict, this page wins — and the retro
is where you say so.

**Judgment for process, mechanics for facts.** How much specification a change
needs, whether to plan first, whether to slice the work, which tools to use —
your call, every time. A fact — "the suite is green", "the linter passes" —
comes from a tool's exit code, never from your impression.

**Simplicity is the top rule.** Few rules, plain words, no machinery without a
need. This holds for the work and for these texts alike.

## The invariants

1. **Intent first.** Acceptance criteria are recorded in the issue before any
   production code is written.
2. **Tests before code.** The implementer writes the tests for the criteria
   first and sees them fail, then makes them pass.
3. **A fresh context reviews the result.** Before the PR, a reviewer that has
   seen only the diff and the written intent checks one against the other. A
   finding without a concrete reproduction is not a finding.
4. **Facts by exit code.** The suite and static analysis pass before the PR,
   shown by exit codes. Report the command and what it covered, never the
   adjective alone: "`npm test -- src/api`, 104 cases, exit 0", not "the
   suite is green". An exit code says only what that command checked.
5. **The record survives the session.** Record decisions, assumptions,
   surprises and checkpoint answers through the `issue` skill as they happen.
   The next session resumes from the tracker, not from a conversation that no
   longer exists.

## Correcting course

**Stop on these signals, whatever a counter would say:**

- *Repetition* — the same failure twice in a row, or the same acceptance
  criterion missed twice, even by two different defects.
- *Surprise* — something behaves differently than the documentation claims.
- *Regression* — a fix breaks something that worked.

Record the observation, then decide: change approach, or ask.

**Two checkpoints.** Once before implementation and once before the PR, record
the answers to three questions: *Does this match what was asked? What
surprised me? What am I assuming without having verified it?* Not a gate —
a cheap moment to correct course.

**Retro after every run.** After the PR, record what got in the way and what
should change. If a rule on this page misfired, propose the fix in the
`metis` repository — this is how the workflow corrects itself.

## The human

Three steering points, nothing else:

1. They approve the acceptance criteria — only when you find the idea
   genuinely unclear. A clear request needs no ceremony.
2. They decide anything irreversible or outward-facing: data migrations,
   cost, public contracts, licences, anything touching production.
3. They merge the pull request.

If the human is away: a material question — one that changes user-visible
behaviour, a public contract, the data model, or the dependency footprint —
parks the work. Anything else: pick a sensible default, record it as a
default, and carry on.

## The shelf

Heavier tools exist. Reach for one when the change warrants it, never because
a condition fired:

- the `grill` skill, when the idea is too vague to write criteria
- the `plan` skill, when the change spans modules
- the `clean-room` skill, when you are stuck or want a second opinion
- the `test-author` subagent, when a test could pass without exercising the
  behaviour — criteria about absence, invariance, something *not* happening
- a task list with intermediate commits, when the change is too big to land
  whole

A skill is like a class: use the interface its page declares and leave the
inside alone. A caller that relies on a skill's internals breaks the first
time those internals change.

For facts about the codebase — before writing intent, deciding or planning —
dispatch the `researcher` subagent instead of assuming.

## The run

```
idea → issue with acceptance criteria      (grilling only if unclear)
     → checkpoint 1
     → implementer                         (plans, tests first, implements)
     → reviewer                            (fresh context: diff vs. intent,
                                            suite by exit code, repro per finding)
     → checkpoint 2
     → commit, push, PR → human merges
     → retro
```

Triage the reviewer's findings by judgment: fix now, dismiss with a recorded
reason, or file for later. A finding without a reproduction is dismissed by
default.

After a fix, the review repeats from a fresh context, against the whole
intent — not only against the findings it fixed. A round that re-checks its
predecessor's list inherits its blind spots.

## Bookkeeping

- One issue = one branch = one pull request. No child issues — a change too
  big to land whole gets a task list instead.
- The tracker is the `issue` skill. Hand it the content — a decision, an
  observation, a new state — and name the operation; where that lands is the
  skill's business. This holds for subagents too: one that needs the tracker
  gets the `Skill` tool, not a path.
- A new session orients itself through that skill and reads nothing else to
  get oriented.
- `README.md` and the rest of the documentation mirror the current state. A
  change that makes a document wrong updates it in the same change. Documents
  may repeat what a rule or skill says, but the rule or skill is where it is
  defined — when they disagree, the document is out of date.
- Branch each new issue from the current default branch, never on top of an
  unmerged predecessor.
- Everything checked in — texts, commit messages — and every pull request is
  written in English.
- Never push to the default branch; it advances only through a merged PR.
- Work found mid-run that serves the current intent joins the task list.
  Anything else is filed through the `issue` skill and waits for its own run.
