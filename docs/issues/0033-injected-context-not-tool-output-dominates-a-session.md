---
status: backlog
branch:
pr:
---

# Injected context, not tool output, dominates a session

## Intent

The command issue 0025 produced was run on the session that built it, and the
first thing it showed contradicts the assumption that session had been working
from. `python3 skills/cost/assets/token-cost.py`, exit 0:

| where the main session's 381,533 cache-write tokens entered | tokens |
| --- | --- |
| hook and attachment output | 235,418 |
| the agent's own tool calls | 57,479 |
| Bash tool output | 37,500 |
| the agent's own output | 19,390 |
| later user messages | 16,118 |
| Read tool output | 10,025 |

Injected context is 62% of it. Every file every agent in that run read came to
10,025 tokens — 2.6%. The most expensive single item of the entire run,
subagents included, is a `skill_listing` attachment at step 69 costing 141,999
tokens, and the skill list is injected whole more than once: steps 1, 47, 65
and 69, alongside `deferred_tools_delta` at 21,270 and `agent_listing_delta`
at 7,132.

This lands in the session that carries 69% of the run's cache-read, so every
step after it carries it again.

That session had spent its effort on three proposals for making subagents
cheaper — trimming the rulebook they inherit, bounding noisy command output,
batching tool calls. All three aimed at the smaller share, and the largest
item turned out to be something no agent chose to read.

What is not yet known, and what this issue exists to establish: whether the
repeated injections are caused by anything on this side — how many skills and
plugins this setup enables, a hook, an MCP server reconnecting — or whether
they are the harness's own behaviour and nothing here can change them. The
measurement says where the tokens went; it does not say who put them there or
whether that was avoidable.

Wanted observable behaviour: the cause of the repeated whole-list injections
is established by a command rather than argued, and whatever part of it this
setup controls is reduced, with the before and after shown by the same
command.

Acceptance criteria:

1. For each whole-list injection the command reports in a session — every
   `skill_listing`, `agent_listing_delta` and `deferred_tools_delta` item —
   the run records what triggered it, established by evidence rather than
   inferred, or records that it could not be established and how it looked.
2. Where a trigger is under this setup's control, the change reduces it, and
   the reduction is shown by `python3 skills/cost/assets/token-cost.py` run
   before and after in comparable sessions, both exiting 0.
3. Where a trigger is not under this setup's control, that is recorded as a
   fact with the evidence for it, and nothing is changed on account of it.
4. No skill, agent or plugin this setup relies on stops being reachable: the
   session self-check reports the same skills and agents after the change as
   before, by exit code.
5. The three subagent proposals this finding displaced — the inherited
   rulebook, bounded command output, batched tool calls — are each either
   measured with the same command or recorded as still unmeasured; none is
   presented as a saving without a before-and-after figure.

## Plan

## Tasks

## Decisions

## Log

- Found by running issue 0025's own command on the session that produced it,
  immediately after the implementer returned. Filed rather than fixed, because
  it serves no criterion of issue 0025 and belongs in a diff of its own.

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
