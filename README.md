# metis

> An AI agent workflow built on judgment, not rules — a few invariants,
> self-correction in the loop, and a human only where it matters.

**Metis** is the Greek titaness of practical wisdom, and in Greek the word
itself: the ability to do the right thing in the moment, rather than follow
a plan. That is this project's principle, not just its name.

## How it works

The rulebook is one page: [`AGENTS.md`](AGENTS.md). Its core is **judgment
for process, mechanics for facts** — everything procedural is the agent's
call, every time; rules remain only where self-assessment fails. A fact like
"the tests pass" comes from an exit code, never from the agent's impression.

Five invariants hold for every change, whatever process judgment picks:

1. The intent — acceptance criteria — is written down before any code.
2. The tests for those criteria are written first — blind, by the
   test-author — and seen to fail; a change with nothing to run says so
   instead.
3. A fresh context reviews the diff against the written intent before the
   PR, with a concrete reproduction per finding — for a change with nothing
   to run, this review is the only check it gets.
4. The suite and static analysis pass, shown by exit code; where nothing
   exists to run, that absence is the reported fact.
5. Decisions, surprises and checkpoint answers are recorded in the issue as
   they happen — the record outlives the session.

```
idea → issue with acceptance criteria → checkpoint 1
     → test-author (failing tests)    → implementer
     → reviewer (fresh context)
     → checkpoint 2 → PR → human merges → retro
```

The human steers at three points only: approving the criteria when the idea
is genuinely unclear, deciding anything irreversible or outward-facing, and
merging the PR.
Everything heavier — grilling, planning, a clean-room second opinion — is a
tool on the shelf, picked by judgment, never fired by a condition.

**The workflow corrects itself through the retro.** After every PR the agent
records what got in the way and what should change. A rule that misfired
becomes a proposal: a pull request against this repository, decided by the
human like any other. And because every project gets the rulebook from this
repository rather than from a copy of its own, an accepted rule change can
reach all of them — through the plugin it takes a released version, see
below. The rulebook is not maintained — it is grown, run by run, out of its
own failures.

## Installing it

Metis is a Claude Code plugin, and this repository is the marketplace that
offers it. In your project:

```
claude plugin marketplace add artkoenig/metis
claude plugin install metis@metis
```

The plugin carries the rulebook, the four subagents and the skills. Its
`SessionStart` hook puts the rulebook text into every session, reports a
self-check status, and points the project's git hooks at the push guard that
refuses a direct push to the default branch.

For a cloud session, declare the plugin in the project so the session has it
from the start — commit this as `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "metis": {
      "source": { "source": "github", "repo": "artkoenig/metis" }
    }
  },
  "enabledPlugins": { "metis@metis": true }
}
```

This repository declares its own plugin the same way, but from
`{"source": "directory", "path": "."}`, so a session here works with the
checked-out tree rather than a release.

**Installing does not track this repository.** `claude plugin install` copies
the tree into the plugin cache under the version in
`.claude-plugin/plugin.json`. Measured with a github source:
`claude plugin marketplace update metis` followed by
`claude plugin update metis@metis` answers `already at the latest version`
and the cache keeps the old files; only a changed `version` in the manifest
delivers the new ones. So a rule change reaches installed projects when it is
released with a version bump, not when it is merged.

Whether a cloud session really performs the declared install before it starts
is documented but not yet shown by an exit code. Until it is, the older path
stays in this repository and keeps working:

```
curl -fsSL https://raw.githubusercontent.com/artkoenig/metis/main/install.sh | bash
```

It installs and commits a `SessionStart` hook that clones this repository and
links the rulebook, subagents and skills into `~/.claude` — the mechanism the
plugin is meant to replace, and the one that always carries the current
`main`. A project already running it needs to change nothing.

Running both is what this repository itself does while the plugin path is
unproven, and it has two costs worth knowing. Each path sets the project's
`core.hooksPath`, so the hook that runs last decides which push guard is
used. And both deliver the rulebook and every skill and agent — the plugin
into the session's context, the loader into `~/.claude` — so a session holds
each twice, from two trees that need not agree. For any project other than
this one, pick one.

To own the feedback loop — retros landing as rule changes in *your* rulebook
— fork this repository and install the plugin from your fork.
