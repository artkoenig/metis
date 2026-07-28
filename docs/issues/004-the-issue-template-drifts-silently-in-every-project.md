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

Wanted: a project's issue template cannot silently disagree with the metis
one. Whether that means it stops being a copy, or the copy is compared and
reported on, is open.

Acceptance criteria:

1. A project whose template has diverged from metis's cannot go unnoticed:
   either the copy is eliminated, or the divergence is surfaced at session
   start.
2. A project that was bootstrapped earlier and never runs the bootstrap skill
   again still ends up with the current template — the fix reaches projects
   that nobody touches.
3. `AGENTS.md` still describes an issue as shaped by
   `docs/issues/TEMPLATE.md`, or says accurately what replaced that path.
4. `skills/bootstrap/SKILL.md` states how the template is kept current, next
   to what it already says about the loader and the core.

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
