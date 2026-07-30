---
status: active
branch: claude/subagenten-anfragen-optimieren-seqel6
pr:
---

# A dispatch makes the subagent rediscover what the caller already knows

## Intent

Nothing says what a dispatch carries. Every subagent starts from near zero and
rediscovers what the conversation already established: which issue is running,
which files the change touches, the command that runs the suite, the decisions
already recorded. That is paid for twice — issue 0025 measured a run in which
cache reads dominated cache writes 16×, so the cost follows steps × the context
each step carries — and the rediscovered answer can differ from the one the
caller already has, which is the worse of the two.

The opposite extreme is worse still: three of the workflow's agents earn their
value by *not* having seen something. The `reviewer` never sees the
implementer's reasoning, the `test-author` never sees the implementation, the
clean-room expert sees no code, no docs and no leaning. Handing them the
conversation's context to save steps would buy the saving with the only thing
they are for.

Wanted observable behaviour: a dispatch hands the subagent the facts the caller
already has, and how far that goes is decided by the receiving agent's own
definition — not by how much could be saved.

Acceptance criteria:

1. When the rulebook is read, it says a dispatch hands the subagent the facts
   the caller already established instead of letting it rediscover them, and
   names what those are.
2. When the rulebook is read, it states the limit: the receiving agent's own
   definition. Where that definition says the agent must not see something,
   that is not handed over, whatever the saving would be.
3. When a fact is handed to the `researcher`, its definition tells it to treat
   that fact as given rather than as one of its own evidenced claims.
4. When this change is finished, nothing in it widens what the `reviewer`'s
   prompt carries: the repository root and the diff range, as its page already
   says.

## Plan

## Tasks

## Decisions

- **The rule is stated once, in the rulebook, and bounds itself by the agent
  pages instead of listing exceptions.** Source: the rulebook's own simplicity
  rule. A list of "hand this to the implementer, not to the reviewer" would
  duplicate what each agent page already says and drift from it.
- **The change is implemented without dispatching the `implementer`.** Source:
  default, unanswered. It is roughly a dozen lines of prose across two files;
  the brief a dispatch would need is longer than the diff. Recorded because the
  run's diagram names the implementer.
- **No test-author is dispatched.** Source: the rulebook's invariant 2. The
  change is prose in the rulebook and an agent definition — nothing a tool
  checks, so there are no tests to write. `./test.sh` is still run for the
  regression fact.

## Log

- Collision check before any edit, as the human asked. Read all four agent
  definitions and all four non-bootstrap skill pages against the intended rule:
  - `implementer` — no collision. Its brief is its contract and a missing fact
    makes it stop and return `blocked`; more handed facts mean fewer stops.
  - `researcher` — no collision with the dispatch, but its rule "every claim
    carries its evidence" leaves a handed fact ambiguous: verify it, or report
    it as its own? Hence criterion 3.
  - `test-author` — partial collision. Conventions, layout and the test command
    may be handed; the implementation or the intended solution may not, because
    working from the intent alone is what keeps its tests free of an
    implementer's misreading.
  - `reviewer` — direct collision. Its page already fixes what its prompt
    carries (repository root, diff range) and says the caller does not hand it
    the intent — it fetches that itself. Hence criterion 4.
  - `clean-room` — direct collision, and its own page already owns it: no code,
    no docs, no leaning.
  - `grill`, `plan`, `issue` — no collision; the first two only dispatch the
    `researcher`.
- Facts before the first review: `./test.sh`, 3 suites, 30 cases, exit 0 — a
  regression fact only, since no harness asserts on the content of `AGENTS.md`
  or an agent page. No static analysis exists: `which shellcheck markdownlint
  vale` finds none, and there is no `package.json`, `Makefile` or lint config.
- **Review round 1 — fresh context**, dispatched with the repository root and
  the diff range and nothing else, which is the new rule applied to the
  `reviewer`. Two findings, both on criterion 2, both fixed:
  1. The bound was keyed on "must not see", but the `reviewer`'s page phrases
     its constraint as *fetch the intent yourself*. A caller could hand the
     reviewer the criteria without breaking the letter of the bound — exactly
     what criterion 4 forbids. Fixed: the bound now covers a fact the page
     tells the receiver to fetch for itself.
  2. The bound was keyed on "the receiving agent's own page", and the
     `clean-room` skill dispatches a general-purpose agent that has no page —
     so its receiver had no limit at all. Fixed: the bound now names the skill
     page where a skill defines the dispatch.
  - Dismissed: the observation that a universal rule sits in the section about
    shelf tools. No reproduction, and that section already carries the only
    other dispatch rule — the `researcher` line the new text follows.
- Observation, not caused by this change: the round-1 reviewer reported that
  the definition it was given lacks the record and blast-radius checks. The
  file is not the cause — `diff /root/.claude/metis/agents/reviewer/agent.md
  agents/reviewer/agent.md` is empty and the clone stands at `2932063`, the
  commit that added those checks. What is stale is the definition this session
  registered at start: the agent list in the session's own prompt still carries
  the pre-`2932063` reviewer description. So a session can register a subagent
  from the clone as it was before the start hook updated it. Filed as its own
  issue, not fixed here — it makes the new bound read from a stale page.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes. The human asked for dispatches that
  leave the subagent less to discover, and for a collision check against the
  agent definitions before any edit. The collision check is done and recorded
  above; it is what turned the request into a rule with a bound rather than a
  rule alone.
- What surprised me? That the collision is not an edge case: three of the five
  dispatch targets are defined by what they must not see. A rule phrased as
  "hand over everything the conversation has" would have been wrong for the
  majority of dispatches.
- What am I assuming without having verified it? That stating the bound as "the
  receiving agent's own definition" is enough for a future caller to apply it
  correctly, without the rulebook naming the three blind agents. Not verified —
  the reviewer is the check on it.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
