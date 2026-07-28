---
status: done
branch: claude/new-session-xeyz5n
pr: https://github.com/artkoenig/metis/pull/17
---

# The loader's no-status promise is untested

## Intent

Since 0009, `AGENTS.md` and `README.md` promise that local sessions never
receive a self-check status: the fallback rule (check the links and the log
yourself) rests on it. That promise is a property of the per-project loader
(`session-start.sh`), and nothing exercises the loader: the test harness
covers only the core. The 0009 round-5 reviewer showed the gap by adding an
`additionalContext` line to a copy of the loader — the harness stayed green,
and both documents were silently false.

Wanted behaviour: a change to the loader that makes it emit a status in a
local session cannot land with a green suite — the documented promise is
guarded by a check, not by reading.

Acceptance criteria:

1. The suite fails when the loader's local-session path emits
   `additionalContext`.
2. The check runs against scratch directories only, like the existing
   harness cases.

## Plan

## Tasks

## Decisions

- Filed from 0009's review round 5, finding 2: not a defect of that change
  (its criterion 3 required the loader untouched, and it was), but a gap a
  future loader edit can fall through. (by agent)

## Log

- Implementer done (tests first): new sibling harness
  `test-session-start-loader.sh`, 3 local-session cases in scratch dirs
  (fake HOME, scratch project, scratch upstream, no network); takes an
  alternative loader path for mutation proofs. Fail-first proven with a
  mutated loader copy (`additionalContext` on the local path): 3 FAIL,
  exit 1; pristine loader 3 cases exit 0. Core suite 5 cases exit 0,
  `test-install.sh` 15 cases exit 0, `bash -n` all *.sh exit 0 (no
  shellcheck on this machine). Bootstrap SKILL.md now names the new
  harness (the only place enumerating suites). Loader itself untouched —
  the promise holds. Implementer's defaults: the reviewer's exact 0009
  mutation text is not on record, its described shape reproduced; the
  `reloadSkills`-only JSON stays allowed ("no status" = no
  `additionalContext`). Out-of-scope note filed by the implementer: no
  runner invokes the three harnesses together.

- Review round 1 (fresh context): facts — loader harness 3 cases exit 0,
  core 5 exit 0, install 15 exit 0, `bash -n` exit 0, no shellcheck. One
  finding, in scope, fixed: the dirty-clone and pull-failed branches of
  the local path could emit `additionalContext` and stay green (both
  mutants reproduced green by the reviewer). Cases 4–5 added, both
  mutants seen red first (exit 1), pristine loader 5 cases exit 0, all
  other suites unchanged green. Trend: 1.
- Review round 2 (fresh context): facts — loader harness 5 exit 0, core 5
  exit 0, install 15 exit 0, `bash -n` exit 0; the reviewer built five own
  mutants (one per local-path branch), all red, pristine green. Both
  criteria met. Two minors, both taken: the pass-guards of cases 2–3
  could print "ok" for a failed case — switched to the failure-counter
  pattern (case 3's same-class defect included), suites re-run green, one
  mutant re-checked red; and the log's "filed by the implementer"
  overstated a note — the runner gap is now really filed as issue 0016.
  No third round: both fixes are reporting/bookkeeping, loader and
  harness semantics unchanged — judgment call, recorded.
  Trend: 1 → 2 (round 2 both minor, reporting/record only).

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — two narrow criteria, a test-only
  change; dispatched to the implementer (real code, tests are the
  deliverable).
- What surprised me? Nothing yet.
- What am I assuming without having verified it? That the loader
  distinguishes local from cloud via `CLAUDE_CODE_REMOTE` and that its
  local path can run harmlessly in a scratch dir — the implementer
  verifies against the loader itself.

### Before the PR

- Does this match what was asked? Yes — the promise is guarded across all
  five local-path branches, proven red per branch (reviewer's own five
  mutants), scratch-only.
- What surprised me? A case could print "ok" while having failed — the
  same claims-success class as the 0013 installer, this time in a test.
- What am I assuming without having verified it? That skipping a third
  round for the two reporting/bookkeeping fixes is safe — the exit codes,
  not the pass lines, carry the criteria; recorded as a judgment call.

## Retro

Smooth run: implementer, two review rounds, done. Worth keeping: round 1
caught real branch coverage gaps because the intent's wording ("the
local-session path", universal) was stronger than the implementer's
reading (the reviewer's one mutation shape) — precise intent wording paid
off. The claims-success defect class from 0013 reappeared inside a test
(a pass line not resting on the failure counter); worth watching whether
it shows up a third time — that would make it a candidate for a rule or a
harness convention. The 0015 open thread recurred: a review round was
again skipped for reporting-only fixes by judgment call; two data points
now for a "when is the repeat waivable" rule.
