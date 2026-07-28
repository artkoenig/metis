---
name: plan
description: Record a short architecture plan before implementation — modules touched, boundaries, shared contracts. A shelf tool — reach for it when the change spans modules or the structure is genuinely undecided; a change that fits inside one module needs no plan beyond the implementer's own.
user-invocable: true
---

# Plan

The change spans modules, so the structure deserves a decision before the
implementer commits to one mid-edit. A page at most, recorded in the tracker.

## How to run it

1. **Get the facts.** Dispatch the `researcher`: which modules the change
   touches, how they depend on each other, where the seams are.
2. **Decide the shape.** From the briefing and the acceptance criteria:
   which modules change, which new ones appear, and — most importantly — the
   contracts between them: the signatures, data shapes or interfaces that
   more than one piece of the work relies on.
3. **Record it** through the `issue` skill's *record a plan* operation, which
   is delegated to this page. A plan contains: the module list, the contracts
   stated concretely, and one sentence per non-obvious choice saying why.
   This is the only page that says so. What you leave out, the implementer
   decides alone — which is fine for everything left out on purpose.

## What it is not

Not a design review (put a risky plan through `clean-room`), not a work
breakdown (that is a task list — its own operation on the `issue` skill), and
not a cage: an implementer that reports the plan does not survive contact
with the code has found something. Update the plan, do not defend it.
