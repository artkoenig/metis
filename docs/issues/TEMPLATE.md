---
status: backlog     # backlog | active | waiting | done
branch:             # set as soon as one exists
pr:                 # set as soon as one is open
---

# <title>

<!--
The sections below are the interface between the agents that read and write
this file — their names and order are fixed, their content is free. They fill
in run order, so the filled sections ARE the progress: Intent only = not
started; Checkpoint 1 answered = implementing; Checkpoint 2 answered = in
review; Retro written = finished. Delete these comments when filing.
-->

## Intent

<!-- The problem and the desired observable behaviour, solution-free. -->

Acceptance criteria:

1. <!-- numbered, observable, falsifiable — "when X, then Y" -->

## Plan

<!-- Optional; the `plan` skill writes it when the change spans modules. -->

## Tasks

<!-- Optional; only when the change is too big to land whole. Mid-run work
     that serves the intent joins this list; anything else becomes a new
     issue file. -->

## Decisions

<!-- One line each, as they happen: decisions with their source, defaults
     marked as defaults, observations (repetition / surprise / regression),
     questions to the human and their answers. -->

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
