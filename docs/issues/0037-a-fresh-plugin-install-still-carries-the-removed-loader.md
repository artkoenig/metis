---
status: backlog
branch:
pr:
---

# A fresh plugin install still carries the removed loader

## Intent

Issues 0031 and 0032 removed the loader machinery from the tree: `install.sh`,
`test-install.sh`, `skills/bootstrap/` and `.claude/hooks/session-start.sh` are
all gone, and `bash test.sh` exits 0 proving it.

The installed plugin does not reflect that. Observed at
`/root/.claude/plugins/cache/metis/metis/0.2.0/` during the grilling for issue
0036: that directory still contains `install.sh`, `test-install.sh`,
`skills/bootstrap/` and `.claude/hooks/session-start.sh`, and its own
`.claude/settings.json` still declares a `SessionStart` hook pointing at
`$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh` — a path the current tree
does not produce.

So a session running the installed plugin runs a different Metis than the one
in the repository, and points a hook at a file that no longer exists. The tree
being clean is not the same fact as an installation being clean, and only the
tree has ever been checked.

Wanted observable behaviour: installing this plugin the way `README.md`
documents yields a plugin that carries only what the tracked tree carries.

Acceptance criteria:

1. A fresh installation of this plugin, performed the way `README.md`
   documents, produces a plugin directory containing no `install.sh`, no
   `test-install.sh`, no `skills/bootstrap/` directory and no
   `.claude/hooks/session-start.sh`.
2. That installation declares no `SessionStart` hook pointing at a file the
   installation itself does not contain.

## Plan

## Tasks

## Decisions

- **No criterion demanding a test per criterion.** The draft carried a third
  criterion requiring every criterion above it to have its own failing test and
  no test beyond them. It was struck because it refers to itself: it is a
  criterion, so it demands a test of itself, and that test is then a criterion's
  test that must itself be covered — the check never terminates. Source: the
  human's answer, "der grund ist, dass solche akzeptanzkriterien
  endlosschleifen verursachen, weil sie auf sich selbst beziehen".

## Log

- Observed while grilling issue 0036, outside that issue's criteria, and filed
  here for its own run.

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
