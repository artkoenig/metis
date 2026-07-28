#!/bin/bash
# Tests for session-start.sh (the per-project loader), local-session path
# only. The documented promise under test: a local session never receives a
# self-check status — the loader's local path must emit no
# `additionalContext`, whatever else it does. Everything runs against
# scratch directories — the real ~/.claude, the real repo and the network
# are never touched. Exit 0 = all cases pass.
#
# An alternative loader path may be passed as $1 (used to prove a mutated
# copy goes red); default is the sibling session-start.sh.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
loader="${1:-$here/session-start.sh}"
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

git_commit() { git -C "$1" -c user.name=t -c user.email=t@t commit --quiet "${@:2}"; }

# Run the loader as a LOCAL session against a scratch dir; prints the fd-3
# output (hook JSON, if any). HOME, project dir and CLAUDE_CODE_REMOTE are
# all pinned to the sandbox, so the loader's log file, symlink walk and git
# operations stay inside $base. $1 = scratch dir from new_scratch.
run_loader_local() {
  (cd "$1/proj" && HOME="$1/home" CLAUDE_PROJECT_DIR="$1/proj" \
    CLAUDE_CODE_REMOTE="" bash "$loader")
}

# Build, inside a scratch dir, what the loader's local path looks for: an
# upstream repo whose path matches the metis URL patterns, a clone of it,
# and a ~/.claude skill symlink pointing into that clone. Prints nothing;
# uses $1 = scratch dir.
make_local_clone() {
  local sc="$1" upstream="$1/upstream/metis"
  mkdir -p "$upstream/skills/demo"
  git -C "$upstream" init --quiet
  echo "demo" > "$upstream/skills/demo/SKILL.md"
  git -C "$upstream" add -A
  git_commit "$upstream" -m "one"
  git clone --quiet "$upstream" "$sc/clone"
  mkdir -p "$sc/home/.claude/skills"
  ln -s "$sc/clone/skills/demo" "$sc/home/.claude/skills/demo"
}

# --- Case 1: no local clone found — fd 3 must stay silent -------------------
sc=$(new_scratch)
out=$(run_loader_local "$sc") || fail "no clone: loader exited non-zero"
[ -z "$out" ] || fail "no clone: local session got hook output: $out"
[ -f "$sc/proj/.claude/hooks/session-start.log" ] || fail "no clone: log not in scratch project"
[ $failures -eq 0 ] && pass "no clone found: silent"

# --- Case 2: clone up to date — fd 3 must stay silent -----------------------
sc=$(new_scratch)
make_local_clone "$sc"
out=$(run_loader_local "$sc") || fail "up to date: loader exited non-zero"
[ -z "$out" ] || fail "up to date: local session got hook output: $out"
grep -q "already up to date" "$sc/proj/.claude/hooks/session-start.log" \
  || fail "up to date: loader did not reach the pull path (log)"
if [ -z "$out" ]; then pass "clone up to date: silent"; fi

# --- Case 3: clone behind upstream — reload allowed, but never a status -----
sc=$(new_scratch)
make_local_clone "$sc"
echo "more" >> "$sc/upstream/metis/skills/demo/SKILL.md"
git -C "$sc/upstream/metis" add -A
git_commit "$sc/upstream/metis" -m "two"
out=$(run_loader_local "$sc") || fail "behind: loader exited non-zero"
[ "$(git -C "$sc/clone" rev-parse HEAD)" = "$(git -C "$sc/upstream/metis" rev-parse HEAD)" ] \
  || fail "behind: clone was not fast-forwarded"
echo "$out" | grep -q '"reloadSkills": true' || fail "behind: reload signal lost: $out"
if echo "$out" | grep -q 'additionalContext'; then
  fail "behind: local session got a self-check status: $out"
else
  pass "clone updated: reload signal only, no status"
fi

# --- Case 4: clone has uncommitted changes — fd 3 must stay silent ----------
prior=$failures
sc=$(new_scratch)
make_local_clone "$sc"
echo "dirty" >> "$sc/clone/skills/demo/SKILL.md"
out=$(run_loader_local "$sc") || fail "dirty: loader exited non-zero"
[ -z "$out" ] || fail "dirty: local session got hook output: $out"
grep -q "uncommitted changes" "$sc/proj/.claude/hooks/session-start.log" \
  || fail "dirty: loader did not reach the dirty-clone branch (log)"
[ $failures -eq $prior ] && pass "dirty clone: silent"

# --- Case 5: pull fails (diverged) — fd 3 must stay silent ------------------
prior=$failures
sc=$(new_scratch)
make_local_clone "$sc"
echo "theirs" >> "$sc/upstream/metis/skills/demo/SKILL.md"
git -C "$sc/upstream/metis" add -A
git_commit "$sc/upstream/metis" -m "theirs"
echo "ours" > "$sc/clone/skills/demo/local.md"
git -C "$sc/clone" add -A
git_commit "$sc/clone" -m "ours"
out=$(run_loader_local "$sc") || fail "diverged: loader exited non-zero"
[ -z "$out" ] || fail "diverged: local session got hook output: $out"
grep -q "Pull failed" "$sc/proj/.claude/hooks/session-start.log" \
  || fail "diverged: loader did not reach the pull-failed branch (log)"
[ $failures -eq $prior ] && pass "pull failed (diverged): silent"

echo
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
