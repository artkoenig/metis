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
- **Issue 0024's status on closure.** The tracker's four states
  (backlog/active/waiting/done) have no dedicated "moot"/"won't do" state.
  `active` is unavailable (at most one issue at a time, and 0032 holds it);
  `waiting` means parked on an open question, which this isn't. Default
  chosen: `status: done`, with the `pr` field pointing at this issue's own
  pull request once opened — this issue's PR is what settles 0024, even
  though 0024 gets no implementation of its own. Default, unanswered — not
  put to the human, since it changes no user-visible behaviour, public
  contract, data model or dependency footprint.

## Log

- Filed from the `reviewer`'s findings on pull request 31, produced while
  measuring a dispatch's cost for issue 0025. Criterion 3 of issue 0031 is the
  only one that change met; this issue carries the rest, plus the two findings
  that a straight deletion would not resolve.
- **Review round 1 (fresh context)**, against `origin/main..HEAD`
  (`fb67c9a..2f4a4ad`). All 7 criteria confirmed met, by exit code
  (`bash test.sh`, `bash test-plugin.sh`, `bash test-loader-removed.sh`, each
  exit 0) and independent re-derivation (a separate `git grep` for
  criterion 3, and a scratch copy with an injected failure in each suite in
  turn to confirm the `METIS_TEST_SH_NESTED` recursion guard in `test.sh`
  doesn't mask a broken suite at the top level). One finding, violating none
  of the 7 criteria: `AGENTS.md`'s Bookkeeping section (the fallback
  self-check diagnostic) told a session to check whether `~/.claude` skill
  and agent symlinks resolve and how `.claude/hooks/session-start.log` ends —
  both artifacts only the loader machinery this issue deletes ever produced,
  so the sentence is now false for every session running only the plugin.
  Fixed directly in this change (not filed separately), per the documentation
  rule's own exception for a finding that this diff's removal itself
  falsified: replaced the fallback question with `claude plugin list` plus
  skill/agent availability, the facts a plugin-only session can actually
  check. `bash test.sh` re-run after the fix: still exit 0, all 54 cases
  across the 3 suites pass.
- **Review round 2 (same context continuing)**, against `origin/main..HEAD`
  (`fb67c9a..3b0a1da`). Re-checked the whole intent, not only round 1's own
  finding. Re-established `bash test.sh`, `bash test-plugin.sh` and
  `bash test-loader-removed.sh` all exit 0 (54/54 cases) itself, re-derived
  criterion 3 independently again, and confirmed `claude plugin list` — what
  the round-1 fix now points the fallback diagnostic at — is a real, working
  command already used the same way elsewhere in this repository's own
  record. No findings.

| | Round 1 | Round 2 |
| --- | --- | --- |
| Criterion 1 | 0 | 0 |
| Criterion 2 | 0 | 0 |
| Criterion 3 | 0 | 0 |
| Criterion 4 | 0 | 0 |
| Criterion 5 | 0 | 0 |
| Criterion 6 | 0 | 0 |
| Criterion 7 | 0 | 0 |
| No criterion | 1 | 0 |
| **Total** | **1** | **0** |

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

- **Does this match what was asked?** Yes. All seven acceptance criteria are
  met, verified independently by the reviewer (not just reported by the
  implementer): `bash test.sh`, `bash test-plugin.sh` and
  `bash test-loader-removed.sh` all exit 0, 54 cases total. The two review
  rounds converged (1 finding → 0), so this run did not hit the three-round
  stop rule.
- **What surprised me?** Three things, in the order they showed up. First,
  fixing criterion 3's self-exemption bug exposed a genuine structural
  conflict: the two verification scripts must contain the very strings
  criterion 3 forbids elsewhere, so an unqualified reading of the criterion
  could never be satisfied — resolved by the human softening it to name an
  explicit, bounded exemption. Second, wiring `test-loader-removed.sh` into
  `test.sh`'s own suite list created literal infinite recursion (that suite's
  criterion-4 check runs `bash test.sh`, which would run that suite again) —
  the implementer's `METIS_TEST_SH_NESTED` guard fixed it, and the reviewer
  independently reproduced both a broken-suite scenario to confirm the guard
  doesn't mask a real failure. Third, the tracker's four states have no
  "closed as moot" state for issue 0024 — resolved with a recorded default
  (`status: done`, riding this issue's own PR) rather than asked, since it
  changes no user-visible behaviour.
- **What am I assuming without having verified it?** That issue 0024's `pr`
  field, left blank by the implementer, should be filled in with this same
  pull request once it is opened — done as part of opening the PR, not
  separately verified by the reviewer. That the criterion-3 grep-based
  search, run against the tracked git tree, is a sufficient check for "no
  reference" — it would not catch a reference in an untracked file, but
  untracked files are outside what any tracked-tree criterion could mean.

## Retro
