---
status: done
branch: claude/new-session-xeyz5n
pr: https://github.com/artkoenig/metis/pull/18
---

# The self-check ignores the hooksPath step

## Intent

The session self-check (issue 0009) verifies skills, agents and the
rulebook — but not the fourth sync step: pointing the project's
`core.hooksPath` at metis's `.githooks`, which is what refuses a direct
push to the default branch. When that step is silently skipped (for
example, `CLAUDE_PROJECT_DIR` is not a git repository), the status still
says "no errors" — the same skipped-outcome-reported-as-success class the
0009 review kept finding, at the one step its self-check does not cover.

Reproduction (0009 review round 6): core run with `CLAUDE_PROJECT_DIR`
pointing at a non-git directory — the log shows no `hooksPath` line, fd 3
carries "no errors", and the push guard is absent.

Wanted behaviour: a session whose push guard did not get installed learns
that from the self-check status, not from an unguarded push later.

Acceptance criteria:

1. The status reflects the hooksPath outcome: set, or why not.
2. The test harness has a case for the skipped step.

## Plan

## Tasks

## Decisions

- Filed from 0009's review round 6, finding 2: outside 0009's criteria as
  written (they enumerate skills and agent links), so a follow-up rather
  than a fix in that run. (by agent)

## Log

- Implementer done (tests first): step 4 no longer skips silently — each
  skip reason logs a line, and the self-check verifies the push guard's
  END STATE (what `core.hooksPath` in the project says, not whether the
  step ran). The status always carries a guard segment: `push guard set`,
  `push guard n/a (project not a git repo)` (non-error — nothing can be
  pushed from there), or `push guard not set (...)` which joins the errors
  and makes the status FAILED. Harness: happy path asserts the guard
  segment and the actual config value; new case 6 (non-git project — the
  reproduced skip) and case 7 (clone without `.githooks`: FAILED,
  hooksPath untouched); case 5's pass guard converted to the
  failure-counter pattern. Fail-first proven: 5 fails against the
  unmodified core, including the reproduced "no guard line + no errors".
  Facts: core suite 7 cases exit 0, install 15 exit 0, loader 5 exit 0,
  `bash -n` exit 0, no shellcheck on this machine. Implementer's defaults:
  non-git project = non-error `n/a`, missing `.githooks` in a git project
  = FAILED, plus a `hooksPath mismatch` end-state branch. Noted out of
  scope: cases 2–4 still use the weaker grep-style pass guard.

- Review round 1 (fresh context): facts — install 15 exit 0, core 7 exit
  0, loader 5 exit 0, `bash -n` exit 0, no shellcheck; real repo config
  verified untouched after the harness runs. Both criteria met: mutants
  for the reverted core (5 red, incl. the recorded reproduction), for a
  lying "set" without the config write (3 red — the tests check end
  state), and for wrong non-git semantics (1 red). Two minors:
  1. The `hooksPath mismatch` branch is unverified (a mutant making it
     lie stays green). Dismissed with reason: the branch is
     defense-in-depth for a state unreachable in a real run — a failed
     `git config` write aborts under `set -e` before the self-check —
     and a test would need to fake git's config reads (env injection).
     Exactly the exotic-state class run 0013 taught us not to chase.
  2. No criterion: the core harness inherits TMPDIR — with TMPDIR inside
     a git repo, case 6 false-fails and the core writes `core.hooksPath`
     into the enclosing repo, contradicting the harness header.
     Pre-existing pattern, outside this intent — filed as issue 0017
     (default recorded; the human can redirect).
  No fix applied, so no repeat round is owed. Trend: 2.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — two narrow criteria with a recorded
  reproduction from 0009 round 6; a core-script + harness change, dispatched
  to the implementer.
- What surprised me? Nothing yet.
- What am I assuming without having verified it? That "why not" can be a
  short reason in the status (e.g. "hooksPath skipped: project is not a git
  repository") without breaking the status sanitizer or the JSON emit — the
  implementer verifies against the harness.

### Before the PR

- Does this match what was asked? Yes — the status names the push guard's
  state in every branch, the reproduced skip is a harness case, and the
  reviewer's mutants confirm the tests check the end state.
- What surprised me? The reviewer found the harness sandbox leaks under a
  git TMPDIR — a hermeticity hole the scratch-dir convention was meant to
  close (filed as 0017).
- What am I assuming without having verified it? That dismissing the
  untested `hooksPath mismatch` branch is safe: it is unreachable without
  faking git, and the run-0013 lesson says not to chase such states —
  recorded as the dismissal reason, not verified by a test.

## Retro

Clean run: one implementer pass, one review round, both criteria met, no
fix round needed. Worth keeping: the run-0013 lesson did its job twice in
triage — the untested defensive branch was dismissed instead of chased,
and the out-of-intent hermeticity finding was filed (0017) instead of
fixed in-run. Worth watching: the weaker grep-style pass guards in core
cases 2–4 are the claims-success class's third sighting (0013 installer,
0010 loader harness, now noted again by the implementer) — that crosses
the threshold the 0010 retro set; a harness convention ("every pass line
rests on the failure counter") is now a candidate rule, not filed yet
because 0017 touches the same files and could carry it.
