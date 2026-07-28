---
status: backlog     # backlog -> active -> done; waiting = parked on a question
branch:             # set as soon as one exists
pr:                 # set when the PR is opened — set status: done with it
---

# <title>

<!--
Copied from the `issue` skill. Delete every comment in this file when filing —
they are instructions for filing, not part of an issue.

Name the file docs/issues/NNNN-slug.md: four digits, zero-padded, the next
number after the highest already filed, never reused.

Keep every heading below, including the ones you leave empty. Their names and
order are the interface between the agents that read and write this file; the
content is yours. They fill in run order, so the filled sections ARE the
progress: Intent only = not started; Checkpoint 1 answered = implementing;
Checkpoint 2 answered = in review; Retro written = finished.
-->

## Intent

<!-- The problem and the desired observable behaviour, solution-free. -->

Acceptance criteria:

1. <!-- numbered, observable, falsifiable — "when X, then Y" -->

## Plan

<!-- Optional content; the `plan` skill writes it when the change spans
     modules. Keep the heading either way. -->

## Tasks

<!-- Optional content; only when the change is too big to land whole. Mid-run
     work that serves the intent joins this list; anything else becomes a new
     issue file. Keep the heading either way. -->

## Decisions

<!-- What was settled and why — one entry each, with the source it derives
     from. Defaults marked as defaults. Questions to the human and their
     answers. Nothing else: a reader arriving mid-run must reach the
     load-bearing decisions without wading through the run's process. -->

## Log

<!-- The run as it happened, oldest first: observations (repetition / surprise
     / regression), review rounds and how their findings were triaged,
     attempts that failed and why. This is the section that grows; keeping it
     out of Decisions is what keeps Decisions readable. -->

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

<!-- After the PR: what got in the way, what should change. Rule-change
     proposals go to the metis repo. -->
