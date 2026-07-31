---
status: active
branch: claude/new-session-e3q44m
pr:
---

# An installation never updates itself, and the README says it does

## Intent

An installed copy of this plugin stays on the commit it was installed at.
Measured this session, in an isolated `HOME` with the marketplace source set
to `artkoenig/metis`: the installation was pinned at `d6c87b6`, the marketplace
clone was then moved one commit ahead to `0426a89` (changing `AGENTS.md`), and
three consecutive `claude -p` sessions ran in a project with the plugin active.
After each one, `installed_plugins.json` still read `d6c87b683d8e` with
`lastUpdated` unchanged, and the installed copy of `AGENTS.md` did not carry
the new line. Only a hand-typed `claude plugin update metis@metis` moved it:
"Plugin metis updated from d6c87b683d8e to 0426a8902ed5".

Issue 0040 removed the `version` field so that a version resolves from the
commit SHA. That was necessary and is not the gap: nothing pulls. An
installation is reachable by an update and never receives one, so every commit
merged into `main` still reaches only the people who remember the command.

`README.md` promises the opposite, twice: "because every wired project loads
metis fresh at session start, an accepted rule change reaches all of them with
their next session" (lines 47-49) and "A session with the plugin active has the
rulebook, subagents and skills of the current `main` — updates included, no
re-installation" (lines 61-63). Both sentences are false as measured. This is
the mechanism the rulebook's self-correction rests on: a retro that lands as a
merged rule change reaches no installed workflow.

Wanted observable behaviour: a commit that lands in the marketplace repository
reaches an existing installation without anyone running a command, and a
session says which copy it is running.

Acceptance criteria:

1. When the plugin is installed from a marketplace whose source is a git
   repository, and a commit then lands in that repository changing a file the
   plugin ships, then starting one session in a project with the plugin active
   leaves the installed plugin directory carrying the changed content — with no
   update command run by hand.
2. A session that moved the installation names both commits in the self-check
   status line it already prints; a session that found the installation already
   current says that instead. Which copy the session itself is running — the
   one from before the move — is visible in that same line.
3. When the installation cannot be updated, the session start survives it: the
   hook's stdout is still exactly one valid JSON object carrying the rulebook,
   the hook still exits 0, and the status line names the reason. This holds for
   each of: no `claude` binary reachable, the plugin running from a working
   checkout rather than an installed copy, the update command exiting non-zero,
   and the update exceeding its time bound.
4. The update carries a time bound, and a session whose update hits that bound
   still starts — criterion 3's guarantees hold unchanged in that case.
5. `README.md` states what criteria 1 and 2 deliver, including that a changed
   copy takes effect from the following session and not the one that fetched
   it. No sentence in the tracked tree claims an installation is current
   without an update having run.
6. `bash test.sh` exits 0.

## Plan

## Tasks

## Decisions

## Log

- Orienting found issue 0036 still `active` with an empty `pr:`, although its
  branch `claude/offene-issues-4rv8ah` is merged as pull request 37 and its
  retro is written. Corrected to `done` with that pull request, so that this
  issue is the only running one — a tracker-only fix.
- The installation commands `README.md` documents do not update an existing
  installation. Measured in an isolated `HOME` with the installation pinned at
  `7e8268a` (version `0.2.0`): `claude plugin marketplace add artkoenig/metis`
  answered "Marketplace 'metis' already on disk" and left the clone at
  `7e8268a` without fetching, and `claude plugin install metis@metis` answered
  "Plugin "metis@metis" is already installed (scope: user)" and left the
  version at `0.2.0`. The pair `claude plugin marketplace update metis` +
  `claude plugin update metis@metis` then moved it to `d6c87b683d8e`. So the
  documented path reaches current `main` on a fresh machine only, and the
  human reports seeing `0.2.0` for exactly this reason — the same symptom
  issue 0040 recorded, one layer further out.
- Measured before filing, in an isolated `HOME` (`claude` 2.1.220): a
  `SessionStart` hook running `claude plugin update metis@metis` completes
  inside a session, exits 0, and reports "updated from d6c87b683d8e to
  b46b397c573b … Restart to apply changes" — so the fetch is possible from
  where the hook runs, and its effect lands in the following session.
- `claude plugin update <plugin>` alone reached the marketplace's origin: with
  the local clone reset to `7e8268a`, behind origin, the update moved the
  installation to `d6c87b6` without a preceding `claude plugin marketplace
  update`. With the clone one commit ahead of origin, it took that local
  commit instead.

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
