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
   status is in the context — local sessions never get one by design; in a
   cloud session that means the hook did not finish — the rule has the agent
   establish the facts itself: do the `~/.claude` skill and agent links
   resolve, how does the session-start log end? Report what it finds, not
   silence.
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

- Review round 2 (fresh context): 6 findings — 1 blocking, 1 docs drift,
  2 test gaps, 2 minor. All fixed. The blocking one was the same class as
  round 1 (a character breaking the JSON — now a control character instead
  of a quote): the repetition signal. Approach changed accordingly — the
  sanitizer now strips the whole class (`tr -d '\000-\037\\"'`) instead of
  the individual offenders, and the harness plants a newline-named link.
  Docs: the harness is now named in the bootstrap skill's page ("Keeping it
  honest") and in README. Test gaps closed: the happy path asserts the
  status names the actual `git rev-parse --short HEAD`; the empty-clone
  case asserts all three causes; a renamed `agent.md` is asserted too.
  Minor: harness is executable now and cleans its scratch dirs via a trap
  (dir count in `/tmp` unchanged across a run).
- Criterion 2 amended to carry the round-1 decision (local sessions never
  get a status by design) instead of contradicting it — the wanted
  behaviour is unchanged, the wrong cause claim is gone from the criterion
  as well as from the documents.

- Review round 3 (fresh context): 2 findings — 1 blocking, 1 cosmetic.
  Both fixed. The blocking one was the third instance of the class both
  earlier rounds hit — the self-check passing a broken outcome (this time a
  real directory shadowing a link's path, so the link lands one level too
  deep and resolves). Third firing of the repetition signal, so the fix
  changed altitude, not just the instance: the check now compares expected
  against actual end state — every skill and agent in the clone must be
  reachable at its exact path with its exact target — instead of
  enumerating failure modes. Harness case 5 plants the shadowing dirs and
  asserts both names. Cosmetic: a stray hard wrap in the README paragraph,
  refilled. The reviewer also ran five mutations of the core against the
  harness — each caught with exit 1 — and shellcheck (clean at warning
  level and above).

- Review round 4 (fresh context): 3 findings — 1 blocking, 1 test gap,
  1 cosmetic. All fixed. The blocking one was the fourth shape of the
  escaping class: bytes above 0x7f are not valid UTF-8, and the round-2 fix
  was still a blacklist. Now a whitelist — the status keeps only printable
  ASCII minus quote and backslash; every byte not on the list is dropped,
  which closes the class by construction. Test gaps: the harness oracle
  decoded stdin leniently (surrogateescape) and would have passed the bad
  bytes — it now decodes raw bytes strictly, and a mutation check confirmed
  the old blacklist sanitizer fails it (UnicodeDecodeError, as intended);
  case 5 additionally asserts a FAILED status keeps counts and commit,
  which no case had pinned. Cosmetic: the README paragraph refilled. The
  reviewer also ran six mutations — five caught; the sixth (FAILED loses
  counts) is the gap case 5 now covers.

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

- **Does this match what was asked?** Yes: greeting plus self-check, with
  both named probes covered — skill reachability (links verified, silently
  skipped dirs named) and hook errors (status carries them; a crashed hook
  leaves no status, which the rulebook treats as the finding).
- **What surprised me?** How weak the first self-check was: it passed an
  empty clone. The reviewer's reproductions, not my design, forced the
  check to verify each outcome. And the escaping defect came back in a
  second shape — patching characters one by one was the wrong altitude.
- **What am I assuming without having verified it?** That Claude Code
  actually surfaces `additionalContext` from a SessionStart hook into the
  session context. Nothing in this change can verify that by exit code;
  the first cloud session on the merged state is the test. If the status
  does not appear there, the fallback path (no status → check links and
  log) is what runs, so the failure mode is honest — but the greeting rule
  should then be revisited.

## Retro
