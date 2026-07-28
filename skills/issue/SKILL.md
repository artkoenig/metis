---
name: issue
description: Open a new issue in the metis tracker, or check the shape of an existing one — the file's name, its frontmatter and its sections. Not a shelf tool: every issue is filed through this skill, because the sections are the interface between the agents that read and write the file. Trigger on "file an issue", "open an issue", "new issue", "put this in the backlog", or whenever you are about to write a file under docs/issues/.
user-invocable: true
---

# Issue

One issue is one markdown file under `docs/issues/`, and that file is the whole
tracker: no database, no script, no status transitions to keep valid. The
sections are the interface between the agents that read and write it, which is
why the shape is fixed and this skill exists.

This skill owns the file whole: its name, its frontmatter, its sections, and
what the states mean. Nothing else in the workflow describes any of that.
Other documents may *name* a field or a section — "record it in `## Decisions`"
— and then point here; they never explain one. A second explanation is the
defect this arrangement exists to prevent, and it fails in both directions:
two descriptions drift apart, and moving a description out of one document
without landing it in this one leaves the question unanswered anywhere.

The rulebook (`AGENTS.md`) owns the run — what happens between the states,
not what they are.

## The interface, and what is behind it

Treat this skill as a class. Four things are public, and a caller outside
`skills/issue/` may rely on exactly these:

- the directory `docs/issues/`, and that one issue is one file in it
- the filename form `NNNN-slug.md`, so a listing is the order they were opened
- the frontmatter keys `status`, `branch`, `pr`, and the four values `status`
  takes
- the heading names — an agent reads and writes them, so renaming one is a
  breaking change

Everything else is behind the interface: `assets/TEMPLATE.md` and that it
exists at all, the filing steps, and above all *what belongs in each section*.
Those change without anything outside this directory changing with them. A
document that explains one of them has reached inside, and it will be wrong
the first time this skill moves.

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

## The shape

| part | what belongs in it |
| --- | --- |
| frontmatter | three lines, no more. `status` — one of the four states below. `branch` — the branch carrying this issue, set as soon as one exists. `pr` — its pull request, set when the PR is opened. |
| `# <title>` | one H1, the issue in a phrase — what a human sees in a listing |
| `## Intent` | the problem and the wanted observable behaviour, solution-free, then the numbered acceptance criteria — observable and falsifiable, "when X, then Y" |
| `## Plan` | optional content, and the `plan` skill writes it — that skill says what belongs in it, this one does not |
| `## Tasks` | optional content: only when the change is too big to land whole |
| `## Decisions` | what was settled and why, each with the source it derives from; defaults marked as defaults; questions to the human and their answers. **Nothing else** — a reader arriving mid-run must reach the load-bearing decisions without wading through the run's process |
| `## Log` | the run as it happened, oldest first: observations, review rounds and how their findings were triaged, attempts that failed. This is the section that grows, and keeping it out of Decisions is what keeps Decisions readable |
| `## Checkpoints` | `### Before implementation` and `### Before the PR`, the three questions answered under each |
| `## Retro` | after the pull request: what got in the way, what should change |

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
