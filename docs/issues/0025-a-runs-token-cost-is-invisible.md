---
status: active
branch: claude/issue-25-4vhg5a
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
- **Transcript layout, confirmed fresh.** A dispatch made during this run
  produced `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl`
  plus a sidecar `agent-<id>.meta.json` holding `agentType`, `description`
  (the short label the caller passed at dispatch — this is "what it was
  dispatched for"), `toolUseId` and `spawnDepth`. Source: inspecting the
  files this run's own `researcher` dispatch created.
- **`output_tokens` is unreliable specifically on subagent transcripts,
  reproduced independently of the 0022 measurement.** That dispatch's final
  message carried a real ~600-character answer but reported
  `usage.output_tokens: 1`. `cache_creation_input_tokens` and
  `cache_read_input_tokens` behaved consistently (grew monotonically,
  plausible scale) and are the fields the command reports; `output_tokens` is
  marked unreliable and never printed as a count, unconditionally — there is
  no runtime signal to tell a good dispatch's count from a bad one, so
  criterion 5 is met by never trusting the field rather than by guessing
  which rows are fine. Source: same fresh dispatch.
- **A "model step" is one unique `message.id` among `type: "assistant"`
  lines, not one JSONL line.** The same dispatch's transcript shows a single
  turn's `thinking` content and its `tool_use` content as two separate JSONL
  lines sharing one `message.id`, each carrying the identical full `usage`
  block. Summing per line double-counts; the command dedupes by
  `message.id` before counting steps or summing tokens. Source: same fresh
  dispatch.
- **No `plan` skill invocation for this change.** It is one self-contained
  new capability (a script plus its documentation) with only mechanical
  wiring elsewhere (`test.sh`, and README/AGENTS.md if criterion 4 turns out
  to need a rulebook line) — not modules with shared contracts to weigh
  against each other.
- **Criterion 4 gets a rulebook line, not just a one-off for this run.**
  "When a run ends, the per-dispatch numbers are in the issue's record"
  reads in the same "when X, then Y" style as the rest of `AGENTS.md`, and
  this repo's own precedent (issues 0006, 0012, 0020) is to fold a
  behavioural finding straight into the rulebook. `AGENTS.md`'s Bookkeeping
  section gets one line: a run that dispatched subagents records the
  command's per-dispatch output in the issue before it is marked done. This
  run demonstrates it by doing exactly that below. Source: this run's own
  reading of the acceptance criterion; a prose-only change, so the reviewer
  is the only check it gets, per invariant 3.
- **Command shape, decided so test-author and implementer build the same
  contract without a full `plan` round-trip.** A new skill,
  `skills/token-cost/`, holds `SKILL.md` and `assets/token-cost.py`
  (`python3`, matching the `python3` precedent already set by `install.sh`
  for JSON handling). Invocation: `python3
  ~/.claude/skills/token-cost/assets/token-cost.py` (reachable at that path
  in any metis-wired session once bootstrap's symlinking runs). Contract:
  reads `$CLAUDE_CODE_SESSION_ID` and `$HOME` from the environment (both
  overridable, which is what makes it testable against a scratch
  `$HOME/.claude/projects` tree instead of the real one); locates
  `$HOME/.claude/projects/*/<session-id>/subagents/agent-*.jsonl` by an
  exact session-id match — never scans other sessions' files; exits 0 with
  a per-dispatch table plus a grand-total row on success, exits 1 with a
  message on stderr when the session can't be found or dispatched no
  subagent; never writes any file. `assets/test-token-cost.sh` is its test
  harness, wired into root `test.sh` alongside the existing two harnesses.

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

- Does this match what was asked? Yes — a documented command that reports
  per-dispatch subagent token cost from this session's own transcripts, with
  the two edge cases (no dispatches, unreliable field) as hard requirements,
  and this run's own numbers landing in this record afterward.
- What surprised me? Reproducing the log's flagged surprise myself, fresh:
  a subagent's own final answer, ~600 real characters long, reported
  `output_tokens: 1`. And a mechanism I had to find to implement this
  correctly at all — a single model turn can appear as two JSONL lines
  sharing one `message.id`, each carrying the same full `usage` block, so a
  naive per-line sum silently doubles cache-write and cache-read.
- What am I assuming without having verified it? That `CLAUDE_CODE_SESSION_ID`
  is set in every metis-wired session, and that the `agent-<id>.jsonl` /
  `.meta.json` layout is stable across Claude Code versions, not an artifact
  of this container's version (2.1.220) alone.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
