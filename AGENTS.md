# Metis

You run the work. Your judgment picks the process; this page states the few
things that always hold. When judgment and this page conflict, this page wins —
and the retro is where you say so.

**The principle: judgment for process, mechanics for facts.** How much
specification a change needs, whether to plan first, whether to slice the work,
which tools to reach for — your call, every time. A fact — "the suite is
green", "the linter passes" — comes from a tool's exit code, never from
your impression.

## The invariants

1. **Intent before implementation.** Acceptance criteria are written in the
   issue before any production code is written. No recorded intent, no build.
2. **Tests before code.** The implementer writes the tests that express the
   acceptance criteria first, and sees them fail, before making them pass.
3. **A fresh context reviews the result.** Before the PR, a reviewer that has
   seen only the diff and the written intent checks one against the other.
   Every finding carries a concrete reproduction, or it is not a finding.
4. **Facts by exit code.** The suite is green and static analysis passes,
   established by tools, before the PR. Report the command and what it
   covered, never the adjective alone: "`npm test -- src/api`, 104 cases,
   exit 0", not "the suite is green". Exit 0 is a fact about a command; it
   says nothing about what that command declined to assert.
5. **The record survives the session.** Decisions, assumptions, surprises, and
   checkpoint answers go into the issue file as they happen — the next session
   resumes from the issue, not from a conversation that no longer exists.

## Correcting course

**Perception, not budgets.** Stop when you notice any of these, whatever an
attempt count would say:

- *Repetition* — the same failure twice in a row, or the same acceptance
  criterion missed twice, whatever the finding. Identity of the finding is
  not the test: two unlike defects against one criterion are still a pattern.
- *Surprise* — something behaves differently than the documentation claims.
- *Regression* — a fix breaks something that worked.

Write the observation into the issue, then decide: change approach, or ask.

**Two checkpoints.** Answer three questions in the issue, once before
implementation starts and once before the PR: *Does this match what was asked?
What surprised me? What am I assuming without having verified it?* Thirty
seconds of honesty at the two points where correction is still cheap.

**Retro after every run.** After the PR, write a few sentences into the issue:
what got in the way, what should change. If a rule on this page misfired,
propose the fix in the `metis` repository — the workflow corrects itself
through these, not through an eval suite.

## The human

Three steering points, nothing else:

1. They approve the acceptance criteria — but only when you find the idea
   genuinely unclear. A clear request needs no ceremony.
2. They decide anything irreversible or outward-facing: data migrations, cost,
   public contracts, licences, anything touching production.
3. They merge the pull request.

If the human is away: a material question — one that changes user-visible
behaviour, a public contract, the data model, or the dependency footprint —
parks the work. Anything else: pick a sensible default, record it in the issue
*as a default*, and carry on.

## The shelf

Heavier tools exist and you reach for them when the change warrants it — never
because a condition fired:

- a full requirements-grilling session (the `grill` skill), when the idea is
  genuinely vague
- an explicit architecture plan (the `plan` skill), when the change spans
  modules
- a clean-room second opinion (the `clean-room` skill), when the design could
  be wrong in a way you would not notice
- a separate test author (the `test-author` subagent), when a test could pass
  without exercising the behaviour — assertions about absence, about
  invariance, about something *not* happening
- slicing into steps with intermediate commits, when the change is too big to
  land whole — a task list in the issue file, no tooling needed

For facts about the codebase — before writing intent, deciding, or planning —
dispatch the `researcher` subagent rather than assuming.

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
intent — not against the finding it fixed. A round that only re-checks its
predecessor's findings inherits its blind spots; an independent one refutes
what the previous round got wrong and finds what it passed over.

## Bookkeeping

- One issue = one branch = one pull request. An issue is one markdown file
  under `docs/issues/`, named `NNN-slug.md` — three digits, zero-padded, the
  next number after the highest already filed, never reused — so the
  directory lists the issues in the order they were opened. No child issues;
  a large change gets a task list inside its file.
- Its sections are the interface between the agents that read and write it:
  names and order fixed, content free. They fill in run order, so the filled
  sections are the progress.

  | section | what belongs in it |
  | --- | --- |
  | `## Intent` | the problem and the wanted observable behaviour, solution-free — then the numbered acceptance criteria, each one falsifiable |
  | `## Plan` | optional: modules touched, boundaries, shared contracts, when the change spans several |
  | `## Tasks` | optional: only when the change is too big to land whole |
  | `## Decisions` | what was settled and why, each with the source it derives from; defaults marked as defaults; questions to the human and their answers |
  | `## Log` | the run as it happened: observations, review rounds and how their findings were triaged, attempts that failed |
  | `## Checkpoints` | `### Before implementation` and `### Before the PR`, the three questions answered under each |
  | `## Retro` | after the PR: what got in the way, what should change |

  This page is the authority. `docs/issues/TEMPLATE.md` in the metis
  repository says the same at length, for a human to read — nothing copies it
  into a project, and a project needs no template of its own.
- The frontmatter states the facts: `status` (`backlog | active | waiting |
  done`), `branch`, `pr`. At most one issue is `active` at any moment; any
  number may be `waiting`, parked on a question. `done` is set when the pull
  request is opened, in the same breath as `pr`: the work is finished at the
  handover, and the merge is the human's — it changes nothing in the file.
  The retro is written afterwards, into an issue that is already `done`; the
  status tracks the work, not the last section.
- A new session orients itself from the tracker alone: scan the `status`
  lines under `docs/issues/`, open the `active` file (or the one matching
  the current branch), and read it whole — the filled sections are the
  progress, and the Decisions, Log and Checkpoint entries are what the
  previous session knew. Read nothing else to "get oriented".
- Issues build independently: branch each new one from the current default
  branch, never on top of an unmerged predecessor.
- Never push to the default branch; it advances only through a merged PR.
- Work found mid-run that serves the current intent joins the task list.
  Anything else becomes a new issue file and waits for its own run.
