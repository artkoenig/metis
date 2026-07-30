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
delivery path for exactly this reason: `install.sh`, `hooks/session-start.sh`,
`hooks/hooks.json`, the `bootstrap` skill, and the test suites that exist only
to guard them.

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

1. `install.sh`, `hooks/session-start.sh`, `hooks/hooks.json`,
   `skills/bootstrap/`, `test-install.sh`, and the suites
   `skills/bootstrap/assets/test-session-start-core.sh` and
   `skills/bootstrap/assets/test-session-start-loader.sh` are absent from the
   repository.
2. This repository's own `.claude/settings.json` declares no `SessionStart`
   hook.
3. `README.md` and `AGENTS.md` instruct a reader to install the plugin, and
   name no step that installs the loader.
4. Searching the repository's current tree (not other issues' own historical
   Log entries) for `install.sh`, the `bootstrap` skill, or
   `session-start.sh` by path finds no reference.
5. When `test.sh` runs, it exits 0, and every suite it names exists; it names
   no suite that guarded a part removed by this issue.
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
