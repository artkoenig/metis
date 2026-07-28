---
status: done
branch: close-001
pr: https://github.com/artkoenig/metis/pull/7
---

# `done` is set when the pull request is opened

## Intent

`Merged means done` cannot be satisfied by the session doing the work. The
merge happens after the last commit, so flipping the status to `done` always
costs a second branch and a second pull request — which is exactly what
closing `001` cost. Left undone, `docs/issues/` claims an issue is still
awaiting its merge forever, and the orientation protocol reads it as live
work.

The human decided the other end: `done` is set when the pull request is
opened, together with `pr`. The work is finished at the handover; the merge
is theirs, and it changes nothing in the file.

That leaves `waiting` with one reading instead of two — parked on a question —
which is the clearer of the pair anyway.

Acceptance criteria:

1. `AGENTS.md` states that `done` is set when the pull request is opened, in
   the same breath as `pr`, and that the merge changes nothing in the file.
2. `waiting` is defined as parked on a question, and nothing else.
3. `docs/issues/TEMPLATE.md` says the same where it explains the frontmatter,
   so an issue filed from the template cannot learn the old rule.
4. Nothing in the rulebook still claims that a merge sets a status.

## Plan

## Tasks

## Decisions

- **Source: the human**, asked directly after closing `001` cost a second
  branch and pull request for a one-line status change. The alternative on the
  table — drop `done` and let `waiting` with `pr` set be the terminal state,
  since the merged pull request records the fact publicly — was not the one
  chosen.
- **Consequence, recorded rather than smoothed over:** the retro is written
  after the pull request, so it now lands in an issue already marked `done`.
  The status tracks the work, not the last section. Stated explicitly in the
  rulebook so it does not read as an inconsistency.
- **Filed and implemented on `close-001` rather than on its own branch.** That
  branch already carries the issue-file bookkeeping this decision came out of,
  and a second branch off `main` would file its own `002` against a `main`
  that does not have one yet. One bookkeeping thread, one branch.

## Log

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes — one decision, stated in one
  sentence by the human, applied to the two places that carry it.
- **What surprised me?** That the rule it replaces was unsatisfiable from the
  start and survived a full run plus a review round without anyone noticing —
  including the review round whose whole subject was the bookkeeping section.
- **What am I assuming without having verified it?** That `AGENTS.md` and
  `TEMPLATE.md` are the only places stating the status semantics; `README.md`
  describes the workflow's philosophy and lists no status values, which I
  checked, but I have not re-read the agent definitions for an incidental
  mention.

### Before the PR

- **Does this match what was asked?** Yes. Two files, four criteria, nothing
  beyond them.
- **What surprised me?** A grep for the status vocabulary across the rulebook,
  the README, every agent definition and every skill found it in exactly two
  places: the bookkeeping bullet and the template. No agent ever reads a
  status — only the caller does. That is worth knowing, and it was not
  obvious from the way the frontmatter is described.
- **What am I assuming without having verified it?** That no issue file
  already in the wild depends on the old reading. One does, and I have not
  touched it: `tome_of_battle:docs/issues/resolver-immutability.md` stands at
  `waiting` with `pr` set — the state that used to mean "awaits the merge" and
  now means nothing. Under the new rule it is `done`. It lives on the branch
  of an open pull request, so correcting it belongs to that branch, not this
  one.

## Retro

**The new rule was used the moment it existed.** This issue went to `done`
when PR #7 was opened, and this retro is being written into it afterwards —
the ordering the rulebook now describes, exercised once. It reads fine: the
status answered "is anyone still working on this?" correctly at every point,
which the old one could not.

**The rule it replaced was unsatisfiable from the start.** It survived the
writing of the rulebook, a full trial run against a foreign project, and a
review round whose subject was the bookkeeping section itself. What surfaced
it was not a review but a cost — closing `001` needed a whole branch for one
line, and that was too much friction to ignore. Worth noticing: the rules that
do not work are found by using them, not by reading them, and Metis has no
mechanism that uses them except a real run.

**Three issues on one branch is a compromise, not a pattern.** The rule
"branch each new one from the current default branch" and the rule "number
after the highest already filed" pull against each other while a numbered
issue file sits unmerged: two branches off `main` would both file a `002`.
It cost nothing here because all three are bookkeeping on the same thread. It
would cost a collision in a repository with real parallel work, and there is
no rule covering it.
