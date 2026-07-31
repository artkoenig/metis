---
name: cost
description: Report what the running session cost in tokens — per dispatch and inside a dispatch — from the session's own transcripts, as a fact produced by a command. Reach for it at the end of a run, before the retro, or whenever a claim about what the workflow costs or what would make it cheaper is about to be made from impression. Also trigger on "what did this run cost", "how many tokens did the subagents use", or "where did the tokens go".
user-invocable: true
---

# Cost

Every claim about what a run costs is an impression until a command has
produced it. This skill is that command.

## How to run it

From the project directory, with no arguments:

```
python3 <this-skill>/assets/token-cost.py
```

Wherever this page sits — plugin cache, `~/.claude/skills`, a checkout — the
command sits next to it in `assets/`, and it works from any project. It reads
the running session's transcript and the transcript of every subagent that
session dispatched, under `~/.claude/projects/`. It creates and modifies no
file, and it reads no session's transcripts but the current one's. Which
session that is comes from `CLAUDE_SESSION_ID` or `CLAUDE_CODE_SESSION_ID`;
where neither names one, the command reports that it cannot identify the
running session and exits non-zero rather than guessing a transcript that may
belong to another session.

It prints one row per dispatch plus one row for the main session — agent
type, what it was dispatched for, model steps, cache-write, cache-read,
output — and under every row where that row's cache-write went: grouped by
the kind of thing that entered the context, and as the individually most
expensive items with the step at which each entered. Rows are sorted by
cache-read, descending.

Then record the per-dispatch numbers through the `issue` skill, together with
the command that produced them — the same way any other fact by exit code
lands in the record.

## How to read the numbers

- **steps** are model calls, not transcript records. One call is written as
  one record per content block, and every one of those records repeats the
  call's usage; adding them up inflates both the steps and the tokens.
- **cache-read** is what the run costs. It dominated cache-write by 16× in
  the measurement this skill was built from, so the cost follows *steps × the
  context each step carries*.
- **output** is marked unreliable and printed with a `~`. Within one call the
  records disagree — a placeholder beside the real count — so the largest
  value seen for a call is shown as a marked figure, not as a count.
- **measured** is one call's whole cache-write, with a single item entering
  the context before it. **estimated** is one call's cache-write split
  proportionally across the items that entered together; the transcript
  attributes nothing finer.
- No weighted or combined total is printed. The three kinds of token are raw
  and separate; weighting them would need a price list this repository does
  not have.

## What it is not

Not a budget and not a limit — whatever the figures are, it reports them and
never refuses over them. And not a live
meter: it reads what the transcripts hold at the moment it runs, so the last
few calls of the running turn are not in it yet.

`skills/cost/assets/test-token-cost.sh` guards the command; `test.sh` runs
that suite with the others.
