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

## Decisions

- **The plugin is added; the hook path stays.** Source: the human's answer to
  "replace the hook, or stand beside it?" — *"replace, but only after proof"*,
  with the explicit fallback of landing the additive variant and reporting it
  when the proof fails. Criterion 6's proof failed (see the Log), so the
  additive variant is what lands.
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
  Conclusion: a plugin cannot replace the loader hook for cloud sessions.
  Criterion 7's second branch applies.
- Two corrections to guesses made along the way, both by measurement:
  `SKIP_PLUGIN_MARKETPLACE=true`, which this cloud environment sets, does
  **not** stop an installed plugin from loading — a run with and a run without
  it both answered `YES`. And a plugin placed under `~/.claude/skills/` needs
  no marketplace and no install step at all; it loads as
  `<name>@skills-dir`.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Partly, and the gap is recorded. The ask
  was to make metis a Claude Code plugin; that lands in full. The human chose
  to retire the hook machinery only on proof that a plugin carries a cloud
  session, and that proof failed, so the machinery stays — which the human
  authorised as the fallback.
- **What surprised me?** Three things, all facts documentation would not have
  given me. Plugin agent discovery does not recurse, and the manifest field
  that looks like the way around it silently loads nothing. A plugin dropped
  into `~/.claude/skills/` needs no marketplace and no install at all. And
  plugin discovery runs *before* `SessionStart` hooks, which is what kills the
  hook-installs-the-plugin idea.
- **What am I assuming without having verified it?** That the interactive
  Claude Code web session behaves like the headless `-p` run I measured in
  this same container — both find no installed plugin in a fresh container, so
  neither loads one. I have not driven the web UI itself. Also that flattening
  the agent layout leaves the loader working: `~/.claude/agents` is scanned
  recursively for `.md` files, so a symlinked file should be found where a
  symlinked directory was before. The core's own harness will establish that
  by exit code rather than my reading.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
