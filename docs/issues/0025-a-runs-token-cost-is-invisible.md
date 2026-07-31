---
status: active
branch: claude/subagenten-token-verbrauch-cvo3ie
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

These four columns are no longer trusted as counts — see the Log entry on
records versus requests. They are kept because the conclusion they carry
survives the doubt: cache reads dominate cache writes by 16×, so the cost
follows *steps × the context each step carries* — and the reviewer, at 60% of
the cache reads, is where the run's money goes. None of this was knowable
while the run happened, and none of it will be knowable in the next run
either. So every claim about what the workflow costs, and every proposal to
make it cheaper, is an impression — which invariant 4 forbids for a fact.

Wanted observable behaviour: what a run cost is a fact produced by a command,
broken down per dispatch and within a dispatch, and it lands in the record
like any other fact.

Acceptance criteria:

1. When a session has dispatched subagents, one documented command prints, per
   dispatch, the agent type, what it was dispatched for, its model steps and
   its token counts, and exits 0.
2. When the command runs, it reports the main session's own consumption in the
   same columns as a dispatch, and when the session has dispatched no
   subagent it still reports the main session and exits 0.
3. When the command runs, it creates and modifies no file, and reads no
   session's transcripts but the current one's.
4. When a run ends, the per-dispatch numbers are in the issue's record together
   with the command that produced them.
5. When a token field in the transcripts is unreliable, the command's output
   marks it as such instead of printing it as a count — see the Log for the
   case that motivates this.
6. The printed step count is the number of model calls, not the number of
   transcript records: several records of one call repeat that call's token
   figures, and a count that adds them corrupts both the steps and the
   tokens. Shown false by any session whose printed step count exceeds the
   number of distinct requests in its transcript.
7. When the command reports a session or a dispatch, it prints both a grouped
   breakdown — what kind of thing put the tokens into the context — and the
   individually most expensive items, each with the step at which it entered.
8. When a printed figure was derived by splitting one request's cache-write
   across several items that entered together, the output marks that figure
   as estimated; a figure the transcript attributes to a single item is
   marked as measured.
9. When the command prints token counts, cache-write, cache-read and output
   are separate raw columns, and no weighted or combined total is printed.
10. When the command is invoked from a project that has metis installed but is
    not this repository, it produces the same output there. Shown false by any
    invocation that depends on a path inside this repository's working tree.

## Plan

## Tasks

## Decisions

- The metric to optimise is cache-read tokens, not output tokens: in the
  measurement above they outweigh output by roughly 300× and cache writes by
  16×. Source: that measurement.
- The command covers both the per-dispatch totals and the breakdown of where
  the tokens went inside a dispatch. Totals alone say whether an optimisation
  helped; only the breakdown says which one to try. Source: the human's
  answer.
- The whole run is measured, main session included — not subagents alone. The
  main session carries 86k per step against the reviewer's 10.8k, so leaving
  it out hides the largest single context. This replaced the filed criterion 2,
  which had required a non-zero exit when no subagent ran. Source: the human's
  answer.
- The breakdown is printed both ways: grouped by what kind of thing consumed
  the tokens, and as the most expensive individual items. The groups say which
  rule to change, the items say which call went wrong. Source: the human's
  answer.
- Where several items enter the context between two requests, their shares are
  split proportionally and every split figure is marked as estimated rather
  than dropped. Source: the human's answer.
- Only raw columns are printed — no weighted or combined total. The weights in
  Claude Code's own `/explain-usage` (write ×2, read ×0.1, output ×5) would
  quintuple exactly the field this issue's Log calls unreliable, and they come
  from a prompt, not from a price list. Source: the human's answer, upholding
  the recorded cache-read decision above.
- Rows sort by cache-read, descending — the most expensive first, since the
  point of the output is to find where the money went. Without a weighted
  column cache-read is the only metric this issue has already settled on. The
  direction was left undecided when the criteria were written and the
  `test-author` returned it as a question rather than guessing an expectation;
  it stays out of the criteria and is not tested. Source: default, unanswered.
- The command ships as a skill's asset rather than as a script in this
  repository's root, because criterion 10 requires it to work in projects that
  install metis as a plugin. Precedent: `skills/bootstrap/assets/`. Source:
  default, unanswered.
- The command is `skills/cost/assets/token-cost.py`, invoked as `python3` and
  guarded by `skills/cost/assets/test-token-cost.sh`, following the layout of
  `skills/bootstrap/assets/`. Python rather than shell because the transcripts
  are JSONL and `jq` is not guaranteed to be present, while `python3` is
  already what every measurement this session used. Source: default,
  unanswered — a name had to exist before tests could invoke anything.
- The premise table in the Intent is kept and annotated rather than deleted or
  recomputed. The 0022 transcripts no longer exist in any container reachable
  from here, so the correct figures cannot be established, and the conclusion
  the table supports does not depend on them. Source: default, unanswered.

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
- **A reviewer dispatch was measured end to end** before this issue's criteria
  were settled, to ground them in figures rather than argument. It reviewed the
  diff of pull request 31 (`61fde90..bf09c04`) against issue 0031's intent
  copied word for word: 15 API requests, 19 tool calls, 198 s. cache-write
  34,796; cache-read 284,118; output 2,318 (unreliable, see below). Attribution
  summed to 34,796 against 34,796 from the step totals.
- **Several transcript records carry one request, each repeating its usage.**
  That reviewer wrote 31 assistant records across 15 distinct `requestId`
  values — one record per content block (thinking, text, tool call), all
  carrying identical cache figures. Summing per record inflated the totals by
  2.07× before the bug was found. Criterion 6 exists for this. The hand-written
  aggregate in the Intent's table predates the finding and may carry the same
  inflation; it cannot be rechecked, because the 0022 transcripts are gone.
- **`output_tokens` is a streaming snapshot, not a final count.** Within one
  request the records disagree — a placeholder of 3 alongside the real 667 —
  so the largest value seen for a request is the only usable one. This is the
  mechanism behind the unreliability the Log already recorded for 0022.
- **The figure the harness reports for a subagent excludes cache-read.** The
  reviewer dispatch was reported as 35,143 subagent tokens against a measured
  cache-write of 34,796 — a match within 1%, while the 284,118 cache-read
  tokens appear nowhere. Anyone reading the reported number sees about 11% of
  what the dispatch consumed.
- **Subagents inherit the whole rulebook.** A `reviewer` dispatched with a
  trivial prompt and told to use no tool quoted invariant 1 verbatim from its
  context and confirmed it also carries "The shelf" and "The run" — sections
  describing what the orchestrator does, which a reviewer never uses. Its bare
  baseline is 9,589 tokens; with issue 0031's intent it was 10,785, and the
  difference of 1,196 is the intent text.
- **Where that reviewer's tokens went**, by the grouping criterion 7 asks for:
  the baseline 33.5% (written once at step 1, then carried 14 more steps),
  Bash output 40.4%, its own output 10.6%, file reads 9.2%, its own tool calls
  6.4%.
- **Only 31% of that dispatch's cache-write is exactly attributable.** One of
  its 15 steps had a single item entering the context; the other 14 had two to
  five. The exactly attributable step is the baseline, which is why the 33.5%
  figure above is measured while the 40.4% is a proportional split. Criterion 8
  exists for this.
- **The idea that opened this session was measured and dropped**: reading only
  a document's header during exploration and fetching the body on demand. File
  reads were 9.2% of that dispatch, and its largest read entered at step 11 of
  15, where deferral saves almost nothing while costing an extra request.
- **The `test-author` wrote 14 cases into
  `skills/cost/assets/test-token-cost.sh` and registered the suite in
  `test.sh`.** `bash skills/cost/assets/test-token-cost.sh` exits 1 with all
  14 failing, each for the missing behaviour rather than a broken test. It
  established the suite is satisfiable by writing a throwaway implementation
  outside the repository — 14/14 — and then broke that implementation nine
  ways, one per intended trap: counting records instead of calls, summing
  `output_tokens` across a call's records, dropping the unreliability
  markers, printing a combined total, reading every session in the project
  directory, writing a report file, marking every figure estimated, dropping
  the grouped breakdown, and hard-coding a path inside the working tree. Each
  mutation was caught by exactly the case meant to catch it. That throwaway
  implementation is deliberately not handed to the implementer: the context
  that wrote the tests must not also write the code that satisfies them.
- **Two suites now fail for a reason the implementer must clear**:
  `skills/cost/` exists without a `SKILL.md`, which `test-plugin.sh` and
  `skills/bootstrap/assets/test-session-start-core.sh` both check.
- **The `test-author` dispatch cost 34 model calls, 128,311 cache-write,
  2,749,268 cache-read and 52,891 output** — roughly ten times the reviewer
  dispatch's cache-read. Its baseline share fell to 7.5% against the
  reviewer's 33.5%, because the baseline is carried linearly while the
  accumulated material grows faster: the fixed overhead matters most in short
  dispatches, not long ones.
- **The implementer wrote `skills/cost/assets/token-cost.py` and
  `skills/cost/SKILL.md`, and nothing else.**
  `bash skills/cost/assets/test-token-cost.sh` → exit 0, 14 cases.
  `bash test.sh` → exit 1 across 5 suites, its only failing case the
  pre-existing one filed as issue 0032; the 9 cases that had failed on the
  missing `SKILL.md` now pass. **No static analysis exists in this project**:
  no `pyproject.toml`, `setup.cfg`, `.flake8`, `.pylintrc`, `ruff.toml`,
  `.shellcheckrc`, `package.json`, `Makefile` or any `*.yml`/`*.yaml` in the
  tree, and no `.github` directory. Both figures were reproduced by the caller
  independently of the implementer's report.
- **What this run cost, by the command this issue produced** —
  `python3 skills/cost/assets/token-cost.py`, exit 0, taken after the
  implementer returned and therefore not counting the review that follows:

  | agent | dispatched for | steps | cache-write | cache-read | output (unreliable) |
  | --- | --- | --- | --- | --- | --- |
  | main session | the run itself | 91 | 381,533 | 11,660,572 | ~87,127 |
  | test-author | Write failing tests for issue 0025 | 34 | 128,311 | 2,749,268 | ~52,891 |
  | implementer | Implement token-cost command | 30 | 92,333 | 2,133,144 | ~18,757 |
  | reviewer | Review issue 0031 change | 15 | 34,796 | 284,118 | ~247 |
  | reviewer | Probe subagent baseline context | 1 | 9,589 | 0 | ~1 |

  The main session carries 11,660,572 of the run's 16,827,102 cache-read
  tokens — 69%. Every proposal this session made for cutting subagent cost was
  aimed at the smaller share. (The share was first written here as 71%, which
  was the figure for the implementer's earlier snapshot, not for this table.
  Corrected before the review round returned.)
- **Work found mid-run, to be filed separately**: the reviewer dispatched for
  this measurement found that pull request 31 left issue 0031 largely
  unimplemented — `bash test.sh` exits 1, and of that issue's six criteria only
  criterion 3 is met. Filed as issue 0032. This serves no criterion of this
  issue.
- **Second finding, also to be filed separately, and larger than anything this
  session proposed**: the first thing the finished command showed is that
  injected context — not tool output — dominates the main session. Hook and
  attachment output is 235,418 of its 381,533 cache-write, 62%, against 37,500
  for all Bash output and 10,025 for all file reads. One item alone, a
  `skill_listing` attachment at step 69, is 141,999 tokens, with further skill
  listings at steps 1, 47 and 65. The skill list is re-injected whole,
  repeatedly, into the session that carries 71% of the run's cache-read. This
  serves no criterion of this issue and does not go into its diff.

## Checkpoints

### Before implementation

- **Does this match what was asked?** The session opened with a different
  request — reduce what subagents consume, by reading only a document's header
  during exploration. Measurement replaced it: file reads were 9.2% of the
  dispatch measured, and the idea was dropped on that figure. The human
  approved the pivot across five answers. So the deliverable is a command that
  makes cost visible, not a saving; the savings this session proposed wait for
  it, per the Log entry from 0022 that says an unmeasured optimisation is
  established neither way.
- **What surprised me?** Two things. The figure the harness reports for a
  dispatch excludes cache-read entirely — 35,143 reported against 284,118
  cache-read unreported, so the visible number is about 11% of the real one.
  And one model call writes several transcript records that each repeat its
  usage: my own first measurement was 2.07× too high before I noticed, which
  is exactly the mistake criterion 6 now forbids.
- **What am I assuming without having verified it?** That the `subagents/`
  directory layout and the `requestId` field are stable across Claude Code
  versions — both were seen only on 2.1.220, in this container. That the
  running session's own transcript is readable from inside that session at the
  moment the command runs; the main session's file was present and non-empty
  here, but I have not read it back mid-turn to confirm it is flushed. And
  criterion 10 has no second metis project in this container to be shown
  against, so it will have to be established by construction — no path inside
  this repository — rather than by running it elsewhere.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
