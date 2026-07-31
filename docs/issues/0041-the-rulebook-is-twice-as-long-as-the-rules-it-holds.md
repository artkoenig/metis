---
status: backlog
branch:
pr:
---

# The rulebook is twice as long as the rules it holds

## Intent

`AGENTS.md` is 209 lines and 1,736 words. Most of that is not rules but the
reasons behind them, written out sentence by sentence, plus two blocks that
describe how one specific receiver works: the reviewer's round protocol and
what a dispatch hands a subagent. The file's own top rule is simplicity, and
the file is the one text that every session reads in full.

Wanted: the same rules in about 130 lines, with the two receiver-specific
blocks living on the pages of the receivers they describe. Nothing is dropped —
what leaves `AGENTS.md` arrives somewhere, or it stays.

A measured draft exists and reached 132 lines and 1,008 words while keeping
every rule.

Acceptance criteria:

1. `AGENTS.md` is at most 140 lines.
2. Every rule in force before the change is still stated once — in
   `AGENTS.md`, on an agent page, or on a skill page — with one exception,
   criterion 8. A reader can name, for each rule, the page that now carries it.
3. The reviewer's round protocol — the trend table after each round, the
   reviewing context continuing across rounds instead of restarting, the waiver
   for a fix that touches only the tracker, and naming the violated criterion
   per finding — is stated on the `reviewer` page.
4. What a dispatch may not hand a receiver, and why the intent is copied word
   for word rather than retold, is stated on the pages of the receivers it
   binds.
5. `AGENTS.md` still states, for each moved rule, the one line that makes the
   rule visible from the rulebook alone, and names the page that owns the rest.
6. The scoping clause of the orientation rule survives: the rulebook says a
   session reads nothing else *to get oriented*, not that it reads nothing
   else.
7. `README.md` states nothing about the workflow that the shortened
   `AGENTS.md` makes false.
8. `AGENTS.md` no longer requires a session to open by greeting the human and
   reporting the SessionStart hook's status line, and states no replacement for
   it. This rule is deleted, not moved: no agent page and no skill page carries
   it after the change either.

## Plan

## Tasks

## Decisions

- Target is about 130 lines, not 100. A draft that keeps every rule measured
  132 lines; reaching 100 would cost either the run diagram or the reply rules.
  Source: the human accepted the measurement, this session.
- The two receiver-specific blocks move rather than being deleted. Source: the
  human's choice between "compress only" and "compress and move", this session.
- The self-check bullet is deleted outright, not moved. Source: the human, this
  session. Consequence carried with it: the greeting requirement is in the same
  bullet and goes with it, and a session that cannot reach its skills or agents
  now says nothing about it — the opening that issue 0040 introduces is what a
  session opens with instead.

## Log

- Measured before filing: `AGENTS.md` is 209 lines / 1,736 words. A condensed
  draft keeping every rule is 132 lines / 1,008 words.

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
