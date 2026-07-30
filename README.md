# metis

> An AI agent workflow built on judgment, not rules — a few invariants,
> self-correction in the loop, and a human only where it matters.

**Metis** is the Greek titaness of practical wisdom, and in Greek the word
itself: the ability to do the right thing in the moment, rather than follow
a plan. That is this project's principle, not just its name.

## How it works

The rulebook is one page: [`AGENTS.md`](AGENTS.md). Its core is **judgment
for process, mechanics for facts** — everything procedural is the agent's
call, every time; rules remain only where self-assessment fails. A fact like
"the tests pass" comes from an exit code, never from the agent's impression.

Five invariants hold for every change, whatever process judgment picks:

1. The intent — acceptance criteria — is written down before any code.
2. The tests for those criteria are written first — blind, by the
   test-author — and seen to fail; a change with nothing to run says so
   instead.
3. A fresh context reviews the diff against the written intent before the
   PR, with a concrete reproduction per finding — for a change with nothing
   to run, this review is the only check it gets.
4. The suite and static analysis pass, shown by exit code and reported with
   the state they ran on — the branch merged with the default branch, which
   is what lands; where nothing exists to run, that absence is the reported
   fact.
5. Decisions, surprises and checkpoint answers are recorded in the issue as
   they happen — the record outlives the session.

```
idea → issue with acceptance criteria → checkpoint 1
     → test-author (failing tests)    → implementer
     → reviewer (fresh context)
     → checkpoint 2 → PR → human merges → retro
```

The human steers at three points only: approving the criteria when the idea
is genuinely unclear, deciding anything irreversible or outward-facing, and
merging the PR.
Everything heavier — grilling, planning, a clean-room second opinion — is a
tool on the shelf, picked by judgment, never fired by a condition.

**The workflow corrects itself through the retro.** After every PR the agent
records what got in the way and what should change. A rule that misfired
becomes a proposal: a pull request against this repository, decided by the
human like any other. And because every wired project loads metis fresh at
session start, an accepted rule change reaches all of them with their next
session. The rulebook is not maintained — it is grown, run by run, out of
its own failures.

## Installing it

Run this in the root of your project (a git repository):

```
curl -fsSL https://raw.githubusercontent.com/artkoenig/metis/main/install.sh | bash
```

It installs and commits a `SessionStart` hook that loads the current
rulebook, subagents and skills into every Claude Code cloud session of the
project — updates included, no re-installation. To own the feedback loop —
retros landing as rule changes in *your* rulebook — fork this repository and
point the installed hook (and `METIS_SOURCE`) at your fork.
