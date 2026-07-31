---
status: active
branch: claude/offene-issues-4rv8ah
pr:
---

# Unused tool schemas cost every session about 15,000 tokens per step

## Intent

Every request in a Claude Code session re-sends the whole tool schema set, so a
tool nobody calls is still paid for at every step. Measured in this
repository's own session: six eagerly loaded tools the Metis workflow never
uses — `Workflow`, `Artifact`, `ScheduleWakeup`, `SendUserFile`,
`ShowOnboardingRolePicker`, `ReportFindings` — are together about 15,060 tokens
of every request. Over that session's 135 steps this is 2.03 million cache-read
tokens, 12.9% of the whole session.

Established by measurement: five fresh headless sessions in an empty directory,
identical except for tool configuration. Total step-1 prompt
(`cache_creation` + `cache_read` + `input`) read from each session's own
transcript:

| configuration | step-1 prompt |
| --- | --- |
| all tools (today's default) | 42,605 |
| `--tools` limited to 8 built-ins | 28,287 |
| `--tools` limited to 10 built-ins | 28,292 |
| `--disallowedTools` naming the 6 tools | 27,546 |
| `.claude/settings.json` with `permissions.deny` naming the same 6 | 27,545 |

`permissions.deny` removes a tool's schema from the request rather than merely
blocking the call: the settings-file variant and the CLI-flag variant differ by
one token. Denying six tools by name beats whitelisting ten via `--tools`
(27,545 against 28,292), so the cost is concentrated in a few long schemas.

The plugin cannot ship such a list. Plugin-level `settings.json` applies only
the allowlisted keys `agent` and `subagentStatusLine`; `permissions` in
`plugin.json` fails `claude plugin validate --strict`, which `test-plugin.sh`
case 4 runs and requires to exit 0. The list can only live in the consuming
repository's `.claude/settings.json`, which a plugin cannot write on its own.

Measured: the list takes effect only in sessions started after it is written. A
fresh session without it answers "Yes" when asked whether it has a tool named
`Workflow`; the same session resumed after the list is written still answers
"Yes"; a fresh session with the list answers "No".

Wanted observable behaviour: the plugin ships a skill a human runs once per
repository. It measures what that repository's sessions actually load, proposes
which tools to deny together with what the proposal saves, lets the human keep
any of them, and writes the agreed list into `.claude/settings.json` — creating
the file, or merging into one that already exists.

Acceptance criteria:

1. The plugin ships a skill whose page states what it does and how it is
   invoked, and `bash test.sh` names every suite this change adds.
2. Invoking the skill establishes the repository's current step-1 prompt size
   by starting a fresh headless session and reading that session's own
   transcript, and reports that number.
3. The list the skill proposes contains only eagerly loaded tools, and never
   contains `Skill`, `Agent`, `AskUserQuestion`, `ToolSearch`, `Read`, `Write`,
   `Edit`, `Glob`, `Grep` or `Bash`.
4. The skill shows the human the proposed list before writing anything, and an
   entry the human removes from it is absent from what is written.
5. The skill establishes the step-1 prompt size a second time with the agreed
   list applied, and reports both numbers and their difference.
6. Run against a repository with no `.claude/settings.json`, the skill creates
   that file, and the created file's only key is `permissions.deny` holding the
   agreed list.
7. Run against a repository that already has `.claude/settings.json`, the skill
   leaves every key already present unchanged, and an existing
   `permissions.deny` list keeps its entries alongside the new ones.
8. The skill's output states that the written list applies only to sessions
   started after it is written, not to the session that ran the skill.
9. This repository's own `.claude/settings.json` carries such a deny list, and
   `bash test.sh` exits 0 with it present.

## Plan

## Tasks

## Decisions

- **Shipped as a skill, not as documentation.** The plugin cannot deliver a
  deny list through its own settings or manifest (measured against `claude`
  2.1.220), so the only thing it can ship that acts on a consuming repository
  is a skill the human invokes. A skill's entry in the session-start skill
  listing costs 300–560 characters, roughly 75–140 tokens per session, against
  15,060 tokens saved per step — a factor of about 170. Source: the human's
  answer, "kann man nicht ein skill daraus machen?".
- **The skill proposes, the human objects.** The skill measures what is loaded,
  proposes a deny list with its token cost, and the human removes anything they
  want to keep, rather than picking the tools they need from a full list. Only
  eagerly loaded tools are offered: the roughly 90 deferred tools are already
  present as names only and there is nothing to save on them. In the measured
  session the eager set was 16 built-in plus 12 MCP tools, 28 in total, which
  does not fit `AskUserQuestion`'s limit of 4 questions by 4 options. Source:
  the human's answer, "lässt den nutzer die tools auswählen, die er braucht und
  editiert eine evtl vorhandene datei oder schreibt sie neu", refined to
  "Vorschlag zum Widersprechen".
- **Two probe runs, not one per tool.** The skill measures the prompt before and
  after and reports the difference, rather than a figure behind each tool name.
  Per-tool figures would need one headless run per tool — about 28 runs, half an
  hour — and the debug log carries only the applied deny rules, not the tool
  schemas, so there is no cheaper source. A shipped table was rejected because
  it would be wrong for any setup with different MCP servers. Source: the
  human's answer, "Vorher/nachher, zwei Läufe".
- **No criterion demanding a test per criterion.** The draft carried a tenth
  criterion requiring every criterion above it to have its own failing test and
  no test beyond them. It was struck because it refers to itself: it is a
  criterion, so it demands a test of itself, and that test is then a criterion's
  test that must itself be covered — the check never terminates. Source: the
  human's answers, "10 ist unnötig" and "der grund ist, dass solche
  akzeptanzkriterien endlosschleifen verursachen, weil sie auf sich selbst
  beziehen".
- **The protected set in criterion 3 is a default, not asked.** Because the
  skill only ever proposes and the human only ever removes entries, the human
  cannot deny a tool the workflow needs by accident. Naming the protected tools
  explicitly makes that testable. Default, unanswered — it changes no
  user-visible behaviour, public contract, data model or dependency footprint.
- **Criterion 9 applies the change to this repository too.** The skill's own
  output run against this repository is what produces it, and it is what makes
  the saving real for Metis's own sessions rather than only for consumers.
  Default, unanswered — reversible by deleting the key.

## Log

- Filed after grilling. The idea started as "deny six tool names in
  `.claude/settings.json`"; the `researcher` established that a plugin cannot
  ship such a list at all, which turned the change into a skill the human
  invokes. Three observations surfaced during the grilling that this issue's
  criteria do not cover, filed separately as issues 0037, 0038 and 0039.
- The `test-author` wrote `skills/trim/assets/test-trim-tools.sh` from this
  intent alone, without seeing an implementation, and named the skill `trim`
  (`skills/trim/`). One or more cases per testable criterion (1 through 9);
  criterion 3's "contains only eagerly loaded tools" has no independent
  oracle to check the positive half against, so only its falsifiable half —
  a proposal never names a protected tool — is tested. Criterion 9's own
  case is expected to fail until the implementer runs the finished skill
  against this repository. Run directly, it fails 7 of 9 cases,
  `bash skills/trim/assets/test-trim-tools.sh` exits 1 — confirmed myself,
  not taken on the subagent's word, and confirmed it made no real `claude`
  calls in that failing run (every case fails immediately because
  `trim-tools.py` does not exist yet). `test.sh` needs
  `skills/trim/assets/test-trim-tools.sh` added to its `suites` list — the
  implementer's job, not the test-author's.
- The `implementer` built `skills/trim/assets/trim-tools.py` and
  `skills/trim/SKILL.md`, wired the suite into `test.sh`, and ran the
  finished skill against this repository for criterion 9: before 38760,
  after 23703, difference 15057 tokens, denying `Artifact`,
  `ReportFindings`, `ScheduleWakeup`, `SendUserFile`,
  `ShowOnboardingRolePicker` and `Workflow` — matching the issue's own
  measured six almost exactly. `bash skills/trim/assets/test-trim-tools.sh`
  9/9, `bash test.sh` 63/63, both exit 0 — confirmed myself. The proposal
  step also named a seventh tool, `Task` (this environment's headless-mode
  name for subagent dispatch), which the implementer excluded by hand
  before applying, acting as the human reviewer criterion 4 describes.
- **Round 1 (fresh context)**, against `git diff e708fd9..HEAD`. Two
  findings, both with reproductions:
  - Violates criteria 2, 5 and 8 as literally documented: `SKILL.md`
    instructs invoking `trim-tools.py probe .` / `apply . ...` (`.` as the
    directory, run from the project directory), and that invocation
    crashes — `project_dir_for()`'s sanitisation of the raw, unresolved
    `"."` argument produces a name that trivially matches the projects
    root itself, so it returns a false-positive project directory before
    ever reaching the correctly resolved path. Reproduced independently,
    not only on the reviewer's word.
  - Undercuts the stated purpose of criterion 3: `PROTECTED` hardcodes the
    literal name `Agent`, but a headless `claude -p` session in this
    environment (the only kind `probe`/`propose` ever spawns) calls the
    same subagent-dispatch tool `Task` instead — so `propose` offers it
    for denial, unprotected. Reproduced independently: a fresh `propose`
    run names `Task` alongside the intended six. No damage landed in this
    repository's own `.claude/settings.json` only because a human/session
    caught and removed it by hand during criterion 9's run — exactly the
    manual step criterion 3's hardcoded list exists to make unnecessary.
  - Both are in scope (they violate the criteria directly, not drift) and
    both got a fix-now dispatch back to the `implementer`, rather than
    being filed separately or dismissed.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes: the human asked to implement issue
  0036 as filed. It was already grilled — intent, nine acceptance criteria
  and their rationale are all recorded — so no further grilling is needed
  before implementation starts.
- What surprised me? The skill needs to spawn *new*, separate headless
  `claude` sessions as its own probe runs (once before proposing a deny
  list, once after) and read each one's own transcript — this is different
  from `skills/cost`, which only ever reads the transcript of the session
  already running it. `claude` (2.1.220, matching the version this issue's
  measurements were taken against) is available in this environment, so the
  probe runs and the tests that exercise criteria 2 and 5 can actually
  invoke it rather than mock it.
- What am I assuming without having verified it? That `skills/cost/assets/
  token-cost.py`'s transcript-location and usage-parsing logic is close
  enough to reusable for finding and reading a *separate* probe session's
  transcript, rather than needing to be built from scratch. That a fresh
  headless run is inexpensive and fast enough to run twice per invocation
  (plus more during the test suite) without making the test suite
  impractically slow — the implementer's first step should check this
  before committing to the design.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
