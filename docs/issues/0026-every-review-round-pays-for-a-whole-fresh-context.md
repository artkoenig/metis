---
status: active
branch: claude/issue-26-8lvd7s
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
- No test-author dispatch: the change touches only `AGENTS.md`,
  `agents/reviewer/agent.md` and `README.md` — prose, nothing `test.sh`'s three
  suites exercise. `grep -rn 'AGENTS.md' test.sh skills/bootstrap/assets/*.sh`
  shows the rulebook only as a file that must exist or gets copied, never as
  content a suite checks, so there is nothing to run and invariant 2 is held by
  saying so. Source: the same grep issue 0021 ran for the identical question.
- Criterion 3 cannot be shown by exit code in this run: it names "the command
  from issue 0025", and 0025 is still `backlog` — no such command exists yet.
  The reviewer reports this criterion as not verifiable rather than guessing at
  a number. Source: `docs/issues/0025-a-runs-token-cost-is-invisible.md`
  frontmatter.
- The mechanism for "the same reviewing context continues" is the harness's
  existing agent-resume path (continue a dispatched agent by addressing it
  again, rather than launching a fresh one) — already available, nothing new
  to build. `AGENTS.md` states the requirement in tool-agnostic terms and
  leaves the mechanism to judgment, matching how the rest of the rulebook
  stays silent on tool mechanics. Source: default, unanswered.

## Log

- Filed after issue 0022's run, on the human's request, out of the token
  measurements taken during it.
- The first round's result never reached the dispatching session and the round
  was relaunched, so the run paid for it twice: 74 steps and 4.5M cache-read
  tokens for a result nobody ever saw. Whether a continued reviewer makes that
  loss cheaper or more expensive is unmeasured, and worth a thought during
  implementation.
- Facts before review: `./test.sh` — 3 suites, all cases, exit 0. It covers the
  installer and the session-start hook; the change touches only `AGENTS.md`,
  `agents/reviewer/agent.md` and `README.md`, none of which any suite reads as
  content. No static analysis exists in the repository (no `.github/`, no lint
  config in `git ls-files`). This review is the change's only check.
- Criterion 5, established by `grep -rn 'fresh' --include='*.md' .` over the
  repository (excluding `docs/issues/`), exit 0: every remaining "fresh"
  either names invariant 3's unchanged property (`AGENTS.md:25`,
  `README.md:23`), the first review round specifically (`AGENTS.md:143`,
  `agents/reviewer/agent.md:3,18,69`), or an unrelated mechanism
  (`clean-room/SKILL.md`'s blind dispatch, `agents/implementer/agent.md:48`'s
  boundary against reviewing its own work, `README.md:47`'s "loads metis
  fresh"). No document still claims every round is fresh.
- Review round 1 (fresh context — no prior round existed to continue): 2
  findings. Triage: finding 1 (`AGENTS.md:145` said the reviewing context
  checks "not only the findings it fixed itself" — the reviewer never fixes,
  only the implementer does, contradicting `agents/reviewer/agent.md:80` and
  the run diagram; the parallel sentence in `agents/reviewer/agent.md` already
  said "raised") fixed by changing "fixed" to "raised" in `AGENTS.md`. Finding
  2 (`agents/reviewer/agent.md`'s opening line claimed the reviewer "has seen
  nothing but the diff and the written intent," unconditional, though 11 lines
  later the same file says a continued round also carries its own prior
  reading) fixed by qualifying the opening line: "only the diff and the
  written intent, and, from the second round on, your own prior reading of
  them." Both fixes touch files the criteria are about, so the waiver does not
  apply; round 2 is due and continues the same reviewing context, per the rule
  this issue itself establishes.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes: the human's decision (recorded
  above) already rejected the opposite fix, so the direction is fixed —
  intermediate rounds resume, they do not restart.
- **What surprised me?** How little there is to build: the harness already
  supports resuming a dispatched agent, so this issue is a rulebook and
  agent-definition rewrite, not new tooling — the same shape as issue 0021.
- **What am I assuming without having verified it?** That criterion 3 is
  meant to hold as a property of the new arrangement, not as something this
  run itself has to measure — issue 0025's command doesn't exist yet to
  measure it with.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
