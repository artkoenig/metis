---
status: active
branch: claude/new-session-xeyz5n
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

- The change lands in `AGENTS.md` (the definition) and `README.md` (which
  mirrors the correcting-course rules). The reviewer's report already names
  the criterion each finding violates, so the per-round table needs no change
  to the reviewer — the caller holds the cross-round tally. The implementer's
  stop signals describe its own inner loop, not review rounds, and stay
  untouched. Source: sweep of every text naming the stop signals
  (`AGENTS.md`, `README.md`, `agents/implementer/agent.md`).
- Implemented in the main context, not through the `implementer`: prose only,
  no production code, no tests; the fresh-context review still runs. Source:
  the precedent recorded in issue 0005.
- Branch is `claude/new-session-xeyz5n`, the session's designated branch,
  instead of the `NNNN-slug` convention. Default, unanswered — the session
  may not push elsewhere.

## Log

- Review round 1 (fresh context): no static analysis exists; the only suite
  (`test-session-start-core.sh`, 5 cases, exit 0) does not touch this change,
  so the reading is the only check. All three criteria met. Two minor
  findings, both fixed: (1) "The signal has a second tier" had no clear
  antecedent after a list of three signals — now "Repetition across review
  rounds has a second tier"; (2) the table had no cell for findings that
  violate no criterion, so its totals could disagree with its rows — now one
  extra row for those. Fix 2 goes beyond the intent's letter but serves its
  stated point (convergence visible); recorded here rather than filed.
  Trend: round 1 = 2 findings (criterion 1: 1, criterion 2: 1,
  criterion 3: 0).

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — a table rule for review-round
  reports and a two-tier stop signal, both in perception style, exactly the
  three criteria of the intent.
- What surprised me? Nothing yet; the sweep confirmed the reviewer already
  attributes findings to criteria, which the table needs.
- What am I assuming without having verified it? That no text outside
  `AGENTS.md`, `README.md` and the implementer repeats the stop-signal rule —
  verified only by one grep over the repo (excluding past issue records).

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
