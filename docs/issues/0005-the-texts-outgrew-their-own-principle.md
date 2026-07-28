---
status: done
branch: 0005-simplify-texts
pr: https://github.com/artkoenig/metis/pull/9
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
- Accepted after round 4. The human chose to finish instead of a fifth
  round: the two remaining fixes were one-sentence changes, verified
  directly, and the corpus had been swept four times. Source: the human's
  answer during this run.
- Repository language rule, set by the human after the PR opened:
  everything checked in — texts, commit messages — and every pull request
  is written in English. Recorded in the rulebook's Bookkeeping section;
  the open PR 9 was translated to comply. Source: the human's instruction
  in this run. (Earlier commits on this branch are German; history stays.)

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
- Review round 2 (fresh context): criteria 2, 3, 5, 6 met. Three findings,
  all fixed: the criterion form ("when X, then Y") restored to the issue
  skill's shape table; the single-description boundary ("described here and
  nowhere else") restored to the issue skill; the dangling "they" in the
  rulebook's skill-as-class sentence replaced with "those internals". The
  round also confirmed round 1's dismissal of the chapter-heading finding.
- Perception signal: criterion 1 missed twice in a row, by different
  defects — the pattern is load-bearing statements dropped during
  compression. Changed approach: before round 3, every deleted normative
  line of the whole diff was swept mechanically (grep over the diff's
  deleted lines) and each checked against the new corpus; everything
  remaining is rationale or survives elsewhere.
- Stale word counts in an earlier Log entry, current after the round-2
  fixes: AGENTS.md 939, README.md 1017, implementer 429, researcher 214,
  reviewer 509, test-author 292, bootstrap 650, clean-room 287, grill 274,
  issue 1121, plan 269 — still every changed file shorter than before.
- Review round 3 (fresh context): criteria 2-6 met, one finding on
  criterion 1: the boundary restored in round 2 was rewritten too wide —
  "what it owns is described here and nowhere else" claimed the delegated
  parts too, contradicting the plan skill. Fixed: the sentence now excepts
  the four handed-over parts. The reviewer also named the method gap — the
  deleted-line sweep cannot catch statements that were rewritten with a
  wider scope, only ones that vanished. The other rewritten boundary
  sentences (no child issues, not a gate, Skill tool not a path, verbatim
  copy) were re-checked for the same class: each keeps its old scope.
- Review round 4 (fresh context): criteria 2, 3, 6 met. Two findings, both
  fixed: the plan skill's prohibition "never a document of its own" restored
  (criterion 1, fourth miss — the class round 3 named, a statement rewritten
  with reduced scope); the overlong welded line from the round-3 fix in the
  issue skill split into two plain paragraphs with the pronoun resolved, and
  the ragged wrap in the plan skill smoothed (criteria 4/5). The round also
  cleared four other rewrites of the scope-change class and re-traced every
  earlier removal as surviving elsewhere.
- Perception: criterion 1 is now missed four rounds in a row, each time by a
  smaller defect. Per the rulebook the next step is decided with the human:
  a fifth fresh round, or accept with direct verification of these two
  one-sentence fixes.

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

- Does this match what was asked? Yes. Every text now states the same rules
  in plainer, shorter language: every changed file is smaller, the two
  named metaphors are gone, and the simplicity rule itself is in the
  rulebook. Four review rounds confirmed criteria 2, 3, 5 and 6; the
  criterion-1 misses were each fixed and the last two verified directly.
- What surprised me? How reliably compression loses load-bearing sentences:
  four rounds, four different ways for a statement to vanish — deleted,
  weakened, rewritten too wide, rewritten too narrow. A deleted-line sweep
  catches only the first class.
- What am I assuming without having verified it? That no fifth class of
  loss exists that all four fresh readings missed. And that the human's
  reformulated clean-room trigger ("stuck or second opinion") is meant to
  replace, not join, the old blind-spot wording everywhere — I applied it
  in all three places that state a trigger.

## Retro

Compression is lossy in ways a single reading does not catch: four fresh
rounds found four different ways a load-bearing sentence disappears. What
worked was naming the failure class after each round and checking for that
class mechanically; what did not work was assuming one sweep method covers
all classes. The perception rule (same criterion missed twice) fired at the
right moments and forced both approach changes — no fixed round budget was
missed. One improvement worth considering: when a future change compresses
prose, write the "no statement lost" criterion with the classes named
(deleted, weakened, scope widened, scope narrowed) so the first review round
already hunts all four.
