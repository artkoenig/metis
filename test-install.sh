#!/bin/bash
# Tests for install.sh. Everything runs against scratch git repos — the real
# repo and the network are never touched: METIS_SOURCE points the installer
# at this checkout. Exit 0 = all cases pass.
set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install="$repo_root/install.sh"
asset="$repo_root/skills/bootstrap/assets/session-start.sh"
hook_cmd='$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh'
base=$(mktemp -d)
trap 'rm -rf "$base"' EXIT
failures=0

fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
pass() { echo "ok:   $1"; }

# Prepare a scratch target repo with a local git identity; prints its path.
new_repo() {
  local repo
  repo=$(mktemp -d "$base/XXXXXX")
  git -C "$repo" init --quiet
  git -C "$repo" config user.email "test@example.invalid"
  git -C "$repo" config user.name "Test"
  echo "$repo"
}

# Run the installer inside a repo, piped through stdin like the curl | bash
# path would — a script that needs its own file path must fail here.
run_install() {
  (cd "$1" && METIS_SOURCE="$repo_root" bash < "$install") >"$1.log" 2>&1
}

# Count SessionStart entries whose hooks name our loader command.
count_entries() { python3 -c '
import json, sys
s = json.load(open(sys.argv[1]))
n = 0
for entry in s.get("hooks", {}).get("SessionStart", []):
    for h in entry.get("hooks", []):
        if h.get("type") == "command" and h.get("command") == sys.argv[2]:
            n += 1
print(n)' "$1" "$2"; }

# --- Case 1: fresh repo — hook installed, settings created, commit made -----
repo=$(new_repo)
if run_install "$repo"; then
  [ -f "$repo/.claude/hooks/session-start.sh" ] || fail "fresh: hook file missing"
  [ -x "$repo/.claude/hooks/session-start.sh" ] || fail "fresh: hook not executable"
  cmp -s "$asset" "$repo/.claude/hooks/session-start.sh" \
    || fail "fresh: hook differs from canonical asset"
  [ -f "$repo/.claude/settings.json" ] || fail "fresh: settings.json missing"
  [ "$(count_entries "$repo/.claude/settings.json" "$hook_cmd")" = "1" ] \
    || fail "fresh: SessionStart entry missing or duplicated"
  commits=$(git -C "$repo" rev-list --count HEAD 2>/dev/null || echo 0)
  [ "$commits" -ge 1 ] || fail "fresh: no commit exists"
  git -C "$repo" ls-tree -r --name-only HEAD | grep -q '\.claude/hooks/session-start\.sh' \
    || fail "fresh: hook not committed"
  git -C "$repo" ls-tree -r --name-only HEAD | grep -q '\.claude/settings\.json' \
    || fail "fresh: settings not committed"
  [ -z "$(git -C "$repo" status --porcelain)" ] || fail "fresh: working tree not clean"
else
  fail "fresh: install exited non-zero: $(cat "$repo.log")"
fi
[ $failures -eq 0 ] && pass "fresh repo: hook, settings entry, commit"

# --- Case 2: existing settings with unrelated keys survive the merge --------
prior=$failures
repo=$(new_repo)
mkdir -p "$repo/.claude"
cat >"$repo/.claude/settings.json" <<'EOF'
{
  "permissions": {"allow": ["Bash(ls:*)"]},
  "hooks": {
    "PreToolUse": [{"hooks": [{"type": "command", "command": "echo pre"}]}]
  }
}
EOF
if run_install "$repo"; then
  python3 -c '
import json, sys
s = json.load(open(sys.argv[1]))
assert s["permissions"] == {"allow": ["Bash(ls:*)"]}, s
assert s["hooks"]["PreToolUse"] == [{"hooks": [{"type": "command", "command": "echo pre"}]}], s
' "$repo/.claude/settings.json" || fail "merge: unrelated keys disturbed"
  [ "$(count_entries "$repo/.claude/settings.json" "$hook_cmd")" = "1" ] \
    || fail "merge: SessionStart entry missing or duplicated"
else
  fail "merge: install exited non-zero: $(cat "$repo.log")"
fi
[ $failures -eq $prior ] && pass "existing settings survive the merge"

# --- Case 3: second run is idempotent ---------------------------------------
prior=$failures
repo=$(new_repo)
run_install "$repo" || fail "idempotent: first run failed: $(cat "$repo.log")"
commits_before=$(git -C "$repo" rev-list --count HEAD)
if run_install "$repo"; then
  commits_after=$(git -C "$repo" rev-list --count HEAD)
  [ "$commits_before" = "$commits_after" ] || fail "idempotent: second run made a commit"
  [ "$(count_entries "$repo/.claude/settings.json" "$hook_cmd")" = "1" ] \
    || fail "idempotent: hook entry duplicated"
  cmp -s "$asset" "$repo/.claude/hooks/session-start.sh" \
    || fail "idempotent: hook no longer matches the asset"
else
  fail "idempotent: second run exited non-zero: $(cat "$repo.log")"
fi
[ $failures -eq $prior ] && pass "second run: no failure, no duplicate, no commit"

# --- Case 4: re-run beside unrelated staged work succeeds, leaves it staged -
prior=$failures
repo=$(new_repo)
run_install "$repo" || fail "staged: first run failed: $(cat "$repo.log")"
echo x >"$repo/unrelated.txt"
git -C "$repo" add unrelated.txt
commits_before=$(git -C "$repo" rev-list --count HEAD)
if run_install "$repo"; then
  commits_after=$(git -C "$repo" rev-list --count HEAD)
  [ "$commits_before" = "$commits_after" ] || fail "staged: re-run made a commit"
  git -C "$repo" diff --cached --name-only | grep -qx 'unrelated.txt' \
    || fail "staged: user's staged file no longer staged"
else
  fail "staged: re-run exited non-zero: $(cat "$repo.log")"
fi
[ $failures -eq $prior ] && pass "re-run beside unrelated staged work: no failure, work stays staged"

echo
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
