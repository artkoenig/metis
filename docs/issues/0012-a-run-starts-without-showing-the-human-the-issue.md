---
status: done
branch: claude/new-session-xeyz5n
pr: https://github.com/artkoenig/metis/pull/19
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
  criteria are about rulebook prose; no suite covers rulebook content
  (the core harness copies AGENTS.md as a presence fixture, nothing
  more). Dogfooded in the same turn — this run itself opened with the
  0012 criteria table.

- Review round 1 (fresh context): both criteria met — the paragraph
  carries title, numbered criteria, table, before-implementation, and
  names no mechanism; placement after the run diagram checked, README
  silence and non-overlap with agents/skills verified by grep; all three
  suites run as baseline, exit 0 each (none covers rulebook prose — this
  review is the change's only check). One minor, no criterion: the Log
  claimed "the shell suites touch nothing in this diff" while the core
  harness copies AGENTS.md as a fixture — wording fixed to "no suite
  covers rulebook content". No repeat round for the one-line record
  correction: judgment call, recorded (third data point for the
  repeat-waiver thread). Trend: 1.

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

- Does this match what was asked? Yes — the rule states exactly what the
  human asked for in run 0006, in perception style; reviewer confirmed
  both criteria with quoted evidence.
- What surprised me? Even in a two-line prose run the claims-success
  class appeared again: the Log stated something falsifiable and false
  ("suites touch nothing in this diff").
- What am I assuming without having verified it? That skipping the repeat
  round for a one-line record correction is safe — the rulebook text the
  criteria are about is unchanged since the review; recorded as a
  judgment call.

## Retro

Smallest run so far: one paragraph, one review round, one minor. Two
recurring threads gained a data point each. The claims-success class
showed up in pure bookkeeping (a Log line stating something false about
the suites) — fourth sighting; the candidate countermeasure recorded in
the 0011 retro (every factual record line must be checkable) still waits
for a carrier issue. And the repeat-round waiver was used a third time,
again for a record-only fix — the pattern is stable enough to propose a
rule: a repeat round is waivable when the fix touches only the tracker
record, never when it touches a file the criteria are about. Not filed
yet; worth bundling with the waiver thread's other two data points.
