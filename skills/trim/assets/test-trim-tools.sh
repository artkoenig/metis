#!/bin/bash
# Tests for trim-tools.py — the script behind the "trim" skill (issue 0036),
# which measures what a repository's sessions eagerly load, proposes a
# tool-deny list, and writes the agreed list into .claude/settings.json.
#
# The command under test does not exist yet; every case here is expected to
# fail until skills/trim/assets/trim-tools.py is written to the contract
# below.
#
# This suite makes REAL headless `claude` calls — it does not fabricate
# transcripts the way test-token-cost.sh does, because criteria 2 and 5 are
# specifically about what a real fresh session's own transcript holds. Each
# case that needs one uses its own brand-new scratch directory (so the
# transcript it produces cannot be confused with another case's), and the
# suite makes at most four such calls in total (one for criterion 2, one for
# criterion 3, one per settings.json branch for criteria 4/5/6/7/8). HOME is
# the real HOME, not a scratch one, because the real credentials the `claude`
# binary needs to place a call live there; each case only ever touches the
# project directories its own scratch target directories sanitise to, and
# removes them again on exit.
#
# The contract every case below assumes (the implementer builds to this):
#
#   python3 trim-tools.py probe <DIR>
#     One real, single-turn headless `claude` call in DIR, then reads that
#     new session's own transcript under ~/.claude/projects/ and prints a
#     line:
#         before: <N> tokens          (see note below on the label)
#     Nothing is written under DIR. N is the transcript's first model call's
#     cache_creation_input_tokens + cache_read_input_tokens + input_tokens.
#     Note: probe's own label just needs to carry the figure somewhere a
#     line-oriented reader can find it; this suite accepts either "before:"
#     or a line containing "step-1 prompt" — see extract_step1() below.
#
#   python3 trim-tools.py propose <DIR>
#     Runs one probe as above in DIR, then prints one line
#         deny: <ToolName> ...
#     per tool it proposes denying — tools that were eagerly loaded in that
#     probe session — never Skill, Agent, AskUserQuestion, ToolSearch, Read,
#     Write, Edit, Glob, Grep or Bash. Nothing is written under DIR.
#
#   python3 trim-tools.py apply <DIR> <BEFORE> <TOOL[,TOOL...]>
#     Writes TOOL[,TOOL...] into DIR/.claude/settings.json under
#     permissions.deny — creating the file if it is absent with that as its
#     only key, merging into it if it exists (every other key, and any of
#     its own existing permissions.deny entries, left untouched) — then runs
#     one more real probe in DIR with the list applied and prints:
#         before: <BEFORE> tokens
#         after: <N> tokens
#         difference: <BEFORE - N> tokens
#     followed by a line stating that the written list applies only to
#     sessions started after this point, not to the session that ran the
#     skill. BEFORE is a figure the caller already has from an earlier probe
#     — apply does not re-measure the "before" figure itself (see the
#     issue's "two probe runs, not one per tool" decision).
#
# Which case covers which acceptance criterion:
#   Case 1  - criterion 1: skills/trim/SKILL.md exists and names the script.
#   Case 2  - criterion 1: test.sh's suites list names this file.
#   Case 3  - criterion 2: a real probe reports a number that matches what
#             its own fresh transcript holds.
#   Case 4  - criterion 3: a real proposal never names a protected tool.
#   Case 5  - criterion 4 (mechanical half) and criterion 6: apply on a
#             directory with no .claude/settings.json creates one whose only
#             key is permissions.deny, holding exactly the given tools and
#             none the caller left out.
#   Case 6  - criterion 5: the same apply call reports before, after and
#             their difference, and "after" matches its own fresh transcript.
#   Case 7  - criterion 8: the same apply call's output states the list
#             applies only to future sessions, not the one that ran it.
#   Case 8  - criterion 7: apply on a directory with an existing
#             settings.json leaves other keys and existing deny entries
#             alone and adds the new ones alongside them.
#   Case 9  - criterion 9: this repository's own .claude/settings.json
#             already carries a deny list (expected to fail until the
#             implementer runs the finished skill against this repository).
#
# Criterion 3's "contains only eagerly loaded tools" (the positive half) is
# not independently checkable from outside without either trusting the
# skill's own detection or having an external oracle of which tools this
# environment loads eagerly, neither of which exists here. What is testable,
# and tested in Case 4, is the falsifiable half: a proposal that wrongly
# names a protected tool is caught.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="$here/trim-tools.py"
repo_root="$(cd "$here/../../.." && pwd)"
suite_relpath="skills/trim/assets/test-trim-tools.sh"

base=$(mktemp -d)
created_projects=()
cleanup() {
  rm -rf "$base"
  for p in "${created_projects[@]:-}"; do
    [ -n "$p" ] && [ -d "$p" ] && rm -rf "$p"
  done
}
trap cleanup EXIT

failures=0
skips=0
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
pass() { echo "ok:   $1"; }
skip() { echo "skip: $1"; skips=$((skips + 1)); }

have_claude() { command -v claude >/dev/null 2>&1; }

show() {
  echo "      --- output (first 40 lines) ---"
  printf '%s\n' "$1" | head -40 | sed 's/^/      /'
}

# --- the helper: finds a real probe's own transcript and sums its step-1 --
# tokens independently of trim-tools.py, so a wrong number cannot be praised
# by comparing it to itself.
cat >"$base/th.py" <<'PYEOF'
import json, os, re, sys

def sanitisations(path):
    out = [path.replace("/", "-"), re.sub(r"[^A-Za-z0-9]", "-", path)]
    seen, uniq = set(), []
    for n in out:
        if n not in seen:
            seen.add(n); uniq.append(n)
    return uniq

def project_dir(home, path):
    root = os.path.join(home, ".claude", "projects")
    for name in sanitisations(path):
        d = os.path.join(root, name)
        if os.path.isdir(d):
            return d
    return None

def newest_jsonl(directory):
    files = [os.path.join(directory, f) for f in os.listdir(directory)
             if f.endswith(".jsonl")]
    if not files:
        return None
    files.sort(key=os.path.getmtime)
    return files[-1]

def step1_tokens(transcript):
    first_request = None
    write = read = inp = 0
    with open(transcript) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if rec.get("type") != "assistant":
                continue
            message = rec.get("message") or {}
            req = rec.get("requestId") or message.get("id")
            if first_request is None:
                first_request = req
            if req != first_request:
                continue
            usage = message.get("usage") or {}
            write = max(write, int(usage.get("cache_creation_input_tokens") or 0))
            read = max(read, int(usage.get("cache_read_input_tokens") or 0))
            inp = max(inp, int(usage.get("input_tokens") or 0))
    return write + read + inp

cmd = sys.argv[1]
if cmd == "step1-newest":
    home, path = sys.argv[2], sys.argv[3]
    pdir = project_dir(home, path)
    if pdir is None:
        sys.exit("no project directory for " + path)
    jf = newest_jsonl(pdir)
    if jf is None:
        sys.exit("no transcript file under " + pdir)
    print("%d\t%s" % (step1_tokens(jf), pdir))
else:
    sys.exit("unknown command " + cmd)
PYEOF

# $1 = target directory. Prints "<tokens>\t<project-dir>" for that
# directory's newest transcript, or nothing (and a message on stderr) if it
# cannot be found. Registers the project directory for cleanup either way it
# is found.
step1_of() {
  local res
  res=$(python3 "$base/th.py" step1-newest "$HOME" "$1" 2>"$base/th.err")
  if [ -z "$res" ]; then
    return 1
  fi
  local pdir
  pdir=$(printf '%s' "$res" | cut -f2)
  [ -n "$pdir" ] && created_projects+=("$pdir")
  printf '%s' "$res" | cut -f1
}

# $1 = text, $2 = extended regex (case-insensitive) selecting a line. Prints
# the first number on the first matching line, thousands separators removed.
line_num() {
  printf '%s\n' "$1" | grep -Ei "$2" | head -1 \
    | grep -Eo -- '-?[0-9][0-9,_]*' | head -1 | tr -d ',_'
}

protected="Skill Agent AskUserQuestion ToolSearch Read Write Edit Glob Grep Bash"
is_protected() {
  local name=$1 p
  for p in $protected; do
    [ "$name" = "$p" ] && return 0
  done
  return 1
}

# --- Case 1 (criterion 1): the skill's page states what it does and how ---
prior=$failures
skill_page="$repo_root/skills/trim/SKILL.md"
if [ -f "$skill_page" ]; then
  grep -q 'trim-tools.py' "$skill_page" \
    || fail "SKILL.md: does not name trim-tools.py — how it is invoked is not stated"
else
  fail "SKILL.md: $skill_page does not exist"
fi
[ $failures -eq $prior ] && pass "skills/trim/SKILL.md exists and names the script it runs"

# --- Case 2 (criterion 1): test.sh names this suite ------------------------
prior=$failures
grep -qF "$suite_relpath" "$repo_root/test.sh" \
  || fail "test.sh: does not name $suite_relpath in its suites list"
[ $failures -eq $prior ] && pass "test.sh names $suite_relpath"

# --- Case 3 (criterion 2): a real probe reports its own transcript's figure
prior=$failures
if have_claude; then
  dir=$(mktemp -d "$base/XXXXXX")
  out=$(python3 "$cmd" probe "$dir" 2>"$base/probe.err")
  status=$?
  if [ $status -ne 0 ]; then
    fail "probe: exit status $status, expected 0: $(tr '\n' ' ' <"$base/probe.err" | cut -c1-300)"
  else
    [ -e "$dir/.claude" ] && fail "probe: wrote something under $dir — probe must only read"
    reported=$(line_num "$out" 'before:|step-1 prompt')
    [ -n "$reported" ] || fail "probe: no reported figure in the output: $(printf '%s' "$out" | head -5)"
    real=$(step1_of "$dir") || fail "probe: no transcript could be found for $dir under ~/.claude/projects"
    if [ -n "$real" ] && [ -n "$reported" ]; then
      [ "$reported" = "$real" ] \
        || fail "probe: reported $reported but the fresh transcript itself sums to $real"
      [ "$real" -gt 1000 ] \
        || fail "probe: the transcript's own figure ($real) is implausibly small for a step-1 prompt"
    fi
  fi
  [ $failures -eq $prior ] && pass "probe: real headless session, figure matches its own transcript" || show "$out"
else
  skip "probe: no claude binary on PATH"
fi

# --- Case 4 (criterion 3): a real proposal never names a protected tool ---
prior=$failures
if have_claude; then
  dir=$(mktemp -d "$base/XXXXXX")
  out=$(python3 "$cmd" propose "$dir" 2>"$base/propose.err")
  status=$?
  if [ $status -ne 0 ]; then
    fail "propose: exit status $status, expected 0: $(tr '\n' ' ' <"$base/propose.err" | cut -c1-300)"
  else
    [ -e "$dir/.claude" ] && fail "propose: wrote something under $dir before any list was shown"
    denylines=$(printf '%s\n' "$out" | grep -Ei '^deny:')
    [ -n "$denylines" ] || fail "propose: no 'deny: <ToolName>' line in the output: $(printf '%s' "$out" | head -5)"
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      name=$(printf '%s' "$line" | sed -E 's/^[Dd]eny:[[:space:]]*//' | awk '{print $1}')
      [ -n "$name" ] || continue
      is_protected "$name" \
        && fail "propose: proposed list names '$name', which criterion 3 forbids"
    done <<EOF
$denylines
EOF
  fi
  [ $failures -eq $prior ] && pass "propose: real proposal names no protected tool" || show "$out"
else
  skip "propose: no claude binary on PATH"
fi

# --- Cases 5, 6, 7 (criteria 4/6, 5, 8): apply on a directory with no ------
# pre-existing settings.json
prior_case5=$failures
if have_claude; then
  dir=$(mktemp -d "$base/XXXXXX")
  before=424242
  out=$(python3 "$cmd" apply "$dir" "$before" "ZqxToolAlpha,ZqxToolBeta" 2>"$base/apply1.err")
  status=$?
  if [ $status -ne 0 ]; then
    fail "apply (new file): exit status $status, expected 0: $(tr '\n' ' ' <"$base/apply1.err" | cut -c1-300)"
  else
    settings="$dir/.claude/settings.json"
    if [ ! -f "$settings" ]; then
      fail "apply (new file): $settings was not created"
    else
      python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert set(d.keys()) == {"permissions"}, "top-level keys are %r, expected only [\"permissions\"]" % (sorted(d.keys()),)
perm = d["permissions"]
assert isinstance(perm, dict) and set(perm.keys()) == {"deny"}, "permissions is %r, expected only a deny key" % (perm,)
deny = perm["deny"]
assert isinstance(deny, list), "permissions.deny is %r, expected a list" % (deny,)
assert set(deny) == {"ZqxToolAlpha", "ZqxToolBeta"}, "permissions.deny is %r" % (deny,)
assert "ZqxToolGamma" not in deny, "permissions.deny holds an entry (ZqxToolGamma) that was never given to apply"
' "$settings" 2>"$base/apply1.py.err" \
        || fail "apply (new file): $(tail -1 "$base/apply1.py.err")"
    fi
    # Case 5 proper: criterion 6 (created file, only key permissions.deny)
    # and the mechanical half of criterion 4 (an entry never given is absent)
    [ $failures -eq $prior_case5 ] \
      && pass "apply, no pre-existing settings.json: file created, only key permissions.deny, exactly the given tools"

    # --- Case 6 (criterion 5): before, after and their difference ---------
    prior=$failures
    reported_before=$(line_num "$out" '^before:')
    reported_after=$(line_num "$out" '^after:')
    reported_diff=$(line_num "$out" '^difference:')
    [ "$reported_before" = "$before" ] \
      || fail "apply: reports before=$reported_before, expected the given $before"
    [ -n "$reported_after" ] || fail "apply: no 'after:' figure in the output: $(printf '%s' "$out" | head -8)"
    real_after=$(step1_of "$dir") || fail "apply: no transcript could be found for $dir's second probe"
    if [ -n "$real_after" ] && [ -n "$reported_after" ]; then
      [ "$reported_after" = "$real_after" ] \
        || fail "apply: reports after=$reported_after but the fresh transcript itself sums to $real_after"
    fi
    if [ -n "$reported_diff" ] && [ -n "$reported_after" ]; then
      expected_diff=$((before - reported_after))
      [ "$reported_diff" = "$expected_diff" ] \
        || fail "apply: reports difference=$reported_diff, expected $before - $reported_after = $expected_diff"
    else
      fail "apply: no 'difference:' figure in the output: $(printf '%s' "$out" | head -8)"
    fi
    [ $failures -eq $prior ] \
      && pass "apply: reports before, a freshly re-measured after, and their difference" || show "$out"

    # --- Case 7 (criterion 8): future-sessions-only note -------------------
    prior=$failures
    printf '%s\n' "$out" | grep -Eqi 'sessions?[^.]*after' \
      || fail "apply: output does not state the list applies to sessions started after it is written: $(printf '%s' "$out" | tail -6)"
    printf '%s\n' "$out" | grep -Eqi 'not (to |)(the |)(current|this) session|session that ran' \
      || fail "apply: output does not state the list does not apply to the session that ran the skill: $(printf '%s' "$out" | tail -6)"
    [ $failures -eq $prior ] \
      && pass "apply: states the list applies only to future sessions, not the one that ran it" || show "$out"
  fi
else
  skip "apply, no pre-existing settings.json: no claude binary on PATH"
  skip "apply: before/after/difference: no claude binary on PATH"
  skip "apply: future-sessions-only note: no claude binary on PATH"
fi

# --- Case 8 (criterion 7): apply on a directory with an existing ----------
# settings.json — other keys and existing deny entries survive untouched
prior=$failures
if have_claude; then
  dir=$(mktemp -d "$base/XXXXXX")
  mkdir -p "$dir/.claude"
  cat >"$dir/.claude/settings.json" <<'JSON'
{
  "someOtherSetting": "keep-me-zqx",
  "permissions": {
    "deny": ["ZqxPreexistingTool"]
  }
}
JSON
  out=$(python3 "$cmd" apply "$dir" 424242 "ZqxToolAlpha,ZqxToolBeta" 2>"$base/apply2.err")
  status=$?
  if [ $status -ne 0 ]; then
    fail "apply (existing file): exit status $status, expected 0: $(tr '\n' ' ' <"$base/apply2.err" | cut -c1-300)"
  else
    python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert d.get("someOtherSetting") == "keep-me-zqx", "someOtherSetting is %r, expected it untouched" % (d.get("someOtherSetting"),)
perm = d.get("permissions")
assert isinstance(perm, dict), "permissions is %r" % (perm,)
deny = perm.get("deny")
assert isinstance(deny, list), "permissions.deny is %r, expected a list" % (deny,)
assert set(deny) == {"ZqxPreexistingTool", "ZqxToolAlpha", "ZqxToolBeta"}, \
    "permissions.deny is %r, expected the pre-existing entry plus the two new ones" % (deny,)
' "$dir/.claude/settings.json" 2>"$base/apply2.py.err" \
      || fail "apply (existing file): $(tail -1 "$base/apply2.py.err")"
    created_projects+=("$(python3 "$base/th.py" step1-newest "$HOME" "$dir" 2>/dev/null | cut -f2)")
  fi
  [ $failures -eq $prior ] \
    && pass "apply, pre-existing settings.json: other keys and existing deny entries survive, new ones added" \
    || show "$out"
else
  skip "apply, pre-existing settings.json: no claude binary on PATH"
fi

# --- Case 9 (criterion 9): this repository's own settings.json -------------
# Expected to fail until the implementer runs the finished skill against
# this repository, per the issue's own criterion 9.
prior=$failures
own_settings="$repo_root/.claude/settings.json"
if [ ! -f "$own_settings" ]; then
  fail "own settings: $own_settings does not exist"
else
  python3 -c '
import json, sys
protected = {"Skill", "Agent", "AskUserQuestion", "ToolSearch", "Read", "Write", "Edit", "Glob", "Grep", "Bash"}
d = json.load(open(sys.argv[1]))
perm = d.get("permissions")
assert isinstance(perm, dict), "no permissions key in this repositorys own .claude/settings.json"
deny = perm.get("deny")
assert isinstance(deny, list) and deny, "permissions.deny is %r, expected a non-empty list" % (deny,)
bad = protected & set(deny)
assert not bad, "permissions.deny names protected tool(s) %r" % (sorted(bad),)
' "$own_settings" 2>"$base/own.err" \
    || fail "own settings: $(tail -1 "$base/own.err")"
fi
[ $failures -eq $prior ] \
  && pass "this repository's own .claude/settings.json carries a deny list" \
  || echo "      (expected to fail until the skill has been run against this repository)"

echo
[ $skips -gt 0 ] && echo "note: $skips case(s) skipped"
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
