---
status: active
branch: 0005-simplify-texts
pr:
---

# The texts outgrew their own principle

## Intent

Simplicity is this project's top rule, but its own texts do not read that way.
The rulebook, the skills and the agent definitions have grown long sentences,
nested qualifications and images that need project history to decode ("a plan
wearing a tracker's clothes"). A human reading them for the first time has to
work to find the rule inside the prose.

Wanted behaviour: every text states its essential message in plain language.
Short sentences, common words, one reading is enough. The rules themselves do
not change — only how they are said.

Acceptance criteria:

1. Every rule, invariant, operation and boundary the texts stated before is
   still stated after, with the same meaning. A statement may only disappear
   through a recorded decision.
2. The interface stays untouched: skill names, operation names, section
   headings, state names, file paths and tool lists are unchanged. The change
   is wording only.
3. Every changed file is shorter than before, counted in words.
4. Sentences are plain: a sentence whose meaning a reader cannot state after
   one reading is a finding, and so is a metaphor that needs project history
   to decode.
5. The texts stay consistent with each other and with the repository: no
   broken cross-reference, no text contradicting another.
6. The rulebook itself states the simplicity rule, so future changes are held
   to it.

## Plan

## Tasks

## Decisions

- Scope is every prose text in the repository: `AGENTS.md`, `README.md`, the
  four agent definitions, the five skills, and the issue template. The files
  under `docs/issues/` are records of past runs and stay untouched. Source:
  the request names "Regeln, Skills"; records are history, not rules.
- The texts stay in English. The request asks for simple language, not for a
  translation, and every text is English today. Default, unanswered.
- The rewriting happens in the main context, not through the `implementer`.
  This change is prose only — no production code, no tests — and the wording
  is the whole deliverable, shaped directly by the human's instruction. The
  fresh-context review still runs unchanged. Source: the rulebook leaves the
  process to judgment; the invariants that apply (intent first, fresh review,
  record survives) all hold.
- The simplicity rule goes into `AGENTS.md` as part of this change. Source:
  the human's instruction "Einfachheit ist das oberste Gebot in diesem
  Projekt" — a rule that only lives in a conversation dies with it.
- The `clean-room` trigger is now "when you are stuck or want a second
  opinion", in every place that names it (rulebook, clean-room description,
  plan skill). Source: the human's answer during this run.

## Log

- Word counts before the change: AGENTS.md 1087, README.md 1144,
  implementer 454, researcher 232, reviewer 590, test-author 308,
  bootstrap 713, clean-room 325, grill 305, issue 1535, plan 304,
  TEMPLATE.md 103 — total 7100.

- Rewrite done in one pass. Word counts after: AGENTS.md 918, README.md 1017,
  implementer 429, researcher 214, reviewer 509, test-author 292,
  bootstrap 648, clean-room 294, grill 274, issue 1101, plan 263 — every
  changed file shorter. The template (103 words) was already a bare skeleton
  and stays unchanged.
- Review round 1 (fresh context): no suite and no static analysis exist in
  this repo (reported with commands, exit codes); criteria 3 and 6 met. Five
  findings fixed: "No child issues" restored to the rulebook; "not a gate"
  restored to the checkpoint rule; bootstrap's "without disturbing existing
  hooks" restored; the plan skill's garden-path sentence rewritten; the
  clean-room trigger in the plan skill restated as "could be wrong in a way
  you would not notice". One finding dismissed: document chapter headings
  were reworded — criterion 2 protects the interface (operation names,
  states, issue-file sections, paths, tool lists, all verified unchanged),
  not the chapter headings of the texts.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes: the request is to simplify all texts
  (rules, skills) to their essential statements, in plain language, readable
  for a human. The criteria pin exactly that: same rules, plainer words,
  shorter files.
- What surprised me? Nothing yet; the texts read as expected from the last
  run.
- What am I assuming without having verified it? That "alle Texte" means the
  metis texts, not the predecessor repository — this whole session works on
  metis and the predecessor is being replaced. And that English is fine
  (recorded as a default).

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
