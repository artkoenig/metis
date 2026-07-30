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
  That documentation says a cloud session installs a plugin declared in the
  repository's `.claude/settings.json` before the session starts — a
  documented claim, not an exit code. **Amended by review round 1:** this
  bullet was written as flat fact and the removals were made on it, but the
  human's answer was "replace, but only after proof" and criterion 6 has no
  proof. So the two paths coexist for now: the plugin is added, the loader,
  the core, the installer and the bootstrap skill stay until criterion 6
  holds. Criterion 7's second branch, not its first.
- **Releases happen on request.** Source: the human, asked whether every
  accepted rule change should bump `.claude-plugin/plugin.json`'s `version` —
  *"veröffentlichung auf anfrage"*. So a merged PR does not release: installed
  projects keep the version they have until a release is asked for, and the
  version is bumped then. The loader path is unaffected — its clone always
  carries the current default branch — so while both paths exist, the loader
  is the one that delivers a rule change immediately and the plugin is the one
  that delivers it on release.
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

- Criterion 6's exit code could not be produced from inside this container.
  Two attempts: `claude --cloud <prompt>` refuses without a TTY, and under a
  pseudo-TTY it produced no output and was killed at the timeout (exit 143) —
  a cloud session cannot be started from within a cloud session. A
  trigger-created session would start on the default branch, where the
  declaration this change adds does not exist yet, so it would prove nothing.
  What settles it is one cloud session opened on this branch: if its first
  line is the `Metis self-check:` status, the plugin was installed before the
  session started. Until then criterion 6 is open, and the risk it carries is
  the human's to weigh: if a cloud session does not perform the install, then
  after the merge every project wired to metis — including this one — loses it
  until its own `.claude/settings.json` declares the plugin.
- Implementation facts by exit code: `bash test.sh` — one suite,
  `test-plugin.sh`, 16 cases, exit 0. `claude plugin validate . --strict` —
  exit 0, but it validates the *marketplace* manifest only.
  `claude plugin validate .claude-plugin/plugin.json --strict` — exit 0, and
  this is the one that walks the skills and all four agents. (The count moved
  twice: five when this was first written, four after `skills/bootstrap/` was
  deleted — the correction review round 1 asked for — and five again from
  commit 077eaaf, which restored it for criterion 7. At HEAD
  `ls -d skills/*/` counts five: bootstrap, clean-room, grill, issue, plan.
  Review round 2 caught the stale correction.)
- The second validate target failed with exit 1 until two frontmatter
  descriptions were quoted. `skills/clean-room/SKILL.md` and
  `agents/researcher.md` carried unquoted YAML scalars containing `": "`, so
  both loaded with *every* frontmatter field silently dropped — the
  `researcher` agent had no description for a model to select it by. The
  defect predates this change; it is fixed here because criterion 1 demands
  the validator exit 0, and the validator is what surfaced it.
- The task list's six steps landed in one commit rather than one commit each.
  Any split would have left an intermediate commit whose suite was red: the
  flattened agents fail the old core's harness, and the plugin manifests fail
  until the hook script exists. A red commit buys nothing here.
- **Review round 1** (fresh context, diff against intent): six findings, all
  with reproductions. Per criterion — 3: 1, 4: 1, 7: 2, 8: 1, no criterion: 1;
  total 6. Facts the round established itself: `bash test.sh` 16 cases exit 0,
  `claude plugin validate .claude-plugin/plugin.json --strict` exit 0 (proven
  to walk the components by breaking `agents/researcher.md` frontmatter in a
  scratch copy → exit 1), `claude plugin validate . --strict` exit 0 but
  marketplace manifest only. Triage:
  - *Criterion 7 took the wrong branch* — fixed. Criterion 6 is open, so the
    machinery had to remain; it was deleted. Restored verbatim from the
    default branch.
  - *Every already-wired project loses metis on merge* — fixed by the same
    restoration. Reproduced by the round: a project holding the old loader
    against this branch's clone exits 1 with `Core script missing at
    …/skills/bootstrap/assets/session-start-core.sh`, and afterwards
    `~/.claude/agents` and `~/.claude/CLAUDE.md` do not exist. The round also
    found that the restored core links agents as directories while agents are
    now flat `.md` — so restoring alone is not enough; tests and a fix follow.
  - *A CR byte in `AGENTS.md` makes the plugin hook emit invalid JSON with
    exit 0* — fixed. `hooks/session-start.sh` drops the other control bytes
    but neither drops nor escapes `\015`, so criteria 3 and 4 fail silently
    for a CRLF edit. The code this replaced was immune (whitelist
    `tr -dc '\040-\176'`).
  - *Criterion 7's falsifiable half has no test, and `test.sh` names one of
    four suites* — fixed; tests written first.
  - *The designated criterion-6 proof would exercise the wrong source* — filed
    as the decision below, not fixed in the diff.
  - *"five skills" is four* — corrected above.
- **How criterion 6 must be proven, and what a green result would and would
  not establish.** Source: review round 1, reproduced. This repository's
  `.claude/settings.json` declares `{"source": "directory", "path": "."}`,
  while `README.md` tells every other project to use
  `{"source": "github", "repo": "artkoenig/metis"}`. A cloud session on this
  branch therefore settles criterion 6 for the *directory* source only; the
  github source that other projects depend on stays unproven by it. Whoever
  closes criterion 6 needs one cloud session per source, and the exit code
  for each.

- **The cloud-environment documentation, handed over by the human**
  (`https://code.claude.com/docs/en/cloud-environments`). It states the claim
  plainly: "Plugins declared in `.claude/settings.json` — Yes — Installed at
  session start from the marketplace you declared. Requires network access to
  reach the marketplace source." A second and clearer source than the one the
  earlier decision rested on — and still not an exit code, so criterion 6
  stays open by its own wording.
  Two facts on that page matter more than the confirmation:
  - The default **Trusted** network level allows `github.com`,
    `api.github.com`, `codeload.github.com` and `raw.githubusercontent.com`,
    so a github marketplace source is reachable at the default level. Only
    **None** would block it.
  - But: "Repository scope: GitHub API and release-asset requests reach only
    repositories attached to the session, so a setup script that downloads
    release assets from an unattached repository gets a 403." A *foreign*
    project's cloud session installing `metis@metis` from
    `{"source": "github", "repo": "artkoenig/metis"}` does not have this
    repository attached. Whether the plugin install goes through the GitHub
    proxy and is therefore subject to that scoping is unknown and untested —
    if it is, the github source cannot work for any project but this one, and
    the loader is not replaceable at all. This is now the sharpest open
    question behind criterion 6, ahead of the directory-vs-github distinction
    recorded above.

- **Review round 2** (fresh context, whole intent): nine findings, up from
  six. Per criterion — 1: 1, 4: 1, no criterion: 7; total 9. Two of the new
  ones were caused by round 1's own fixes, which is the rulebook's
  *regression* signal; recorded here rather than absorbed into a third round
  unremarked. Facts the round established itself: `bash test.sh` 4 suites,
  55 cases, exit 0, nothing skipped; `bash -n` over all 10 tracked `*.sh`
  plus `.githooks/pre-push` exit 0; `jq empty` over all 4 tracked `*.json`
  exit 0; both validate targets exit 0; no linter exists (`shellcheck`,
  `shfmt`, `markdownlint`, `yamllint` all missing, no CI, no lint config).
  Verdicts: criteria 1, 2, 3, 5, 7, 8 met; 4 partly; 6 open, and the round
  could not produce its exit code either. Triage:
  - *This repository was the one already-wired project the change unwired* —
    fixed. `.claude/settings.json` had lost its `hooks.SessionStart` entry, so
    metis's only mechanism was the unproven plugin path: no rulebook, no
    status, `core.hooksPath` unset, a direct push to `main` no longer refused.
    Both are declared again.
  - *`AGENTS.md` claimed a missing status means the hook did not run* — fixed.
    The loader is deliberately silent in local sessions and
    `test-session-start-loader.sh` asserts exactly that, so the text this
    branch wrote would have every local loader session open by reporting a
    failure that did not happen. Regression from round 1's fix.
  - *The Log's own skill-count correction had gone stale* — fixed. Commit
    077eaaf restored `skills/bootstrap/`, so five again. Regression from
    round 1's fix.
  - *A rule change never reaches an installed plugin* — documented, not
    fixed in code. Measured by the round: `claude plugin install` copies the
    tree into the cache under the manifest's `version`;
    `marketplace update` + `plugin update` answer `already at the latest
    version` and keep the old files; only a bumped `version` delivers new
    ones. `README.md` claimed the opposite and now states the measurement.
    Releasing is a decision for the human, not something to invent here — see
    the question below.
  - *The plugin ships the `bootstrap` skill, whose page said this repo
    dogfoods the loader* — fixed by the same settings restoration, which makes
    the claim true again; the page now also says both paths run here on
    purpose and that this is metis's exception.
  - *Coexistence duplicates the rulebook and every component, and `README`
    warned only about `core.hooksPath`* — fixed in `README.md`.
  - *The suite's criterion-1 case pins `claude plugin validate .`, which
    checks the marketplace manifest only* — open, and the next thing to do.
    The round reproduced it: reintroduce the unquoted-YAML defect in
    `agents/researcher.md` and `bash test.sh` stays exit 0 while
    `claude plugin validate .claude-plugin/plugin.json --strict` exits 1. The
    defect class this change had to fix can return with the suite green. Needs
    a test change, so it goes to the `test-author`, not to a fix here.
  - *The self-check reports "no problems" for a component that is present but
    unparseable* — dismissed with reason. Criterion 4 names the case "a part
    is missing"; a file that exists is not missing, and the gap it really
    points at is the validator missing from the suite, which the item above
    fixes. Filed as a note, not carried as a defect.
  - *Plugin root = repo root ships `docs/` and the suites to every consumer* —
    dismissed: it is the recorded cost of a recorded default, and the round
    says so itself.

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
