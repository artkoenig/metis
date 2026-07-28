---
status: done
branch: claude/reviewer-questions-changes-v5rq3e
pr: https://github.com/artkoenig/metis/pull/23
---

# The reviewer is not asked about blast radius or the record

## Intent

The reviewer's checklist asks whether the diff meets the intent, but never
what the change could break *outside* its acceptance criteria — regressions
in behaviour no criterion mentions go unasked. And its record check covers
only the checkpoint assumptions, not whether the issue's record as a whole
(decisions, log, task list) matches what the diff actually did. Wanted: every
review answers both questions, every time.

Acceptance criteria:

1. The reviewer agent definition instructs the reviewer to always answer
   what the change could break outside its acceptance criteria.
2. The reviewer agent definition instructs the reviewer to always check
   whether the issue's record matches the diff — not only the checkpoint
   assumptions.
3. Documentation that mirrors the reviewer's duties is consistent with the
   change.

## Plan

## Tasks

## Decisions

- The change lands in `agents/reviewer/agent.md` only. README and AGENTS.md
  name the reviewer at a higher altitude (fresh context, diff vs. intent,
  facts by exit code) that the change does not contradict, so criterion 3 is
  met by verification, not by edits. Source: grep over the repository;
  default, unanswered.
- Prose change, nothing to run — no tests to write (invariant 2/3); the
  reviewer's reading is the change's only check, plus the existing shell
  harness as a regression fact. Source: default, unanswered.

## Log

- Implemented directly instead of dispatching the implementer: a prose edit
  in one file, nothing to run; the fresh context arrives with the review.
  Judgment call under "judgment for process".
- Change: check 4 widened from checkpoint assumptions to the whole record
  against the diff; new check 5 (blast radius beyond the criteria) added;
  report must close with the blast-radius answer; description updated to
  mirror both duties.
- Review round 1 (facts: `./test.sh` 30 cases exit 0; no static analysis
  exists): 1 finding, minor — check 4's enumeration dropped the task list
  the intent names. Triage: fixed now ("decisions, log, task list,
  checkpoint answers"). Criteria 1 and 3 met, 2 met in letter only.
- Review round 2 (facts: `./test.sh` 30 cases exit 0; no static analysis
  exists): round-1 finding verified fixed; 1 new finding, cosmetic — the
  fixed line ran to 86 chars against the file's ≤79 wrap. Triage: fixed now
  (rewrapped). All three criteria met.
- Review round 3 (facts: `./test.sh` 30 cases exit 0; no static analysis
  exists): 0 findings, all criteria met, record matches diff, nothing found
  beyond the criteria. Trend 1 → 1 → 0.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — the request names exactly the two
  questions the criteria encode: blast radius beyond the criteria, and the
  record against the diff.
- What surprised me? The record check already exists in the definition but
  covers only the checkpoint assumptions — the gap is narrower than the
  request implies, which confirms the request.
- What am I assuming without having verified it? That no document outside
  the repository mirrors the reviewer's checklist (verified inside the repo
  by grep; outside it, unverifiable from here).

### Before the PR

- Does this match what was asked? Yes — both questions the human named are
  now mandatory: check 5 plus the report's closing answer for blast radius,
  check 4 for the record against the diff; three review rounds confirmed it.
- What surprised me? Reviewing an uncommitted working tree needed the diff
  range spelled out as "working tree vs HEAD" — the definition's default
  wording assumes committed work.
- What am I assuming without having verified it? That deployed copies under
  `~/.claude/agents/` follow this repo via the bootstrap symlinks — round 3
  noticed its own instructions were the pre-0019 version, which is
  environment staleness, not a defect of this diff.

## Retro

What got in the way: reviewing before the first commit forced spelling the
diff range out as "working tree vs HEAD" — the reviewer's premise assumes a
committed range; it coped, but only because the prompt overrode it. Round 3
also reviewed with a stale deployed copy of its own definition (pre-0019
symlink target), which cost it a paragraph of self-doubt.

What should change: nothing in the rules — the run converged in three
rounds and the round-2 cosmetic finding shows fresh contexts do read
whole files, which is the point. If the "working tree vs HEAD" case
recurs, widening the premise wording in the reviewer definition is a
one-line follow-up; filed as not worth its own issue yet.
