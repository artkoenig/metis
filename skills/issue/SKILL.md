---
name: issue
description: The metis tracker. Every read of and every write to an issue goes through this skill — file an issue, record a decision, an observation, a plan, checkpoint answers, a retro or a task list, set the state, or orient a session on the running issue. Hand it the content and name the operation; it knows where that content lands. Not a shelf tool. Trigger on "file an issue", "open an issue", "new issue", "put this in the backlog", "record this in the issue", "where did we leave off", or whenever you are about to read or write anything in the tracker.
user-invocable: true
---

# Issue

One issue is one markdown file under `docs/issues/`, and that file is the whole
tracker: no database, no script, no status transitions to keep valid. The
sections are the interface between the agents that read and write it, which is
why the shape is fixed and this skill exists.

This skill owns the file whole: its name, its frontmatter, its sections, and
what the states mean. Nothing else in the workflow describes any of that.

The rulebook (`AGENTS.md`) owns the run — what happens between the states,
not what they are.

## The interface: operations, not fields

Treat this skill as a class. A caller hands it **content** and names the
**operation**; where that content lands, and in what form, is this skill's
business. A caller never states a path, a filename, a frontmatter key or a
heading — a document that does has reached inside, and it will be wrong the
first time this skill moves.

| operation | what the caller hands it |
| --- | --- |
| **file an issue** | the problem and the observable behaviour it wants, plus the acceptance criteria |
| **record a decision** | what was settled, and the source it derives from — a document, a human's answer, or "default, unanswered" |
| **record an observation** | what happened in the run: a review round and its triage, an attempt that failed, a surprise |
| **record a plan** | handed straight to the `plan` skill, which owns this one — see below |
| **record checkpoint answers** | the rulebook's three answers, and which of the two checkpoints they belong to |
| **record a retro** | what got in the way, what should change |
| **record a task list** | the steps a change is being landed in, when it is too big to land whole |
| **set the state** | which state the issue is now in, and the branch or the pull request if one now exists |
| **orient a session** | nothing. Returns which issue is running and everything the previous session knew about it |

Four of these are delegated whole, and the delegate is then the only document
that says what the content is. `record a plan` belongs to the `plan` skill.
Three belong to the rulebook, because each is a rule of the run and not a
property of the file: the three questions behind `record checkpoint answers`,
what a retro says, and when a change gets a task list at all.

Everything below this line is behind the interface — the directory, the
filenames, the template, the sections, and what belongs in each. It changes
without anything outside `skills/issue/` changing with it.

## Filing one

1. **Pick the number.** `NNNN-slug.md` — four digits, zero-padded, the next
   number after the highest already filed under `docs/issues/`, never reused.
   The padding is what makes the directory listing the order the issues were
   opened; unpadded numbers sort as 10, 2, 80.
2. **Copy `assets/TEMPLATE.md`** to that path. Copy it — do not retype it from
   memory, and do not reorder or rename its sections. The template is a bare
   skeleton on purpose: the table below is the only description of what goes
   in each section — except where it hands a section to another skill, which
   then owns that one alone. Two descriptions of one section is the defect
   this arrangement exists to prevent.
3. **Delete the comment block** under the title. It is an instruction for
   filing, not part of an issue.
4. **Write the `## Intent`** and nothing else. The problem and the wanted
   observable behaviour, solution-free, then numbered acceptance criteria that
   can each be shown false. Everything below Intent fills in as the run
   happens; an issue that arrives with its Decisions pre-written is a plan
   wearing a tracker's clothes.

## Orienting a session

Scan the `status:` lines of every file under `docs/issues/` and open the
`active` one — or, if none is `active`, the one whose `branch:` matches the
branch checked out. Read it whole. The filled sections *are* the progress
(see below), and Decisions, Log and Checkpoints are everything the previous
session knew. Read nothing else to get oriented: the tracker is the record,
and a session that goes looking further is reconstructing what is already
written down.

## The shape

| part | what belongs in it |
| --- | --- |
| frontmatter | three lines, no more. `status` — one of the four states below. `branch` — the branch carrying this issue, set as soon as one exists. `pr` — its pull request, set when the PR is opened. |
| `# <title>` | one H1, the issue in a phrase — what a human sees in a listing |
| `## Intent` | the problem and the wanted observable behaviour, solution-free, then the numbered acceptance criteria — observable and falsifiable, "when X, then Y" |
| `## Plan` | optional content, and the `plan` skill writes it — that skill says what belongs in it, this one does not |
| `## Tasks` | optional content, and the rulebook says when a change gets one — this skill only holds the place |
| `## Decisions` | what was settled and why, each with the source it derives from; questions to the human and their answers. **Nothing else** — a reader arriving mid-run must reach the load-bearing decisions without wading through the run's process |
| `## Log` | the run as it happened, oldest first: observations, review rounds and how their findings were triaged, attempts that failed. This is the section that grows, and keeping it out of Decisions is what keeps Decisions readable |
| `## Checkpoints` | `### Before implementation` and `### Before the PR`, with the rulebook's three questions answered under each — the rulebook owns those, this skill only holds the place |
| `## Retro` | written after the pull request, and the rulebook says what goes in one — this skill only holds the place |

**Every heading is always present, including the empty ones.** "Optional"
above describes the content, never the heading — a reader who scrolls to
`## Plan` and finds it empty learns that no plan was needed, which is
information; a reader who finds it missing learns nothing and has to search.

The sections fill in run order, so **the filled sections are the progress**:
Intent only = not started; Checkpoint 1 answered = implementing; Checkpoint 2
answered = in review; Retro written = finished.

## The four states

`status` tracks the work, not the last section that got written.

- **`backlog`** — filed, nobody has started it.
- **`active`** — someone is on it now. At most one issue is `active` at any
  moment.
- **`waiting`** — parked on a question, and nothing else. Not "waiting for a
  merge", not "waiting for CI".
- **`done`** — set when the pull request is opened, in the same breath as the
  `pr` field. The work is finished at the handover: the merge is the human's
  and changes nothing in the file. `## Retro` is written *afterwards*, into an
  issue that is already `done`.

## Why there is no version field, and what would change that

An issue file is prose read by a language model, not a record parsed by a
schema. A schema needs migrations because a missing field breaks it; prose does
not — an issue without `## Log` is simply one filed before `## Log` existed,
and the file says so by not having it. A version number would duplicate what is
already visible, and it would need its own migration path, which would need its
own maintenance. That is the machinery this workflow exists without.

What would change it: a shape change that an old file does **not** reveal — a
section that keeps its name and changes its meaning. If that ever happens, the
migration belongs here, in prose ("issues before `NNNN` have no `## Log`; read
their `## Decisions` as carrying both"), not in a field.
