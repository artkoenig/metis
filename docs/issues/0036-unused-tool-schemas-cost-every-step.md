---
status: backlog
branch:
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
