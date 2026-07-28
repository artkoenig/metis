#!/bin/bash
# Tests for session-start-core.sh. Everything runs against scratch
# directories — the real ~/.claude and the real repo's git config are never
# touched. Exit 0 = all cases pass.
set -u

core="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-start-core.sh"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
failures=0

fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
pass() { echo "ok:   $1"; }

# Prepare a scratch HOME + project repo; prints the scratch path.
new_scratch() {
  local scratch
  scratch=$(mktemp -d)
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

json_context() { python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])'; }

# --- Case 1: happy path against the real repo -------------------------------
sc=$(new_scratch)
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "happy path: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -Eq 'self-check: [1-9][0-9]* skills and [1-9][0-9]* agents linked' \
  || fail "happy path: no counts in status: $ctx"
echo "$ctx" | grep -q 'no errors' || fail "happy path: not clean: $ctx"
b=0
for link in "$sc/home/.claude/skills"/* "$sc/home/.claude/agents"/*; do
  [ -L "$link" ] && [ ! -e "$link" ] && b=1
done
[ $b -eq 0 ] || fail "happy path: broken link created"
[ -f "$sc/home/.claude/CLAUDE.md" ] || fail "happy path: rulebook not synced"
[ $failures -eq 0 ] && pass "happy path"

# --- Case 2: empty clone must FAIL, not report no errors --------------------
empty=$(mktemp -d)
mkdir -p "$empty/skills/bootstrap/assets" "$empty/agents"
cp "$core" "$empty/skills/bootstrap/assets/"
out=$(run_core "$empty/skills/bootstrap/assets/session-start-core.sh" "$(new_scratch)")
ctx=$(echo "$out" | json_context) || { fail "empty clone: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'FAILED' || fail "empty clone: not flagged: $ctx"
echo "$ctx" | grep -q 'no skills linked' || fail "empty clone: cause not named: $ctx"
echo "$ctx" | grep -q 'commit' || fail "empty clone: commit missing from status: $ctx"
echo "$ctx" | grep -Fq 'FAILED' && pass "empty clone flagged"

# --- Case 3: a skill dir without SKILL.md must be named ---------------------
maimed=$(mktemp -d)
cp -r "$repo_root/skills" "$repo_root/agents" "$maimed/" 2>/dev/null
cp "$repo_root/AGENTS.md" "$maimed/"
mv "$maimed/skills/plan/SKILL.md" "$maimed/skills/plan/SKILL.md.off"
out=$(run_core "$maimed/skills/bootstrap/assets/session-start-core.sh" "$(new_scratch)")
ctx=$(echo "$out" | json_context) || { fail "maimed skill: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'skill without SKILL.md: plan' \
  && pass "silently skipped skill named" || fail "maimed skill not named: $ctx"

# --- Case 4: broken link with a quote in its name — JSON stays valid --------
sc=$(new_scratch)
mkdir -p "$sc/home/.claude/skills"
ln -s /nonexistent-target "$sc/home/.claude/skills/dead\"skill"
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || fail "quoted name: JSON invalid: $out"
echo "$ctx" | grep -q 'broken link' && pass "broken link reported, JSON valid" \
  || fail "quoted name: broken link not reported: $ctx"

echo
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
