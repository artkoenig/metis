---
status: backlog
branch:
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

## Log

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
