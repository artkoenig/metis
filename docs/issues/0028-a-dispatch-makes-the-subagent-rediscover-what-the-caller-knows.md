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
4. When the `reviewer` is dispatched, its prompt carries the repository root,
   the diff range, and the issue's problem statement and numbered criteria
   copied word for word — and its page no longer tells it to fetch the intent
   itself.
5. When written intent is handed to any receiver, the rulebook requires it
   copied rather than retold — not reworded, not summarised, not extended.
6. When the `reviewer` reviews, its page has it judge every changed file
   against the intent, the issue's own record included wherever the diff
   carries it — and it reaches the record that way rather than through tracker
   access of its own.

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
- **The `reviewer` is handed the intent instead of fetching it, and is handed
  intent and criteria only.** Source: the human's answer, mid-run. This
  reverses what its page said — that the caller does not hand it the intent —
  and it collides with nothing: invariant 3 asks for a reviewer that has seen
  only the diff and the written intent, which is exactly what it now gets. What
  it must not see is the caller's reasoning, and that is unchanged.
- **Intent and criteria are copied from the issue word for word, never retold.**
  Source: the human's answer. The caller is the party whose drift the receiver
  exists to catch, so a reworded criterion would have the receiver check the
  work against the caller's reading instead of against the intent. The rule is
  written for every dispatch, not only the reviewer's.
- **The `reviewer` keeps judging the issue's record, and reaches it through the
  diff.** Source: the human's answer to "why should that check go?". It was
  wrong to remove it: the record is a changed file in the diff — `git diff
  --name-only origin/main HEAD` lists this issue's own file — so the reviewer
  needs nothing handed and no tracker access to see it. Everything in the diff,
  record included, is judged against intent and criteria; what no criterion
  asked for is a finding, which is also how out-of-scope work gets rejected.
- **No `researcher` was dispatched for the grilling round.** Source: default,
  unanswered. The facts the questions touched were already established in this
  session; dispatching would have been exactly the rediscovery this issue is
  about. Recorded because the `grill` skill's first step names the researcher.
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
- After round 1 the human reversed the `reviewer`'s constraint: it is handed
  intent and criteria instead of fetching them. Implementing that, the
  record-against-the-diff check and the `Skill` tool were removed with it
  (commit `a886e9d`) on the reasoning that the check had lost its input. Wrong,
  and the human caught it: the record is a file *in the diff*, so the check
  needs nothing handed. Restored in the form the human named — every changed
  file, record included, judged against intent and criteria. The removal
  survived one push; no review round ran against it.
- Criteria revised mid-run after that reversal: old criterion 4 asserted the
  opposite of the decision and was replaced; 5 and 6 added for the copied-intent
  rule and the record reached through the diff.
- **Review round 2 — the same context continued**, dispatched under the new
  rule: repository root, diff range, and the intent copied word for word. The
  reviewer verified the copy byte for byte against the issue file and reported
  `diff -u` exit 0. Two findings, both fixed:
  1. The halt sentence added to the reviewer's premise — "if the intent is too
     thin, say so and stop" — served no criterion and sat before check 1, so a
     halt would drop the suite and static-analysis facts invariant 4 requires.
     Removed. The gap it tried to cover is real but outside this intent, so it
     is filed as its own issue rather than fixed here.
  2. Merging the record check into check 2 kept "a recorded decision the diff
     contradicts" and lost the rest of the removed check's cues. Shown by this
     run: round 1's first finding was reached through a checkpoint answer, an
     admitted-unverified assumption that contradicted nothing. Restored — the
     record's parts are named again, and so are the three places to look
     hardest.
  - Not a finding, flagged for me to disagree with: `0029` in the diff serves
    no criterion. It stands as filed-and-waiting work, which the rulebook asks
    for; the same holds for `0030`.
- **Review round 3 — the same context continued.** One finding, and it is
  against the caller, not the diff: the round-3 dispatch broke the very bound
  this change installs. Beyond the three permitted items it carried my account
  of what I had fixed and my characterisation of `0030` as "the filed-and-
  waiting form of the gap" — handed before the reviewer had read either file,
  which is exactly the anchoring the reviewer's page forbids. Round 2's
  dispatch did the same in smaller degree. No file needs changing; the fix is
  the caller's conduct, and the rule that catches it was already in the diff
  it was reviewing. Triaged as fixed in conduct, carried into the retro.
- Round 3 also flagged a historical line-number pointer in `0030` — corrected,
  the sentence now names the place without the numbers.
- Reviewing stopped after round 3. Its only finding needs no change to any
  file, so a further round would re-read an unchanged diff; and the anchoring
  it names has already happened in that context and cannot be undone by
  another round in it.
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

- Does this match what was asked? Yes, and further than the opening request:
  the human asked for dispatches that leave less to discover, then decided
  mid-run that the reviewer is handed intent and criteria copied word for word,
  and that everything in the diff — the record included — is judged against
  them. All three are in the change.
- What surprised me? That I broke the rule in the act of shipping it. Round 3's
  dispatch carried my account of what I had fixed and my reading of a file the
  reviewer was there to judge. The rule is one sentence and I violated it one
  message after writing it, which says the danger is habit, not ignorance.
- What am I assuming without having verified it? Two things. That copying the
  recorded intent is enough — a recorded intent that is thin passes through
  untouched, which is filed as `0030` and not solved here. And that the
  reviewer's dispatch was the only place my own reasoning leaks into a
  receiver; I did not examine the implementer or test-author dispatches,
  because this run made none.

## Retro
