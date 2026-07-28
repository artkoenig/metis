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
points `core.hooksPath` at metis's `.githooks` so a direct push to the default
branch is refused. In a local session the hook manages no symlinks — the user
owns their own `~/.claude` — but it does fast-forward the local metis clone
(found via those symlinks, skipped when it has uncommitted changes), so local
sessions stop accumulating the drift of a clone nobody remembers to pull.

## Loader and core — why the hook is split in two

The predecessor's hook carried all of its sync logic in the per-project copy,
so a workflow change never reached an already-bootstrapped project until
someone re-ran the bootstrap skill there — which nobody did. This skill
therefore installs only a thin, stable **loader** (`assets/session-start.sh`):
it clones or updates the metis repo — re-cloning instead of silently serving a
stale cache when the update fails — and then hands over to the **core**
(`assets/session-start-core.sh`) *inside the clone*. Editing the core changes
what every bootstrapped project does on its next session start; the loader
itself should almost never need to change again, and the core is never copied
anywhere.

## When to run it

At the start of a session in any git repository Artjom owns — no remote yet,
or `origin` on `github.com/artkoenig` — when the hook is missing or differs
from this skill's canonical asset. Anything else (work, client, third-party)
is out of scope; skip it silently. Compare, don't assume:

```bash
diff <target>/.claude/hooks/session-start.sh <this-skill>/assets/session-start.sh
```

Identical → nothing to do. Missing or different → install.

## What to install

1. **The loader.** Copy `assets/session-start.sh` to the target's
   `.claude/hooks/session-start.sh` (create the directory if needed) and make
   it executable. Always copy the asset verbatim — never hand-edit the copy,
   never inline the script into settings as a `bash -c` blob; both create a
   second, independently drifting version. The core is not installed — it runs
   from the clone.
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

   Create the file with just this content if it is absent; otherwise merge the
   `SessionStart` entry in without disturbing existing hooks or settings.
3. **Commit both files** — they are ordinary versioned project files, and a
   cloud session only benefits from a hook that was committed before it
   started.

Those two are everything. In particular there is no issue template to
install: the `issue` skill *is* the tracker and reaches the session through
the same symlinks as the subagents. A project still holding a
`docs/issues/TEMPLATE.md` from an earlier setup can delete it — nothing keeps
it current, which is exactly why it stopped being a copy.

## Migrating from the predecessor

Projects wired to `global-agents-config-and-skills` use the same file path and
the same settings entry, so installing this hook over the old one *is* the
migration — nothing to unwire. The hook itself prunes `~/.claude` symlinks
left by the predecessor's clone, so a migrated session never loads both skill
sets side by side. Legacy `PreToolUse`/`WorktreeCreate` entries (the old
worktree machinery) are not managed by metis: leave them if the project still
wants them locally, remove them if it is going all-in on metis — ask only if
the project's own files leave it genuinely unclear.

## Keeping it honest

This repo dogfoods the same hook in its own `.claude/hooks/`, copied from
`assets/`. When the asset changes, update every copy the same way: re-run this
skill, don't hand-edit.
