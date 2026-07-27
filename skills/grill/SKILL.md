---
name: grill
description: Turn a genuinely vague idea into written acceptance criteria by interviewing the human, one question at a time, grounded in facts from the codebase. A shelf tool — reach for it only when the idea is too unclear to write criteria directly; a clear request needs no ceremony. The output is the intent section of the issue file, approved by the human.
user-invocable: true
---

# Grill

The idea is too vague to build. Close the gap the only way that works: ask the
human, one question at a time, until the intent is concrete enough that a
criterion could fail.

## How to run it

1. **Ground yourself first.** Dispatch the `researcher` for the facts the idea
   touches: what exists today, what the change would collide with. Question
   from knowledge, not from a blank page.
2. **One question per turn.** Ask the single question whose answer most
   constrains the design. Offer the options you see and your recommendation —
   the human picks faster than they draft. Never bundle questions; bundled
   questions get half-answers.
3. **Chase the observable.** Every answer must eventually land as behaviour
   someone could check: "when X, then Y". Push politely past "it should be
   better" until you have a falsifiable sentence.
4. **Stop when criteria stop changing.** When two consecutive answers refine
   wording but not substance, you are done — more grilling is ceremony.

## The output

Write the result into the issue file as acceptance criteria — numbered,
observable, each one falsifiable — plus the decisions made along the way, each
attributed to the human's answer. Show the criteria to the human for approval:
this is the first of their three steering points, and the one place a run
genuinely waits.
