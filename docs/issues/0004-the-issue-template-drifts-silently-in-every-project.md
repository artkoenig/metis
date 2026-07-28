---
status: waiting
branch: 004-template-drift
pr:
---

# The issue template drifts silently in every project that uses it

## Intent

The SessionStart hook keeps `agents/` and `skills/` current by symlinking them
out of the metis clone: change one here, and every bootstrapped project has it
on its next session start. `docs/issues/TEMPLATE.md` is not covered by that.
It is copied into each project when the tracker is set up, and from then on it
is a private fork that no mechanism ever updates or compares.

This is not hypothetical. Metis has existed for one day and has two projects
using it, and the copy had already gone stale: `003` changed the status
semantics, and the copy in `tome_of_battle` went on telling every newly filed
issue that `pr` is "set as soon as one is open" and that `waiting` still means
awaiting a merge. It was caught because someone happened to remember, which is
not a mechanism.

It is also the same defect the bootstrap skill was built to eliminate. Its
loader/core split exists because the predecessor carried its sync logic in the
per-project hook copy, so a workflow change never reached an already-wired
project. The template is that bug, surviving in the one file the split does
not cover.

Wanted: no project has an issue template at all, and the shape is stated in
exactly one place. Filing an issue is a procedure, not an invariant, and
procedures in this workflow are skills — which the core already symlinks into
`~/.claude` alongside the subagents. The delivery problem was solved before it
was posed; it only had to be recognised as the same problem.

Acceptance criteria:

1. The `issue` skill exposes **operations, not fields**. Its page lists each
   operation a caller can ask for and what content the caller hands it. No
   caller states where that content goes.
2. Two properties, and they hold together:
   - *Absence.* No file outside `skills/issue/` states a path, a filename, a
     frontmatter key, a heading, or what belongs under one. A caller names an
     operation and hands over content. The one exception is a document the
     `issue` skill itself names as the owner of one part — that document says
     what that part contains, and nothing else about the tracker.
   - *Presence.* `skills/issue/SKILL.md` covers every frontmatter field and
     every heading the template contains: it either describes the part itself,
     or names exactly one other document that owns it.

   Presence is not decoration. Without it, deleting the information everywhere
   satisfies absence — which is how `branch` came to have no stated meaning at
   all.

   `README.md` and the rest of the documentation are out of scope for both
   halves: they are written for a human reader, and a page of pointers serves
   nobody. They repeat, they never define.
3. `AGENTS.md` reaches the tracker only through operations, and restates
   nothing of what the file looks like or what the states mean — except the
   parts the skill hands it by name.
4. Nothing writes a template into a project: no step in
   `skills/bootstrap/assets/session-start-core.sh` copies one, and
   `skills/bootstrap/SKILL.md` claims none.
5. Issue files are named `NNNN-slug.md` — four digits — and the four already
   filed are renamed, so that a fifth cannot sort ahead of the first.
6. An agent that has only the skill files a file matching the four that exist:
   the H1 title, all seven headings including the empty ones, and the Log's
   ordering are stated, not left to be inferred.
7. No sentence this branch adds is contradicted by the rest of the
   repository. Four consecutive rounds lost to one, so it is a criterion now
   rather than a habit.
8. The documentation matches the state this branch leaves the repository in.
   That is the price of the exemption in criterion 2 — repetition is allowed
   only because it is kept current, and documentation nobody updates is worth
   less than none.

## Plan

## Tasks

## Decisions

- **Source:** noticed while migrating `tome_of_battle` to Metis, and confirmed
  the same day when `003` changed the status semantics in metis and the
  project's copy kept the old ones. The copy was corrected by hand there; this
  issue is about the mechanism, not that one file.
- **Filed rather than fixed on the spot.** It serves no acceptance criterion
  of the migration that surfaced it, so by the rulebook it is a new issue and
  waits for its own run.
- **The shape of the fix was deliberately left open at filing.** A symlink
  like `agents/` and `skills/` is the obvious candidate, but the template is a
  file a project might legitimately want to extend, which a symlink forbids; a
  compare-and-warn keeps that freedom and costs a check. That trade-off
  belonged to whoever ran this.
- **Decided: the template becomes a generated file, refreshed from the clone
  at every session start.** Reasoning, in order:
  - *Not a symlink.* `docs/issues/TEMPLATE.md` is versioned in the project and
    read by humans on GitHub. A symlink into `~/.claude/metis/…` would be
    committed and dangle for anyone without the clone.
  - *Not compare-and-warn.* A warning needs someone to act on it, and the run
    it interrupts is never the run that wants to fix it. That is the
    predecessor's failure mode in a new costume.
  - *Extension is not a freedom worth protecting here.* The rulebook already
    fixes the sections as the interface between the agents that read and write
    the file — "their names and order are fixed". A per-project template that
    diverges is a per-project agent contract, which is the thing the interface
    exists to prevent.
  - *Precedent inside metis:* `AGENTS.md` is already copied into
    `~/.claude/CLAUDE.md` on every session start by the same core. The
    template is the same kind of artifact reaching a different destination.
  - The cost is that a local edit is silently discarded. That is made visible
    by a generated-file notice in the template itself, naming where to edit it
    instead.
- **Only for projects that already use the tracker.** The refresh writes into
  an existing `docs/issues/`; it never creates one. A project without a
  tracker has not opted in, and metis does not conjure a directory into it.
- **Superseded — the refresh decision above is withdrawn, and with it the
  criteria it was built against.** Kept in the record because the reasoning
  is what got refuted, and a decision log that only shows what survived
  teaches nothing. What refuted it:
  - *The human's question:* why is the template copied at all? Nothing in the
    original reasoning answers it. It weighed symlink against compare-and-warn
    and never asked whether a project needs the file.
  - *The grep:* `TEMPLATE.md` is named by the core script, by `SKILL.md`, by
    `AGENTS.md` and by itself. No agent definition and no skill reads it. Its
    only reader is the caller, which already holds the rulebook.
  - *The review:* the mechanism did not even work. The core runs only in cloud
    sessions — the loader exits before `exec bash "$core"` on every local path
    — so a project opened only locally never gets the refresh and is never
    told it drifted. Criteria 1 and 2 were unmet, and two sentences the change
    added to `AGENTS.md` and `SKILL.md` were false.
  - *The argument I gave for keeping it in the project* was that a human reads
    it on GitHub. The rulebook is not in the project either, and nobody has
    missed it.
- **Decided instead: `AGENTS.md` carries the section interface, and nothing is
  delivered anywhere.** The interface is seven section names with a line each
  — a table in a page that already reaches every session. `TEMPLATE.md` stays
  in metis as the long form and names the rulebook as the authority.
- **The residual risk, stated rather than denied:** the interface now exists
  in two levels of detail, and they can diverge. The difference from what was
  reverted is that both live in this repository, one diff shows both, and a
  reviewer reads both. It is the same failure mode one storey up and far
  cheaper.
- **Projects that already carry a copy** — `tome_of_battle` has one — are not
  touched from here. Removing it is a change in that repository, on its own
  branch. It is a removal, not an update: the `sync-template` branch already
  pushed there brings the copy up to date, which is the wrong repair, and it
  is superseded by a branch that deletes the file.
- **Superseded again — the rulebook-carries-the-table decision is withdrawn.**
  It removed the copy but kept the duplication: `AGENTS.md` restated the
  template instead of replacing it, and the review found the two levels of
  detail already disagreeing on the day they were created.
- **Decided: the shape moves into a skill, `skills/issue/`, with the template
  as its asset.** The human proposed it, and it is better than what it
  replaces on every count that mattered:
  - *The delivery mechanism already exists.* The core symlinks `skills/` into
    `~/.claude` exactly as it does `agents/`. No copy, no refresh step, no
    cloud/local asymmetry — the failure that killed the first design.
  - *One source instead of two.* Four of the five findings from review round 2
    exist only because `AGENTS.md` retold the template; they disappear rather
    than getting fixed.
  - *The rulebook gets shorter.* A one-page rulebook that had grown a
    seven-row table loses it again.
  - *It is the honest classification.* Filing an issue is a procedure. The
    invariants are what always holds; a procedure with steps is a skill.
  - The one thing it costs: skills are invoked, not read. So the bookkeeping
    rule has to say an issue is filed *through* the skill — this is the one
    skill that is not a shelf tool.
- **Rejected: a version field in the template, for migrations.** The human
  raised it; the argument against is that an issue file is prose read by a
  language model, not a record parsed by a schema. A schema needs migrations
  because a missing field breaks it; prose does not — an issue without
  `## Log` is one filed before `## Log` existed, and the file says so by not
  having it. A version would duplicate what is already visible and would need
  its own migration path to maintain. There are nine issue files in existence;
  a shape change is one pass, not a pipeline. Recorded in the skill together
  with what would change it: a section that keeps its name and changes its
  meaning, which an old file does not reveal.
- **Four digits instead of three**, on the human's instruction: more headroom.
  The four existing files are renamed in the same change, because `0005` sorts
  before `001` and a mixed directory loses the ordering the padding is for.
- **Decided by the human, after a grilling session, four answers that settle
  where a fact about an issue file lives.** The grilling was called because
  criterion 1 had been missed three rounds running and the fourth round would
  have been the fourth patch:
  - *There are no copies in projects, full stop.* The first answer was that
    metis outranks a target project, and the human then sharpened it: a
    precedence rule presumes two versions, and there are never meant to be
    two. The copy in `tome_of_battle` is not a stale peer to be reconciled,
    it is a bug — it gets deleted, not synchronised. A rule for resolving a
    conflict that cannot arise is machinery this workflow exists without.
  - *The `issue` skill outranks everything inside metis for the issue file,
    and it owns the file whole* — the fields, the sections, and what they
    mean. A reference to the skill names it and stops; it does not expose the
    skill's internals by retelling them.
  - *Therefore the frontmatter semantics leave `AGENTS.md`.* The rulebook
    keeps the run and says an issue is filed through the skill; the skill
    keeps the file. The previous cut — shape in the skill, meaning in the
    rulebook — is what rounds 2 to 4 kept falling through, because every move
    left the question open which half was moving.
  - *Skill and template are assumed consistent, and that assumption is not
    checked.* Both live in `skills/issue/`, the template is a bare skeleton,
    and a mechanical check would only cover the enumerable part anyway. The
    human took the risk deliberately over the cost of a script and a rule.
- **A skill is a class, on the human's instruction.** The four decisions above
  settle where the issue file is described; this settles the general rule they
  are an instance of. A skill declares an interface and hides how it works
  inside, so that changing the inside costs nothing outside. Landed in two
  places, because they are two different statements: `AGENTS.md` says it of
  skills in general, and `skills/issue/SKILL.md` declares its own public
  surface — the directory, the filename form, the frontmatter keys and their
  values, and the heading names. Everything else, above all *what belongs in
  each section*, is behind the interface. This is what makes criterion 1
  checkable by reading a reference rather than the whole repository: a
  reference is legal if it uses only the declared surface.
- **Criterion 1 rewritten, and this is the actual repair.** The old wording —
  "stated in exactly one place" — describes a state of the repository, not a
  property of a diff. Nothing in a diff shows it, so checking it demands
  reading the whole repository, which is why each round's leftover sat
  somewhere the round did not look. Worse, "zero places" satisfies it: the
  `branch` hole in round 4 was criterion 1 being met by deletion. The new
  wording has two halves, an absence and a presence, and the presence half is
  the one deletion cannot satisfy.

## Log

- **First implementer dispatch returned `blocked` against the wrong
  repository.** It worked in `/home/user/global-agents-config-and-skills` —
  the predecessor workflow — and reported, accurately for that repo, that
  there is no loader/core split, no `docs/issues/TEMPLATE.md`, no
  `skills/bootstrap/`, and no `## Bookkeeping` section. Every one of those
  exists in `/workspace/metis`. Cost: one dispatch, no edits.
- **My briefing defect, found by the same dispatch.** The brief named
  `assets/session-start-core.sh`. The real path is
  `skills/bootstrap/assets/session-start-core.sh`; `SKILL.md` refers to its
  own assets relatively and I copied that shorthand without qualifying it. A
  brief that names a path names it from the repository root or it names
  nothing.
- Both corrected and the same agent re-briefed rather than re-dispatched, so
  what it had already established about the predecessor repo is not paid for
  twice.
- **Implementation landed as `8c2e230`.** The implementer reported `done` and
  flagged one thing rather than fixing it: in a metis cloud session the
  refresh overwrites the checkout's template from the clone of pushed `main`.
  It also caught a defect of its own making before shipping it — a self-copy
  would have aborted the core under `set -euo pipefail` before it emits the
  hook JSON, costing the session `reloadSkills` — and it refused to let a
  vacuous assertion pass, building the naive `mkdir -p` variant to watch its
  own check go red first.
- **Review round 1, triage.** Four findings; the reviewer re-ran the harness
  itself, and additionally verified against the pre-change baseline and
  against the naive variant instead of trusting the implementer's account.
  - *Blocking:* the core never runs in a local session, so the refresh reaches
    cloud sessions only. Criteria 1 and 2 unmet, and two sentences the change
    added were false. Reproduced with a drifted template: loader exit 0, no
    core in the log, template unchanged.
  - *Confirmed, no criterion violated:* the metis self-overwrite. The
    reviewer's verdict — outside the criteria, but it inverts the premise the
    decision rests on, because in metis the clone is the older thing.
  - *Confirmed:* the `-ef` guard is dead on every path where the core runs.
  - *Low:* `SKILL.md` misdescribed which comment block holds the notice.
  - The harness itself had the blind spot that let the first finding through:
    it invokes the core directly and never the loader, so nothing in it
    asserts that a session ever reaches the refresh.
- **`8c2e230` reverted as `5a47ad5`** — the four implementation files back to
  `cc315b5`, this issue file kept. Three of the four findings exist only
  because a copy exists; the fix is to stop copying, not to patch the copier.
- **Perception rule note:** this is not *repetition* — one attempt, one set of
  findings. It is *surprise* in the rulebook's sense: the mechanism behaved
  differently than the decision assumed, and the decision was the thing that
  had to change.
- **Round 2 built the rulebook-carries-the-table design (`6b2df81`), and the
  review found five things.** One — `SKILL.md` claiming the loader is the only
  file metis puts into a project, two sections above a step that installs a
  second — was a false sentence the change itself added, the same defect class
  as round 1. Four were consequences of the duplication: the `## Log` ordering
  rule existed only in the template, the H1 title line was never mentioned in
  the rulebook, the template pointed at "the same table" while containing no
  table, and whether an empty optional heading stays was left ambiguous. The
  reviewer proved the divergence was already present rather than merely
  possible, on the day it was introduced.
- **`6b2df81` reverted as `db1ea7c`.** The five findings were not fixed: four
  of them cease to exist under the skill design, and fixing them would have
  been work spent on an approach about to be replaced.
- **Review round 3 — and the perception rule fired.** Criterion 1 was missed
  in round 2 and again in round 3, each time with a different finding. Under
  the rule as `0001` widened it — *the same acceptance criterion missed twice,
  whatever the finding* — that is a stop signal, and the question it forces is
  the right one: is the shape stated in too many places by construction? It
  was. The answer was structural, not another patch: the template is now a
  bare skeleton and the skill's table is the only description of what goes in
  a section. Round 3's findings 2, 4 and 5 all dissolve in that one move.
  This is the first time a perception rule has fired in anger, and it earned
  its keep — two rounds of patching would each have looked reasonable.
- **Round 3 triage.**
  - *Fixed by the structural move:* the template shipped the status semantics
    the skill disclaims (finding 2); the skill and the template each described
    the sections (finding 5); "delete the HTML comments" missed the YAML ones
    (finding 4).
  - *Fixed:* `AGENTS.md` enumerated the frontmatter fields after delegating
    them — it now states what the states mean without listing the shape
    (finding 3); one sentence described filing without routing through the
    skill (finding 6).
  - *Refuted:* a newly added skill does not reach a local session. The
    reviewer traced it correctly through the loader and the core, and named
    the one precondition it could not check from inside the repository — the
    layout of the human's own `~/.claude`. The human answered: `~/.claude` is
    itself a symlink, so the whole directory hangs off the clone and a new
    skill is present the moment it is in the clone. The per-item symlinks the
    reviewer reasoned from are this container's, created by the predecessor's
    hook, not the human's. Filed as `0005` and deleted again when the answer
    came; criterion 1 is met.
  - Worth keeping from it: the finding was correct in its reasoning and wrong
    in its premise, and only the human could say which. A reviewer that names
    the precondition it could not verify is worth more than one that either
    swallows the finding or asserts it.
- **Review round 4 — criterion 1 missed a third time, and the sweep is why.**
  Four findings, all of them things the previous three rounds never looked at:
  - *`skills/plan/SKILL.md` describes `## Plan` too*, differently — it wants
    one sentence per non-obvious choice, the issue skill's table wants
    boundaries, and neither cites the other. The old template had *delegated*
    that row ("the `plan` skill writes it"); round 3 replaced a pointer with a
    competing description. Fixed by delegating again: the table now hands
    `## Plan` to the plan skill and describes nothing.
  - *`branch` had no stated meaning anywhere.* The skill deferred the
    frontmatter to the rulebook and the rulebook, after round 3's fix, no
    longer mentions the field — while its own orientation protocol tells a
    session to open "the one matching the current branch". Fixed: the skill
    states all three fields, and defers only the *status semantics*, which is
    the part the rulebook genuinely owns.
  - *The `## Decisions` / `## Log` boundary was destroyed.* The old template
    said "nothing else" of Decisions and "keeping it out of Decisions is what
    keeps Decisions readable" of Log — the rule `0001` introduced for exactly
    this file's benefit. Stripping the template to a skeleton took it with it.
    Restored in the table.
  - *The falsifiability form* `"when X, then Y"` survived only inside the
    `grill` shelf skill, which the common path skips. Restored.
- **The rule fired twice and did not converge, and that is the finding.** Each
  round's leftover sat in a different file, and round 4 was the first review
  briefed to sweep the whole repository — which is when three of these four
  appeared. That points at the reviews, not at the design: a criterion of the
  form "stated in exactly one place" cannot be checked by reading the diff,
  only by reading everything. Nothing in the rulebook says a criterion can
  demand a sweep rather than a diff.
- **Second reversal on this issue, and it is worth naming as such.** Two
  designs, two refutations, both because the question *who actually needs this
  file?* was asked late. The perception rules do not fire on it — no failure
  repeated, nothing regressed — which is itself the observation: neither
  *repetition* nor *surprise* catches "the problem was framed wrong", and
  what caught it both times was the human asking a question rather than any
  rule.
- **A clean-room second opinion was taken and then set aside.** It arrived at
  writer-owns-the-part with a name-versus-restate distinction, which is close
  to what the human decided independently — worth recording as agreement from
  a source that had never seen this repository. It also proposed a two-column
  part table as the checkable artifact; that was not adopted, because the
  human's cut removes the split the table would have governed.
- **The grilling was restarted once, at the human's instruction.** The first
  attempt asked which failure mode — duplication or hole — should be caught
  mechanically, which presupposed my own answer and offered three variants of
  it. The instruction: forget the solution, grill on the original problem. The
  four decisions above came out of the second attempt. The lesson is about
  briefs to humans as much as briefs to subagents — a question whose options
  are all one design is not a question.
- **Review round 5 — first round under the ownership model, and criterion 1
  failed a fourth time.** The reviewer swept all eleven markdown files and all
  four shell scripts, not the diff. It reported no test suite and no
  `shellcheck` in the container, and fell back to `bash -n` on the four
  scripts, exit 0 each — none of them touched by this diff. Criteria 2 to 5
  met, with the evidence named per criterion.
- **Round 5 triage.**
  - *Blocking, fixed:* `skills/grill/SKILL.md` described what belongs in
    `## Intent` and `## Decisions`, near-verbatim on the criteria triple, and
    never named the `issue` skill. Round 4 created this one: it copied
    `"when X, then Y"` into the issue skill and left the grill copy standing.
    Grill now names the two sections and points; its own stopping rule refers
    to the form instead of restating it.
  - *Blocking, fixed in the criterion rather than the code:* `skills/plan/`
    describes `## Plan`, which the issue skill delegates to it by name — the
    round-4 fix, deliberate and correct. The criterion forbade the very
    mechanism the design uses, and on its presence half the delegated row read
    as a hole. The reviewer refused to pick a reading and stated the
    reproduction for both, which is the right call: only the author of a
    criterion can say what it meant. Criterion 1 now names delegation
    explicitly on both halves.
  - *Fixed:* `AGENTS.md` said "nothing is copied into a project" with no
    subject binding it to the issue file — false as a general claim, since
    `skills/bootstrap/` copies the loader and the settings entry into every
    project. Third round in a row that a sentence the change itself added was
    false; the class is worth naming as its own risk.
  - *Fixed:* the `## Checkpoints` row now names the rulebook as the owner of
    the three questions, so `AGENTS.md` stating them is delegation rather than
    duplication.
  - *Accepted, not fixed:* `README.md` repeats the three checkpoint questions
    verbatim. The reason it is different from the others: `AGENTS.md` is
    copied to `~/.claude/CLAUDE.md` and every agent runs on it; `README.md` is
    loaded into nothing. It is the repository's description for a human
    reader, and drift there misleads a human who can see the contradiction,
    not an agent who cannot.
  - *Accepted, not fixed:* the `## Tasks` condition phrase appears in four
    places. None outside the skill names the heading, so each is the permitted
    form — a reader still has to invoke the skill to learn where a task list
    goes.
- **Review round 6, and the human redefined the interface underneath it.**
  The round found four things, three of which survive the redefinition:
  `## Retro`'s content stated verbatim in `AGENTS.md` while the skill did not
  delegate it; `skills/plan/` describing `## Tasks`, which is not the part it
  owns; and "the one skill that is not a shelf tool" being false, because
  `bootstrap` is a second one. The fourth — `README.md` repeating the
  checkpoint questions — the reviewer correctly refused to inherit as
  *accepted*, on the ground that the criterion had been rewritten since that
  triage. It was right: an acceptance recorded against old wording is not an
  acceptance. `README.md` is now excluded in the criterion itself, with the
  reason.
- **Decided by the human: a skill exposes operations, not fields.** The
  interface I had built listed *data* a caller may rely on — the directory,
  the filename form, the frontmatter keys, the heading names. The human's
  correction: a caller should hand over content and name an operation, and
  the skill alone knows where it lands. "Nutze skill `issue` um die
  Akzeptanzkriterien festzuhalten", with the criteria as input, instead of
  "write them into `## Intent` as numbered, falsifiable statements".
  - *Why it is better:* every finding in rounds 5 and 6 is a caller that
    named a place. Under field-exposure they are violations to be found one
    at a time by sweeping the repository; under operation-exposure there is
    nothing for a caller to get wrong, because the caller never had the
    information. It removes the failure mode instead of policing it.
  - *What it cost:* nine operations replace four public data items, and four
    of them are delegated back out — the plan to the `plan` skill, and the
    checkpoint questions, the retro's content and the task-list condition to
    the rulebook, because each is a rule of the run rather than a property of
    the file. Delegation is now the explicit mechanism rather than an
    exception the criterion had to be widened to permit.
  - Criteria 1 and 2 rewritten accordingly, and criterion 7 added for the
    false-sentence class that has now cost four rounds.
- **Decided by the human: the documentation is a mirror, and it is kept
  current.** The round-6 triage exempted `README.md` from criterion 2 because
  no agent loads it — true, but only half the answer, and the half that lets
  documentation rot. The human supplied the other half: it describes the
  status quo, so a change that makes it wrong updates it in the same change.
  Repetition is allowed *because* it is maintained, not instead of.
  - Landed as a rule in `AGENTS.md`, which had no documentation rule at all,
    and as criterion 8 rather than a note — an obligation that lives in a
    triage note is one the next round drops.
  - The check found drift immediately: `README.md` listed five invariants and
    two were wrong. Invariant 2, *tests before code*, was missing entirely,
    and "irreversible decisions go to the human" stood in its place — that is
    a steering point, not an invariant, and the README lists it again nine
    lines further down. Invariant 4 was missing the part `0001` added, that a
    fact is reported as the command and its scope rather than as "green".
  - Worth naming: this is the drift the whole issue is about, sitting in the
    file I had just argued was safe to let drift. The exemption was right and
    my reason for it was wrong.
- **Review round 7 — six findings, and the hard stop is spent.** Criteria 1,
  3, 4, 5 and 6 met with the evidence named; 2, 7 and 8 not. The absence half
  of criterion 2 is down to two violations from round 6's eight, and the
  reviewer states it swept every one of the 20 tracked files whole and found
  no other path, filename, key or heading outside `skills/issue/`. That is
  convergence, not repetition — but the stop was promised unconditionally,
  and a stop that is waived the first time it fires was never a stop.
  - *F2 is the one that matters, and it is a defect in the design rather than
    in a sentence.* `AGENTS.md` claims "there is no other way to read or
    write an issue". No subagent in this repository can invoke a skill —
    `agents/*/agent.md` grant `Read, Glob, Grep, Bash` and no Skill tool — so
    the reviewer opens the issue by the path its caller hands it, which
    `agents/reviewer/agent.md` prescribes in the same branch. The reviewer
    reported itself as the reproduction.
  - *F3:* `skills/issue/SKILL.md` says "Nothing else in the workflow describes
    any of that" and delegates four parts twenty lines later.
  - *F1:* `skills/bootstrap/SKILL.md` names `docs/issues/TEMPLATE.md` — a path
    and a filename, in a document the skill delegates nothing to.
  - *F4:* `skills/plan/` states the task-list condition, which is delegated to
    the rulebook, not to it.
  - *F5:* the `record a task list` row states the same condition it delegates
    away two paragraphs below.
  - *F6:* `README.md` says one skill in `skills/` is not optional; `bootstrap`
    is a second. Round 6's finding, relocated rather than removed.
- **Parked at `waiting` for the human.**
- **Hard stop, moved to round 7.** It was set for round 6, and round 6 ran
  against a design the human replaced mid-round. Re-arming it rather than
  spending it is the honest call — but it does not reset: if criterion 2
  fails again, the run stops and the question goes to the human, whatever the
  finding says. Five rounds have now failed the same criterion, and each
  cause was genuinely different — a copy, a duplication, a hole, two shelf
  skills nobody had swept, a criterion that forbade its own mechanism. That is
  not one unsolved problem repeating; it is a design being found wrong in a
  new place each time, which is the more expensive kind and the reason the
  stop exists.

## Checkpoints

### Before implementation

- **Does this match what was asked?** Yes. The human asked for this issue to
  be built; its four criteria are unchanged from the filing. The one thing
  the filing left open — symlink or compare-and-warn — was mine to settle,
  and it is settled above with its reasoning rather than left to the
  implementer.
- **What surprised me?** That the criteria as written admit a solution that
  fails the spirit: a warning satisfies "the divergence is surfaced" while
  leaving the drift in place. That is why the decision above rules it out
  explicitly instead of relying on the criteria.
- **What am I assuming without having verified it?** Three things, all for
  the implementer to check first. (a) That the core can learn the project
  directory — a `SessionStart` hook should have `$CLAUDE_PROJECT_DIR`, but I
  have not read the script. (b) That the core runs in the cloud path only,
  and that a local session therefore needs its own answer or none. (c) That
  no project currently has a deliberately extended template; only
  `tome_of_battle` uses one, and its copy was verbatim until it went stale.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
