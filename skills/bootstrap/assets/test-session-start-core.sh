#!/bin/bash
# Tests for session-start-core.sh. Everything runs against scratch
# directories — the real ~/.claude and the real repo's git config are never
# touched. Exit 0 = all cases pass.
set -u

core="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-start-core.sh"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
base=$(mktemp -d)
trap 'rm -rf "$base"' EXIT
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

json_context() { python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])'; }

# --- Case 1: happy path against the real repo -------------------------------
sc=$(new_scratch)
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "happy path: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -Eq 'self-check: [1-9][0-9]* skills and [1-9][0-9]* agents linked' \
  || fail "happy path: no counts in status: $ctx"
echo "$ctx" | grep -q 'no errors' || fail "happy path: not clean: $ctx"
head=$(git -C "$repo_root" rev-parse --short HEAD)
echo "$ctx" | grep -q "commit ${head};" || fail "happy path: status does not name HEAD ($head): $ctx"
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

# --- Case 4: hostile link names (quote, newline) — JSON stays valid ---------
sc=$(new_scratch)
mkdir -p "$sc/home/.claude/skills"
ln -s /nonexistent-target "$sc/home/.claude/skills/dead\"skill"
ln -s /nonexistent-target "$sc/home/.claude/skills/$(printf 'dead\nskill')"
out=$(run_core "$core" "$sc")
if ctx=$(echo "$out" | json_context); then
  echo "$ctx" | grep -q 'broken link' && pass "hostile names reported, JSON valid" \
    || fail "hostile names: broken links not reported: $ctx"
else
  fail "hostile names: JSON invalid: $out"
fi

echo
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
