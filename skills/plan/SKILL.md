---
name: plan
description: Record a short architecture plan before implementation — modules touched, boundaries, shared contracts. A shelf tool — reach for it when the change spans modules or the structure is genuinely undecided; a change that fits inside one module needs no plan beyond the implementer's own.
user-invocable: true
---

# Plan

The change spans modules, so the structure deserves a decision before the
implementer commits to one mid-edit. The plan is recorded in the tracker, not
a document of its own — a page at most.

## How to run it

1. **Get the facts.** Dispatch the `researcher`: which modules the change
   touches, how they depend on each other today, where the seams are.
2. **Decide the shape.** From the briefing and the acceptance criteria, decide:
   which modules change, which new ones (if any) appear, and — most
   importantly — the contracts between them: the signatures, data shapes, or
   interfaces that more than one piece of the work will rely on.
3. **Record it** through the `issue` skill's *record a plan* operation, which
   is delegated to this page: hand it the module list, the contracts stated
   concretely, and one sentence per non-obvious choice saying why. That is
   what a plan contains, and this is the only page that says so. What you do
   not write down, the implementer will decide alone — which is fine for
   everything you left out on purpose.

## What it is not

Not a design review (put the plan through `clean-room` if it could be wrong in
a way you would not notice), not a work breakdown (that is a task list — its
own operation on the `issue` skill, due when the rulebook says so), and not a
cage — an implementer that reports the plan
does not survive contact with the code has found something; update the plan,
do not defend it.
