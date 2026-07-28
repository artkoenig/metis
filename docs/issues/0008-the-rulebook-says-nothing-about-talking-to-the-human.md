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

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
