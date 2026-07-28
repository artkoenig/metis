---
status: active
branch: claude/new-session-xeyz5n
pr:
---

# The README is too long and partly stale

## Intent

The README has grown to ~1200 words and mirrors the rulebook in detail —
which makes it drift: four claims are already out of step (the run diagram
omits checkpoints and retro; the trend-table description misses the
out-of-criteria row; invariant 3 lacks the no-facts clause; "three or four
subagents" where there are exactly four). The human wants it cut to three
parts: the core idea, how it works, how to install it.

Wanted behaviour: a reader gets the idea, the mechanism and the installation
from a README half the size, and nothing in it contradicts the rulebook or
the skills.

Acceptance criteria:

1. The current preamble — everything before "Why this exists" — stays as the
   core idea, unchanged in substance.
2. After the preamble the README has exactly two further parts: how the
   workflow works — compressed, with self-correction through the retro as
   its focus — and how to install metis into one's own project. Every other
   current section is gone or folded into these.
3. The repository carries an install script: run from a project's root, it
   installs the loader from the repo's canonical asset to
   `.claude/hooks/session-start.sh` (executable), merges the `SessionStart`
   entry into `.claude/settings.json` without disturbing existing settings,
   and commits both — and it works when piped from the raw GitHub URL
   (`curl -fsSL … | bash`).
4. The script's behaviour is proven by a test harness like the bootstrap
   core's: in a fresh git repo it produces the three outcomes, and existing
   settings survive the merge — shown by exit code, tests written first.
5. The README's installation part is the one-line `curl | bash` command plus
   one sentence naming the fork option — own fork URL in the loader — for
   owning the feedback loop. No manual step list.
6. Nothing the README still claims contradicts `AGENTS.md` or a skill's
   page; the four stale claims above are gone or corrected.
7. The README ends at no more than half today's length (≤ ~600 words).

## Plan

## Tasks

1. The install script (`install.sh`) with its test harness — tests first
   (criteria 3 and 4). Intermediate commit.
2. The README rewrite referencing the script (criteria 1, 2, 5, 6, 7).

## Decisions

- The criteria were approved by the human after grilling ("Freigegeben —
  leg los"). Source: the human's answer.

- Direct use is the installation's main path: the loader keeps the
  `artkoenig/metis` URL, every session pulls that repo's current state. A
  fork is not needed to install — it is how a reader owns the feedback loop
  (retro → own rules) and pins what their sessions execute; the README says
  this in one sentence. Source: the human's answer during grilling.
- The three manual steps are the way to describe installation (not the
  bootstrap skill's trigger phrases — the skill is owner-specific and a
  stranger's session does not have it yet). Source: the human's approval of
  the proposed approach.
- The "how it works" part centres on self-correction through the retro.
  Source: the human's request opening this issue.
- The three steps are automated by an install script in this repository
  instead of being listed as manual steps in the README. Source: the human's
  question-turned-request during grilling ("can't we write an installation
  script for this?").
- The script is invoked via `curl -fsSL <raw URL> | bash` — no clone needed;
  the trust posture matches the loader itself, which already executes code
  from this repo on every session start. Source: the human's answer during
  grilling.
- The script installs the loader from the same canonical asset the bootstrap
  skill copies (`skills/bootstrap/assets/session-start.sh`), so script and
  skill cannot drift apart on the loader. Default, unanswered.

## Log

- Grounding (researcher, before filing): section-by-section word counts,
  the four stale claims with file:line evidence, the bootstrap skill's
  declared install interface, and the fact that the loader hard-codes the
  `artkoenig/metis` URL — the basis of the grilling questions.
- Task 1 done (implementer, tests first): `install.sh` + `test-install.sh`.
  Harness seen failing first, then `bash test-install.sh` 3 cases exit 0;
  whole-repo suite `test-session-start-core.sh` 5 cases exit 0; `bash -n`
  both files exit 0 (no shellcheck in this environment). Both re-run by the
  caller before committing, same exit codes. Implementer's choices:
  `METIS_SOURCE` override (local path or raw-URL base, default
  artkoenig/metis main), python3 for the JSON merge with a clear failure if
  missing, refusal to touch invalid settings JSON, sanity check on the
  fetched loader before installing, harness pipes the script via stdin to
  enforce the curl|bash contract.
- Task 2 done in the main context (prose): README rewritten to 440 words
  (`wc -w`, was 1205; 455 after the round-1 invariant-3 fix) — preamble
  kept, then "How it works" (invariants, run diagram with checkpoints and
  retro, retro-as-self-correction focus) and "Installing it" (the one-liner
  plus the fork sentence).

- Review round 1 (fresh context): facts — `test-install.sh` 3 cases exit 0,
  core suite 5 cases exit 0, `bash -n` exit 0, no shellcheck here. Three
  findings, all fixed: (1) moderate, criterion 3 — the re-run failed beside
  unrelated staged work because the staged-changes check was unscoped; test
  case 4 written first and seen failing, then the check scoped to the two
  installed paths, 4 cases exit 0. (2) minor, criterion 6 — README's
  invariant 3 still omitted the no-facts clause; added. (3) nit, no
  criterion — the loader asset's header named only the bootstrap skill as
  installer; now names install.sh too (the bookkeeping rule pulled it into
  this change). Reviewer's verifiability note accepted: the live raw URL
  cannot be exercised before merge; the pipe mechanism is what the harness
  proves. Trend: round 1 = 3 findings (criterion 3: 1, criterion 6: 1,
  no criterion: 1).

- Review round 2 (fresh context): facts — `test-install.sh` 4 cases exit 0,
  core suite 5 cases exit 0, `bash -n` exit 0; the reviewer additionally
  proved the curl branch against a local HTTP server (exit 0, hook
  byte-identical). Three findings, lighter in weight than round 1's
  (moderate/minor/nit → minor/nit/trivial — converging by class): (1) minor,
  criterion 3, fixed — a repo whose `.gitignore` ignores `.claude/` died
  half-installed with git's raw hint; test case 5 written first and seen
  failing, then an early precondition added that refuses cleanly before
  writing anything, 5 cases exit 0. (2) nit, criterion 5, dismissed with
  reason — the install part has one descriptive sentence beyond the
  letter; the letter bound the fork option to one sentence and forbade a
  step list, and the extra sentence says what the hook does. (3) trivial,
  record, fixed — the log's word count updated (440 at rewrite, 455 after
  the round-1 fix). Round 1's fixes held up under fresh reading.
  Trend: 3 → 3, but strictly lighter (criterion 3: 1→1 lighter,
  criterion 5: 0→1 nit, criterion 6: 1→0, record/none: 1→1 trivial).

- Review round 3 (fresh context): facts — 5 cases exit 0, core suite exit 0,
  `bash -n` exit 0; the reviewer proved the live raw-URL fetch from main.
  Four findings: one minor (settings.json-ignored repo dies half-installed),
  two nits (missing git identity dies half-installed; README narrows the
  human's second steering point by dropping "outward-facing"), one repeat of
  the criterion-5 letter nit.
- Repetition signal observed, as the rulebook defines it: criterion 3 missed
  three rounds in a row by different defects of one class — the git step
  fails partway with git's raw error. Decision: change approach instead of
  patching the next path. All installed paths now live in one list that the
  preconditions, `git add` and `git commit` all read, and a committer
  identity is checked up front — every git precondition now fails cleanly
  before anything is written. Test cases 6 and 7 written first and seen
  failing (half-install, raw git errors), then the rework: 7 cases exit 0,
  core suite exit 0, `bash -n` exit 0.
- Round 3 triage of the rest: "outward-facing" restored to the README's
  steering points (one-word fix). The criterion-5 letter nit dismissed
  afresh, same conclusion as round 2: the letter bound the fork option to
  one sentence and forbade a step list; the one descriptive sentence
  explains what the hook does and stays. Trend: 3 → 3 → 4 by count, but
  round 3's set is lighter (1 minor + 3 nits) and two of the four are
  record/wording, not behaviour; the behaviour class itself is now closed
  structurally, not per path.

- Review round 4 (fresh context): facts — 7 cases exit 0, core suite exit 0,
  `bash -n` exit 0; curl branch proven against a local HTTP server. One
  minor finding plus two nits: the half-install class survives in the
  settings-merge step (valid-but-unexpected JSON shapes like
  `{"hooks": []}` traceback after the hook is written; invalid JSON refuses
  cleanly but also after the hook write), and the harness never exercises
  the curl branch. The criterion-5 letter observation was re-examined and
  re-dismissed a third time, independently. Criteria all met in substance.
- Second-tier stop signal: criterion 3 hit four rounds in a row by
  different defects of one class, and the round-3 approach change closed
  only the git preconditions — the class migrated to the merge step. Per
  the rulebook, the run stops here and asks the human instead of running
  another round.

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — the human approved the seven
  criteria verbatim after the grilling; the two tasks cover them completely.
- What surprised me? The grilling turned a documentation-only issue into one
  with runnable code: the install script flips the change's class, so
  invariants 2 and 4 bite normally for task 1 (tests first, exit codes).
- What am I assuming without having verified it? That the settings merge can
  rely on a JSON tool being present in target projects (the script must
  handle absence gracefully); that piping from the raw GitHub URL works in
  the environments that matter — the tests will cover the mechanism through
  a local override, not the live URL.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
