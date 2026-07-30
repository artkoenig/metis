---
status: backlog
branch:
pr:
---

# Every review round pays for a whole fresh context

## Intent

`AGENTS.md:143` says a review repeats from a fresh context after every fix, so
each round starts empty and re-establishes everything the previous round
already knew: it reads the intent, reads the diff, runs the suite, runs the
validator, reads the scripts. Measured over issue 0022's four rounds:

| round | model steps | cache-read |
| --- | --- | --- |
| 1 (lost, relaunched) | 74 | 4,536,578 |
| 1 (relaunch) | 49 | 2,150,958 |
| 2 | 78 | 4,807,370 |
| 3 | 76 | 4,409,773 |

That is 277 steps and 15.9M cache-read tokens, 60% of everything the run's ten
subagent dispatches consumed. The rounds do not get cheaper as the change
converges — round 3 cost as much as round 2 while finding a third as many
things.

The rule exists for a reason, and the same run shows it: it was the fresh round
2 that noticed this repository had unwired its own hook, and the fresh round 3
that found a criterion round 2 had wrongly dismissed. So the cheap version has
to keep that guarantee where it earns its price and drop it where it only pays
for re-reading.

Wanted observable behaviour: a review round that follows a fix costs the diff
it has not seen yet, not the whole change again — while the first review of a
change is still done by a context that has seen only the diff and the written
intent.

Acceptance criteria:

1. When a change is reviewed for the first time, the reviewing context has seen
   only the diff and the written intent — invariant 3 of `AGENTS.md` unchanged.
2. When a round follows a fix, the same reviewing context continues instead of
   a new one starting, and its findings still cover the whole intent rather
   than only the findings it raised itself.
3. When rounds are continued this way, round N+1 of an issue costs fewer
   cache-read tokens than round N, shown by the command from issue 0025.
4. When a round was continued rather than started fresh, the issue's record
   says so for that round.
5. `AGENTS.md` and `agents/reviewer.md` describe the same arrangement as each
   other and as the criteria above; no document still asks for a fresh context
   where a continued one is used.

## Plan

## Tasks

## Decisions

- The human rejected the opposite change — making the last round before the
  pull request always fresh — because a fresh round can raise the finding count
  again and start another loop. Their preference: intermediate rounds are
  resumed, not restarted. Source: their answer during issue 0022's run,
  recorded there.
- What this issue does *not* claim to fix: the loops themselves. The run's
  numbers blame those on findings outside the criteria being repaired, which is
  issue 0027. Source: the finding counts per criterion in issue 0022's trend
  table.

## Log

- Filed after issue 0022's run, on the human's request, out of the token
  measurements taken during it.
- The first round's result never reached the dispatching session and the round
  was relaunched, so the run paid for it twice: 74 steps and 4.5M cache-read
  tokens for a result nobody ever saw. Whether a continued reviewer makes that
  loss cheaper or more expensive is unmeasured, and worth a thought during
  implementation.

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
