---
status: backlog
branch:
pr:
---

# Review rounds show no trend and have no convergence signal

## Intent

Two gaps showed up during run 0005, which took four review rounds.

First, the human could not see the trend. Each round's findings were reported
as prose, so whether the run was converging — fewer and smaller findings per
round — had to be asked for instead of being visible.

Second, the rulebook knows only one stop signal: repetition (the same
criterion missed twice), which triggers "change approach, or ask". It says
nothing about what happens when the changed approach also fails to converge.
In run 0005 that case occurred and was handled by judgment; the honest move —
stop and ask the human — stood nowhere as a rule.

Wanted behaviour: after every review round the human sees a compact table —
one row per acceptance criterion, the number of findings per criterion for
this and all earlier rounds, and the totals (e.g. 5 → 3 → 1). And when
findings stop getting fewer or smaller even after a changed approach, the run
stops and asks the human instead of running another round.

Acceptance criteria:

1. After every review round, the report to the human contains a table with
   one row per acceptance criterion and one column per round so far, each
   cell the number of findings, plus the totals per round.
2. The rulebook states a two-tier stop signal: repetition means change the
   approach or ask; no convergence despite a changed approach — the findings
   neither fewer nor smaller in weight or class — means stop and ask the
   human.
3. Both rules stay in the perception style: no numeric budget, no fixed
   round limit.

## Plan

## Tasks

## Decisions

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
