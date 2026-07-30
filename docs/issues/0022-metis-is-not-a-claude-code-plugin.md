---
status: active
branch: claude/metis-claude-plugin-anmted
pr:
---

# Metis is not a Claude Code plugin

## Intent

Metis reaches a session through machinery it maintains itself: a per-project
`SessionStart` loader, a core script inside the clone, symlink management in
`~/.claude`, an installer, a bootstrap skill, and three test suites guarding
all of it. Claude Code distributes exactly this kind of content natively —
skills, subagents and hooks, installed from a marketplace and updated without
anyone re-running anything.

Wanted observable behaviour: metis installs as a Claude Code plugin from this
repository, and a session with that plugin active has the same skills, agents,
rulebook text and push guard available as a hooked session has today. The
hand-built loading machinery disappears — but only once a cloud session has
been shown to load the plugin, because a cloud session starting from a bare
clone is the case that machinery exists for.

Acceptance criteria:

1. When `claude plugin validate` runs against this repository with `--strict`,
   it exits 0.
2. When a session loads the plugin, every skill directory under `skills/` and
   every agent under `agents/` in this repository is listed as a component of
   that plugin — none missing, none extra.
3. When a session loads the plugin, the text of `AGENTS.md` is in that
   session's context without the session reading a file: the plugin delivers
   the rulebook itself, not a pointer to it.
4. When a session loads the plugin, it receives a self-check status naming how
   many skills and agents are reachable and the push-guard state — and when a
   part is missing, the status says so instead of reporting success.
5. When a session loads the plugin in a git repository, a direct push to that
   repository's default branch is refused.
6. Whether a cloud session installs and loads this plugin from a project's
   `.claude/settings.json` alone is established by a command's exit code and
   recorded in this issue — an assumption recorded as a fact fails this
   criterion.
7. When criterion 6 holds, `install.sh`, the `bootstrap` skill, the loader,
   the core and the suites that only guard them are absent from the
   repository, and `README.md` tells a reader to install the plugin instead.
   When it does not hold, all of them remain and this issue records the
   failing command and its output.
8. When `test.sh` runs, it exits 0, and every suite it names exists.

## Plan

## Tasks

The change both adds a plugin and removes the machinery it replaces, so it
lands in steps with a commit each.

1. Flatten `agents/<name>/agent.md` to `agents/<name>.md`.
2. Add the plugin manifest, the marketplace manifest, and the plugin's
   `SessionStart` hook with its script — rulebook text, self-check status and
   push guard.
3. Wire this repository to its own plugin: `.claude/settings.json` declares the
   marketplace and enables the plugin, and the dogfooded loader copy goes.
4. Remove what the plugin replaces: `install.sh`, the `bootstrap` skill, the
   loader, the core, and the three suites that only guard them.
5. Rewrite `README.md` for the plugin installation.
6. Establish criterion 6 by exit code from a fresh cloud session on this
   branch, and record the output.

## Decisions

- **The plugin replaces the hook path.** Source: the human's answer to
  "replace the hook, or stand beside it?" — *"replace, but only after proof"*.
  The first reading of the measurements said the proof failed; the human
  challenged it and the documentation settled it the other way (see the Log).
  A cloud session installs a plugin declared in the repository's
  `.claude/settings.json` before the session starts, so the loader, the core,
  the installer and the bootstrap skill have nothing left to do.
- **This repository is its own marketplace**, and registering it is an
  accepted prerequisite for installing the plugin. Source: the human, asked
  nothing — they said so unprompted after seeing the measurements: if a
  marketplace is the precondition, that is the way, since one can register
  one's own. So `claude plugin marketplace add artkoenig/metis` followed by
  `claude plugin install metis@metis` is the documented installation, and the
  loader hook survives only for the cloud case, whose blocker is startup
  ordering rather than the marketplace.
- **The rulebook reaches a session as `additionalContext` from the plugin's
  own `SessionStart` hook.** Source: the plugin documentation — a `CLAUDE.md`
  at a plugin root is explicitly not loaded, and instructions are to be
  shipped "in a skill". A skill is model-invoked and therefore optional; the
  rulebook is unconditional, so the hook is the only mechanism that delivers
  it every time. Verified: a plugin hook's `additionalContext` reaches the
  model's context.
- **Agents move from `agents/<name>/agent.md` to `agents/<name>.md`.** Source:
  measurement, not documentation — plugin agent discovery does not recurse,
  and the manifest's `agents` field does not substitute for it (see the Log).
  One flat layout serves both the plugin and the loader; keeping the nested
  layout for the loader and adding a flat copy for the plugin would create two
  files that drift apart.
- **The plugin's root is the repository root**, with the marketplace entry
  pointing at `./`. Source: default — nothing requires a subdirectory, and a
  subdirectory would need `skills/` and `agents/` duplicated or symlinked into
  it.

## Log

- Established what a Claude Code plugin can carry, by probing a scratch plugin
  with `claude` 2.1.220 rather than by reading alone:
  - `claude plugin details` on a plugin holding both `agents/flat.md` and
    `agents/nested/agent.md` reported `Agents (1) flat` — **discovery does not
    recurse**, and the name comes from the filename, not the frontmatter.
  - Declaring the nested file in the manifest's `agents` field installed
    cleanly but still reported `Agents (0)`; declaring a *directory* there
    (`"./agents/"`, `"./custom/"`) failed the install with
    `Validation errors: agents: Invalid input`. The field is no substitute for
    the flat default scan.
  - A plugin `SessionStart` hook runs with `CLAUDE_PLUGIN_ROOT`,
    `CLAUDE_PROJECT_DIR` and `CLAUDE_CODE_REMOTE` set, and its
    `additionalContext` reaches the model: a headless run asked whether a
    marker string was in its context answered `YES`.
- Criterion 6 — three measurements, all against a scratch config directory,
  each asking a headless session whether the plugin's marker string reached
  its context:
  1. Marketplace and `enabledPlugins` declared only in the project's
     `.claude/settings.json`: `claude plugin marketplace list` reported *no
     marketplaces configured*, `claude plugin list` reported none installed,
     the plugin's hook did not run, answer `NO`.
  2. The same declaration in user settings: the marketplace was registered,
     but `claude plugin list` still reported no plugin installed, the hook did
     not run, answer `NO`. `enabledPlugins` enables; it does not install.
  3. A `SessionStart` hook that placed a complete plugin into
     `~/.claude/skills/probe` during startup: the hook itself ran and its own
     context arrived (`BOOTSTRAP=YES`), and `claude plugin list` afterwards
     showed `probe@skills-dir` as `loaded` — but the plugin's own hook did not
     run in that session and its context did not arrive (`MARKER=NO`).
     Plugin discovery happens before `SessionStart` hooks, so a plugin created
     by a hook takes effect one session late. In an ephemeral cloud container
     that is one session too late.
  Conclusion drawn at the time: a plugin cannot replace the loader hook for
  cloud sessions. **That conclusion was wrong** — see the next entry.
- **Course correction, prompted by the human**, who found the conclusion
  implausible and asked for the official documentation. The cloud-environment
  documentation states it in its table of what carries over: *"Plugins declared
  in `.claude/settings.json` — Yes — Installed at session start from the
  marketplace you declared. Requires network access to reach the marketplace
  source"*, and immediately below, plugins enabled only in user settings do not
  carry over and are to be declared *"in the repo's `.claude/settings.json`
  instead"*. A cloud session therefore installs a repo-declared plugin before
  the session begins, which is exactly the same-session guarantee measurement 3
  found missing from a hook.
  The error in the measurement: a plain `claude -p` inside this container is not
  the cloud session's startup path. Measurement 1 failed at the workspace-trust
  gate — the marketplace was not even registered — not at the mechanism, and I
  read a trust failure as an absent feature. What the three measurements do
  establish stands: `enabledPlugins` alone installs nothing, and a hook that
  places a plugin acts one session late. Neither is the cloud path.
  Criterion 7's first branch applies, and criterion 6 still owes an exit code:
  the documentation is not a fact by exit code. A fresh cloud session on this
  branch, reporting `claude plugin list`, is what settles it.
- Two corrections to guesses made along the way, both by measurement:
  `SKIP_PLUGIN_MARKETPLACE=true`, which this cloud environment sets, does
  **not** stop an installed plugin from loading — a run with and a run without
  it both answered `YES`. And a plugin placed under `~/.claude/skills/` needs
  no marketplace and no install step at all; it loads as
  `<name>@skills-dir`.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes. The ask was to make metis a Claude
  Code plugin; it becomes one, installed from its own marketplace, and the
  machinery that existed only to load it goes away.
- **What surprised me?** Three measured facts, then one of my own conclusions.
  Plugin agent discovery does not recurse, and the manifest field that looks
  like the way around it silently loads nothing. A plugin dropped into
  `~/.claude/skills/` needs no marketplace and no install at all. Plugin
  discovery runs before `SessionStart` hooks. And the surprise that mattered
  most: I turned three negative measurements into a conclusion about cloud
  sessions that the documentation flatly contradicts, and it took the human
  saying "that seems unlikely" to catch it. The measurements were sound; the
  inference from them to a startup path I had not measured was not.
- **What am I assuming without having verified it?** That a cloud session
  really performs the install the documentation promises — this is the whole of
  criterion 6 and it is still owed an exit code; a fresh cloud session on this
  branch has to show it. That the marketplace source can name this repository
  before the change is merged, which needs a `ref` pointing at this branch and
  is therefore a temporary value that must not survive the merge. And that
  flattening the agent layout costs nothing, since after this change nothing
  but plugin discovery reads it.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
