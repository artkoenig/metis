#!/bin/bash
# Tests for the Claude Code plugin this repository packages (issue 0022).
# Everything runs against scratch directories: the real ~/.claude, the real
# Claude configuration and the real repository's git config are never
# touched — every `claude` call gets a scratch CLAUDE_CONFIG_DIR, every hook
# run gets a scratch HOME and a scratch project repo. No model is called;
# `claude plugin validate|marketplace|install|details` are shell-level.
# Nothing leaves the machine. Exit 0 = all cases pass.
#
# Which acceptance criterion each block covers:
#
#   Criterion 1 — `claude plugin validate --strict` exits 0
#     Cases 1-3: the two manifests are the documented shape, and the
#     validator accepts the repository with --strict.
#   Criterion 2 — the exposed component inventory equals what is in the tree
#     Case 4: the layout the plugin's own discovery needs (agents flat, one
#     `.md` file each, because discovery does not recurse and takes the name
#     from the filename; every skill directory carries its SKILL.md).
#     Case 5: set equality — the inventory `claude plugin details` reports
#     equals the skill directories under skills/ and the agent files under
#     agents/, none missing, none extra.
#   Criterion 3 — the rulebook text itself is delivered
#     Case 7: additionalContext contains the whole text of AGENTS.md
#     verbatim, which a pointer to the file could not carry.
#   Criterion 4 — a self-check status naming counts and the guard state
#     Case 6: hooks/hooks.json registers exactly one SessionStart command
#     hook and it runs hooks/session-start.sh from the plugin root.
#     Case 8: the details inventory shows that one SessionStart hook.
#     Case 9: the happy status names the real skill and agent counts and the
#     push-guard state, and reports no failure.
#     Cases 10-13: each missing part — no skills, no agents, no AGENTS.md,
#     no push guard — is named and the status stops reporting success; a
#     project that is not a git repository makes the guard not applicable
#     rather than failed.
#   Criterion 5 — a push to the default branch is refused
#     Case 14: with core.hooksPath set the way the hook sets it, `git push`
#     to main against a scratch bare remote is refused by exit code, the
#     remote branch is not created, and a push to a non-default branch still
#     succeeds.
#   Criterion 8 — test.sh names existing suites
#     Case 15: every path in test.sh's `suites` list exists, and no listed
#     suite is still pinned to the nested agent layout that this change
#     removes — a suite that moves `agents/<name>/agent.md` cannot exit 0
#     once agents are flat files, so test.sh could not exit 0 either.
#
# Criteria 6 and 7 are records in the issue, not behaviour, and have nothing
# to run here.
#
# Wording the status assertions rely on, since "says so instead of reporting
# success" needs a token to test: a status that reports a problem contains
# the word "fail" (any case); a status that reports success contains none of
# "fail", "missing", "not set", "n/a". A missing part is named by its own
# word ("skills", "agents", "rulebook" or "AGENTS.md", "guard"). The status
# is read as the context minus the rulebook text, so the rulebook's own
# prose cannot satisfy these greps.
set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base=$(mktemp -d)
trap 'rm -rf "$base"' EXIT

# A scratch base inside a git repository breaks the sandbox: a case
# without a repo of its own would see that repo, and git could write into
# it. Refuse before running any case.
if git -C "$base" rev-parse --git-dir >/dev/null 2>&1; then
  echo "test-plugin.sh: refusing to run: $base is inside a git repository (check TMPDIR)" >&2
  exit 1
fi

mkdir -p "$base/home"

failures=0
skips=0

fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
pass() { echo "ok:   $1"; }
skip() { echo "skip: $1"; skips=$((skips + 1)); }

have_claude() { command -v claude >/dev/null 2>&1; }

# Count how many of the given paths exist (a glob that matches nothing stays
# literal, so plain $# would over-count).
count_paths() {
  local n=0 p
  for p in "$@"; do [ -e "$p" ] && n=$((n + 1)); done
  echo "$n"
}

# A copy of the repository tree without its .git, usable as a plugin root
# that cases may mutate. Prints the path.
copy_plugin() {
  local dst
  dst=$(mktemp -d "$base/XXXXXX")
  (cd "$repo_root" && tar -cf - --exclude=.git .) | (cd "$dst" && tar -xf -)
  echo "$dst"
}

# A scratch project repository with its own git identity. Prints the path.
new_project() {
  local p
  p=$(mktemp -d "$base/XXXXXX")
  git -C "$p" init --quiet --initial-branch=main
  git -C "$p" config user.email "test@example.invalid"
  git -C "$p" config user.name "Test"
  echo "$p"
}

# Run the plugin's SessionStart hook the way Claude Code runs it: the plugin
# root and the project in the environment, the envelope on stdout. HOME is
# scratch so nothing can reach the real ~/.claude.
# $1 = plugin root, $2 = project dir.
run_hook() {
  HOME="$base/home" CLAUDE_PLUGIN_ROOT="$1" CLAUDE_PROJECT_DIR="$2" \
    bash "$1/hooks/session-start.sh"
}

# Strict oracle for the envelope: read raw bytes and decode UTF-8 ourselves
# — stdin's default surrogateescape handler would wave invalid bytes
# through. Pin the event name, then print additionalContext.
# $1 = file holding the hook's stdout.
ctx_of() { python3 -c '
import json, sys
h = json.loads(open(sys.argv[1], "rb").read().decode("utf-8"))["hookSpecificOutput"]
assert h["hookEventName"] == "SessionStart", h
ctx = h["additionalContext"]
assert isinstance(ctx, str) and ctx.strip(), "additionalContext must be a non-empty string"
sys.stdout.write(ctx)' "$1"; }

# The status part of the context: the context with the rulebook text removed
# once, so the rulebook's own prose cannot satisfy a status grep.
# $1 = context file, $2 = rulebook file.
strip_rulebook() { python3 -c '
import sys
ctx = open(sys.argv[1], encoding="utf-8").read()
book = open(sys.argv[2], encoding="utf-8").read().strip("\n")
sys.stdout.write(ctx.replace(book, "", 1))' "$1" "$2"; }

# Run the hook and split its output. On success $ctx_file holds
# additionalContext and $status_file the status part; on failure $why says
# what was wrong. $1 = plugin root, $2 = project dir.
hook_status() {
  local d
  d=$(mktemp -d "$base/XXXXXX")
  ctx_file="$d/ctx"; status_file="$d/status"; why=""
  if ! run_hook "$1" "$2" >"$d/out.json" 2>"$d/err"; then
    why="hook exited non-zero: $(tr '\n' ' ' <"$d/err" | cut -c1-200)"
    return 1
  fi
  if ! ctx_of "$d/out.json" >"$ctx_file" 2>"$d/parse.err"; then
    why="envelope not the documented shape: $(tr '\n' ' ' <"$d/parse.err" | tail -c 200) stdout=[$(head -c 200 "$d/out.json")]"
    return 1
  fi
  if ! strip_rulebook "$ctx_file" "$repo_root/AGENTS.md" >"$status_file" 2>/dev/null; then
    why="could not separate the status from the rulebook text"
    return 1
  fi
  return 0
}

# Does the status report a problem?
says_failure() { grep -Eqi 'fail' "$1"; }
# Does the status report plain success?
says_success() { ! grep -Eqi 'fail|missing|not set|n/a|not applicable' "$1"; }
# Print the status on one line, for a failure message.
show() { tr '\n' ' ' <"$1" | cut -c1-300; }

plugin_manifest="$repo_root/.claude-plugin/plugin.json"
market_manifest="$repo_root/.claude-plugin/marketplace.json"
hooks_manifest="$repo_root/hooks/hooks.json"
hook_script="$repo_root/hooks/session-start.sh"

skills_total=$(count_paths "$repo_root"/skills/*/)
agents_total=$(count_paths "$repo_root"/agents/*.md)

# --- Case 1: the plugin manifest is there and names the plugin -------------
prior=$failures
if [ -f "$plugin_manifest" ]; then
  python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
assert m.get("name") == "metis", "plugin name is %r, expected \"metis\"" % (m.get("name"),)
' "$plugin_manifest" 2>"$base/m1.err" || fail "plugin manifest: $(tail -1 "$base/m1.err")"
else
  fail "plugin manifest: $plugin_manifest missing"
fi
[ $failures -eq $prior ] && pass "plugin manifest exists and names the plugin metis"

# --- Case 2: the marketplace manifest offers exactly this one plugin -------
prior=$failures
if [ -f "$market_manifest" ]; then
  python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
assert m.get("name") == "metis", "marketplace name is %r, expected \"metis\"" % (m.get("name"),)
p = m.get("plugins")
assert isinstance(p, list), "plugins is %r, expected a list" % (type(p).__name__,)
assert len(p) == 1, "%d plugin entries, expected exactly 1" % len(p)
assert p[0].get("name") == "metis", "entry name is %r, expected \"metis\"" % (p[0].get("name"),)
assert p[0].get("source") == "./", "entry source is %r, expected \"./\"" % (p[0].get("source"),)
' "$market_manifest" 2>"$base/m2.err" || fail "marketplace manifest: $(tail -1 "$base/m2.err")"
else
  fail "marketplace manifest: $market_manifest missing"
fi
[ $failures -eq $prior ] && pass "marketplace manifest offers exactly one plugin: metis at ./"

# --- Case 3: the validator accepts the repository under --strict -----------
prior=$failures
if have_claude; then
  cfg=$(mktemp -d "$base/XXXXXX")
  if CLAUDE_CONFIG_DIR="$cfg" claude plugin validate "$repo_root" --strict \
      >"$base/validate.log" 2>&1; then
    pass "claude plugin validate --strict exits 0"
  else
    fail "claude plugin validate --strict exited non-zero: $(tr '\n' ' ' <"$base/validate.log" | cut -c1-400)"
  fi
else
  skip "claude plugin validate --strict: no claude binary on PATH"
fi

# --- Case 4: the layout plugin discovery needs -----------------------------
# Discovery does not recurse and takes an agent's name from the filename, so
# every agent must be one flat `.md` file under agents/; a skill directory
# without its SKILL.md would not be exposed either.
prior=$failures
if [ -d "$repo_root/agents" ]; then
  nested=0
  for entry in "$repo_root"/agents/*; do
    [ -e "$entry" ] || continue
    if [ -d "$entry" ]; then
      fail "agent layout: $(basename "$entry") is a directory — plugin discovery does not recurse"
      nested=1
    elif [ "${entry##*.}" != "md" ]; then
      fail "agent layout: $(basename "$entry") is not a .md file"
    fi
  done
  [ "$agents_total" -ge 1 ] || fail "agent layout: no agents/<name>.md file exists ($nested nested directories found)"
else
  fail "agent layout: $repo_root/agents missing"
fi
for d in "$repo_root"/skills/*/; do
  [ -d "$d" ] || continue
  [ -f "$d/SKILL.md" ] || fail "skill layout: $(basename "$d") has no SKILL.md"
done
[ "$skills_total" -ge 1 ] || fail "skill layout: no skills/<name>/ directory exists"
[ $failures -eq $prior ] && pass "agents are flat .md files, every skill directory has its SKILL.md"

# --- Cases 5 and 8: the inventory the plugin exposes ----------------------
# Install a copy of this repository as a plugin into a scratch config and ask
# for its component inventory. The skill and agent sets must equal what is in
# the tree, and the hook must show up as one SessionStart hook.
inventory_out="$base/details.out"
inventory_log="$base/details.log"
inventory_ok=0
if have_claude; then
  cfg=$(mktemp -d "$base/XXXXXX")
  plug=$(copy_plugin)
  if CLAUDE_CONFIG_DIR="$cfg" claude plugin marketplace add "$plug" >"$inventory_log" 2>&1 \
     && CLAUDE_CONFIG_DIR="$cfg" claude plugin install metis@metis >>"$inventory_log" 2>&1 \
     && CLAUDE_CONFIG_DIR="$cfg" claude plugin details metis@metis >"$inventory_out" 2>>"$inventory_log"; then
    inventory_ok=1
  fi
fi

prior=$failures
if ! have_claude; then
  skip "component inventory equals the tree: no claude binary on PATH"
elif [ "$inventory_ok" -eq 0 ]; then
  fail "component inventory: installing this repository as a plugin failed: $(tr '\n' ' ' <"$inventory_log" | cut -c1-400)"
else
  python3 - "$inventory_out" "$repo_root" <<'PYEOF' 2>"$base/inv.err" || fail "component inventory: $(tail -2 "$base/inv.err" | tr '\n' ' ')"
import os, re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
root = sys.argv[2]

def listed(label):
    m = re.search(r"^\s*%s \((\d+)\)[ \t]*(.*)$" % label, text, re.M)
    if not m:
        sys.exit("no %s line in the inventory output" % label)
    names = re.split(r"\s\s+\(", m.group(2))[0]
    names = {n.strip() for n in names.split(",") if n.strip()}
    if len(names) != int(m.group(1)):
        sys.exit("%s says (%s) but lists %d names: %r"
                 % (label, m.group(1), len(names), sorted(names)))
    return names

want_skills = {d for d in os.listdir(os.path.join(root, "skills"))
               if os.path.isdir(os.path.join(root, "skills", d))}
adir = os.path.join(root, "agents")
want_agents = {f[:-3] for f in os.listdir(adir)
               if f.endswith(".md") and os.path.isfile(os.path.join(adir, f))}

problems = []
for label, want in (("Skills", want_skills), ("Agents", want_agents)):
    got = listed(label)
    if got != want:
        problems.append("%s: missing %r, extra %r"
                        % (label, sorted(want - got), sorted(got - want)))
if problems:
    sys.exit("; ".join(problems))
PYEOF
fi
[ $failures -eq $prior ] && [ "$inventory_ok" -eq 1 ] \
  && pass "inventory equals the skill directories and agent files in the tree"

# --- Case 6: hooks.json registers one SessionStart command hook ------------
prior=$failures
if [ -f "$hooks_manifest" ]; then
  python3 -c '
import json, sys
doc = json.load(open(sys.argv[1]))
events = doc["hooks"] if isinstance(doc.get("hooks"), dict) else doc
entries = events.get("SessionStart")
assert isinstance(entries, list) and entries, "no SessionStart entry: %r" % (events,)
cmds = [h for e in entries for h in e.get("hooks", []) if h.get("type") == "command"]
assert len(cmds) == 1, "%d SessionStart command hooks, expected exactly 1" % len(cmds)
c = cmds[0].get("command", "")
assert "CLAUDE_PLUGIN_ROOT" in c, "command does not use CLAUDE_PLUGIN_ROOT: %r" % c
assert "hooks/session-start.sh" in c, "command does not run hooks/session-start.sh: %r" % c
' "$hooks_manifest" 2>"$base/m3.err" || fail "hook config: $(tail -1 "$base/m3.err")"
else
  fail "hook config: $hooks_manifest missing"
fi
[ -f "$hook_script" ] || fail "hook config: $hook_script missing"
[ -x "$hook_script" ] || fail "hook config: $hook_script not executable"
[ $failures -eq $prior ] && pass "hooks.json registers one SessionStart command hook running the script"

# --- Case 7: the rulebook text itself arrives in the context ---------------
prior=$failures
proj=$(new_project)
if hook_status "$repo_root" "$proj"; then
  python3 -c '
import sys
ctx = open(sys.argv[1], encoding="utf-8").read()
book = open(sys.argv[2], encoding="utf-8").read().strip("\n")
if book in ctx:
    sys.exit(0)
# Narrow the report down to the first paragraph that did not arrive.
for para in book.split("\n\n"):
    if para.strip() and para not in ctx:
        sys.exit("rulebook text not delivered whole; first missing passage: %r"
                 % para[:120])
sys.exit("rulebook paragraphs present but not the whole text verbatim")
' "$ctx_file" "$repo_root/AGENTS.md" 2>"$base/book.err" \
    || fail "rulebook: $(tail -1 "$base/book.err")"
  bytes=$(wc -c <"$repo_root/AGENTS.md")
  [ "$(wc -c <"$ctx_file")" -ge "$bytes" ] \
    || fail "rulebook: context is shorter than AGENTS.md ($(wc -c <"$ctx_file") < $bytes bytes) — a pointer, not the text"
else
  fail "rulebook: $why"
fi
[ $failures -eq $prior ] && pass "additionalContext carries the whole text of AGENTS.md"

# --- Case 9: the happy self-check status ----------------------------------
prior=$failures
proj=$(new_project)
if hook_status "$repo_root" "$proj"; then
  got_skills=$(grep -oEi '[0-9]+ skills' "$status_file" | head -1 | cut -d' ' -f1)
  got_agents=$(grep -oEi '[0-9]+ agents' "$status_file" | head -1 | cut -d' ' -f1)
  [ -n "$got_skills" ] || fail "status: no skill count: $(show "$status_file")"
  [ -n "$got_agents" ] || fail "status: no agent count: $(show "$status_file")"
  [ "${got_skills:-x}" = "$skills_total" ] \
    || fail "status: names ${got_skills:-no} skills, the tree has $skills_total"
  [ "${got_agents:-x}" = "$agents_total" ] \
    || fail "status: names ${got_agents:-no} agents, the tree has $agents_total"
  [ "$agents_total" -ge 1 ] || fail "status: the tree holds no agents/<name>.md to count"
  grep -Eqi 'push[ -]?guard' "$status_file" \
    || fail "status: no push-guard state: $(show "$status_file")"
  says_success "$status_file" \
    || fail "status: reports a problem on a complete plugin: $(show "$status_file")"
  [ "$(git -C "$proj" config core.hooksPath 2>/dev/null)" = "$repo_root/.githooks" ] \
    || fail "status: core.hooksPath is '$(git -C "$proj" config core.hooksPath 2>/dev/null)', expected $repo_root/.githooks"
else
  fail "status: $why"
fi
[ $failures -eq $prior ] && pass "happy path: counts match the tree, guard state named, no problem reported"

# A plugin root with one part removed must name that part and stop reporting
# success. $1 = case label, $2 = command that breaks the copy (the copy is
# its argument), $3 = extended regex the status must match.
names_missing_part() {
  local label=$1 break_cmd=$2 want=$3 plug proj
  prior=$failures
  plug=$(copy_plugin)
  bash -c "$break_cmd" _ "$plug"
  proj=$(new_project)
  if hook_status "$plug" "$proj"; then
    grep -Eqi "$want" "$status_file" \
      || fail "$label: status does not name it (/$want/): $(show "$status_file")"
    says_failure "$status_file" \
      || fail "$label: status still reports success: $(show "$status_file")"
  else
    fail "$label: $why"
  fi
  [ $failures -eq $prior ] && pass "$label: named in the status, success withdrawn"
}

# --- Cases 10-12: a missing part is named, success withdrawn --------------
names_missing_part "no skills" 'rm -rf "$1/skills" && mkdir "$1/skills"' 'no skills|0 skills|skills missing'
names_missing_part "no agents" 'rm -rf "$1/agents"' 'no agents|0 agents|agents missing'
names_missing_part "no rulebook" 'rm -f "$1/AGENTS.md"' 'rulebook|AGENTS\.md'

# --- Case 13a: no .githooks in the plugin, project is a git repo -----------
# Pushes from that project are possible and unguarded, so this is a failure,
# and nothing may point core.hooksPath at a directory that is not there.
prior=$failures
plug=$(copy_plugin)
rm -rf "$plug/.githooks"
proj=$(new_project)
if hook_status "$plug" "$proj"; then
  grep -Eqi 'push[ -]?guard' "$status_file" \
    || fail "no guard: status does not mention the push guard: $(show "$status_file")"
  grep -Eqi 'not set|missing' "$status_file" \
    || fail "no guard: status does not say the guard is absent: $(show "$status_file")"
  says_failure "$status_file" \
    || fail "no guard: status still reports success: $(show "$status_file")"
  [ -z "$(git -C "$proj" config core.hooksPath 2>/dev/null)" ] \
    || fail "no guard: core.hooksPath was set anyway to '$(git -C "$proj" config core.hooksPath)'"
else
  fail "no guard: $why"
fi
[ $failures -eq $prior ] && pass "missing .githooks: guard absence named, success withdrawn, no hooksPath set"

# --- Case 13b: project is not a git repo — n/a, not a failure -------------
prior=$failures
proj=$(mktemp -d "$base/XXXXXX")   # deliberately no `git init`
if hook_status "$repo_root" "$proj"; then
  grep -Eqi 'push[ -]?guard' "$status_file" \
    || fail "non-git project: status does not mention the push guard: $(show "$status_file")"
  grep -Eqi 'n/a|not applicable' "$status_file" \
    || fail "non-git project: guard not reported as not applicable: $(show "$status_file")"
  says_failure "$status_file" \
    && fail "non-git project: absence of the guard reported as a failure: $(show "$status_file")"
else
  fail "non-git project: $why"
fi
[ $failures -eq $prior ] && pass "non-git project: guard not applicable, not a failure"

# --- Case 14: the guard the hook installs refuses the default branch ------
prior=$failures
proj=$(new_project)
remote="$base/remote.git"
rm -rf "$remote"
git init --bare --quiet "$remote"
git -C "$proj" remote add origin "$remote"
echo one >"$proj/file.txt"
git -C "$proj" add file.txt
git -C "$proj" -c commit.gpgsign=false commit --quiet -m "one"
if hook_status "$repo_root" "$proj"; then :; else fail "push guard: $why"; fi
[ "$(git -C "$proj" config core.hooksPath 2>/dev/null)" = "$repo_root/.githooks" ] \
  || fail "push guard: core.hooksPath is '$(git -C "$proj" config core.hooksPath 2>/dev/null)', expected $repo_root/.githooks"
if git -C "$proj" push origin main >"$base/push-main.log" 2>&1; then
  fail "push guard: push to the default branch main was not refused"
else
  grep -qi 'refus' "$base/push-main.log" \
    || fail "push guard: push failed, but not with a refusal from the guard: $(tr '\n' ' ' <"$base/push-main.log" | cut -c1-300)"
  git -C "$remote" rev-parse --verify --quiet refs/heads/main >/dev/null \
    && fail "push guard: main exists on the remote despite the refusal"
fi
git -C "$proj" checkout --quiet -b feature
echo two >>"$proj/file.txt"
git -C "$proj" add file.txt
git -C "$proj" -c commit.gpgsign=false commit --quiet -m "two"
if git -C "$proj" push origin feature >"$base/push-feature.log" 2>&1; then
  git -C "$remote" rev-parse --verify --quiet refs/heads/feature >/dev/null \
    || fail "push guard: feature push exited 0 but the remote has no such branch"
else
  fail "push guard: push to a non-default branch was refused: $(tr '\n' ' ' <"$base/push-feature.log" | cut -c1-300)"
fi
[ $failures -eq $prior ] && pass "default branch push refused, non-default branch push accepted"

# --- Case 8: the inventory shows the one SessionStart hook ----------------
prior=$failures
if ! have_claude; then
  skip "inventory names the SessionStart hook: no claude binary on PATH"
elif [ "$inventory_ok" -eq 0 ]; then
  fail "inventory hook: installing this repository as a plugin failed: $(tr '\n' ' ' <"$inventory_log" | cut -c1-400)"
else
  grep -Eq '^[[:space:]]*Hooks \(1\)' "$inventory_out" \
    || fail "inventory hook: not exactly one hook: $(grep -Ei 'hooks \(' "$inventory_out" | tr '\n' ' ')"
  grep -Eq '^[[:space:]]*Hooks \(1\).*SessionStart' "$inventory_out" \
    || fail "inventory hook: the hook is not a SessionStart hook: $(grep -Ei 'hooks \(' "$inventory_out" | tr '\n' ' ')"
  [ $failures -eq $prior ] && pass "inventory names exactly one SessionStart hook"
fi

# --- Case 15: test.sh names suites that exist and fit this layout ---------
prior=$failures
listed_suites=$(python3 -c '
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"^suites=\(\s*(.*?)^\)", src, re.M | re.S)
if not m:
    sys.exit("no suites=( ... ) list in test.sh")
for line in m.group(1).splitlines():
    line = line.split("#")[0].strip()
    if line:
        print(line)
' "$repo_root/test.sh" 2>"$base/suites.err") || fail "test.sh: $(tail -1 "$base/suites.err")"
[ -n "$listed_suites" ] || fail "test.sh: the suites list is empty"
# The nested agent layout this change removes, spelled so this file is not
# itself a match.
nested_pat="agents/[A-Za-z0-9._-]""+/agent[.]md"
while IFS= read -r suite; do
  [ -n "$suite" ] || continue
  if [ -f "$repo_root/$suite" ]; then
    grep -Eq "$nested_pat" "$repo_root/$suite" \
      && fail "test.sh: suite $suite still uses the removed nested agent layout"
  else
    fail "test.sh: suite $suite does not exist"
  fi
done <<EOF
$listed_suites
EOF
echo "$listed_suites" | grep -qx "$(basename "${BASH_SOURCE[0]}")" \
  || fail "test.sh: the suites list does not name $(basename "${BASH_SOURCE[0]}")"
[ $failures -eq $prior ] && pass "test.sh names existing suites, none pinned to the nested agent layout"

echo
[ $skips -gt 0 ] && echo "note: $skips case(s) skipped"
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
