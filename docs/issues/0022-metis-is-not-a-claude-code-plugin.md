---
status: active
branch: claude/metis-plugin-0022
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
   marketplace and enables the plugin. **Superseded:** the dogfooded loader
   copy stays and is declared alongside the plugin — criterion 6 is open, so
   this repository must keep the path that works.
4. **Do not execute.** "Remove what the plugin replaces: `install.sh`, the
   `bootstrap` skill, the loader, the core, and the three suites that only
   guard them" — this is criterion 7's *first* branch, and criterion 6 does not
   hold. Review round 1 found it executed wrongly; commit 077eaaf restored
   everything, and `test-plugin.sh` now asserts all seven artifacts stay. This
   step becomes due only once criterion 6 is established.
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

- **Review round 3** (fresh context, whole intent): six findings. Trend across
  the rounds, findings per criterion:

  | criterion | R1 | R2 | R3 |
  | --- | --- | --- | --- |
  | 1 validate | 0 | 1 | 0 |
  | 3 rulebook text | 1 | 0 | 0 |
  | 4 self-check | 1 | 1 | 1 |
  | 7 branch in force | 2 | 0 | 0 |
  | 8 test.sh | 1 | 0 | 0 |
  | no criterion | 1 | 7 | 5 |
  | **total** | **6** | **9** | **6** |

  Facts the round established itself: `bash test.sh` 4 suites, 57 cases, exit
  0, nothing skipped; the same suite exit 1 on a scratch copy with the
  unquoted-YAML defect reintroduced, so round 2's open item is closed and case
  3b has teeth; both validate targets exit 0; `bash -n` over all 10 tracked
  `*.sh` plus `.githooks/pre-push` exit 0; `jq empty` over all 4 tracked
  `*.json` exit 0; no linter exists (`shellcheck`, `shfmt`, `markdownlint`,
  `yamllint`, `jsonlint` all missing; `eslint` and `ruff` are on PATH but
  `git ls-files '*.js' '*.ts' '*.py' '*.mjs'` returns nothing). Verdicts:
  criteria 1, 2, 3, 5, 7, 8 met; 4 **not met**; 6 not met and open.
- **Criterion 4 is not met, and round 2's dismissal of it was wrong.**
  *(Superseded by the round-4 entry below: the per-part comparison was
  implemented in `b2abb11` and the criterion is met.)*
  `hooks/session-start.sh:85` treats "count greater than zero" as success, so
  it detects total loss and never partial loss. Reproduced: remove
  `skills/plan/SKILL.md` from a copy of the tree and the status says
  `4 skills and 4 agents reachable; ... no problems` while five directories
  exist under `skills/`; add an old-layout `agents/planner/agent.md` and it
  says `5 skills and 4 agents reachable; ... no problems` while the tree holds
  five agents. The criterion's wording is "when a part is missing, the status
  says so instead of reporting success", and an absent `SKILL.md` is the
  plainest reading of missing. The code this replaces detects exactly that
  (`skills/bootstrap/assets/session-start-core.sh:102-106`,
  `skill without SKILL.md: <name>`), so the plugin hook is weaker than the
  loader it is meant to retire. Round 2's dismissal answered the case it was
  handed — a file that exists is not missing — but named the wrong gap: cases
  3b/3c guard this repository's tree at test time and do nothing for a session
  that loads an incomplete plugin. The suite cannot catch it either
  (`test-plugin.sh:489-491` removes *all* skills, *all* agents or the whole
  rulebook, never one of many), so those cases verify the code that exists
  rather than the criterion's wording.
- **The run is halted here by the human.** Not parked on a question: they were
  shown criterion 4 unmet with its reproductions and the estimated cost of
  fixing it, and chose to stop rather than fix it or open the pull request. No
  pull request exists, so no checkpoint 2 was recorded and no retro is due.
  `status` stays `active` rather than moving to `waiting`, because `waiting`
  means parked on a question and nothing else — this is a deliberate stop, and
  `active` is the state that makes the next session orient here and read this
  entry. Recorded as the judgment call it is.
- **The branch's suite is red, by design, and that is where it stops.**
  *(Superseded: `bash test.sh` exits 0 at `b2abb11`, 61 cases.)* The
  `test-author` run for criterion 4 had finished writing its cases before it
  was stopped, so `test-plugin.sh` carries them: 71 lines, seven failing
  assertions across three cases — a skill directory without its `SKILL.md` not
  named and success still reported, an old-layout `agents/planner/agent.md` not
  named and success still reported, and both together. `bash test.sh` therefore
  exits **1**, with the other three suites passing. This is the tests-before-code
  state the rulebook expects in the middle of a run, not a broken suite: the
  failing assertions are the proof that criterion 4 is unmet, and the
  implementer that makes them pass may not edit them.
  A correction to the record: the commit that halted the run first claimed
  `bash test.sh` exit 0. That was wrong — it was written from the run before
  the test cases landed, and the commit message was amended to say exit 1 with
  this reason.
- **What a next session finds open.** *(Superseded by the round-4 entry: only
  criterion 6 is still open.)* Criterion 4 needs a per-part comparison
  in `hooks/session-start.sh`; its tests already exist and are red.
  Criterion 6 still needs its exit code from a real cloud session, and the
  sharpest question behind it is whether the GitHub proxy's repository scoping
  lets a foreign project install from a github marketplace source at all.
  Three findings of round 3 were left unfixed on purpose, all of them
  documentation this branch itself made wrong: `AGENTS.md:160-168` still misses
  the world `README.md` creates — a project that declares the plugin but has
  nothing installed gets no status in a local session, and the bullet tells
  that session to report a failure that did not happen, while line 168 points
  at a log a plugin-only project never has; and `README.md:82-84` states as
  fact that a session here works with the checked-out tree, which is
  measurably false locally (`claude plugin list` → `No plugins installed`
  despite the declaration) and unproven in the cloud.
- **Two findings outside the criteria were filed for their own runs**, on the
  human's decision: issue 0023 (the plugin hook overwrites a project's
  existing `core.hooksPath` and reports success) and issue 0024 (the plugin
  ships and exposes the `bootstrap` skill, whose description tells a session to
  install the loader path into the consumer's repository).
- **A rule decision from the human, for the rulebook.** They rejected making
  the last review round before a pull request always fresh, because a fresh
  round can raise the finding count again and start another loop. The evidence
  from this run cuts both ways: R1 6 → R2 9 is exactly the effect they name,
  and it was the fresh R2 that found this repository had unwired itself while
  R3 found criterion 4 unmet after it had been wrongly dismissed. Their
  preference is intermediate rounds resumed rather than restarted. What the
  numbers actually blame for the loop is not the fresh context but fixing
  findings outside the criteria: 5 of 6 findings in R3 and 7 of 9 in R2 hang
  on no criterion, and round 2 repaired several of them instead of filing
  them, which made new diff for the next round to review. The rulebook already
  says such a finding goes to the human; applying that strictly is the cheaper
  half of the fix.
- **The scope was restored to the eight criteria, retroactively.** The human's
  rule — the scope is fixed, no feedback changes it, nothing outside it is
  fixed — was filed as issue 0027 and then applied to this branch. Reverted to
  `origin/main`: `README.md` (76 lines), `AGENTS.md`'s self-check bullet (13
  lines), and the paragraph added to `skills/bootstrap/SKILL.md`. No criterion
  asks for any of them; criterion 7 gates the `README.md` rewrite on criterion
  6 holding, and 6 does not hold, so that requirement never fired at all.
  Two of round 3's six findings are void rather than fixed by this:
  `AGENTS.md:160-168` and `README.md:82-84` were both statements this branch
  introduced and got wrong, and removing the text removes the falsehood.
  Documenting the plugin belongs to the change that makes it the delivery
  mechanism, which is criterion 7's first branch.
  One bounded correction stays: adding `test-plugin.sh` to `test.sh` made
  `skills/bootstrap/SKILL.md`'s enumeration of the suites incomplete, so it now
  names the fourth — criterion 8's own consequence, not new content.
  No fact was lost with the reverted text: the version-pinning measurement and
  the release-on-request decision live in this issue's Decisions and Log, not
  in `README.md`.
  What remains in the diff, per criterion: `.claude-plugin/*` and the quoted
  YAML in `agents/researcher.md` and `skills/clean-room/SKILL.md` (1) — round 4
  measured the second one: restore it from `origin/main` and
  `claude plugin validate .claude-plugin/plugin.json --strict` exits 1 with
  `frontmatter: YAML frontmatter failed to parse`; the flat `agents/<name>.md`
  layout (2);
  `hooks/hooks.json` and `hooks/session-start.sh` (3, 4, 5); the plugin
  declaration and the restored loader entry in `.claude/settings.json` (2-6,
  and 7's "all of them remain"); the flat-agent support in
  `skills/bootstrap/assets/session-start-core.sh` with its suite, which the
  layout change of criterion 2 forced and criterion 8 requires to stay green;
  `test-plugin.sh` and the `test.sh` line (8); the issue files (invariant 5).
  Fact after the revert: `bash test.sh` exits 1 with the same seven criterion-4
  assertions as before and 58 cases passing, so nothing the revert touched was
  load-bearing for the rest.
- **Pull request 26 was opened by the human** from the Claude Code UI at commit
  `522370d`, while the run was halted. `status` therefore moves to `done`, which
  the `issue` skill defines as "the pull request is opened" — not as "the
  criteria are met". Two of them are not: 4 and 6, with 8 failing as a
  consequence of 4.
  The generated body claimed the self-check "reports missing parts by name",
  which is exactly the part criterion 4 does *not* do, so the body was rewritten
  to carry the state per criterion, the suite's exit 1 with its reason, the
  static-analysis facts, and what is deliberately absent. A body that reads as
  finished in front of a red suite is the kind of claim invariant 4 exists
  against.
  No review round has read the current diff: round 3 read the tree before the
  scope restoration, which reverted three files afterwards. The rulebook's
  waiver covers a fix that touches only the tracker, and this one touched files
  the criteria are about, so a round is owed before the merge. Recorded as the
  open gap it is; the merge is the human's.
- **A fresh cloud session was reported by the human**, and it does not settle
  criterion 6. Its greeting carried the loader's status format — five skills,
  four agents, push guard, `commit 8064945`, no errors — and the plugin hook's
  format names no commit, so the plugin hook did not run in that session. Two
  readings remain open and the greeting cannot separate them: the plugin was not
  installed, or the session did not sit on this branch and never had the
  declaration in its tree at all. `8064945` is `main`'s tip and the loader
  clones `main` in any case, so it distinguishes nothing. What criterion 6 needs
  from such a session is `claude plugin list` with its exit code, plus the
  session's branch and the presence of `enabledPlugins` in its
  `.claude/settings.json`. The fact the greeting does establish: the loader path
  works in a fresh cloud session, which is why criterion 7's second branch keeps
  it.
- **Criterion 4 was implemented** in `b2abb11`: both loops in
  `hooks/session-start.sh` now compare every entry in the tree against what
  plugin discovery can read and name what it cannot — `skill without SKILL.md:
  <name>`, `agent not reachable: <name>`, the loader core's wording. The
  test-author's seven assertions pass without any test being edited.
  `bash test.sh`: 4 suites, 61 cases, exit 0.
- **Review round 4** (fresh context, whole intent): five findings, and seven of
  the eight criteria met, each by a command's exit code.

  | criterion | R1 | R2 | R3 | R4 |
  | --- | --- | --- | --- | --- |
  | 1 validate | 0 | 1 | 0 | 0 |
  | 3 rulebook text | 1 | 0 | 0 | 0 |
  | 4 self-check | 1 | 1 | 1 | 1 |
  | 6 cloud install | 0 | 0 | 0 | 1 |
  | 7 branch in force | 2 | 0 | 0 | 0 |
  | 8 test.sh | 1 | 0 | 0 | 0 |
  | no criterion | 1 | 7 | 5 | 3 |
  | **total** | **6** | **9** | **6** | **5** |

  Criterion 6 appears as a row only from round 4 on; the earlier rounds recorded
  it as open rather than counting it. Facts the round established itself: `bash
  test.sh` exit 0, 61 cases, 0 skipped, over four suites; both validate targets
  exit 0; `bash -n` over all 10 tracked `*.sh` plus `.githooks/pre-push` exit 0;
  `jq empty` over all 4 tracked `*.json` exit 0; no linter exists. It also
  proved the criterion-4 tests have teeth by mutation: the implementation
  reverted → 7 assertions fail; either `else` branch deleted alone → 3 fail;
  `problems` seeded non-empty to flag everything → 6 other cases fail, so the
  cheap pass is refused.
  Triage: *criterion 6* — not fixable from inside a container, it is the open
  criterion itself, and the round added a third negative measurement with its
  confounders named. *The record contradicting the diff* — fixed here.
  *The per-criterion list missing `skills/clean-room/SKILL.md`* — fixed above,
  with the round's measurement. *A component whose file is deleted entirely is
  still reported as "no problems"* — **dismissed with reason**: the plugin tree
  is its own only inventory, so nothing remains to compare against once a file
  is gone; `test-plugin.sh:60-62` excludes the case deliberately and says so;
  fixing it would mean inventing an expected-inventory list, which no criterion
  asks for. *A stale `core.hooksPath` after a version bump or an uninstall
  silently disables every git hook in a consumer project* — outside every
  criterion, reproduced, and not filed yet.
  Not filed either: the loader core is blind to an agent in the old nested
  layout, found by the implementer and left alone by it.
  The fixes from this round touch only the tracker record and the pull request
  body — no file the criteria are about — so the rulebook's waiver applies and
  the round is not repeated. Recorded as the judgment call it is.
- **A new fact about criterion 6**: this cloud environment sets
  `SKIP_PLUGIN_MARKETPLACE=true`. That is the likeliest reason no marketplace is
  ever configured and no plugin ever installed here, whatever
  `.claude/settings.json` declares. Not yet measured against a session without
  it, so it is a lead, not the answer.
- **The run was split on the human's instruction.** The plugin change and its
  record move to their own branch, `claude/metis-plugin-0022`; pull request 26
  keeps only the issues this run filed (0023 to 0027). `status` therefore
  returns to `active` and `pr` is cleared: the pull request that carried this
  change no longer does, and the `issue` skill's `done` means the change's own
  pull request is open.
- **Rebased onto `main` (`33f72bb`) by merge (`d91417f`)**, since `main` had
  independently resolved issues 0026 and 0027 (same file paths, different
  content) after this branch split off. Conflicts resolved by taking `main`'s
  completed versions of both files; everything else auto-merged cleanly,
  verified against `origin/main` and by content diff of `agents/reviewer.md`
  and `agents/researcher.md`. Facts after the merge: `bash test.sh` — 4
  suites, exit 0; `claude plugin validate .claude-plugin/plugin.json
  --strict` — exit 0; `claude plugin validate . --strict` — exit 0. Pushed
  to `origin/claude/metis-plugin-0022`. Criterion 6 is still open and needs
  one fresh cloud session opened on this branch, reporting `claude plugin
  list`'s exit code, to settle it.
- **Criterion 6, fourth measurement** — a genuine fresh cloud session,
  confirmed via `git rev-parse HEAD` == `d5fbc16114cfc64a285a0daee9710f6d70c988fb`
  (this branch's actual pushed tip, not a self-probe from inside a
  container): `claude plugin marketplace list` reported "No marketplaces
  configured", and `claude plugin list` showed four plugins from the
  claude.ai registry (`artkoenig-skills`, `engineering`, `data`,
  `cowork-plugin-management`), none of them `metis`. This repeats
  measurement 1's result, but this time from a real cloud-session bootstrap,
  so it can no longer be dismissed as a workspace-trust artifact of probing
  from inside a container. It does not contradict the cloud-environment
  documentation: the documentation's guarantee is qualified — "Installed at
  session start from the marketplace you declared. Requires network access
  to reach the marketplace source" — and this repository's own
  `.claude/settings.json` declares a directory source (`path: "."`), not a
  network source. So this measurement settles the directory-source case
  negatively, and leaves the github source — the one `README.md` actually
  tells consumers to use — untested. The human caught the premature
  conclusion that this contradicted the documentation before it was
  recorded as such.
- **`.claude/settings.json` switched to the github source for the next
  measurement**, commit `52ba613`: `{"source": "github", "repo":
  "artkoenig/metis", "ref": "claude/metis-plugin-0022"}`, matching the
  schema `github: {repo, ref?, sha?}` from the plugin-marketplaces
  reference. The `ref` names this branch so the marketplace can be found
  before the merge — a temporary value, per the assumption already
  recorded in checkpoint 1, and it must be dropped or changed once
  criterion 6 is settled and this branch is ready to merge. `bash test.sh`
  still exits 0, 4 suites, after the change. Needs one more fresh cloud
  session on this commit, reporting `claude plugin marketplace list` and
  `claude plugin list`, to settle criterion 6 for the source consumers
  actually use.
- **Criterion 6, fifth measurement** — a real fresh cloud session on commit
  `11831c0` (github source, `ref: claude/metis-plugin-0022`), confirmed via
  the settings file the human pasted back matching what was pushed: `claude
  plugin marketplace list` → "No marketplaces configured", exit 0; `claude
  plugin list` → "No plugins installed", exit 0. Same negative result as the
  directory source. The human confirmed `SKIP_PLUGIN_MARKETPLACE=true` is
  also set in this session. That variable is not documented on
  `code.claude.com`'s environment-variables or cloud-environments pages, and
  a web search found no independent source describing its scope either — its
  exact effect is unconfirmed. It remains, as an earlier entry in this Log
  already said, "the likeliest reason no marketplace is ever configured and
  no plugin ever installed here, whatever `.claude/settings.json`
  declares... not yet measured against a session without it, so it is a
  lead, not the answer." Two real cloud sessions, two different marketplace
  source types, identical negative result, both with this variable set: the
  common factor is the variable, not the source type, but nothing here rules
  the source type out on its own, since no session without the variable has
  been measured. Criterion 6 stays open; a session in an environment that
  does not set `SKIP_PLUGIN_MARKETPLACE` is what would separate the two
  explanations.
- **A documented gate found in `/docs/en/discover-plugins#configure-team-marketplaces`**
  (fetched as raw markdown via `curl`, not summarised, after the WebFetch tool
  truncated the settings page twice before reaching this section): "As of
  Claude Code v2.1.195, this install step applies on every path that loads
  plugins. A plugin that only the project's `.claude/settings.json` enables,
  and that comes from an external source such as a GitHub repository or npm
  package, doesn't load until the team member installs it. Until then,
  Claude Code reports the plugin as not installed and shows the `claude
  plugin install` command to run." This session runs `claude` 2.1.220, after
  that change. It fully explains the github-source negative result
  (measurement 5): an external-source plugin declared only in project
  settings needs a per-user consent step a non-interactive cloud session
  cannot perform.
  It does not fully explain the directory-source result (measurement 4): the
  quoted text specifically scopes the gate to "an external source such as a
  GitHub repository or npm package," and a `directory` source pointing at
  the already-checked-out working tree is not that. Both measurements also
  reported "No marketplaces configured" rather than "found, install needed,"
  which is not the message this gate's own description predicts. So the
  gate is a confirmed, documented cause for one of the two negative results
  and not, on its own, a full explanation for the other; `SKIP_PLUGIN_MARKETPLACE`
  remains the standing candidate for the directory-source case, still
  unconfirmed. `cloud-environments.md`'s claim ("Installed at session start
  from the marketplace you declared") and this gate read as in tension for
  the github source specifically; which one describes the actual cloud
  bootstrap path is not resolved by anything measured so far.
- **`SKIP_PLUGIN_MARKETPLACE` cannot be overridden through the documented
  mechanism.** The human set it to `false` as an environment variable in the
  environment dialog at claude.ai/code — the place the settings
  documentation says session environment variables are configured — and a
  new cloud session still reported it as `true`, with the same negative
  result as every prior measurement. Either something in this account's
  environment forces the value regardless of the per-environment
  configuration, or a different, unidentified layer sets it after the
  session's own environment copy runs. Either way, the variable is not
  something this investigation can toggle to test its effect, so the
  directory-source case (measurement 4) stays open with `SKIP_PLUGIN_MARKETPLACE`
  as an unconfirmed, now unfalsifiable-from-here candidate.
- **The human's request to search for how other repositories handle this**
  surfaced a confirmed, closed bug report that settles criterion 6.
  `anthropics/claude-code` issue #32606, "extraKnownMarketplaces +
  enabledPlugins in project settings never prompts user to install": a
  project's `.claude/settings.json` declaring `extraKnownMarketplaces` and
  `enabledPlugins`, exactly the mechanism `cloud-environments.md` and
  `discover-plugins.md` document, tested by that reporter across 12+
  repositories with an identical configuration — none triggered the install
  prompt or populated `installed_plugins.json`. **Status: closed as not
  planned**, no maintainer comment confirming a fix or a documentation
  correction. A second, related report, issue #51806, found the same root
  shape from the CLI side: `/plugin marketplace add` writes to
  `settings.json`'s `extraKnownMarketplaces`, but plugin discovery reads a
  separate internal cache (`~/.claude/plugins/known_marketplaces.json`) that
  the write never reaches — closed as a duplicate of the same underlying
  gap.
  This matches every measurement in this Log: three real cloud sessions,
  two source types, one `SKIP_PLUGIN_MARKETPLACE` override attempt, all
  negative, all with the identical "no marketplace configured" shape #32606
  describes. It also means the source-type question (directory vs. github)
  and the `SKIP_PLUGIN_MARKETPLACE` hypothesis were never the deciding
  factor: the declare-only mechanism this repository's `.claude/settings.json`
  uses does not work, confirmed by a third party and left unfixed by
  Anthropic, independent of source type or environment variable.
  **Criterion 6 is settled: not met**, by the strongest evidence available
  without filing a new report against Anthropic — five own measurements
  plus a maintainer-closed bug report describing the identical failure.
  Criterion 7's second branch is therefore not a temporary state pending
  proof; it is what the documented mechanism's confirmed unreliability
  requires. The loader, the installer, the bootstrap skill and their
  guarding suites stay.

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

Recorded after the pull request was opened, not before it: the human opened
pull request 26 from the Claude Code UI while the run was halted. The answers
are the state at that moment.

- **Does this match what was asked?** In part, and the parts are named. Metis
  is a plugin: a session that loads it has the rulebook text, five skills, four
  agents and the push guard, each shown by a suite case. *Corrected after
  criterion 4 was implemented in `b2abb11` and review round 4 read the result:*
  seven of the eight criteria are met, each by an exit code; only criterion 6 is
  not, because no exit code establishes the cloud install. Nothing was therefore
  removed and the loader path stays, which is what criterion 7's second branch
  prescribes. `bash test.sh` exits 0 over four suites and 61 cases.
  *(The first version of this answer, written while the run was halted, said
  criteria 4 and 8 were unmet as well; that was true when written.)*
- **What surprised me?** That the criteria were never what made this run long.
  Of 21 findings across three rounds, 13 belonged to no criterion, and
  repairing them was what produced the next round each time. Two regressions
  came out of my own round-1 fixes. My round-2 dismissal of criterion 4 was
  wrong and round 3 proved it with three reproductions. And the smallest
  surprise with the longest reach: a documentation claim I wrote into
  `## Decisions` as a flat fact deleted the loader path for a while.
- **What am I assuming without having verified it?** That the seven failing
  assertions are the whole distance between criterion 4 and a green suite —
  nobody has implemented the per-part check, so that is an estimate, not a
  fact. That the current diff would survive a review round: round 3 read a
  different diff, because the scope restoration afterwards reverted three
  files. Two assumptions from checkpoint 1 are now settled facts and no longer
  assumed: `.claude-plugin/marketplace.json` carries `"source": "./"` and no
  branch `ref`, so nothing temporary survives the merge, and the manifest's
  `"license": "GPL-3.0-or-later"` matches the repository's `LICENSE`.

## Retro

**What got in the way, biggest first.**

- *The scope moved while the run was in progress.* 13 of 21 findings across
  three rounds belonged to no criterion, and repairing several of them produced
  the diff the next round then reviewed. `README.md` grew by 76 lines nobody had
  asked for. The rule against this already existed in the rulebook and I broke
  it. Filed as issue 0027, then applied to this branch retroactively on the
  human's instruction, which removed 95 lines.
- *A documented claim entered `## Decisions` as a flat fact*, and the loader
  path was deleted on it while criterion 6 was open. The `issue` skill already
  asks for a decision's source, and this one had a source — a document. What is
  missing is that a document is not an exit code, so a decision resting on one
  cannot license an irreversible step. This is the run's most expensive single
  mistake and the only retro item not yet filed as an issue.
- *Every review round paid for a whole fresh context.* Four rounds, 277 model
  steps, 15.9M cache-read tokens, 60% of everything the run's ten subagent
  dispatches consumed, and round 3 cost as much as round 2 while finding a third
  as many things. Filed as issue 0026, with the human's decision on how far to
  go.
- *What a run costs was invisible* until it was measured by hand from the
  session's own transcripts. Filed as issue 0025.
- *One reviewer result never reached the dispatching session*, so 74 steps and
  4.5M cache-read tokens bought nothing and the round was relaunched. Recorded
  in issue 0026, where a continued reviewer changes what such a loss costs.
- *Two regressions came out of my own round-1 fixes*, and my round-2 dismissal
  of criterion 4 was wrong — round 3 proved it with three reproductions. The
  rulebook's repetition and regression signals both fired and both worked; what
  they did not do is stop the growth of the diff, which is issue 0027's subject.

**What should change, beyond the issues already filed.**

- A decision whose source is documentation is marked as such and may not
  license a deletion. The proof is criterion 6's shape — it demands an exit code
  and says an assumption recorded as a fact fails it — and that shape belongs in
  the rulebook or the `issue` skill rather than in one issue's criteria. Not yet
  filed; it needs the human's word on where it belongs.
- Chain a verification and the commit that reports it with `&&`, never `;`. This
  run committed a red suite with a message claiming exit 0 because of that one
  character, and the message had to be amended.
