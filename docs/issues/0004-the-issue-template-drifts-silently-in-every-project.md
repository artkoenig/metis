---
status: active
branch: 004-template-drift
pr:
---

# The issue template drifts silently in every project that uses it

## Intent

The SessionStart hook keeps `agents/` and `skills/` current by symlinking them
out of the metis clone: change one here, and every bootstrapped project has it
on its next session start. `docs/issues/TEMPLATE.md` is not covered by that.
It is copied into each project when the tracker is set up, and from then on it
is a private fork that no mechanism ever updates or compares.

This is not hypothetical. Metis has existed for one day and has two projects
using it, and the copy had already gone stale: `003` changed the status
semantics, and the copy in `tome_of_battle` went on telling every newly filed
issue that `pr` is "set as soon as one is open" and that `waiting` still means
awaiting a merge. It was caught because someone happened to remember, which is
not a mechanism.

It is also the same defect the bootstrap skill was built to eliminate. Its
loader/core split exists because the predecessor carried its sync logic in the
per-project hook copy, so a workflow change never reached an already-wired
project. The template is that bug, surviving in the one file the split does
not cover.

Wanted: no project has an issue template at all, and the shape is stated in
exactly one place. Filing an issue is a procedure, not an invariant, and
procedures in this workflow are skills — which the core already symlinks into
`~/.claude` alongside the subagents. The delivery problem was solved before it
was posed; it only had to be recognised as the same problem.

Acceptance criteria:

1. The shape of an issue file — its name, its frontmatter, its sections and
   what belongs in each — is stated in exactly one place, and that place
   reaches every session without anything being copied into a project.
2. `AGENTS.md` says an issue is filed through that skill and does not restate
   the shape. It keeps what the states *mean*; the skill keeps what the file
   *looks like*.
3. Nothing writes a template into a project: no step in
   `skills/bootstrap/assets/session-start-core.sh` copies one, and
   `skills/bootstrap/SKILL.md` claims none.
4. Issue files are named `NNNN-slug.md` — four digits — and the four already
   filed are renamed, so that a fifth cannot sort ahead of the first.
5. An agent that has only the skill files a file matching the four that exist:
   the H1 title, all seven headings including the empty ones, and the Log's
   ordering are stated, not left to be inferred.

## Plan

## Tasks

## Decisions

- **Source:** noticed while migrating `tome_of_battle` to Metis, and confirmed
  the same day when `003` changed the status semantics in metis and the
  project's copy kept the old ones. The copy was corrected by hand there; this
  issue is about the mechanism, not that one file.
- **Filed rather than fixed on the spot.** It serves no acceptance criterion
  of the migration that surfaced it, so by the rulebook it is a new issue and
  waits for its own run.
- **The shape of the fix was deliberately left open at filing.** A symlink
  like `agents/` and `skills/` is the obvious candidate, but the template is a
  file a project might legitimately want to extend, which a symlink forbids; a
  compare-and-warn keeps that freedom and costs a check. That trade-off
  belonged to whoever ran this.
- **Decided: the template becomes a generated file, refreshed from the clone
  at every session start.** Reasoning, in order:
  - *Not a symlink.* `docs/issues/TEMPLATE.md` is versioned in the project and
    read by humans on GitHub. A symlink into `~/.claude/metis/…` would be
    committed and dangle for anyone without the clone.
  - *Not compare-and-warn.* A warning needs someone to act on it, and the run
    it interrupts is never the run that wants to fix it. That is the
    predecessor's failure mode in a new costume.
  - *Extension is not a freedom worth protecting here.* The rulebook already
    fixes the sections as the interface between the agents that read and write
    the file — "their names and order are fixed". A per-project template that
    diverges is a per-project agent contract, which is the thing the interface
    exists to prevent.
  - *Precedent inside metis:* `AGENTS.md` is already copied into
    `~/.claude/CLAUDE.md` on every session start by the same core. The
    template is the same kind of artifact reaching a different destination.
  - The cost is that a local edit is silently discarded. That is made visible
    by a generated-file notice in the template itself, naming where to edit it
    instead.
- **Only for projects that already use the tracker.** The refresh writes into
  an existing `docs/issues/`; it never creates one. A project without a
  tracker has not opted in, and metis does not conjure a directory into it.
- **Superseded — the refresh decision above is withdrawn, and with it the
  criteria it was built against.** Kept in the record because the reasoning
  is what got refuted, and a decision log that only shows what survived
  teaches nothing. What refuted it:
  - *The human's question:* why is the template copied at all? Nothing in the
    original reasoning answers it. It weighed symlink against compare-and-warn
    and never asked whether a project needs the file.
  - *The grep:* `TEMPLATE.md` is named by the core script, by `SKILL.md`, by
    `AGENTS.md` and by itself. No agent definition and no skill reads it. Its
    only reader is the caller, which already holds the rulebook.
  - *The review:* the mechanism did not even work. The core runs only in cloud
    sessions — the loader exits before `exec bash "$core"` on every local path
    — so a project opened only locally never gets the refresh and is never
    told it drifted. Criteria 1 and 2 were unmet, and two sentences the change
    added to `AGENTS.md` and `SKILL.md` were false.
  - *The argument I gave for keeping it in the project* was that a human reads
    it on GitHub. The rulebook is not in the project either, and nobody has
    missed it.
- **Decided instead: `AGENTS.md` carries the section interface, and nothing is
  delivered anywhere.** The interface is seven section names with a line each
  — a table in a page that already reaches every session. `TEMPLATE.md` stays
  in metis as the long form and names the rulebook as the authority.
- **The residual risk, stated rather than denied:** the interface now exists
  in two levels of detail, and they can diverge. The difference from what was
  reverted is that both live in this repository, one diff shows both, and a
  reviewer reads both. It is the same failure mode one storey up and far
  cheaper.
- **Projects that already carry a copy** — `tome_of_battle` has one — are not
  touched from here. Removing it is a change in that repository, on its own
  branch.
- **Superseded again — the rulebook-carries-the-table decision is withdrawn.**
  It removed the copy but kept the duplication: `AGENTS.md` restated the
  template instead of replacing it, and the review found the two levels of
  detail already disagreeing on the day they were created.
- **Decided: the shape moves into a skill, `skills/issue/`, with the template
  as its asset.** The human proposed it, and it is better than what it
  replaces on every count that mattered:
  - *The delivery mechanism already exists.* The core symlinks `skills/` into
    `~/.claude` exactly as it does `agents/`. No copy, no refresh step, no
    cloud/local asymmetry — the failure that killed the first design.
  - *One source instead of two.* Four of the five findings from review round 2
    exist only because `AGENTS.md` retold the template; they disappear rather
    than getting fixed.
  - *The rulebook gets shorter.* A one-page rulebook that had grown a
    seven-row table loses it again.
  - *It is the honest classification.* Filing an issue is a procedure. The
    invariants are what always holds; a procedure with steps is a skill.
  - The one thing it costs: skills are invoked, not read. So the bookkeeping
    rule has to say an issue is filed *through* the skill — this is the one
    skill that is not a shelf tool.
- **Rejected: a version field in the template, for migrations.** The human
  raised it; the argument against is that an issue file is prose read by a
  language model, not a record parsed by a schema. A schema needs migrations
  because a missing field breaks it; prose does not — an issue without
  `## Log` is one filed before `## Log` existed, and the file says so by not
  having it. A version would duplicate what is already visible and would need
  its own migration path to maintain. There are nine issue files in existence;
  a shape change is one pass, not a pipeline. Recorded in the skill together
  with what would change it: a section that keeps its name and changes its
  meaning, which an old file does not reveal.
- **Four digits instead of three**, on the human's instruction: more headroom.
  The four existing files are renamed in the same change, because `0005` sorts
  before `001` and a mixed directory loses the ordering the padding is for.

## Log

- **First implementer dispatch returned `blocked` against the wrong
  repository.** It worked in `/home/user/global-agents-config-and-skills` —
  the predecessor workflow — and reported, accurately for that repo, that
  there is no loader/core split, no `docs/issues/TEMPLATE.md`, no
  `skills/bootstrap/`, and no `## Bookkeeping` section. Every one of those
  exists in `/workspace/metis`. Cost: one dispatch, no edits.
- **My briefing defect, found by the same dispatch.** The brief named
  `assets/session-start-core.sh`. The real path is
  `skills/bootstrap/assets/session-start-core.sh`; `SKILL.md` refers to its
  own assets relatively and I copied that shorthand without qualifying it. A
  brief that names a path names it from the repository root or it names
  nothing.
- Both corrected and the same agent re-briefed rather than re-dispatched, so
  what it had already established about the predecessor repo is not paid for
  twice.
- **Implementation landed as `8c2e230`.** The implementer reported `done` and
  flagged one thing rather than fixing it: in a metis cloud session the
  refresh overwrites the checkout's template from the clone of pushed `main`.
  It also caught a defect of its own making before shipping it — a self-copy
  would have aborted the core under `set -euo pipefail` before it emits the
  hook JSON, costing the session `reloadSkills` — and it refused to let a
  vacuous assertion pass, building the naive `mkdir -p` variant to watch its
  own check go red first.
- **Review round 1, triage.** Four findings; the reviewer re-ran the harness
  itself, and additionally verified against the pre-change baseline and
  against the naive variant instead of trusting the implementer's account.
  - *Blocking:* the core never runs in a local session, so the refresh reaches
    cloud sessions only. Criteria 1 and 2 unmet, and two sentences the change
    added were false. Reproduced with a drifted template: loader exit 0, no
    core in the log, template unchanged.
  - *Confirmed, no criterion violated:* the metis self-overwrite. The
    reviewer's verdict — outside the criteria, but it inverts the premise the
    decision rests on, because in metis the clone is the older thing.
  - *Confirmed:* the `-ef` guard is dead on every path where the core runs.
  - *Low:* `SKILL.md` misdescribed which comment block holds the notice.
  - The harness itself had the blind spot that let the first finding through:
    it invokes the core directly and never the loader, so nothing in it
    asserts that a session ever reaches the refresh.
- **`8c2e230` reverted as `5a47ad5`** — the four implementation files back to
  `cc315b5`, this issue file kept. Three of the four findings exist only
  because a copy exists; the fix is to stop copying, not to patch the copier.
- **Perception rule note:** this is not *repetition* — one attempt, one set of
  findings. It is *surprise* in the rulebook's sense: the mechanism behaved
  differently than the decision assumed, and the decision was the thing that
  had to change.
- **Round 2 built the rulebook-carries-the-table design (`6b2df81`), and the
  review found five things.** One — `SKILL.md` claiming the loader is the only
  file metis puts into a project, two sections above a step that installs a
  second — was a false sentence the change itself added, the same defect class
  as round 1. Four were consequences of the duplication: the `## Log` ordering
  rule existed only in the template, the H1 title line was never mentioned in
  the rulebook, the template pointed at "the same table" while containing no
  table, and whether an empty optional heading stays was left ambiguous. The
  reviewer proved the divergence was already present rather than merely
  possible, on the day it was introduced.
- **`6b2df81` reverted as `db1ea7c`.** The five findings were not fixed: four
  of them cease to exist under the skill design, and fixing them would have
  been work spent on an approach about to be replaced.
- **Review round 3 — and the perception rule fired.** Criterion 1 was missed
  in round 2 and again in round 3, each time with a different finding. Under
  the rule as `0001` widened it — *the same acceptance criterion missed twice,
  whatever the finding* — that is a stop signal, and the question it forces is
  the right one: is the shape stated in too many places by construction? It
  was. The answer was structural, not another patch: the template is now a
  bare skeleton and the skill's table is the only description of what goes in
  a section. Round 3's findings 2, 4 and 5 all dissolve in that one move.
  This is the first time a perception rule has fired in anger, and it earned
  its keep — two rounds of patching would each have looked reasonable.
- **Round 3 triage.**
  - *Fixed by the structural move:* the template shipped the status semantics
    the skill disclaims (finding 2); the skill and the template each described
    the sections (finding 5); "delete the HTML comments" missed the YAML ones
    (finding 4).
  - *Fixed:* `AGENTS.md` enumerated the frontmatter fields after delegating
    them — it now states what the states mean without listing the shape
    (finding 3); one sentence described filing without routing through the
    skill (finding 6).
  - *Accepted, filed as `0005`:* a newly added skill does not reach a local
    session, because the loader exits before the core on that path. Pre-dates
    this change, affects every future skill and subagent equally, and rests on
    a precondition the reviewer could not verify from inside the repository.
    `0004`'s criterion 1 is therefore not fully met, and that is stated rather
    than argued away.
- **Second reversal on this issue, and it is worth naming as such.** Two
  designs, two refutations, both because the question *who actually needs this
  file?* was asked late. The perception rules do not fire on it — no failure
  repeated, nothing regressed — which is itself the observation: neither
  *repetition* nor *surprise* catches "the problem was framed wrong", and
  what caught it both times was the human asking a question rather than any
  rule.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes. The human asked for this issue to
  be built; its four criteria are unchanged from the filing. The one thing
  the filing left open — symlink or compare-and-warn — was mine to settle,
  and it is settled above with its reasoning rather than left to the
  implementer.
- **What surprised me?** That the criteria as written admit a solution that
  fails the spirit: a warning satisfies "the divergence is surfaced" while
  leaving the drift in place. That is why the decision above rules it out
  explicitly instead of relying on the criteria.
- **What am I assuming without having verified it?** Three things, all for
  the implementer to check first. (a) That the core can learn the project
  directory — a `SessionStart` hook should have `$CLAUDE_PROJECT_DIR`, but I
  have not read the script. (b) That the core runs in the cloud path only,
  and that a local session therefore needs its own answer or none. (c) That
  no project currently has a deliberately extended template; only
  `tome_of_battle` uses one, and its copy was verbatim until it went stale.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
