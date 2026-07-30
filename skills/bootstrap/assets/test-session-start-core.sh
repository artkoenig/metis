#!/bin/bash
# Tests for session-start-core.sh. Everything runs against scratch
# directories — the real ~/.claude and the real repo's git config are never
# touched. Exit 0 = all cases pass.
set -u

core="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-start-core.sh"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
base=$(mktemp -d)
trap 'rm -rf "$base"' EXIT

# A scratch base inside a git repository breaks the sandbox: a case
# without a repo of its own would see that repo, and git could write into
# it. Refuse before running any case.
if git -C "$base" rev-parse --git-dir >/dev/null 2>&1; then
  echo "test-session-start-core.sh: refusing to run: $base is inside a git repository (check TMPDIR)" >&2
  exit 1
fi

failures=0

fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
pass() { echo "ok:   $1"; }

# Prepare a scratch HOME + project repo under $base; prints the scratch path.
new_scratch() {
  local scratch
  scratch=$(mktemp -d "$base/XXXXXX")
  mkdir -p "$scratch/home" "$scratch/proj"
  git -C "$scratch/proj" init --quiet
  echo "$scratch"
}

# Run a core script against a scratch dir; prints the fd-3 output (hook JSON).
# $1 = core script path, $2 = scratch dir from new_scratch.
run_core() {
  (cd "$2/proj" && HOME="$2/home" CLAUDE_PROJECT_DIR="$2/proj" \
    bash -c 'exec 3>&1 1>"$0/core.log" 2>&1; bash "$1"' "$2" "$1")
}

# Strict oracle: read raw bytes and decode as UTF-8 ourselves — stdin's
# default surrogateescape handler would wave invalid bytes through. Also
# pin the envelope: without the event name and reloadSkills the injection
# never arrives, whatever the status says.
json_context() { python3 -c '
import json, sys
h = json.loads(sys.stdin.buffer.read().decode("utf-8"))["hookSpecificOutput"]
assert h["hookEventName"] == "SessionStart", h
assert h["reloadSkills"] is True, h
print(h["additionalContext"])'; }

# --- Case 1: happy path against the real repo -------------------------------
sc=$(new_scratch)
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "happy path: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -Eq 'self-check: [1-9][0-9]* skills and [1-9][0-9]* agents reachable' \
  || fail "happy path: no counts in status: $ctx"
echo "$ctx" | grep -q 'no errors' || fail "happy path: not clean: $ctx"
head=$(git -C "$repo_root" rev-parse --short HEAD)
echo "$ctx" | grep -q "commit ${head};" || fail "happy path: status does not name HEAD ($head): $ctx"
echo "$ctx" | grep -q 'push guard set' || fail "happy path: push guard state missing from status: $ctx"
[ "$(git -C "$sc/proj" config core.hooksPath 2>/dev/null)" = "$repo_root/.githooks" ] \
  || fail "happy path: core.hooksPath not pointing at the clone's .githooks"
b=0
for link in "$sc/home/.claude/skills"/* "$sc/home/.claude/agents"/*; do
  if [ -L "$link" ] && [ ! -e "$link" ]; then b=1; fi
done
[ $b -eq 0 ] || fail "happy path: broken link created"
[ -f "$sc/home/.claude/CLAUDE.md" ] || fail "happy path: rulebook not synced"
[ $failures -eq 0 ] && pass "happy path"

# --- Case 2: empty clone must FAIL and name each cause ----------------------
empty=$(mktemp -d "$base/XXXXXX")
mkdir -p "$empty/skills/bootstrap/assets" "$empty/agents"
cp "$core" "$empty/skills/bootstrap/assets/"
out=$(run_core "$empty/skills/bootstrap/assets/session-start-core.sh" "$(new_scratch)")
ctx=$(echo "$out" | json_context) || { fail "empty clone: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'FAILED' || fail "empty clone: not flagged: $ctx"
echo "$ctx" | grep -q 'no skills linked' || fail "empty clone: missing skills not named: $ctx"
echo "$ctx" | grep -q 'no agents linked' || fail "empty clone: missing agents not named: $ctx"
echo "$ctx" | grep -q 'rulebook missing from clone' || fail "empty clone: missing rulebook not named: $ctx"
if echo "$ctx" | grep -q 'FAILED'; then pass "empty clone flagged"; fi

# --- Case 3: a dir without its SKILL.md / agent.md must be named ------------
maimed=$(mktemp -d "$base/XXXXXX")
cp -r "$repo_root/skills" "$repo_root/agents" "$maimed/"
cp "$repo_root/AGENTS.md" "$maimed/"
mv "$maimed/skills/plan/SKILL.md" "$maimed/skills/plan/SKILL.md.off"
mv "$maimed/agents/researcher/agent.md" "$maimed/agents/researcher/agent.md.off"
out=$(run_core "$maimed/skills/bootstrap/assets/session-start-core.sh" "$(new_scratch)")
ctx=$(echo "$out" | json_context) || { fail "maimed clone: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'skill without SKILL.md: plan' || fail "skipped skill not named: $ctx"
echo "$ctx" | grep -q 'agent without agent.md: researcher' || fail "skipped agent not named: $ctx"
if echo "$ctx" | grep -q 'skill without SKILL.md: plan'; then pass "silently skipped dirs named"; fi

# --- Case 4: hostile link names (quote, newline, non-UTF-8 byte) — JSON
# stays valid under a strict parser ------------------------------------------
sc=$(new_scratch)
mkdir -p "$sc/home/.claude/skills"
ln -s /nonexistent-target "$sc/home/.claude/skills/dead\"skill"
ln -s /nonexistent-target "$sc/home/.claude/skills/$(printf 'dead\nskill')"
ln -s /nonexistent-target "$sc/home/.claude/skills/$(printf 'dead\xffskill')"
out=$(run_core "$core" "$sc")
if ctx=$(echo "$out" | json_context); then
  if echo "$ctx" | grep -q 'broken link'; then
    pass "hostile names reported, JSON valid"
  else
    fail "hostile names: broken links not reported: $ctx"
  fi
else
  fail "hostile names: JSON invalid: $out"
fi

# --- Case 5: a real directory shadowing a link's path must be named ---------
prior=$failures
sc=$(new_scratch)
mkdir -p "$sc/home/.claude/skills/plan" "$sc/home/.claude/agents/reviewer"
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "shadowed path: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'skill not reachable: plan' || fail "shadowed skill not named: $ctx"
echo "$ctx" | grep -q 'agent not reachable: reviewer' || fail "shadowed agent not named: $ctx"
echo "$ctx" | grep -Eq '^Metis self-check: [0-9]+ skills and [0-9]+ agents reachable; push guard set; commit [0-9a-f]+; FAILED:' \
  || fail "FAILED status lost counts, guard state or commit: $ctx"
set -- "$repo_root"/skills/*/; skills_total=$#
set -- "$repo_root"/agents/*/; agents_total=$#
echo "$ctx" | grep -q "$((skills_total - 1)) skills and $((agents_total - 1)) agents reachable" \
  || fail "counts include the unreachable ones: $ctx"
[ $failures -eq $prior ] && pass "shadowed paths named, FAILED status keeps counts, guard state and commit"

# --- Case 6: project dir is not a git repo — the reproduced skip. The guard
# cannot be installed there (and nothing can be pushed from there either), so
# the status must say why it is absent without turning it into an error ------
prior=$failures
sc=$(mktemp -d "$base/XXXXXX")
mkdir -p "$sc/home" "$sc/proj"   # deliberately no `git init`
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "non-git project: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'push guard n/a (project not a git repo)' \
  || fail "non-git project: guard state not in status: $ctx"
echo "$ctx" | grep -q 'no errors' || fail "non-git project: wrongly flagged as error: $ctx"
[ $failures -eq $prior ] && pass "non-git project: guard absence named, no error"

# --- Case 7: clone without .githooks but a git project — pushes are possible
# and unguarded, so the status must FAIL and name the cause ------------------
prior=$failures
noguard=$(mktemp -d "$base/XXXXXX")
cp -r "$repo_root/skills" "$repo_root/agents" "$noguard/"
cp "$repo_root/AGENTS.md" "$noguard/"          # complete clone, minus .githooks
sc=$(new_scratch)
out=$(run_core "$noguard/skills/bootstrap/assets/session-start-core.sh" "$sc")
ctx=$(echo "$out" | json_context) || { fail "no .githooks: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'push guard not set (no .githooks in clone)' \
  || fail "no .githooks: guard state not in status: $ctx"
echo "$ctx" | grep -q 'FAILED' || fail "no .githooks: not flagged: $ctx"
[ -z "$(git -C "$sc/proj" config core.hooksPath 2>/dev/null)" ] \
  || fail "no .githooks: hooksPath was set anyway"
[ $failures -eq $prior ] && pass "missing .githooks: flagged, cause named"

echo
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
