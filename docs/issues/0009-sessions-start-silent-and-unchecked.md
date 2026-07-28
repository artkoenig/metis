---
status: active
branch: 0009-greet-and-self-check
pr:
---

# Sessions start silent and unchecked

## Intent

A session starts cold: no greeting, and no word on whether the machinery
underneath it actually works. The SessionStart hook syncs skills, agents and
the rulebook — but when it fails, nothing tells anyone. The human finds out
when a skill is missing mid-run.

Wanted behaviour: every session opens by greeting the human and reporting a
self-check — are the skills reachable, did the SessionStart hook run clean?
A broken hook is visible in the first reply, not discovered mid-run.

Acceptance criteria:

1. The sync logic (`session-start-core.sh`) checks its own result — every
   skill and agent link it created resolves — and injects a one-line status
   into the session context: counts, the metis commit, and errors or their
   absence.
2. `AGENTS.md` has the session open with a greeting and that status. When no
   status is in the context, the rule treats that as the finding — the hook
   did not finish — and has the agent establish the facts itself: do the
   `~/.claude` skill and agent links resolve, how does the session-start log
   end? Report what it finds, not silence.
3. The per-project loader (`session-start.sh`) stays untouched — the
   self-check must reach every bootstrapped project on its next session
   start, without re-running bootstrap anywhere.
4. `README.md`'s description of the wiring stays in step.

## Plan

- The core script already logs every step and traps crashes; add counting
  and link verification to what it does, build one status line, and emit it
  as `additionalContext` in the existing hook JSON on fd 3.
- A crashed run emits no JSON (`set -e` exits before the final line), so a
  missing status is itself the failure signal — no extra machinery needed.
- The rule goes into Bookkeeping in `AGENTS.md`, next to the bullet on how a
  new session orients itself.
- Test first: run the core script against a scratch `HOME` and a scratch
  project repo, assert the JSON carries `additionalContext` — red before the
  change, green after.

## Tasks

## Decisions

- The self-check lives in the core script, not the loader: the loader is
  installed per project and only re-bootstrap updates it, while the core
  runs fresh from the clone in every cloud session. Source: the loader's own
  header and README's "Wiring it in". (by agent)
- Local sessions get no injected status by design (the loader only
  fast-forwards the clone there); criterion 2's fallback covers them — the
  agent checks the links and the log itself. Recorded as a default, not
  derived: the request named cloud machinery ("SessionStart hook"), and
  extending the loader would violate criterion 3. (by agent)

## Log

- Test written first, against a scratch `HOME` and scratch project repo:
  assert the core script's hook JSON carries `additionalContext` with a
  skill count, and no created link is broken. Red before the change (exit 1,
  "no additionalContext in JSON"), green after (exit 0, PASS).
- Failure path exercised: a dangling link planted in the scratch
  `~/.claude/skills` yields "Metis self-check FAILED: broken links:
  dead-skill" in the status; the emitted JSON parses (`python3 json.load`,
  exit 0). `bash -n` on the changed script: exit 0.
- The check scans every link in the two directories, not only the ones this
  run created: in a cloud session the directories are fresh anyway, and a
  broken skill link is worth reporting whoever made it.

- Review round 1 (fresh context): 3 findings, all blocking, all fixed.
  (1) The self-check passed an empty clone — it only looked at dangling
  links; now every outcome is verified (something linked, no clone dir
  silently skipped, rulebook synced, links resolve) and the FAILED status
  keeps counts and commit. (2) A quote in a broken link's name broke the
  JSON; the status line is now stripped of quotes and backslashes before
  embedding. (3) "No status means the hook did not finish" was false for
  local sessions, which never get one by design; `AGENTS.md` and
  `README.md` now say so. The reviewer also noted the red/green run left
  nothing committed — the harness now lives at
  `skills/bootstrap/assets/test-session-start-core.sh` (4 cases, including
  the reviewer's reproductions; scratch dirs only) and exits 0.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Greeting plus self-check with the two
  named probes — skill reachability (criterion 1: links resolve) and
  SessionStart-hook errors (criteria 1 and 2: errors in the status, missing
  status as the error signal).
- **What surprised me?** The crash path needs nothing built: `set -e` plus
  the ERR trap already guarantee a failed run emits no JSON, so absence of
  the status is a reliable failure signal for free.
- **What am I assuming without having verified it?** That
  `additionalContext` in the SessionStart hook JSON reaches the session
  context in this harness — to be verified by the next session actually
  showing the status. Also that the status line needs no JSON escaping —
  holds as long as it is built only from counts, a short hash and fixed
  words; verified by keeping it that way.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
