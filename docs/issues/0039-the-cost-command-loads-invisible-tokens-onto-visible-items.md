---
status: backlog
branch:
pr:
---

# The cost command loads invisible tokens onto visible items

## Intent

`skills/cost/assets/token-cost.py` reports what each item in a session's
context cost. When several items enter before one request, it splits that
request's cache-write across them by character share. At step 1 this is wrong
in a way that inflates every figure it produces.

Measured in this repository's own session. The command reported the step-1
`skill_listing` attachment at 19,042 tokens. The raw attachment in the
transcript is 14,433 characters, about 3,608 tokens — a factor of five. The
step-1 cache-write was 58,362 tokens, while the transcript items that entered
at step 1 total only about 11,050. The remaining roughly 47,300 tokens are the
system prompt, the tool schemas and the global rulebook, none of which exist as
transcript records. The command has nothing to attribute them to, so it spreads
them over the items it can see.

Every step-1 figure the command prints is therefore too large, and the error is
silent: the rows are labelled `estimated`, which reads as "rounded", not as
"carrying tokens that belong to something else entirely".

This matters beyond the command itself. Issue 0033 was filed on the strength of
a `skill_listing` figure of 141,999 tokens produced this same way, and its
premise — that injected context dominates a session — has not been re-derived
since.

Wanted observable behaviour: the command never charges an item more tokens than
that item's own content can account for, and tokens it cannot attribute are
shown as what they are.

Acceptance criteria:

1. No item in the command's output carries a token figure larger than its own
   content in the transcript can account for.
2. When a request's cache-write exceeds the total size of the items that
   entered the context before it, the command reports the excess as its own
   row rather than distributing it across those items.
3. That row names what it holds — the system prompt, the tool schemas and the
   global rulebook — rather than appearing as an unlabelled remainder.

## Plan

## Tasks

## Decisions

- **No criterion demanding a test per criterion.** The draft carried a fourth
  criterion requiring every criterion above it to have its own failing test and
  no test beyond them. It was struck because it refers to itself: it is a
  criterion, so it demands a test of itself, and that test is then a criterion's
  test that must itself be covered — the check never terminates. Source: the
  human's answer, "der grund ist, dass solche akzeptanzkriterien
  endlosschleifen verursachen, weil sie auf sich selbst beziehen".

## Log

- Observed while grilling issue 0036, outside that issue's criteria, and filed
  here for its own run.

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
