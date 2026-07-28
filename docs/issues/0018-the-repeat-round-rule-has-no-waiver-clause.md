---
status: active
branch: claude/offene-issues-3hysxf
pr:
---

# The repeat-round rule has no waiver clause

## Intent

The rulebook says: "After a fix, the review repeats from a fresh context,
against the whole intent." No exception exists — yet three runs in a row
skipped the repeat as a recorded judgment call, each time for a fix that
touched only the record, never a file the criteria are about:

- 0015: the fix was a pure deletion the reviewer itself proposed.
- 0010: round-2 fixes were reporting/bookkeeping only (pass-line guards,
  a log correction).
- 0012: a one-line wording fix in the issue's own Log.

Three deviations with the same shape are no longer judgment calls — they
are an unwritten rule, and unwritten rules drift. The pattern observed:
the repeat is skippable exactly when the fix cannot change what the
criteria are about.

Wanted behaviour: the rulebook says when the repeat round is waivable, so
future runs neither re-run reviews that cannot find anything new nor skip
ones that could.

Acceptance criteria:

1. The rulebook's repeat-round rule states a waiver: a repeat may be
   skipped when the fix touches only the tracker record; a fix that
   touches any file the criteria are about always gets a fresh round.
2. The waiver's use is recorded in the issue, like any judgment call.
3. `README.md` stays in step where it repeats the rule.

## Plan

## Tasks

## Decisions

- Filed from the 0012 retro, bundling the open thread first recorded in
  the 0015 retro and seconded in 0010 — three data points, same shape.
  (by agent)

## Log

- One sentence added to the rulebook's repeat-round paragraph
  (`AGENTS.md`, "The run"): the waiver, its boundary (no file the
  criteria are about), and the duty to record its use (criteria 1 and 2).
- `README.md` checked whole: it summarises the reviewer step but never
  repeats the repeat-round rule, so criterion 3 needs no edit.
- Nothing to run for this change — a rulebook edit produces no facts by
  exit code; per invariant 3 the fresh-context review is the only check
  it gets. (`bash test.sh` still exits 0, but that covers the harnesses,
  not this text.)

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — one sentence in the rulebook's
  repeat-round paragraph stating the waiver and the duty to record its
  use. A fourth data point landed this very run: 0017's round-1 finding
  was record-only and the repeat was skipped as a judgment call.
- What surprised me? `README.md` does not repeat the repeat-round rule
  anywhere (checked its whole text) — criterion 3 is satisfied by
  showing nothing needs changing.
- What am I assuming without having verified it? That "the tracker
  record" is unambiguous enough — it means the issue file the `issue`
  skill owns, and nothing else.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
