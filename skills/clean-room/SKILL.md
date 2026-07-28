---
name: clean-room
description: Get an independent solution proposal from a fresh agent that has seen NO code, NO docs, and NO preferred answer — then reconcile the blind proposal with reality. A shelf tool — reach for it when you are stuck or want a second opinion: an architecture choice, a "are we overcomplicating this?" doubt, a plan worth stress-testing before implementation.
user-invocable: true
---

# Clean-Room

A second opinion is only worth having if it is independent. Anyone who has
seen your code, your plan or your leaning will anchor on it — so the
clean-room expert sees none of them. Their blind proposal shows what someone
would build starting today; the difference between that and your answer is
the signal.

## How to run it

1. **Write the problem statement.** The domain, the requirements, the real
   constraints — nothing about the existing solution, the codebase, or the
   answer you lean toward. Write it as if the reader had just joined the
   industry, not the project; any leak destroys the independence you are
   paying for.
2. **Dispatch a fresh general-purpose agent** with only that statement and
   the ask: "How would you solve this? Design your solution and state its
   trade-offs." No repository access — it designs from the problem alone.
3. **Reconcile.** Compare the blind proposal with your own answer, knowing
   what the expert could not. Adopt what is genuinely better. For each
   significant divergence you keep, record a decision saying why reality
   wins — a proposal dismissed without a written reason was a wasted
   dispatch.

## What it is not

Not a review of existing code (that is the `reviewer`), and not arbitration:
the blind expert is not right because they are fresh, only unanchored. The
decision stays with you.
