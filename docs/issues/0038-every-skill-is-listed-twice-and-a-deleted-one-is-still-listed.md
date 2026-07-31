---
status: backlog
branch:
pr:
---

# Every skill is listed twice and a deleted one is still listed

## Intent

Every session begins with a skill listing injected into its context. Measured
from this repository's own session transcript: that listing is 14,433
characters, about 3,608 tokens, and it is carried at every step of the session.

Two things in it are wrong. Each Metis skill appears twice, once unprefixed and
once prefixed — `issue` and `metis:issue`, `bootstrap` and `metis:bootstrap`.
And `bootstrap` is listed at all, though issues 0031 and 0032 deleted that
skill from the tree.

So roughly half of those 3,608 tokens buys nothing, and a session is told about
a skill it cannot invoke.

Two candidate causes were observed but neither was established: the marketplace
is registered twice, once as a directory in this repository's
`.claude/settings.json` and once from GitHub in the user's own settings; and
the installed plugin is stale, which issue 0037 covers separately. Which of
these produces which half of the problem is not known.

Wanted observable behaviour: a session started in this repository is told about
each Metis skill once, and about no skill that is absent from the tracked tree.

Acceptance criteria:

1. In a session started in this repository, each skill this plugin ships
   appears exactly once in the session-start skill listing.
2. No skill absent from the tracked tree appears in that listing.

## Plan

## Tasks

## Decisions

- **No criterion demanding a test per criterion.** The draft carried a third
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
