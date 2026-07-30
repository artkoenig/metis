---
status: active
branch: claude/metis-remove-loader-0031
pr:
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
3. `README.md` and `AGENTS.md` instruct a reader to install the plugin, and
   name no step that installs the loader.
4. Searching the repository's current tree — excluding `docs/issues/`, and
   excluding the plugin's own retained `hooks/session-start.sh` and
   `hooks/hooks.json` — for `install.sh`, the `bootstrap` skill, or the
   loader script (`.claude/hooks/session-start.sh`,
   `skills/bootstrap/assets/session-start.sh`) finds no reference.
5. When `test.sh` runs, it exits 0, and every suite it names exists; it names
   no suite that guarded a part removed by this issue. This includes
   `test-plugin.sh`'s own case that asserted the loader's presence for issue
   0022's criterion 7 — that assertion no longer holds unconditionally once
   this issue lands and must be updated, not merely left to fail.
6. Issues 0023 and 0024 — both findings against code this issue removes — are
   marked resolved as moot, noting the file each described no longer exists.

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

## Retro
