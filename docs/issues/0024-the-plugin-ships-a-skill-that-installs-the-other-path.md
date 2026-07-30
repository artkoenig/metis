---
status: done
branch:
pr: https://github.com/artkoenig/metis/pull/31
---

# The plugin ships a skill that installs the other path

## Intent

The metis plugin exposes five skills, `bootstrap` among them. Verified with a
real install during issue 0022's review round 3:
`claude plugin details metis@metis` → `Skills (5) bootstrap, clean-room, grill,
issue, plan`.

`skills/bootstrap/SKILL.md`'s description tells a session to wire a project
for the *loader* path — "Run it at the start of any session in one of Artjom's
git repositories whose hook is missing or has drifted — proactively, not only
when asked" — and the skill then commits a `SessionStart` loader hook and a
`.claude/settings.json` entry into that repository.

So a consumer who installs only the plugin carries a model-invocable skill
that will, unasked, commit the second mechanism into their repo — the state
`README.md` tells every project but metis itself to avoid. The skill is not
inert like the `docs/` and test files that also ship: its description is
always in context and it triggers proactively by its own wording.

Issue 0022 could not fix this: its criterion 2 requires every skill under
`skills/` to be exposed as a plugin component, and its criterion 7 requires
`bootstrap` to remain in the repository while the plugin's cloud install is
unproven. The two criteria together force exactly this state.

Wanted observable behaviour: installing the metis plugin never leads a session
to install the loader path into the consumer's repository.

Acceptance criteria:

1. When a project has the metis plugin installed and is not metis itself, no
   skill reachable in that session instructs the session to install or repair
   the loader hook.
2. When metis itself needs the bootstrap capability — it runs both paths on
   purpose while the plugin's cloud install is unproven — it is still
   available there, and how it is reached is recorded.
3. When `claude plugin details metis@metis` lists the plugin's skills, the
   list and the skills a consumer should have are the same set — none missing,
   none extra.
4. `README.md` and `skills/bootstrap/SKILL.md` describe whichever arrangement
   is chosen, and neither contradicts the other.

## Plan

## Tasks

## Decisions

- Not decided yet, and the choice is the point of this issue: drop `bootstrap`
  once criterion 6 of issue 0022 is settled and the loader path goes away;
  narrow its description so it never triggers outside metis; or move it
  somewhere plugin discovery does not expose. Whether the loader path survives
  at all depends on issue 0022's criterion 6, so this issue may resolve itself
  by that decision.

## Log

- Filed out of issue 0022's review round 3, which verified the component list
  from a real install. The finding is outside 0022's acceptance criteria — and
  in fact forced by two of them — so it goes to its own run. The human decided
  to file it.
- Resolved as moot by issue 0031 (criterion 6): the human decided to remove
  the loader path entirely, which took the first option this issue's own
  Decisions section had named — "drop `bootstrap` once criterion 6 of issue
  0022 is settled and the loader path goes away." `skills/bootstrap/SKILL.md`,
  the file this issue's finding is about, no longer exists in the repository.
  No production change was made for this issue directly; the deletion is
  issue 0031's.

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
