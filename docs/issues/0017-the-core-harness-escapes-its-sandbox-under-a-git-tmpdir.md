---
status: active
branch: claude/offene-issues-3hysxf
pr:
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
  inside a scratch git repo → core harness exit 1, 3 FAILs, enclosing
  repo's local config gained `core.hookspath`. Siblings under the same
  TMPDIR: exit 0, config untouched.
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

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
