---
name: bootstrap
description: Wires a project so its Claude Code CLOUD sessions (CLAUDE_CODE_REMOTE) load the Metis rulebook, subagents and skills, by installing a SessionStart hook that clones the metis repo and symlinks its agents/ and skills/ into ~/.claude. Run it at the start of any session in one of Artjom's git repositories whose hook is missing or has drifted — proactively, not only when asked. Also trigger on "set up cloud sessions for this project", "wire up metis here", "install the metis hook", or "migrate this project from the old agents repo".
user-invocable: true
---

# Bootstrap

Cloud sessions start from a bare clone with no `~/.claude` of their own. This
skill installs the SessionStart hook that fills the gap: it clones
[metis](https://github.com/artkoenig/metis), symlinks its `agents/` and
`skills/` into `~/.claude`, makes `AGENTS.md` the global instructions, and
points `core.hooksPath` at metis's `.githooks` so a direct push to the
default branch is refused. In a local session the hook manages no symlinks —
the user owns their own `~/.claude` — but it does fast-forward the local
metis clone (found via those symlinks, skipped when it has uncommitted
changes), so local sessions stop drifting behind.

## Loader and core — why the hook is split in two

The predecessor kept all sync logic in a per-project copy, so a workflow
change never reached a project until someone re-ran the bootstrap there —
which nobody did. This skill therefore installs only a thin, stable
**loader** (`assets/session-start.sh`): it clones or updates the metis repo —
re-cloning rather than serving a stale cache when the update fails — and
hands over to the **core** (`assets/session-start-core.sh`) *inside the
clone*. Editing the core changes what every bootstrapped project does on its
next session start; the loader itself should almost never change, and the
core is never copied anywhere.

## When to run it

At the start of a session in any git repository Artjom owns — no remote yet,
or `origin` on `github.com/artkoenig` — when the hook is missing or differs
from this skill's asset. Anything else (work, client, third-party) is out of
scope; skip it silently. Compare, don't assume:

```bash
diff <target>/.claude/hooks/session-start.sh <this-skill>/assets/session-start.sh
```

Identical → nothing to do. Missing or different → install.

## What to install

1. **The loader.** Copy `assets/session-start.sh` to the target's
   `.claude/hooks/session-start.sh` (create the directory if needed) and make
   it executable. Copy the asset verbatim — a hand-edited copy or an inlined
   `bash -c` blob is a second, independently drifting version. The core is
   not installed; it runs from the clone.
2. **The settings wiring.** Ensure `.claude/settings.json` contains:

   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
             }
           ]
         }
       ]
     }
   }
   ```

   Create the file with just this content if it is absent; otherwise merge
   the `SessionStart` entry in without disturbing existing settings.
3. **Commit both files** — a cloud session only benefits from a hook that
   was committed before it started.

The loader and its settings entry are the whole installation. There is no
issue template to install: the `issue` skill *is* the tracker and reaches the
session through the same symlinks as the subagents. A project still holding
a template from an earlier setup can delete it — invoke the `issue` skill to
find out which file that is.

## Migrating from the predecessor

Projects wired to `global-agents-config-and-skills` use the same file path
and settings entry, so installing this hook over the old one *is* the
migration. The hook prunes the predecessor's `~/.claude` symlinks itself, so
a migrated session never loads both skill sets. Legacy
`PreToolUse`/`WorktreeCreate` entries (the old worktree machinery) are not
managed by metis: leave them if the project still wants them, remove them if
it is going all-in on metis — ask only if the project's own files leave it
genuinely unclear.

## Keeping it honest

This repo dogfoods the same hook in its own `.claude/hooks/`, copied from
`assets/`. When the asset changes, update every copy by re-running this
skill — don't hand-edit.
