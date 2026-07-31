---
status: backlog
branch:
pr:
---

# A misspelled manifest field passes the suite

## Intent

Issue 0040 removed the `version` key from `.claude-plugin/plugin.json` so that
every commit reaches an installation. That forced `--strict` out of the two
`claude plugin validate` cases in `test-plugin.sh`: without a version the flag
turns the *"No version specified"* warning into an error and the validation
exits 1 on a defect-free tree.

`--strict` was also the only thing catching a second class of defect: manifest
fields the CLI silently ignores at load time. Measured by review round 1 of
issue 0040 on `claude` 2.1.220, against a tree with the version still present
so the version warning is out of the way:

- `.claude-plugin/plugin.json` with `repository` misspelled `repositry` —
  `claude plugin validate .claude-plugin/plugin.json` exits 0,
  `… --strict` exits 1 with *"Unknown field 'repositry'. Claude Code ignores
  it at load time."*
- the same manifest with `description` removed — plain exits 0,
  `--strict` exits 1.

And on the tree issue 0040 shipped: with `repositry` in the manifest,
`bash test-plugin.sh` exits 0 and every case passes. A manifest key that the
plugin loader drops on the floor now gets past the whole suite.

Component frontmatter is not affected — a `SKILL.md` or an agent whose
frontmatter does not parse makes `claude plugin validate
.claude-plugin/plugin.json` exit 1 without `--strict`, and issue 0040's
criterion 4 pins that.

Wanted observable behaviour: a manifest field the CLI ignores at load time
fails the suite, without the suite depending on a `version` key.

Acceptance criteria:

1. When `.claude-plugin/plugin.json` declares a field the CLI does not know —
   `repository` misspelled `repositry`, for instance — `bash test-plugin.sh`
   exits non-zero and names the offending field.
2. When `.claude-plugin/plugin.json` is missing a field the CLI warns about —
   `description`, for instance — `bash test-plugin.sh` exits non-zero.
3. Neither check requires a `version` key in `.claude-plugin/plugin.json` or
   in the `metis` entry of `.claude-plugin/marketplace.json`; with the tree as
   issue 0040 leaves it, `bash test.sh` exits 0.

## Plan

## Tasks

## Decisions

## Log

- Found by review round 1 of issue 0040, outside that issue's criteria — no
  criterion of 0040 requires the warning class to stay covered — and filed
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
