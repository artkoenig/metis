---
status: active
branch: claude/metis-plugin-config-jstgt0
pr:
---

# A result report names no base and decisions drown in the log

## Intent

Three findings from one retro, all about how a run reports and records what it
did.

**Green without a base.** The rulebook requires the suite to pass before the
pull request and to be reported by command and count. It says nothing about
what the command ran against. Four times a run reported green while the
default branch was already failing; each time the sentence was rewritten by
hand into "no new failure", and each rewrite was a judgment nobody had
recorded. Once the gap only surfaced in the pull request: the branch passed
locally, the merge of branch and default branch did not, and continuous
integration found what the run had not.

**Decisions drown in the log.** An issue file keeps Decisions and Log apart
already. In one run the Decisions section still grew past a hundred lines,
because entries were written as stories — which review round found the
problem, what held before it, why the earlier reading was wrong. A reader
looking for what currently holds has to reconstruct it from the narration.

**Texts that presuppose.** The failure is not a missing cross-reference — it
is a text that assumes knowledge its reader does not have, and often cannot
get. A passage that says "the class invariant 3 names"
is unreadable without counting invariants first, and a term used before it is
explained sends the reader elsewhere. The rulebook does this to itself in one
place. The rule the retro asks for is about how every text is written,
including the rulebook.

Wanted: a reported result that names what it ran against, a decision that can
be read in one line, and texts that carry their own meaning.

Acceptance criteria:

1. When a run reports that checks pass, the rulebook requires the report to
   name the base the checks ran against, not only the command and its
   coverage.
2. When the default branch already fails a check, the rulebook says what to
   report instead of a pass: the same command on the base, and the difference
   between the two runs.
3. Before the pull request, the run fetches the default branch and runs the
   checks on the merge of it and the branch, so a failure that exists only in
   the merge is found before the pull request rather than by continuous
   integration.
4. The `issue` skill states that a Decisions entry says what holds now and
   where it came from, and that the history behind it — the round that found
   it, the reading it replaced — belongs in the Log.
5. The rulebook requires a text to assume no knowledge its reader does not
   have — naming what a rule says rather than its number, and explaining a
   term where it first appears.
6. The rulebook holds to criterion 5 itself: no passage in it identifies a
   rule only by its position.

## Plan

## Tasks

## Decisions

- Criterion 4 sharpens what a Decisions entry is, instead of moving the Log
  into a second file. The retro named the separation, and the sections are
  already separate — what failed is the writing, not the structure, and a
  second file would cost the "one issue is one file" property and make
  orienting a session read two. Source: default, unanswered — the human was
  asked and did not answer.

- Criterion 5 is about presupposition, not about cross-references. The first
  wording of both the criterion and the rule said "never send the reader
  elsewhere", which describes a text that points somewhere; the failure being
  fixed is a text that assumes what the reader already knows. Source: the
  human, mid-run.
- The rule criterion 5 adds stays inside the paragraph on talking to the
  human, although a session about to write a skill page has no reason to look
  under a heading about the human. Source: the human's request named that
  section as the place for it.
- The reviewer names the state its checks ran on but does not produce it: the
  fetch and the merge belong to the session that dispatches it, because a
  reviewer that merges is no longer read-only. Source: default, unanswered.

## Log

- Review round 1: seven findings, six fixed in this run, one dismissed.
  1. The two agent pages that actually run the checks — reviewer and
     implementer — still asked for command, coverage and exit code with no
     state, so an agent following its own page reports exactly what the new
     invariant forbids. Reproduced by the reviewer against its own
     instructions. 2. The merge step named no branch for a failing fetch or a
     conflicting merge, while every other clause of that invariant names its
     fallback. 3. The new writing rule sits under the heading about the human
     — dismissed, see Decisions. 4. The rulebook used "the `issue` skill"
     before explaining it, breaking the rule it had just added. 5. Removing
     the reference to an invariant's number left two copies of one class list
     that already differed ("a rule" against "the rulebook"); invariant 2 now
     names the class instead of listing it. 6. "Merge it in" left open
     whether the merge commit stays in the branch. 7. The new sentence about
     decision entries sat behind the skill's interface line, where a caller
     reading only the operations table would not see it.
- Review round 2: five findings, four fixed in this run, one for the human.
  1. The decision that the session, not the reviewer, produces the merge was
     recorded but shipped nowhere, so no text told anyone to do it — and the
     reviewer's page demanded a state its own read-only rule forbids it to
     create. The run section now assigns the fetch and the merge to the
     session. 2. Criterion 3 asks for a fetch and the rulebook never
     instructed one; a session merging a stale local copy of the default
     branch satisfied the wording and still shipped what continuous
     integration would reject. Now explicit: fetch from the remote. 3. The
     writing rule against presupposition read as forbidding any pointer,
     which collides with the tracker skill describing its own parts and
     nowhere else. Reviewed against the wording before the correction above;
     the corrected sentence forbids assuming what the reader knows, not
     naming an owner. Left to the human rather than fixed. 4. The run diagram
     labelled the checkpoints by ordinal, which the reader can only resolve
     by counting — the failure criterion 6 names, in a passage the diff had
     not touched. Both diagrams now name the moment. 5. Four lines this diff
     created broke the paragraph wrap of their own files.
  The round also named a risk outside the criteria: nothing stopped a
  conflicted merge from reaching a commit. The run section now says such a
  merge is undone and reported, never committed.
- This branch carried a different change first: an idempotent session-start
  loader, filed as issue 0021 with five further issues around it, seventeen
  commits, suite green. The human dropped it in favour of these three retro
  points. The work is reachable at commit `6ca8a26` and the issue number 0021
  was reused, because nothing of the old branch remains.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes. The human named three points of a
  retro list and said everything else leaves this pull request. Criteria 1 to
  3 are the first point, criterion 4 the second, criteria 5 and 6 the third.
- **What surprised me?** The rulebook breaks the rule the third point asks
  for, in the sentence that defines when a change has no tests to write. It
  refers to a class by the number of the invariant that names it, so the
  reader has to count invariants to know what the sentence excludes.
- **What am I assuming without having verified it?** That criterion 3 costs
  little in practice. Fetching the default branch and testing the merge adds a
  step before every pull request, and I have not measured it on a repository
  where the suite is slow or the merge conflicts. On this repository the suite
  runs in seconds.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
