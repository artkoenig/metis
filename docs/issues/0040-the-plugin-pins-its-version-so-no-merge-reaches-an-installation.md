---
status: active
branch: claude/metis-plugin-version-update-o7sgio
pr:
---

# The plugin pins its version, so no merge reaches an installation

## Intent

`.claude-plugin/plugin.json` declares `"version": "0.2.0"`. Claude Code
resolves a plugin's version from that field first, and an installation whose
resolved version is unchanged keeps its cached copy — so every commit merged
into `main` since the bump on 2026-07-30 has reached no installation at all.
Roughly thirty commits are affected, among them the removal of the loader
that issue 0037 observes still sitting in the installed `0.2.0` cache.

The human reports seeing `0.1.0` in claude.ai: the same mechanism one step
earlier, an installation pinned to a version string older than the one in the
repository.

`README.md` promises the opposite — that a session with the plugin active has
"the rulebook, subagents and skills of the current `main` — updates included,
no re-installation". With a pinned version that is false.

Wanted observable behaviour: a change merged into `main` reaches an
installation with its next update, without anyone editing a version string.

Acceptance criteria:

1. `.claude-plugin/plugin.json` declares no `version` key, and the `metis`
   entry in `.claude-plugin/marketplace.json` declares no `version` key
   either.
2. When the plugin is installed from a marketplace whose source is this
   repository, and a further commit then changes a tracked file that the
   plugin ships, `claude plugin marketplace update` followed by
   `claude plugin update` yields an installed plugin directory whose copy of
   that file carries the changed content — with no version string edited
   anywhere.
3. `claude plugin validate` over this repository's marketplace manifest and
   over `.claude-plugin/plugin.json` exits 0.
4. Each of those two validations still exits 1 when an agent's frontmatter
   fails to parse.
5. When `test.sh` runs, it exits 0, and every suite it names exists.
6. `README.md` describes what an installation receives in a way that matches
   criterion 2, and names no version bump or release step as a condition for
   a change to arrive.

## Plan

## Tasks

## Decisions

- **The `version` field goes, and versions resolve from the commit SHA.**
  Source: the human, asked how the plugin version should resolve, chose
  "`version`-Feld entfernen". This supersedes issue 0022's decision
  *"Releases happen on request"* — that decision pinned the plugin on purpose
  and is the direct cause of this issue.

- **`--strict` leaves the two `claude plugin validate` cases in the suite.**
  Source: measured, not chosen. Without a `version` key both validations warn
  *"No version specified"*, and `--strict` turns that warning into an error:
  `claude plugin validate . --strict` exits 1 and
  `claude plugin validate .claude-plugin/plugin.json --strict` exits 1, while
  the same commands without `--strict` exit 0. Criterion 4 exists so that
  dropping the flag is not a silent loss of coverage.

## Log

- The version resolution was measured against a local marketplace fixture,
  two runs, `claude` 2.1.220:

  | `plugin.json` | new commit, no bump | result |
  | --- | --- | --- |
  | `"version": "0.2.0"` | yes | `plugin update` → *"already at the latest version (0.2.0)"*, cache keeps the old file |
  | no `version` key | yes | cache keyed by commit SHA, *"updated from f211b4cac41e to eea7fb26507b"*, new file delivered |

- A fresh install of the real plugin from GitHub into an isolated `HOME`
  (`claude plugin marketplace add artkoenig/metis`,
  `claude plugin install metis@metis`, both exit 0) resolves to
  `cache/metis/metis/0.2.0` with `gitCommitSha 004d46e` — the publishing path
  itself works, only the pinning blocks updates.

- The `--strict` loss was bounded by measurement: with the `version` key
  removed and `agents/researcher.md`'s `description` made unparseable,
  `claude plugin validate .claude-plugin/plugin.json` *without* `--strict`
  reports `frontmatter: YAML frontmatter failed to parse` and exits 1. The
  defect class issue 0022 cared about survives the flag's removal; only the
  missing-version warning does not.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes. The human reported that plugin
  versions do not update and chose, from three measured options, to drop the
  `version` field. The issue carries exactly that and the two things it drags
  along: the `--strict` flag and the `README` claim.
- **What surprised me?** That `README.md` already promises what this change
  makes true. Issue 0022 recorded that the README had been corrected to state
  the measurement; the current text says the opposite again, so the
  correction was lost in a later rewrite.
- **What am I assuming without having verified it?** That the SHA-based
  fallback behaves for the `github` source the way it did for the local
  `directory` fixture I measured — the documentation states it for both, but
  my exit codes cover only `directory`. Criterion 2 does not distinguish the
  source types, so a suite case for the github source is not owed; the
  assumption is recorded here instead.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
