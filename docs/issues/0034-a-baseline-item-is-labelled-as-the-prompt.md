---
status: backlog
branch:
pr:
---

# A baseline item is labelled as the prompt

## Intent

`skills/cost/assets/token-cost.py` labels the first item of a dispatch by the
text of the dispatch prompt. For a dispatch's first model call that item is
not the prompt: it carries everything the call had to pay for — the subagent
system prompt, its tool schemas, the inherited `CLAUDE.md`, and the prompt.
The command prints it as `measured`, which is correct, beside a label that
names one small part of what was measured.

Reproduced by the reviewer against this repository's own live transcripts,
`python3 skills/cost/assets/token-cost.py`, exit 0:

```
reviewer - Probe subagent baseline context
    step 1   9,589  measured   prompt: Do not use any tool. Answer from your context alone, in a...
```

That prompt is two sentences. The same 9,589 is recorded in issue 0025's Log
as the bare baseline a `reviewer` inherits before any prompt of consequence.
The grouped line directly above it is already honest — `the prompt and the
baseline  9,589  measured` — so only the item label narrows it.

This matters because the item list is the part a reader acts on. A reader who
sees 9,589 tokens against a two-sentence prompt concludes the prompt is
expensive and shortens it, when the figure is dominated by what the dispatch
inherits and the prompt is a small remainder.

Wanted observable behaviour: an item's label says what the item is, so a
reader deciding what to shorten is not pointed at the wrong thing.

Acceptance criteria:

1. When the command prints the item covering a dispatch's or a session's first
   model call, the label names the fixed inherited context as well as the
   prompt, not the prompt alone.
2. When that first-call item is printed, its figure stays `measured` and keeps
   the same token count it has today — this changes what the row is called,
   not what it counts.
3. Items other than the first-call one keep the labels they have today.
4. `bash skills/cost/assets/test-token-cost.sh` exits 0, and `bash test.sh`
   fails no case that passed before this change.

## Plan

## Tasks

## Decisions

## Log

- Raised as finding 2 of review round 1 on issue 0025, with the reproduction
  above. It violates none of that issue's acceptance criteria, so it was filed
  rather than fixed in its diff.

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
