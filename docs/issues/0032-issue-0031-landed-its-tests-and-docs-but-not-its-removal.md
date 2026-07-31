---
status: active
branch: claude/issue-32-overview-anfrh9
pr:
---

# Issue 0031 landed its tests and docs but not its removal

## Intent

Pull request 31 was merged for issue 0031, whose intent was that the
repository carries exactly one delivery mechanism — the plugin — and nothing
that exists solely to prop up the other one. The merge did not do that. Its
diff (`61fde90..bf09c04`) touches three files: `README.md`, the issue record,
and a new suite `test-loader-removed.sh`. It deletes nothing.

Found by the `reviewer`, dispatched against that diff and issue 0031's intent
while measuring a dispatch's token cost for issue 0025. Of issue 0031's six
acceptance criteria only criterion 3 is met. `bash test.sh` exits 1, and the
suite written for the issue, `bash test-loader-removed.sh`, exits 1 with 15
failures.

Two of the findings are not simply unfinished work, and a run that only
deletes files will not resolve them:

- Issue 0031's criterion 4 forbids any reference to `install.sh`, the
  `bootstrap` skill or the loader script outside `docs/issues/`. But
  `test-loader-removed.sh` is tracked, sits outside `docs/issues/`, and
  contains those literal strings — it is the suite that checks the criterion.
  It currently exempts itself from its own search, so it can reach exit 0
  while the criterion as written stays unmet.
- Issue 0031's criterion 6 asks that issues 0023 and 0024 be closed as moot,
  "noting the file each described no longer exists". For 0024 that holds. For
  0023 it does not: 0023 reproduces against `hooks/session-start.sh`, the
  plugin's own hook, which issue 0031's criterion 1 explicitly retains. That
  file still exists after a complete implementation, and the `core.hooksPath`
  overwrite it reports is still reachable.

Wanted observable behaviour: the repository carries only the plugin, the one
command behind "the suite is green" exits 0, and no criterion is satisfied by
a test that exempts itself from it.

Acceptance criteria:

1. `install.sh`, `.claude/hooks/session-start.sh`, `skills/bootstrap/`,
   `test-install.sh`, and the suites
   `skills/bootstrap/assets/test-session-start-core.sh` and
   `skills/bootstrap/assets/test-session-start-loader.sh` are absent from the
   repository, while `hooks/session-start.sh` and `hooks/hooks.json` remain.
2. This repository's `.claude/settings.json` declares no `SessionStart` hook
   pointing at the removed loader script, and its `extraKnownMarketplaces`
   and `enabledPlugins` entries are unchanged from before this issue.
3. Searching the tracked tree — excluding `docs/issues/`, the two retained
   plugin-hook files, and this issue's own verification scripts
   (`test-loader-removed.sh` and `test-plugin.sh`) — for `install.sh`, the
   `bootstrap` skill or the loader script finds no reference, and the check
   that establishes this exempts no other tracked file from its own search.
4. `bash test.sh` exits 0, it names every suite present in the tree, and it
   names no suite that guarded a removed part.
5. `test-plugin.sh` contains no case asserting that the loader, `install.sh`,
   the `bootstrap` skill or their suites are present.
6. Issue 0024 is marked resolved as moot, noting the file it described no
   longer exists. Issue 0023 is either still open or closed with a reason that
   is true of the tree it is closed against — it is not closed on the ground
   that its file is gone, because `hooks/session-start.sh` remains.
7. Every acceptance criterion of this issue has a test that fails when the
   behaviour it names is absent, and no test asserts a condition this issue's
   criteria do not state.

## Plan

## Tasks

## Decisions

- **Criterion 3 softened.** Excluded from its tree-wide search, alongside
  `docs/issues/` and the two retained plugin-hook files: this issue's own
  verification scripts, `test-loader-removed.sh` and `test-plugin.sh`. Both
  must contain the literal strings `install.sh`/`bootstrap` in their own
  source to check for their absence elsewhere, so without this exemption the
  criterion could never be met by any implementation. This is bounded to the
  two files whose sole purpose is checking these paths' absence, recorded
  here rather than hidden inside the test — unlike the original bug the
  criterion targets, where the check silently excluded itself by name with no
  such record. Source: the human's answer, "weiche 3 auf, das issue selbst,
  die dazugehörigen skripte und tests sind ausgeschlossen".

## Log

- Filed from the `reviewer`'s findings on pull request 31, produced while
  measuring a dispatch's cost for issue 0025. Criterion 3 of issue 0031 is the
  only one that change met; this issue carries the rest, plus the two findings
  that a straight deletion would not resolve.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes — the human asked to implement issue
  0032, whose intent and seven acceptance criteria are already filed. Verified
  by hand: `bash test.sh` exits 1 (test-plugin.sh's own coverage case fails
  because test-loader-removed.sh exists but isn't named in test.sh's suite
  list); `bash test-loader-removed.sh` exits 1 with 15 failures, matching the
  issue's own count exactly; every file criterion 1 names for deletion
  (install.sh, .claude/hooks/session-start.sh, skills/bootstrap/,
  test-install.sh, and the two nested bootstrap test suites) is present, and
  the two retained plugin-hook files (hooks/session-start.sh, hooks/hooks.json)
  are present; issues 0023 and 0024 are both still status: backlog as the
  issue describes.
- **What surprised me?** Reading test-plugin.sh's own case 19 (lines 747-762)
  shows it hard-codes the opposite expectation of this issue: it fails unless
  the loader, install.sh and the bootstrap skill are all still present
  ("criterion 7: X is missing, but criterion 6 does not hold — it must
  remain"). Reading issue 0031's own checkpoint record clarified this is not
  an oversight: the human was told explicitly that removing the loader
  overrides issue 0022's settled criterion 7, and accepted the loss of reach
  ("ja"). So this run finishes a change the human already deliberately
  authorized, not one that silently overrides an earlier decision.
- **What am I assuming without having verified it?** That fixing
  test-loader-removed.sh's self-exemption bug (criterion 3) and wiring it into
  test.sh's suite list falls within the implementer's normal scope even though
  the file being touched is itself a test file — the acceptance criterion is
  about that check's own correctness, not about production behaviour it
  guards. And that issue 0031's own frontmatter being stuck at status: active
  despite its PR (#31) being merged is out of this issue's seven criteria and
  not something to fix in this diff.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
