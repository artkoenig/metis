---
status: backlog
branch:
pr:
---

# A session with nothing running has no way to pick the next issue

## Intent

The rulebook says how a session resumes a run that is already going: orient
through the `issue` skill, open the `active` issue, read nothing else. It says
nothing about the case where no issue is running. Every session invents its own
entry there — one asks the human, one scans the backlog, one starts on whatever
the last message mentioned.

The resume path is not reliable either. Issues 0027 and 0031 both stand on
`active` although their pull requests are merged, so a fresh session opens a
finished run and takes it for the running one. Nothing in the orientation
notices this, because it reads one file and stops.

Wanted: a session that finds nothing running reads the `status` of every issue
and the `## Intent` of every issue that is not `done`, works out which of those
issues depend on each other, and puts one of them in front of the human as a
proposal with a short reason. The human's three steering points do not become
four: without an answer the session takes its own proposal and records it as a
default.

Acceptance criteria:

1. When an issue is `active` and its branch is checked out, the rulebook still
   has the session resume that issue and read nothing else to get oriented —
   word for word the rule in force today.
2. When no issue is running, the `issue` skill's orientation reads the `status`
   line of every issue file and the `## Intent` section of every issue whose
   status is not `done`, and no other section and no other file.
3. The rulebook names dependency between issues as the ordering basis: an issue
   that another open issue depends on is proposed before the issue that depends
   on it.
4. The rulebook has the session name exactly one issue as its proposal, with a
   reason for that issue over the others.
5. When the human does not answer the proposal, the rulebook has the session
   take its own proposal and record it through the `issue` skill as a default,
   marked as a default.
6. The rulebook still lists three steering points for the human, and picking
   the next issue is not among them.
7. The `issue` skill's "Orienting a session" section and the rulebook's
   orientation rule describe the same protocol: neither states a step the other
   contradicts.
8. `README.md` states nothing about orientation that criteria 1–7 make false.

## Plan

## Tasks

## Decisions

- Orientation reads `status` for every issue and `## Intent` only for issues
  that are not `done` — not the whole file. Source: the human's answer, this
  session. Measured basis: the twelve open issues total 7,654 words whole and
  4,072 words as Intents alone.
- The ordering basis is dependency between issues, not age, cost or severity.
  Source: the human's answer, this session.
- Without an answer from the human the session takes its own proposal and
  records it as a default, so the steering points stay three. Source: default,
  unanswered — the human left the question open after it was asked once.

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
