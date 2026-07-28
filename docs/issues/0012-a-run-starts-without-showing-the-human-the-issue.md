---
status: active
branch: claude/new-session-xeyz5n
pr:
---

# A run starts without showing the human the issue

## Intent

When a session picks up an issue, the human currently gets whatever prose the
session chooses to open with. What the issue is — its name and what "done"
means — is not reliably in front of them before the work starts, so they
steer blind unless they open the tracker themselves.

Wanted behaviour (requested by the human during run 0006): before work on an
issue begins, the human sees a short summary of it — the issue's name and its
acceptance criteria, as a table.

Acceptance criteria:

1. The rulebook states that before implementation of an issue starts, the
   report to the human contains a compact summary: the issue's title and its
   numbered acceptance criteria, rendered as a table.
2. The rule stays in the perception style of the rulebook: it prescribes what
   the human sees, not a script or mechanism that produces it.

## Plan

## Tasks

## Decisions

- The rule lands in `AGENTS.md`, "The run", directly after the run diagram
  — the one place describing how a run proceeds. README stays untouched:
  a grep over table/criteria/summary/opens shows it does not describe what
  the human sees at run start. Implemented in the main context — prose
  only, fresh review still runs (precedent 0005/0006/0015).

## Log

- Change applied: one paragraph after the run diagram — "A run opens with
  the issue in front of the human: its title and its numbered acceptance
  criteria, as a table. What 'done' means is visible before implementation
  starts — not on request." Perception style: it prescribes what the human
  sees, no mechanism. Nothing to run (invariant 2's honest path): the two
  criteria are about rulebook prose; the shell suites touch nothing in
  this diff. Dogfooded in the same turn — this run itself opened with the
  0012 criteria table.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — the human's own request from run
  0006, two narrow prose criteria; no ceremony needed.
- What surprised me? Nothing.
- What am I assuming without having verified it? That "as a table" means a
  markdown table in the report to the human, matching the trend-table
  precedent — the request did not specify a format beyond "table";
  recorded as the plain reading.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
