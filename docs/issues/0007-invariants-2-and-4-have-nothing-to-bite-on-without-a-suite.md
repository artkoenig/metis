---
status: active
branch: claude/new-session-xeyz5n
pr:
---

# Invariants 2 and 4 have nothing to bite on without a suite

## Intent

Invariant 3 now names the class of change that produces no facts by exit
code — the rulebook, an agent definition, a skill's page, documentation. But
invariants 2 ("tests before code") and 4 ("the suite and static analysis
pass before the PR") still speak as if every change had a suite. For that
class an agent has no honest path: it must either declare the invariants met
with no exit code and no tests, or record two violated invariants. The
implementer definition has the same gap — its steps make a green suite by
exit code a precondition of reporting `done`, so for a prose change it
cannot honestly report `done` at all.

The run of issue 0002 hit this itself: a rulebook change with no tests and
no suite, landed by declaring nothing about invariants 2 and 4 because
nothing true could be declared.

Wanted behaviour: an agent landing a change with no tests and no suite to
run can satisfy every invariant honestly — the rules say what those two
invariants mean for this class, instead of silently not applying.

Acceptance criteria:

1. `AGENTS.md` invariants 2 and 4 account for a change with nothing to run:
   an agent landing such a change can state, truthfully, that every
   invariant holds. `README.md`'s restatement of the invariants stays in
   step.
2. The `implementer` definition gives the same honest path to `done` that
   the `reviewer` definition already has — reporting that nothing exists to
   run, with how it looked, instead of a green suite.
3. No new machinery: the accommodation is a clause in the existing rules,
   not a new process or a new class system.

## Plan

## Tasks

## Decisions

- The change touches `AGENTS.md` (invariants 2 and 4), `README.md` (its
  invariants list) and `agents/implementer/agent.md` (description, steps 3
  and 4, report format). The reviewer already has the honest path and is the
  wording model; the `test-author` is a shelf tool dispatched only when tests
  exist to write, so it stays untouched. Source: grep over the repo for
  suite/exit-code language (excluding past issue records).
- Implemented in the main context, not through the `implementer`: prose
  only, no production code, no tests; the fresh-context review still runs.
  Source: the precedent recorded in issues 0005 and 0006.
- Branch is `claude/new-session-xeyz5n`, restarted from `origin/main` after
  PR 13 merged. Default, unanswered — the session may not push elsewhere.

## Log

- Review round 1 (fresh context): no suite and no static analysis cover this
  change (established with commands; the bootstrap core test, 5 cases, exit
  0, does not touch it), so the reading is the only check. Criteria 1 and 3
  met; one finding on criterion 2, fixed: the new clauses said "no suite
  *and* no analysis", the reviewer's model says "*or*" — a project with a
  suite but no linter would again have had no honest path, the issue's own
  gap one level down. All four places now speak per item, disjunctively.
  Trend: round 1 = 1 finding (criterion 1: 0, criterion 2: 1,
  criterion 3: 0).

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — a clause in invariants 2 and 4, the
  README kept in step, and the implementer given the reviewer's honest path;
  no new machinery.
- What surprised me? Nothing; the grep matched the intent's own list of
  gaps exactly.
- What am I assuming without having verified it? That the reviewer's wording
  ("report that as the fact and show how you looked") is the right model to
  mirror — chosen for consistency, not confirmed with the human.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
