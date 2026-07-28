---
status: active
branch: 0008-how-to-talk-to-the-human
pr:
---

# The rulebook says nothing about talking to the human

## Intent

The rulebook governs the work but not the conversation. How the agent talks
to the human is left to each session's defaults, so tone and length drift
from session to session — sometimes formal, sometimes verbose, sometimes
both.

Wanted behaviour: every session talks to the human the same way — informal,
plain, and short.

Acceptance criteria:

1. `AGENTS.md` carries a communication rule with three parts: address the
   human informally (in languages that mark the distinction, such as German
   "du"), use short and simple wording, and cut every reply to the
   essentials.
2. The rule lives where the human is already the subject — no new section
   machinery, no style guide document.
3. Nothing else about the rulebook changes.

## Plan

## Tasks

## Decisions

- The rule goes into the existing "The human" section of `AGENTS.md` — that
  section already defines the relationship to the human, and criterion 2
  rules out new machinery. (by agent)
- The rule is written in English like everything checked in, but names the
  German "du" as the concrete case, since English does not mark the
  distinction. Source: the human's request was about "duzen". (by agent)

## Log

- Review round 1 (fresh context): no findings. All three criteria met. No
  suite and no static analysis exist — established by the reviewer with
  commands and exit codes; its reading was the change's only check, per
  invariant 3. One observation, not a finding: the closing list "the
  finding, the decision, the change" is narrower than "the essentials" — a
  direct answer to a factual question is none of the three. Read as
  illustrative, kept as is: the criterion's own words stand verbatim before
  the colon, and lengthening the list to make it exhaustive would work
  against the rule it states.

## Checkpoints

### Before implementation

- **Does this match what was asked?** The request named three things: informal
  address, simple short wording, output cut to the essentials. All three are
  criterion 1.
- **What surprised me?** Nothing — AGENTS.md has a "The human" section that
  fits, and README.md does not restate anything about communication, so no
  mirror to keep in step.
- **What am I assuming without having verified it?** That README.md really
  carries no restatement — verified by reading it: its human section lists
  the three steering points only.

### Before the PR

- **Does this match what was asked?** Yes — the three requested parts
  (informal address, simple short wording, essentials only) are one
  paragraph in the section about the human, nothing else changed.
- **What surprised me?** A one-round review with zero findings — a first.
  The change is four lines against a section that already fit it.
- **What am I assuming without having verified it?** That the illustrative
  reading of "the finding, the decision, the change" holds up in practice —
  if a future session treats the list as exhaustive and refuses plain
  answers, the list needs an explicit "or the answer asked for".

## Retro
