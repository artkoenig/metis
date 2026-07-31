---
status: backlog
branch:
pr:
---

# The cost skill's prose is ragged where two fixes landed

## Intent

Two places in issue 0025's change read worse than the text around them. Both
are correct; neither is false. They were left as they are because they violate
no acceptance criterion of that issue, and the rulebook gives an off-criterion
finding one outcome only.

`skills/cost/SKILL.md`, in "What it is not":

```
Not a budget and not a limit — whatever the figures are, it reports them and
never refuses over them. And not a live
meter: it reads what the transcripts hold at the moment it runs, so the last
few calls of the running turn are not in it yet.
```

The second line breaks at half the width the rest of the file uses. It is
where the sentence "it reports, it never refuses" was rescoped after the
command gained a non-zero exit; the edit was bounded correctly and the wrap
was not redone.

`docs/issues/0025-a-runs-token-cost-is-invisible.md`, in the Log: one bullet
begins "**Second finding, filed as issue 0033, and larger than anything this
session proposed**" and ends "Filed as issue 0033. This serves no criterion of
this issue". The same fact is stated twice inside one bullet, because the
heading was rewritten in the same commit that added the closing sentence.

Wanted observable behaviour: both passages read like the text around them,
and neither says the same thing twice.

Acceptance criteria:

1. In `skills/cost/SKILL.md`, no line of a paragraph is shorter than the
   paragraph's other lines other than its last, and the wrapped width matches
   the rest of the file.
2. In `docs/issues/0025-a-runs-token-cost-is-invisible.md`, the Log bullet
   about the injected-context finding names issue 0033 once.
3. No sentence changes its meaning: the claims both passages make are the same
   before and after, and the figures in them are unchanged.
4. `bash skills/cost/assets/test-token-cost.sh` exits 0, and `bash test.sh`
   fails no case that passed before this change.

## Plan

## Tasks

## Decisions

## Log

- Raised as finding 2 of review round 2 on issue 0025. It violates none of
  that issue's criteria and neither passage is wrong, so the documentation
  exception the rulebook grants — for a statement the change's own diff made
  false — does not reach it. Filed rather than fixed, which is the only
  outcome the rulebook leaves for an off-criterion finding.

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
