---
status: active
branch: claude/agent-response-optimization-h73q5x
pr:
---

# Replies assume context the human does not have and pad it with justification

## Intent

Replies in the main conversation are written for a reader who has the project
documents in mind. They name a rule, an issue, a document or a project term
and expect the human to know what it holds; understanding such a reply means
opening the documents, which costs the human more time than the reply saves.

The same replies carry sentences that explain why something is right instead
of saying what it is — general statements, restated principles, a defect named
after the rule it violates. They add tokens and no information.

Wanted: a reply that stands on its own for a reader who has only the
conversation in front of them, and that says nothing beyond what it has to
say. The rule for this belongs where the rulebook already says how to talk to
the human.

Acceptance criteria:

1. When the rulebook's rule on talking to the human is read, it requires a
   reply to be understandable from the conversation alone, and it forbids
   naming a document, a rule, an issue or a project term without carrying its
   content in the same sentence.
2. When that rule is read, it requires every sentence of a reply to carry a
   fact, a decision, an assumption or a question, and it forbids sentences
   whose only content is a justification, a general principle or a restated
   rule.
3. Both requirements are stated once, in the section that already owns how to
   talk to the human; no other file in the repository states a rule about how
   replies to the human are written.
4. When a document in the repository describes how the agent talks to the
   human, it matches the rule after the change — or no document does, and the
   commands that established that are reported.

## Plan

## Tasks

## Decisions

- The change lands in the rulebook's `The human` section, as two rules that
  follow the `How to talk to them` paragraph and are each led by a bold phrase —
  the form that section's neighbours already use for an independent rule. It
  touches nothing else that defines reply style. Source: the human named only
  the main-conversation replies as the problem; the placement wording corrected
  after reviewer round 4, finding 2.
- The human's three example sentences stay in this issue as evidence and are
  not copied into the rulebook; the rule is stated in general terms so it also
  covers examples nobody has seen yet. Source: default, unanswered.
- The older list — "Cut every reply to the essentials: the finding, the
  decision, the change" — is replaced, not kept beside the new one, so one
  list governs what a reply may contain. The new list is the wider of the two
  and adds "the answer that was asked for", the gap issue 0008 recorded in its
  checkpoint 2. Source: reviewer round 1, finding 1.
- The prohibition's unit is the sentence and it keeps "only" — "a sentence
  whose only content is an unasked justification, a general principle or a rule
  restated is left out" — so a sentence that carries a fact and a justification
  stays permitted. Source: reviewer round 1, finding 3; restored after round 3,
  finding 1, where a rewrite had made the prohibition bite on any clause.
- The rule keeps a length limit of its own — "only as many sentences as the
  human needs now" — because the merge in round 1 dropped the older brevity
  instruction, and a per-sentence content filter permits an arbitrarily long
  reply. Source: reviewer round 2, finding 1.
- Two exemptions are named instead of left to reading: a greeting carries none
  of the listed content but the rulebook mandates one at session start, and a
  justification is the answer itself when the human asks "why". The second is
  expressed once, by the word "unasked" in the prohibition, not twice. Source:
  reviewer round 2, findings 2 and 3; round 3, finding 4.
- The contrast example — not "this violates the facts rule", but "the status
  message claims more than it measured" — is dropped; the rule states the
  requirement without it. Source: the human's answer, 2026-07-30, "kannst du
  weglassen".
- The `grill` skill's "one question per turn" stays untouched: it constrains a
  turn addressed to the human, but the change's intent is the content of a
  reply, not how many questions one may hold. Outside the intent, so it goes
  to the human instead of being fixed here. Source: reviewer round 1,
  finding 4.

## Log

- Facts before the review: `./test.sh` — 3 suites, exit 0. It covers the
  installer and the session-start hook; `grep -rn 'AGENTS.md'` over the
  harnesses shows the rulebook only as a file that is copied or must exist, so
  no exit code covers the changed text. No static analysis exists in the
  repository: no `.github/`, no lint config in `git ls-files`, `shellcheck` not
  installed. This review is the change's only check.
- Criterion 4, established by
  `grep -rlicE 'repl(y|ies)|talk to (them|the human)|informal|tone\b|concise|terse' $(git ls-files)`
  over all 45 tracked files, exit 0: four files match — `AGENTS.md`, this issue,
  and the records of issues 0008 and 0009. The two records document what was
  true when they were written and are not documents that mirror the current
  state, so nothing outside `AGENTS.md` had to change. `README.md` was also read
  whole: its paragraph on the human lists the three steering points and no reply
  style.
- Repetition signal: the evidence above was recorded twice with line numbers,
  and both times a later edit to the same paragraph made them wrong (reviewer
  round 2, finding 4; round 3, finding 3). Approach changed rather than
  repeated: this record counts hits per file and cites no line number, so an
  edit to the paragraph cannot falsify it.
- Review round 1 (fresh context): 5 findings plus one style note. Triage:
  findings 1 and 3 fixed by merging the two lists into one and keeping "only"
  in the prohibition; finding 2 fixed by recording the commands here;
  finding 5 fixed by writing the checkpoint 1 answers into this file;
  finding 4 handed to the human as outside the intent; the style note on the
  rulebook's own justification sentences was acted on anyway — those sentences
  are now gone, which shortens the rule.
- Review round 2 (fresh context): 5 findings. The count did not decrease
  against round 1. Triage: finding 1 (round 1's merge deleted the brevity
  instruction and no criterion asked for that) fixed by "only as many sentences
  as the human needs now"; finding 2 (a reply to "why?" was required and
  forbidden at once) fixed by exempting what the human asked for; finding 3
  (the rule forbade the session-opening greeting the rulebook mandates) fixed
  by "a greeting aside"; finding 4 fixed by re-running the command and
  recording what it actually shows; finding 5 stays dismissed on the recorded
  reason — the `grill` skill is outside this intent and is the human's call.
- Review round 3 (fresh context): 4 findings, down from 5. Triage: finding 1
  (round 2's rewrite lost the sentence as the prohibition's unit, so any
  justifying clause was banned) and finding 4 (the exemption for a requested
  justification stated twice) fixed together by one wording — "a sentence whose
  only content is an unasked justification …"; finding 2 (checkpoint 2 claimed
  the rule is shorter than what it replaces — it is 118 words against 34) and
  finding 3 (the criterion-4 evidence carried line numbers that a same-commit
  edit had already invalidated) fixed in this file, the second by dropping line
  numbers from the record for good.
- Review round 4 (fresh context): 2 findings, both against the record, none
  against the rule. Finding 1 — the criterion-4 sweep skipped 24 tracked files
  (`docs/issues/`, `.githooks/pre-push`, `.gitignore`, `LICENSE`) — fixed by
  running it over `$(git ls-files)` and recording what all 45 files show.
  Finding 2 — a decision claimed the change stays inside the `How to talk to
  them` paragraph while the diff adds two bold-led rules after it — fixed by
  correcting the decision. Both fixes touch this file only, no file the criteria
  are about, so the repeat round is waived under the rulebook's waiver clause;
  the trend is 5 → 5 → 4 → 2.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes: the human named two defects in the
  replies — background knowledge the conversation does not hold, and sentences
  that only justify — and both became a criterion.
- **What surprised me?** Reply style is defined in exactly one place,
  `AGENTS.md`; nothing else in the repository states one.
- **What am I assuming without having verified it?** That the human's two
  quoted example sentences are typical of the problem, and that a rule stated
  in general terms catches the rest.

### Before the PR

- **Does this match what was asked?** Yes. The rule holds both halves, plus a
  length limit and two exemptions the rounds forced out; it is longer than what
  it replaces — 118 words against 34 (`wc -w`) — because it names those
  exemptions instead of leaving them to reading. One finding, the `grill`
  skill's "one question per turn", is outside the intent and is the human's
  call.
- **What surprised me?** Every round found a defect the previous round's fix
  had introduced, not one the original change had: a list colliding with the
  old one, a deleted length limit, a prohibition that outgrew its own unit.
- **What am I assuming without having verified it?** Nothing left on the
  distribution path: reviewer round 4 read `session-start-core.sh` and found the
  copy of `AGENTS.md` over `~/.claude/CLAUDE.md` unconditional at every session
  start, so no cached copy of the removed sentence survives. What stays
  unverified is the effect: whether the rule actually changes how the next
  session's replies read, which only the next runs can show.

## Retro
