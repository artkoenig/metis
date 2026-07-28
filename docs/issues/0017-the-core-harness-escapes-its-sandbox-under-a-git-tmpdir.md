---
status: done
branch: claude/offene-issues-3hysxf
pr: https://github.com/artkoenig/metis/pull/21
---

# The core harness escapes its sandbox under a git TMPDIR

## Intent

The core harness builds its scratch world with `mktemp -d`, which honours
`TMPDIR`. When `TMPDIR` points inside a git repository, the sandbox breaks
two ways (0011 review round 1, reproduced): case 6's "non-git project"
scratch dir suddenly *is* inside a repo, so the case false-fails
("push guard set ... no errors", exit 1) — and worse, the core writes
`core.hooksPath` into that enclosing repository, contradicting the harness
header's promise that no real git config is ever touched. The failure
direction is a false red, not a false green, and a normal `/tmp` is safe —
but a harness that can mutate a repo it never created is not hermetic.

Reproduction: `TMPDIR=<dir inside a git repo> bash
skills/bootstrap/assets/test-session-start-core.sh` → case 6 fails, and the
enclosing repo's config gains `core.hooksPath`.

Wanted behaviour: the harness either works correctly under such a TMPDIR or
refuses to run, and it never writes into a repository it did not create.
The sibling harnesses (`test-session-start-loader.sh`, `test-install.sh`)
share the pattern and should be checked with it.

Acceptance criteria:

1. With `TMPDIR` inside a git repository, the core harness either passes
   honestly or aborts with a clear message before running any case — and
   the enclosing repository's config is untouched either way.
2. The sibling harnesses get the same guarantee.

## Plan

## Tasks

## Decisions

- Filed from 0011's review round 1, finding 2: no criterion of that issue
  violated, pre-existing pattern across the harnesses — its own run per
  the scope guard. Filing chosen as the recorded default; the human can
  redirect. (by agent)
- Refuse, don't adapt: all three harnesses abort with a clear message
  before running any case when their scratch base lands inside a git
  repository. Chosen over `GIT_CEILING_DIRECTORIES` (which would need
  exporting into every case and reasoning about propagation) because the
  intent allows either and refusal is a three-line guard whose
  correctness is obvious. A normal `/tmp` is unaffected. (default,
  unanswered)
- The guard checks `git -C "$base" rev-parse --git-dir`, not
  `--is-inside-work-tree`, so a TMPDIR inside a `.git` directory itself
  is also caught. (default, unanswered)
- Like 0016's runner, the guard gets no meta-harness; both directions are
  recorded command facts — the reproduction below red before the fix,
  refusal plus untouched config after it, and `bash test.sh` exit 0 under
  a normal TMPDIR. (default, unanswered)

## Log

- Reproduced red first (the failing test for this change): `TMPDIR`
  inside a scratch git repo → core harness exit 1, one failing case
  (case 6, "non-git project"; the earlier "3 FAILs" note counted FAIL
  lines including the summary), enclosing repo's local config gained
  `core.hookspath`. Siblings under the same TMPDIR: exit 0, config
  untouched.
- Guard added to all three harnesses, identical three lines after the
  scratch base is made: if `git -C "$base" rev-parse --git-dir` succeeds,
  print a refusal naming the script, the path and TMPDIR as the likely
  cause, and exit 1; the EXIT trap removes the base.
- After the fix, recorded command facts:
  - Each harness under the git TMPDIR → exit 1, refusal message, zero
    cases run (`grep -c '^ok:'` = 0), enclosing repo config unchanged
    (`git config --local -l` diff empty).
  - Core under a TMPDIR inside a `.git` directory → same refusal.
  - `bash test.sh` under a normal TMPDIR → exit 0, "PASS: all 3 suites".
- Review round 1 (fresh context, diff 1b14c6b..HEAD): one finding, minor,
  record-only — the Log's "3 FAILs" did not reproduce (1 failing case;
  the 3 was FAIL lines incl. the summary). Both criteria met; the
  reviewer reproduced pre-fix red, post-fix refusal on all three
  harnesses, the `.git`-dir edge and the untouched config independently.
  Triage: fixed the Log wording. Repeat round skipped as a judgment
  call: the fix touches only the tracker record, no file the criteria
  are about — the same shape 0015/0010/0012 recorded, which issue 0018
  (next in this run) turns into a written waiver. Trend: AC1 0, AC2 0,
  no-criterion 1 → total 1 in round 1, fix record-only.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — reproduced first: `TMPDIR` inside
  a scratch git repo, core harness exit 1 with 3 FAILs and the enclosing
  repo's config gained `core.hookspath` (the issue's reproduction,
  confirmed). The siblings under the same TMPDIR: loader exit 0,
  install exit 0, config untouched — they pass today but share the
  pattern, so they get the same guard (criterion 2 asks for the same
  guarantee, not the same current behaviour).
- What surprised me? The siblings do not currently false-fail — every
  case of theirs creates its own scratch repo, so git never walks up.
  Only the core's "non-git project" case does.
- What am I assuming without having verified it? That no case needs a
  scratch base that legitimately lives inside a git repo — checked: all
  three build their worlds from `mktemp -d` and expect it repo-free.

### Before the PR

- Does this match what was asked? Yes — all three harnesses refuse under
  a git TMPDIR before any case, the enclosing repo's config stays
  untouched, and `bash test.sh` under a normal TMPDIR exits 0. Review
  round 1 confirmed every fact independently; its one finding was a
  wording slip in this file's Log, fixed.
- What surprised me? The siblings never false-failed — only the core's
  non-git case walks up. And my own FAIL count was sloppy: `grep -c FAIL`
  counts the summary line too. Facts want exact oracles even in a log
  entry.
- What am I assuming without having verified it? That refusing (rather
  than adapting via GIT_CEILING_DIRECTORIES) never blocks a real
  workflow — normal `/tmp` is repo-free everywhere this runs today.

## Retro

- What got in the way: my own log entry stated a fact ("3 FAILs") from a
  sloppy oracle (`grep -c FAIL` counts the summary line); the reviewer
  caught it. Lesson, already covered by invariant 4's spirit: even log
  prose should quote counts only from an oracle that counts the right
  thing.
- The waiver 0018 was about got its fourth use here, one run before it
  became a written rule — the ordering (0017 before 0018) was lucky
  evidence, not a problem.
