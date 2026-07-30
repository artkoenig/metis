---
status: done
branch: claude/metis-remove-loader-0031
pr: https://github.com/artkoenig/metis/pull/31
---

# The repository still ships a loader that duplicates the plugin

## Intent

Metis already installs as a Claude Code plugin (issue 0022). But the plugin
does not reliably reach a cloud session declared only through a project's
`.claude/settings.json` — issue 0022's criterion 6 measured this by exit code
across two marketplace source types and settled it as **not met**, corroborated
by two independent upstream reports (`anthropics/claude-code#32606`,
`#51806`). Issue 0022's criterion 7 therefore kept a second, hand-built
delivery path for exactly this reason: `install.sh`, the installed loader
script (`.claude/hooks/session-start.sh`, this repository's own copy of
`skills/bootstrap/assets/session-start.sh`), the `bootstrap` skill, and the
test suites that exist only to guard them. The plugin's *own* `SessionStart`
hook — `hooks/session-start.sh` and `hooks/hooks.json` at the repository
root, added by issue 0022 itself — is a different thing: it is what delivers
the rulebook text, the self-check status and the push guard for criteria 3–5
of that issue, and stays regardless of what this issue does.

The human, told explicitly that removing this second path means a cloud
session in a project that currently receives metis only via the loader (any
project set up by `install.sh`/`bootstrap` rather than by declaring the
plugin) will stop receiving metis at all until that project switches to the
plugin declaration, decided to remove it anyway. This is a deliberate, accepted
reduction in reach, not an oversight, and it reopens what issue 0022's
criterion 7 had kept in place for as long as criterion 6 stayed unmet.

Wanted observable behaviour: the repository carries exactly one delivery
mechanism — the plugin — and nothing that exists solely to prop up the other
one.

Acceptance criteria:

1. `install.sh`, `.claude/hooks/session-start.sh`, `skills/bootstrap/`,
   `test-install.sh`, and the suites
   `skills/bootstrap/assets/test-session-start-core.sh` and
   `skills/bootstrap/assets/test-session-start-loader.sh` are absent from the
   repository. `hooks/session-start.sh` and `hooks/hooks.json` — the plugin's
   own hook — are out of this issue's scope and stay.
2. This repository's own `.claude/settings.json` no longer declares a
   `SessionStart` hook pointing at the removed loader script; its plugin
   declaration (`extraKnownMarketplaces`, `enabledPlugins`) stays untouched.
3. `README.md` instructs a reader to install the plugin and names no step
   that installs the loader; `AGENTS.md` (which never carried install
   instructions of either kind) names no step that installs the loader
   either.
4. Searching the repository's current tree — excluding `docs/issues/`, the
   test files whose own job is to name these paths while checking their
   absence, and the plugin's own retained `hooks/session-start.sh` and
   `hooks/hooks.json` — for `install.sh`, the `bootstrap` skill, or the
   loader script (`.claude/hooks/session-start.sh`,
   `skills/bootstrap/assets/session-start.sh`) finds no reference.
5. When `test.sh` runs, it exits 0, and every suite it names exists; it names
   no suite that guarded a part removed by this issue. This includes
   `test-plugin.sh`'s own case that asserted the loader's presence for issue
   0022's criterion 7 — that assertion no longer holds unconditionally once
   this issue lands and must be updated, not merely left to fail.
6. Issue 0024 — a finding against `skills/bootstrap/SKILL.md`, which this
   issue deletes — is marked resolved as moot, noting the file it described no
   longer exists. Issue 0023 targets `hooks/session-start.sh`, the plugin's
   own hook this issue retains unchanged, so it stays open and untouched.

## Plan

## Tasks

## Decisions

- **The human accepted the loss of reach this causes**, having been told
  explicitly, before confirming: a cloud session in a project that currently
  receives metis only via `install.sh`/the `bootstrap` skill loses metis
  entirely, since the plugin path is already confirmed (issue 0022) not to
  reach such a session. Source: the human's own answer ("ja"), not a
  document.

## Log

- **The `test-author` wrote `test-loader-removed.sh`** from this intent alone,
  without seeing an implementation: one case per testable criterion (1, 2, 3,
  4, 5 — criterion 6 has nothing to run, since closing two other issues is
  bookkeeping, not behaviour). Run directly, it fails all 18 assertions,
  `bash test-loader-removed.sh` exits 1 — confirmed myself, not taken on the
  subagent's word. Criterion 3's marker for "instructs installing the plugin"
  is the literal command `claude plugin install`, chosen from issue 0022's own
  decision record; flagged by the test-author as a judgment call the reviewer
  may need to revisit if the implementer phrases the instruction differently.
  `test.sh` itself is left untouched by the test-author on instruction, and
  now exits 1 rather than 0 for an expected reason: `test-plugin.sh`'s own
  criterion-8 case sees the new suite file on disk and fails because it is
  not yet wired into `test.sh`'s list — the implementer's job.
- **The `implementer` stopped before changing anything**, exactly the
  surprise checkpoint 1 had already flagged as an unverified assumption: it
  read `hooks/session-start.sh`'s own header ("The plugin's SessionStart
  hook... it puts the rulebook text into the session's context... and it
  points the project's git hooks at the push guard") and `hooks/hooks.json`,
  and found that criterion 1, as first written, named these two files for
  deletion — but they are the plugin's *own* hook, added by issue 0022 for
  criteria 3–5, not the per-project loader. The loader is a different, already
  correctly-named file: the installed copy at `.claude/hooks/session-start.sh`
  (from the `bootstrap` skill's `skills/bootstrap/assets/session-start.sh`
  template). Verified myself, not taken on the subagent's word: `cat
  hooks/hooks.json` shows it running
  `"${CLAUDE_PLUGIN_ROOT}"/hooks/session-start.sh`, discovered by the plugin
  system itself; `.claude/settings.json`'s `hooks.SessionStart` points instead
  at `$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh`, the tracked,
  installed loader copy. Deleting the plugin's own hook as criterion 1
  originally said would have left the plugin delivering nothing at all —
  the opposite of "exactly one delivery mechanism" — and would have regressed
  issue 0022's criteria 3–5 for every session, not just the reduced-reach
  cloud case this issue is about. Criteria 1 and 4 corrected above; no
  production file was touched by the blocked implementer run, so nothing
  needed reverting.
- **The `test-author` corrected `test-loader-removed.sh`'s criteria 1 and 4
  cases** to match: criterion 1 now expects `.claude/hooks/session-start.sh`
  absent instead of `hooks/session-start.sh`/`hooks/hooks.json`, and asserts
  the latter two are still present (the plugin's own hook, retained);
  criterion 4's grep patterns now target the loader script's own path
  specifically rather than a bare `session-start.sh`, so a legitimate mention
  of the plugin's own retained hook no longer trips it. Confirmed myself:
  `bash test-loader-removed.sh` still exits 1, still 18 failures, and none of
  them names `hooks/session-start.sh` or `hooks/hooks.json`.
- **A second test bug, found by running the corrected file myself**:
  criterion 4's grep searched the whole tracked tree including
  `test-loader-removed.sh` itself, which necessarily contains the literal
  path strings it searches for (in its own `removed_paths` array and header
  comment) — so criterion 4 could never pass, even after a correct
  implementation, since the test file would always match its own patterns.
  Fixed directly (by me, not a subagent, since the human asked for that after
  declining another dispatch): excluded `test-loader-removed.sh` from
  criterion 4's file list, the same way `docs/issues/` already is. Confirmed:
  `bash test-loader-removed.sh` still exits 1, still 18 failures, and no
  failure line now names `test-loader-removed.sh`.
- **A third correction, also found by re-reading the criteria against the
  actual repository before implementing further**: criterion 3 originally
  required both `README.md` and `AGENTS.md` to instruct installing the
  plugin. `git log --all -p -- AGENTS.md | grep install.sh` finds no commit
  where `AGENTS.md` ever named `install.sh` or any install step at all — it
  never carried install instructions, so requiring it to newly gain plugin
  install text is not correcting drift, it is adding content no prior state
  asked for. Corrected criterion 3 to only require README.md to instruct the
  plugin install; AGENTS.md is only required to name no loader step (which it
  already doesn't). `test-loader-removed.sh`'s criterion 3 case split
  accordingly. README.md's install section rewritten directly (by me): the
  `curl ... install.sh` block replaced with
  `claude plugin marketplace add artkoenig/metis` /
  `claude plugin install metis@metis`, matching issue 0022's own decision
  record. `bash test-loader-removed.sh` now shows 15 failures, not 18 — both
  criterion-3 cases already pass.
- **Direct implementation** (by me, not a subagent, per the human's
  "implementiere selbst"): deleted `install.sh`, `.claude/hooks/session-start.sh`,
  `skills/bootstrap/` (all five files under it), `test-install.sh`, and the
  untracked `.claude/hooks/session-start.log`. Rewrote `.claude/settings.json`
  to drop the `hooks.SessionStart` block, keeping only the plugin declaration.
  Reduced `test.sh`'s suites array to `test-plugin.sh` and
  `test-loader-removed.sh`. Rewrote `test-plugin.sh`'s case 19 (issue 0022
  criterion 7) to assert the loader paths are now absent instead of present,
  and its header comment to explain the override. Rewrote README.md's install
  section to `claude plugin marketplace add artkoenig/metis` /
  `claude plugin install metis@metis`.
- **A fourth test bug, this one a real infinite recursion, not a
  false-positive grep**: `test-loader-removed.sh`'s criterion 5 case
  re-invoked `bash test.sh` to check its own exit code — but `test.sh` runs
  `test-loader-removed.sh` as one of its two suites, so that suite's own
  criterion-5 case spawned another full `test.sh` run, which spawned another,
  unbounded. Caught live: a backgrounded `bash test.sh` run produced no output
  for several minutes while 29 `test.sh`/`test-plugin.sh`/
  `test-loader-removed.sh` processes accumulated (`ps aux | grep -c`), killed
  with `pkill -9`. Fixed directly: removed the recursive
  `bash "$repo_root/test.sh"` call from criterion 5; the suite-existence and
  no-removed-suite checks (already in the same block) are what criterion 5 is
  actually about, and whether the overall run exits 0 is already established
  by `test.sh`'s own top-level runner summing every suite's exit code — a
  suite re-running the whole thing to prove that fact about itself is both
  circular and redundant. Updated the case's header comment and pass message
  to match. Re-verified: `bash test-loader-removed.sh` standalone exits 0
  (6/6 cases), and a plain `timeout 60 bash test.sh` (no longer at risk of
  hanging) exits 0 with both suites fully green — `test-plugin.sh` 27 cases,
  `test-loader-removed.sh` 6 cases.
- **Criterion 6 was wrong about issue 0023, checked before acting on it**:
  criterion 6 as first written treated both 0023 and 0024 as findings against
  code this issue removes. `cat docs/issues/0023-...md` shows its acceptance
  criteria are about the hook that overwrites a project's `core.hooksPath`
  unconditionally — that is `hooks/session-start.sh`, the plugin's own hook,
  which this issue explicitly keeps. `grep -n hooksPath hooks/session-start.sh`
  confirms the unconditional write is still there at line 93, unchanged by
  this issue's diff. So 0023 is not moot; only 0024 is (its subject,
  `skills/bootstrap/SKILL.md`, is deleted by this issue, and 0024's own
  Decisions section already named "drop bootstrap once the loader path goes
  away" as one of its options — this issue is that decision). Corrected
  criterion 6 above to close only 0024; 0023 is left open and untouched.

- **Review round 1, fresh** (first review of this diff): confirmed all six
  criteria met, verified independently — not on the test's word alone: its
  own `git ls-files`/grep pass across all 22 tracked non-`docs/issues/` files,
  its own read of `hooks/session-start.sh:93` (still writes `core.hooksPath`
  unconditionally, confirming 0023 correctly stays open), its own `bash
  test.sh` run (exit 0). Two findings, both violating no listed criterion:
  (1) `AGENTS.md`'s self-check fallback instructions named two artifacts
  (`~/.claude` skill/agent links, `.claude/hooks/session-start.log`) that only
  the now-deleted loader ever produced, so that fallback text could never
  again describe anything real — this is the documentation-falsification
  exception the rulebook itself carves out, so fixed in this change: replaced
  the fallback with a check of `claude plugin list` and directly invoking a
  skill/agent. (2) `.gitignore` still ignores `.claude/hooks/session-start.log`,
  a harmless dead entry, but not a false documentation statement — filed as
  issue 0032, not fixed here. Re-ran `bash test.sh` after the AGENTS.md edit:
  exit 0, unchanged.

  | | Round 1 |
  | --- | --- |
  | Criterion 1 | 0 |
  | Criterion 2 | 0 |
  | Criterion 3 | 0 |
  | Criterion 4 | 0 |
  | Criterion 5 | 0 |
  | Criterion 6 | 0 |
  | Violates no criterion | 2 (1 fixed here, 1 filed as 0032) |
  | **Total** | **2** |

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes. The human asked, in plain words,
  to remove the old session-start hook and everything that exists only to
  support it — twice, the second time after I named the consequence.
- **What surprised me?** That the request directly overrides a criterion
  (issue 0022's 7) settled and merged only hours earlier for the opposite
  reason. Nothing in the rulebook stops the human from doing this; it is
  exactly the human's second steering point — anything irreversible or
  outward-facing is theirs to decide — and I surfaced the consequence before
  taking it as settled, per the same point.
- **What am I assuming without having verified it?** That every reference to
  `install.sh`, `session-start.sh` and the `bootstrap` skill outside this
  repository's own tree (other projects that ran the installer already) is
  out of this issue's reach — this issue only touches what is in this
  repository, not projects that already cloned or ran the loader elsewhere.
  That `test-plugin.sh` and its suite do not themselves depend on any file
  named in criterion 1 — an assumption the implementer's first step should
  check before deleting anything.

### Before the PR

- **Does this match what was asked?** Yes: the loader and everything that
  existed only to support it are gone; the plugin's own hook and its skills
  other than `bootstrap` are untouched; `test.sh` is green.
- **What surprised me?** That criterion 6, which I myself drafted, was wrong
  for issue 0023 — I had bundled a still-live bug in retained code together
  with a genuinely moot one, without first re-reading 0023 against what this
  issue actually touches. Caught before acting on it, not after. Also: a
  criterion 5 case I let the test-author write turned out to recurse
  `test.sh` into itself once wired into `test.sh`'s own suite list — a defect
  that only a real run surfaced, not a reading of the text.
- **What am I assuming without having verified it?** That no other project's
  `.claude/settings.json` in this GitHub account still points at the removed
  `.claude/hooks/session-start.sh` — this issue only changes what is in the
  metis repository itself, and any project that already ran `install.sh`
  keeps its own installed copy regardless of what this repository does next.

## Retro
