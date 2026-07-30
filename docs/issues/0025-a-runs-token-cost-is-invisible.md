---
status: backlog
branch:
pr:
---

# A run's token cost is invisible

## Intent

Nothing in the workflow says what a run costs. The question first came up
during issue 0022's run and could only be answered by hand-writing a Python
aggregate over the session's own subagent transcripts under
`~/.claude/projects/<project>/<session>/subagents/*.jsonl`. What that aggregate
found for that run's ten dispatches:

| agent | dispatches | model steps | cache-write | cache-read |
| --- | --- | --- | --- | --- |
| reviewer | 4 | 277 | 819,369 | 15,904,679 |
| test-author | 4 | 164 | 585,207 | 6,491,868 |
| implementer | 2 | 104 | 248,179 | 4,289,743 |
| **total** | **10** | **545** | **1,652,755** | **26,686,290** |

Cache reads dominate cache writes by 16×, so the cost follows *steps × the
context each step carries* — and the reviewer, at 60% of the cache reads, is
where the run's money goes. None of this was knowable while the run happened,
and none of it will be knowable in the next run either. So every claim about
what the workflow costs, and every proposal to make it cheaper, is an
impression — which invariant 4 forbids for a fact.

Wanted observable behaviour: what a run cost is a fact produced by a command,
broken down per dispatch, and it lands in the record like any other fact.

Acceptance criteria:

1. When a session has dispatched subagents, one documented command prints, per
   dispatch, the agent type, what it was dispatched for, its model steps and
   its token counts, and exits 0.
2. When it runs in a session that dispatched no subagent, it says so and exits
   non-zero instead of printing an empty table as if that were the answer.
3. When the command runs, it creates and modifies no file, and reads no
   session's transcripts but the current one's.
4. When a run ends, the per-dispatch numbers are in the issue's record together
   with the command that produced them.
5. When a token field in the transcripts is unreliable, the command's output
   marks it as such instead of printing it as a count — see the Log for the
   case that motivates this.

## Plan

## Tasks

## Decisions

- The metric to optimise is cache-read tokens, not output tokens: in the
  measurement above they outweigh output by roughly 300× and cache writes by
  16×. Source: that measurement.

## Log

- Filed after issue 0022's run, on the human's request, out of the token
  measurements taken during it.
- **The transcripts' output-token field cannot be trusted uniformly**, found
  while taking the measurement above. Four of the ten dispatches report under
  1,000 output tokens across 40 to 75 model steps — 967 tokens over 74 steps
  for one reviewer round, 457 over 59 for a test-author. That is not plausible
  for runs that wrote whole test files. Steps and cache-read counts are
  internally consistent across all ten. Whoever implements this establishes
  which fields are reliable before reporting any of them; criterion 5 exists
  for the ones that are not.
- **One optimisation was tried during 0022 and is established neither way**:
  frontloading repository facts into the dispatch prompt so the subagent would
  not have to re-derive them. The later dispatches were smaller in scope than
  the earlier ones, so their lower step counts cannot be attributed to the
  prompt change. Recorded as an attempt, not as a result — and as the reason
  this issue comes before any further optimisation.

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
