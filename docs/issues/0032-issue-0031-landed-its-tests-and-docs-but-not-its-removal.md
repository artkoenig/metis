---
status: backlog
branch:
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
3. Searching the tracked tree — excluding `docs/issues/` and the two retained
   plugin-hook files — for `install.sh`, the `bootstrap` skill or the loader
   script finds no reference, and the check that establishes this exempts no
   tracked file from its own search.
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

## Log

- Filed from the `reviewer`'s findings on pull request 31, produced while
  measuring a dispatch's cost for issue 0025. Criterion 3 of issue 0031 is the
  only one that change met; this issue carries the rest, plus the two findings
  that a straight deletion would not resolve.

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
