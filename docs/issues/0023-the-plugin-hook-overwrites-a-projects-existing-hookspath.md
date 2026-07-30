---
status: backlog
branch:
pr:
---

# The plugin hook overwrites a project's existing core.hooksPath

## Intent

The plugin's `SessionStart` hook points a project's git hooks at metis's push
guard by writing `core.hooksPath`. It writes unconditionally and reports
success, so a project that manages its own git hooks — husky, lefthook,
pre-commit — silently loses all of them from the next session start onwards.

Reproduced by review round 3 of issue 0022:

```
git -C "$P" config core.hooksPath .husky        # before: .husky
CLAUDE_PLUGIN_ROOT=<metis> CLAUDE_PROJECT_DIR="$P" bash hooks/session-start.sh
→ "Metis self-check: ... push guard set; no problems."
git -C "$P" config core.hooksPath               # after: <metis>/.githooks
```

The behaviour predates the plugin — `skills/bootstrap/assets/session-start-core.sh`
does the same — but it used to reach only projects where somebody ran
`install.sh` deliberately. Through the marketplace it reaches anyone who runs
`claude plugin install metis@metis`, which is what makes it worth its own run.

Wanted observable behaviour: metis guards the default branch without
destroying hook wiring a project already had, and a session can see from the
status what happened to it.

Acceptance criteria:

1. When the hook runs in a project whose `core.hooksPath` is set to something
   other than metis's `.githooks`, that value is still in effect afterwards.
2. When the hook does not take over `core.hooksPath`, the self-check status
   says so and names the value it left alone, instead of reporting the guard
   as set.
3. When the hook runs in a project with no `core.hooksPath`, or one already
   pointing at metis's `.githooks`, the guard is set as it is today and a
   direct push to the default branch is refused.
4. When a project's own hooks are in effect and metis therefore does not guard
   the default branch, that is visible in the status as a missing guard rather
   than as success.

## Plan

## Tasks

## Decisions

## Log

- Filed out of issue 0022's review round 3, which reproduced it. The finding
  is outside 0022's acceptance criteria, so it goes to its own run rather than
  being fixed there. The human decided to file it.

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
