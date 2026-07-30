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

- The change touches the rulebook's `How to talk to them` paragraph and
  nothing else that defines reply style: a grep over `agents/`, `skills/` and
  `README.md` for style wording found no second definition. Source: the human
  named only the main-conversation replies as the problem.
- The human's three example sentences stay in this issue as evidence and are
  not copied into the rulebook; the rule is stated in general terms so it also
  covers examples nobody has seen yet. Source: default, unanswered.
- The older list — "Cut every reply to the essentials: the finding, the
  decision, the change" — is replaced, not kept beside the new one, so one
  list governs what a reply may contain. The new list is the wider of the two
  and adds "the answer that was asked for", the gap issue 0008 recorded in its
  checkpoint 2. Source: reviewer round 1, finding 1.
- The prohibition keeps "only" ("a sentence whose only content is …"), so a
  sentence that carries a fact and a justification stays permitted. Source:
  reviewer round 1, finding 3.
- The rule keeps a length limit of its own — "only as many sentences as the
  human needs now" — because the merge in round 1 dropped the older brevity
  instruction, and a per-sentence content filter permits an arbitrarily long
  reply. Source: reviewer round 2, finding 1.
- Two exemptions are named instead of left to reading: a greeting carries none
  of the listed content but the rulebook mandates one at session start, and a
  justification is the answer itself when the human asks "why". Source:
  reviewer round 2, findings 2 and 3.
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
  `grep -rniE 'repl(y|ies)|talk to (them|the human)|informal|tone\b|concise|terse' README.md AGENTS.md agents/ skills/ .claude/ install.sh test-install.sh test.sh`
  — four hits, all in `AGENTS.md`, all inside the changed paragraph (lines 81,
  82, 84, 88), exit 0 — and by reading `README.md` whole: its paragraph on the
  human lists the three steering points and no reply style. No document had to
  change. An earlier, wider version of this command was recorded here with
  line numbers that no longer matched and with hits it did not mention; this
  entry replaces it (reviewer round 2, finding 4).
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

- **Does this match what was asked?** Yes. The rule now holds both halves and
  is shorter than the paragraph it replaces; one finding — the `grill` skill's
  "one question per turn" — is outside the intent and is the human's call.
- **What surprised me?** The reviewer found the new list colliding with the
  old one seven lines above; the change was meant to add a rule and instead
  had to replace one.
- **What am I assuming without having verified it?** That no session reads the
  removed sentence "Cut every reply to the essentials" from a cached copy —
  wired projects reload the rulebook at session start, which I have not
  re-verified in this run.

## Retro
