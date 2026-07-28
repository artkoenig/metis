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

Wanted: no project has an issue template at all. The rulebook already reaches
every session; it can carry the section interface itself, and then there is
nothing to keep in sync. The drift is removed by removing the copy, not by
maintaining it.

Acceptance criteria:

1. `AGENTS.md` carries the section interface itself — every section name, in
   order, and what belongs in each — so an agent holding only the rulebook can
   file a correctly shaped issue.
2. Nothing writes a template into a project: no step in
   `skills/bootstrap/assets/session-start-core.sh` copies one, and
   `skills/bootstrap/SKILL.md` claims none.
3. `AGENTS.md` no longer says an issue is shaped by `docs/issues/TEMPLATE.md`.
   That path names a file inside metis; from a project it resolves to
   whatever stale copy happens to sit there, or to nothing.
4. `docs/issues/TEMPLATE.md` stays in metis as the long form for a human
   reader, and says on its face that the rulebook is the authority — so the
   two cannot be read as competing sources.

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
