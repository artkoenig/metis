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

## Log

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
