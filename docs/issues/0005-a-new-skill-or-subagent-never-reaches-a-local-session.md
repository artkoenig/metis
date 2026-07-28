---
status: backlog
branch:
pr:
---

# A newly added skill or subagent never reaches a local session

## Intent

The session hook links metis's `agents/` and `skills/` into `~/.claude` one
symlink per item, and it does that in the core — which only the cloud path of
the loader reaches. A local session fast-forwards the clone and exits before
the core runs, on purpose: the user owns their own `~/.claude`.

The consequence is asymmetric in a way that is easy to miss. *Editing* an
existing skill or subagent reaches a local session immediately, because the
symlink already points into the clone and the pull updates the target.
*Adding* a new one does not: no link exists, nothing creates it, and the new
skill is simply absent from every local session until someone links it by
hand. It bites exactly once per addition, silently, and the session that
suffers it has no way to notice — an absent skill looks like a skill that
was not needed.

Found while reviewing `0004`, which adds the first new skill since the hook
was written and would have been the first to hit it.

Acceptance criteria:

1. A local session started after a new skill or subagent is added to metis has
   that skill or subagent available, without anyone linking it by hand.
2. The local session still does not take ownership of `~/.claude`: nothing
   that the user put there is removed or overwritten, and a link metis does
   not own is left alone.
3. A local session that finds nothing to do says nothing — the fix does not
   add noise to the common case.

## Plan

## Tasks

## Decisions

- **Source: review round 3 of `0004`.** The reviewer traced it concretely:
  `skills/bootstrap/assets/session-start.sh` exits on the local path before
  `exec bash "$core"`, and the only code creating `~/.claude/skills/<name>`
  is in `session-start-core.sh`. It flagged one precondition it could not
  verify from inside the repository — whether the human's local `~/.claude`
  uses per-item symlinks or one whole-directory link. Under a
  whole-directory link the problem does not exist. **That is the first thing
  to establish, and it decides whether this issue is real.**
- **Not fixed inside `0004`.** It is a property of the bootstrap design that
  predates that change and affects every future skill and subagent equally;
  `0004` is merely the first addition to run into it. Folding it in would
  have widened a run that had already been redesigned twice.
- **Accepted for `0004` with this issue as the record.** `0004`'s criterion 1
  asks that the shape reach every session; on this path it does not, and that
  is stated in its checkpoint rather than papered over.

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
