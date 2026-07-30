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

# A scratch clone of the repository that a case may mutate: the skills (which
# carry the core script itself), the rulebook and the push guard are copied,
# agents/ is created empty for the case to fill. Prints the clone path.
new_clone() {
  local clone
  clone=$(mktemp -d "$base/XXXXXX")
  cp -r "$repo_root/skills" "$clone/"
  cp -r "$repo_root/.githooks" "$clone/"
  cp "$repo_root/AGENTS.md" "$clone/"
  mkdir -p "$clone/agents"
  echo "$clone"
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

# --- Case 3: a skill dir without its SKILL.md must be named -----------------
# Agents have no analogue here any more: an agent is one flat file, so there
# is no directory that could be missing its contents — cases 8-11 cover what
# an agent that is not an `agents/<name>.md` file leads to.
maimed=$(mktemp -d "$base/XXXXXX")
cp -r "$repo_root/skills" "$repo_root/agents" "$maimed/"
cp "$repo_root/AGENTS.md" "$maimed/"
mv "$maimed/skills/plan/SKILL.md" "$maimed/skills/plan/SKILL.md.off"
out=$(run_core "$maimed/skills/bootstrap/assets/session-start-core.sh" "$(new_scratch)")
ctx=$(echo "$out" | json_context) || { fail "maimed clone: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'skill without SKILL.md: plan' || fail "skipped skill not named: $ctx"
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
# An agent lives at agents/<name>.md and is linked at that same name, so the
# path a real directory can shadow is `reviewer.md`.
mkdir -p "$sc/home/.claude/skills/plan" "$sc/home/.claude/agents/reviewer.md"
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "shadowed path: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'skill not reachable: plan' || fail "shadowed skill not named: $ctx"
echo "$ctx" | grep -Eq 'agent not reachable: reviewer(\.md)?' || fail "shadowed agent not named: $ctx"
echo "$ctx" | grep -Eq '^Metis self-check: [0-9]+ skills and [0-9]+ agents reachable; push guard set; commit [0-9a-f]+; FAILED:' \
  || fail "FAILED status lost counts, guard state or commit: $ctx"
set -- "$repo_root"/skills/*/; skills_total=$#
set -- "$repo_root"/agents/*.md; agents_total=$#
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

# --- Case 8: every agents/<name>.md in the clone is reachable by that name --
# Agents are flat files now (the nested agents/<name>/agent.md layout is
# gone), so the link a session needs sits at ~/.claude/agents/<name>.md and
# points at the file in the clone. The self-check counts exactly those.
prior=$failures
sc=$(new_scratch)
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "flat agents: JSON invalid: $out"; ctx=""; }
set -- "$repo_root"/agents/*.md; agents_total=$#
[ -f "$1" ] || fail "flat agents: the repo holds no agents/<name>.md to link"
for f in "$repo_root"/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  link="$sc/home/.claude/agents/$name"
  if [ ! -L "$link" ]; then
    fail "flat agents: no link at ~/.claude/agents/$name"
  elif [ "$(readlink -f "$link")" != "$(readlink -f "$f")" ]; then
    fail "flat agents: ~/.claude/agents/$name resolves to '$(readlink -f "$link")', expected $f"
  fi
done
linked=$(find "$sc/home/.claude/agents" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
[ "$linked" -eq "$agents_total" ] \
  || fail "flat agents: ~/.claude/agents holds $linked entries, the clone has $agents_total agents"
echo "$ctx" | grep -q "$agents_total agents reachable" \
  || fail "flat agents: status does not count the $agents_total agents: $ctx"
echo "$ctx" | grep -q 'no errors' || fail "flat agents: status not clean: $ctx"
[ $failures -eq $prior ] && pass "flat agents: linked at <name>.md, counted, no error"

# --- Case 9: only the .md files are agents ----------------------------------
# A clone whose agents/ also holds a non-.md file and a leftover directory:
# neither is an agent, so neither is linked and neither is counted.
prior=$failures
clone=$(new_clone)
printf 'alpha\n' >"$clone/agents/alpha.md"
printf 'beta\n' >"$clone/agents/beta.md"
printf 'notes\n' >"$clone/agents/notes.txt"
mkdir -p "$clone/agents/leftover"
sc=$(new_scratch)
out=$(run_core "$clone/skills/bootstrap/assets/session-start-core.sh" "$sc")
ctx=$(echo "$out" | json_context) || { fail "mixed agents dir: JSON invalid: $out"; ctx=""; }
for name in alpha.md beta.md; do
  link="$sc/home/.claude/agents/$name"
  if [ ! -L "$link" ]; then
    fail "mixed agents dir: no link at ~/.claude/agents/$name"
  elif [ "$(readlink -f "$link")" != "$(readlink -f "$clone/agents/$name")" ]; then
    fail "mixed agents dir: ~/.claude/agents/$name resolves to '$(readlink -f "$link")', expected $clone/agents/$name"
  fi
done
for name in notes.txt leftover; do
  [ -e "$sc/home/.claude/agents/$name" ] || [ -L "$sc/home/.claude/agents/$name" ] \
    && fail "mixed agents dir: $name is not an agent but was linked anyway"
done
echo "$ctx" | grep -q '2 agents reachable' \
  || fail "mixed agents dir: status does not count exactly the 2 .md agents: $ctx"
[ $failures -eq $prior ] && pass "mixed agents dir: only the .md files linked and counted"

# --- Case 10: an agents/ without a single .md is still a failure ------------
prior=$failures
clone=$(new_clone)
printf 'not an agent\n' >"$clone/agents/README.txt"
sc=$(new_scratch)
out=$(run_core "$clone/skills/bootstrap/assets/session-start-core.sh" "$sc")
ctx=$(echo "$out" | json_context) || { fail "no .md agents: JSON invalid: $out"; ctx=""; }
echo "$ctx" | grep -q 'FAILED' || fail "no .md agents: not flagged: $ctx"
echo "$ctx" | grep -q 'no agents linked' || fail "no .md agents: cause not named: $ctx"
echo "$ctx" | grep -q '0 agents reachable' || fail "no .md agents: count is not 0: $ctx"
[ -z "$(find "$sc/home/.claude/agents" -mindepth 1 2>/dev/null)" ] \
  || fail "no .md agents: something was linked anyway: $(find "$sc/home/.claude/agents" -mindepth 1 | tr '\n' ' ')"
[ $failures -eq $prior ] && pass "agents dir without a .md: flagged, nothing linked"

# --- Case 11: a link left by the old nested layout is gone afterwards -------
# A session bootstrapped before agents became flat files left
# ~/.claude/agents/<name> pointing at a directory that no longer exists. It
# must not survive the run — a dangling link there is what discovery trips
# over — and the flat link must be there instead.
prior=$failures
sc=$(new_scratch)
mkdir -p "$sc/home/.claude/agents"
set -- "$repo_root"/agents/*.md
stale=$(basename "$1" .md)
ln -s "$repo_root/agents/$stale" "$sc/home/.claude/agents/$stale"
out=$(run_core "$core" "$sc")
ctx=$(echo "$out" | json_context) || { fail "stale nested link: JSON invalid: $out"; ctx=""; }
if [ -L "$sc/home/.claude/agents/$stale" ] || [ -e "$sc/home/.claude/agents/$stale" ]; then
  fail "stale nested link: ~/.claude/agents/$stale survived (-> $(readlink "$sc/home/.claude/agents/$stale" 2>/dev/null))"
fi
if [ ! -L "$sc/home/.claude/agents/$stale.md" ]; then
  fail "stale nested link: no link at ~/.claude/agents/$stale.md"
elif [ "$(readlink -f "$sc/home/.claude/agents/$stale.md")" != "$(readlink -f "$repo_root/agents/$stale.md")" ]; then
  fail "stale nested link: ~/.claude/agents/$stale.md resolves to '$(readlink -f "$sc/home/.claude/agents/$stale.md")', expected $repo_root/agents/$stale.md"
fi
echo "$ctx" | grep -q 'broken link' && fail "stale nested link: a broken link is left behind: $ctx"
echo "$ctx" | grep -q 'no errors' || fail "stale nested link: status not clean: $ctx"
[ $failures -eq $prior ] && pass "stale nested agent link removed, flat link in its place"

echo
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
