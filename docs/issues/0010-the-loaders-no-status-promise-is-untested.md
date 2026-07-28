---
status: active
branch: claude/new-session-xeyz5n
pr:
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

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
