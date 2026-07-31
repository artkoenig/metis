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
4. `claude plugin validate .claude-plugin/plugin.json` still exits 1 when an
   agent's frontmatter fails to parse.
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

- **Criterion 4 covers the plugin-manifest validation only.** Its first
  wording asked both validations to reject a broken agent. The `test-author`
  measured that the marketplace-manifest validation never opens an agent: with
  `agents/researcher.md`'s `description` made unparseable,
  `claude plugin validate <repo root>` and
  `claude plugin validate .claude-plugin/marketplace.json` both exit 0, while
  `claude plugin validate .claude-plugin/plugin.json` exits 1 on the
  frontmatter. A case built on the marketplace half would have passed on a
  defect-free tree, so the criterion was narrowed before implementation
  started. Source: the `test-author`'s measurement.

- **`README.md` need not name the update commands.** Criterion 6 asks the
  README to match criterion 2 and to name no version bump as a condition; it
  does not ask it to spell out `claude plugin marketplace update` and
  `claude plugin update`. "Updates included, no re-installation" is the
  promise the human's text already makes, and naming a command is not part of
  what this issue fixes. Source: default, unanswered — recorded rather than
  put to the human, because it changes no observable behaviour of the plugin.

- **Criterion 6's first half is not covered by the suite, on purpose.**
  Whether the README's prose "matches criterion 2" is a judgement, and two
  attempts to mechanise it failed in opposite directions within one round of
  each other — a README saying *"is not updated … never arrives … delete the
  plugin and add it back"* passed, while re-wrapping the unchanged promise
  across a line break failed. The negative half stays tested, because "names
  no version, release, bump or publish step" is a word blocklist and a
  blocklist is the right instrument for it. The first half is established by
  the fresh-context review, which is what invariant 3 exists for and which
  has now confirmed the shipped README twice. Source: default, unanswered —
  it changes no behaviour of the plugin, only what the suite claims to check.

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
  defect class issue 0022 cared about survives the flag's removal.

  **Superseded by review round 1.** The sentence that followed — *"only the
  missing-version warning does not"* — was false. `--strict` also caught
  manifest warnings that nothing else catches: with `repository` misspelled
  `repositry` in `.claude-plugin/plugin.json`,
  `claude plugin validate .claude-plugin/plugin.json` exits 0 while
  `… --strict` exits 1 with *"Unknown field 'repositry'. Claude Code ignores
  it at load time."*; a removed `description` behaves the same way. On this
  branch, `repositry` in the manifest lets `bash test-plugin.sh` exit 0.
  Component frontmatter is unaffected — a broken `SKILL.md` and a broken
  agent both exit 1 without `--strict`.

- The `test-author` wrote the cases into `test-plugin.sh` and proved them red:
  `bash test-plugin.sh` exits 1 with `FAIL: 2 case(s)` — criterion 1
  (*"version pin: plugin.json declares version '0.2.0'"*) and criterion 2
  (*"the installed AGENTS.md does not carry the change committed after the
  install: metis is already at the latest version (0.2.0)"*). Criteria 3–6 are
  preserve criteria and pass today by construction. Reachability was shown on
  a scratch copy with only the `version` key deleted: `bash test-plugin.sh`
  exits 0, `bash test.sh` exits 0 over all 3 suites.

- A user-scope install of the plugin into this container's real home
  (`claude plugin install metis@metis`, exit 0) resolves to
  `cache/metis/metis/0.2.0` at `gitCommitSha a305f334` and contains no
  `install.sh` and no `skills/bootstrap/`, but does contain `skills/cost/`.
  So a *fresh* install under a pinned version does carry current `main`; only
  an install that already exists stays frozen. That refines issue 0037, whose
  observation came from a cache written before the loader was removed.

- **Review round 1** (fresh context, `86567f6..ae6fd50`): 3 findings, each
  reproduced. It established `bash test.sh` exit 0 over 3 suites and 57 cases
  with none skipped, found no static analysis in the repository to run
  (`shellcheck` is not installable behind the proxy; `bash -n` over all six
  scripts exits 0), and mutation-verified that cases 25 and 26 are
  load-bearing for both halves of criterion 1. Triage:

  - *The Log claimed `--strict` only guarded the missing-version warning* —
    fixed above, and the coverage it really loses is filed as issue 0041. The
    flag cannot be kept: criterion 1 removes the version, and `--strict` then
    fails on its absence.
  - *Case 27 does not falsify criterion 6's first half* — sent back to the
    `test-author`. A README claiming the opposite outcome ("frozen at the
    commit you installed, re-install to update") passes the case today.
  - *A stranded comment in `test-plugin.sh` now makes two contradicting
    claims about "criterion 6"* — one about issue 0022's, one about this
    issue's — *and the block names no case for criterion 5* — sent back to
    the `test-author` with it.

- `main` moved from `004d46e` to `a305f33` during the run (PR #35, the
  `AGENTS.md` shortening) and was merged into this branch; `bash test.sh`
  exits 0 over 3 suites on the merged tree. Issue numbers do not collide —
  `main` still ends at `0039`.

- **Review round 2** (same context continued, `a305f33..9d1b4d7`): 3 findings.
  It re-established `bash test.sh` exit 0 over 3 suites and 57 cases, re-ran
  the mutation on cases 25 and 26, confirmed round-1 finding 2 fixed (the
  counter-README now exits 1 naming lines 61 and 62), and confirmed the merge
  of `a305f33` leaves nothing in this diff stale — the rulebook rewrite
  changed no issue template, and `README.md` still matches the new
  `AGENTS.md`. Triage:

  - *Case 27's replacement accepts a README stating criterion 2's opposite,
    and fails on a pure reflow* — two findings, one cause. See the decision
    below: the approach changed instead of the regex.
  - *The criterion-5 comment gives a false reason* — `test-loader-removed.sh`
    does run `bash test.sh` from inside a `test.sh` run; what stops
    `test-plugin.sh` doing the same is the `METIS_TEST_SH_NESTED` guard not
    exempting it. Sent back with the above.

- **Repetition signal, and the approach changed.** Two rounds in a row found
  the same defect class in the same check: a regex deciding whether prose
  "matches criterion 2". Round 1 found it too permissive, round 2 found it
  both too permissive *and* too strict. The finding count did not decrease
  (3, then 3), one round short of the rulebook's stop-and-ask.

- **Review round 3** (same context continued, `a305f33..a6ccf17`): 1 finding.
  It re-established `bash test.sh` exit 0 over 3 suites and 57 cases, verified
  the corrected criterion-5 comment against the code it cites
  (`test-loader-removed.sh:201-203`, `test.sh:23-30`), confirmed both of round
  2's false failures now pass, and read `README.md` against criterion 2
  itself — met, and `grep -ic "version\|release\|bump\|publish" README.md`
  returns 0. Triage:

  - *The surviving blocklist is disarmed by any denial word on the same line*
    — fixed by deleting the `denial` exemption, not by another expression.
    Reproduction: *"a merged change arrives after the next release, with no
    re-installation needed"* passed the case, because the `no` in
    *"no re-installation"* exempted the whole line. The exemption was never
    load-bearing: the shipped README contains no blocklist word at all. The
    cost is recorded in the suite — a future README wanting to say *"no
    version bump is needed"* now fails the case, deliberately.

  Finding count across the rounds: 3, 3, 1. It decreased, so the rulebook's
  stop-and-ask did not trigger. What repeated three times is the defect class
  in one case, and each round answered it by removing machinery rather than
  adding it.

- **The reviewer's judgement on where criterion 6's first half landed**, asked
  for explicitly: acceptable, because invariant 3 is what a change producing
  no facts by exit code is checked by, because the surviving half asks a word
  question a blocklist can answer, and because nothing in the plugin's
  behaviour depends on it. It named the residual risk: a future run that
  rewrites `README.md` gets its own reviewer checking that diff against *that*
  run's intent, and nobody will check it against this issue's criterion 2
  again. Guarding that mechanically would be its own issue, not a fourth
  regex.

- One thing the reviewer could not establish by exit code and did not raise as
  a finding: the CLI's plugin auto-update is asynchronous — it notifies
  *"Plugins updated: … Run /reload-plugins to apply"* — so the first session
  after a merge can still be one refresh behind. Criterion 2 does not speak to
  it, and there is no headless way to reproduce the timing.

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

- **Does this match what was asked?** Yes. The human reported that plugin
  versions do not update in claude.ai and chose, from three measured options,
  to drop the `version` field. The production change is one deleted line;
  everything else in the diff is the suite that guards it, this record, and
  issue 0041 for the coverage the change gives up.
- **What surprised me?** Three rounds in a row found the same defect class in
  one test case, every time a regex judging prose. Each round answered by
  removing machinery — the positive half, then the denial exemption — and the
  count went 3, 3, 1, 0. Also: a *fresh* install under a pinned version does
  carry current `main`; only an install that already exists freezes. That is
  not what issue 0037's observation suggested.
- **What am I assuming without having verified it?** That the commit-SHA
  fallback behaves for the `github` source the way it did for the local
  `directory` fixture the suite drives. The documentation states it for both
  and criterion 2 does not distinguish them, but every exit code in this run
  came from a `directory` source. The first real update of the installed
  plugin after this merges is what will settle it.

- **Review round 4** (same context continued, `a305f33..9e37a76`): **0
  findings** — converged, 3, 3, 1, 0. It re-established `bash test.sh` exit 0
  over 3 suites and 57 cases, confirmed the round-3 hole closed and neither
  round-2 false failure resurrected, re-ran the restored-pin mutation on cases
  25 and 26, checked the accepted cost by exit code (a README saying *"no
  version bump needed"* now fails, and the failure message states the rule),
  read `README.md` against criterion 2 a third time, and checked this record
  against the diff. One optional improvement it raised without making it a
  finding — the case title and pass message say *"as a condition"* while the
  check enforces "not named at all" — was **not taken**: the understatement
  never asserts more than the check established, the failure message states
  the stricter rule at the moment an author hits it, and re-opening the case a
  fourth time for a wording nicety is the machinery this run kept removing.

## Retro
