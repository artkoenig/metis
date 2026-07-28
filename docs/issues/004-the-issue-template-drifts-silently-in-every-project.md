---
status: backlog
branch:
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
- **The shape of the fix is deliberately left open.** A symlink like `agents/`
  and `skills/` is the obvious candidate, but the template is a file a project
  might legitimately want to extend, which a symlink forbids; a compare-and-
  warn keeps that freedom and costs a check. That trade-off belongs to whoever
  runs this, not to the filing.

## Log

## Checkpoints

### Before implementation

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
