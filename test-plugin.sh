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
#     Superseded by issue 0040: with no `version` key in plugin.json (issue
#     0040 criterion 1) both validations warn "No version specified", and
#     --strict turns that warning into an error. The flag is gone from the
#     cases below; what it was kept for is pinned without it, as issue 0040's
#     criteria 3 and 4.
#     Cases 1-2: the two manifests are the documented shape.
#     Cases 3a-3b: the validator accepts this repository at both of its
#     targets (issue 0040 criterion 3). The two targets check different
#     things and the criterion covers both: the repository root target reads
#     `.claude-plugin/marketplace.json` and stops, while the
#     `.claude-plugin/plugin.json` target walks the components — every
#     skills/<name>/SKILL.md and every agents/<name>.md. 3a pins the
#     marketplace target, 3b the component-walking one.
#     Case 3c: issue 0040 criterion 4 — 3b is the target with teeth, and it
#     keeps its teeth without --strict: an agent whose frontmatter does not
#     parse is rejected there.
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
#     Cases 16-18: the delivery does not depend on which bytes the rulebook
#     holds. A CRLF line, a lone CR, a double quote, a backslash and a tab
#     each stay inside a JSON string one way or another; whatever the hook
#     does with them, its stdout must parse and both the rulebook text and
#     the status must arrive. A raw CR cannot sit in a JSON string, so
#     escaping it and dropping it are both faithful and the CR cases
#     compare with CR removed from both sides; quote, backslash and tab
#     have to survive as they are.
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
#     Cases 21-24: partial loss, not only total loss. "When a part is
#     missing, the status says so instead of reporting success" holds for one
#     part out of many, not just for all of them: a skill directory that has
#     lost its SKILL.md (22) and an agent that sits in a directory instead of
#     being a flat .md file (23) are each in the tree and invisible to plugin
#     discovery, so each must be named and success withdrawn. Case 24 is the
#     repeat: both at once, both named. Case 21 is the centre those bracket —
#     an untouched copy of the tree still reports no problems with the real
#     counts, so naming an unreachable part may not be bought by flagging
#     every tree. A component whose file is simply gone (rm agents/x.md)
#     leaves nothing in the tree to compare against and is deliberately not
#     a case here.
#   Criterion 5 — a push to the default branch is refused
#     Case 14: with core.hooksPath set the way the hook sets it, `git push`
#     to main against a scratch bare remote is refused by exit code, the
#     remote branch is not created, and a push to a non-default branch still
#     succeeds.
#   Criterion 7 — while criterion 6 does not hold, the per-project
#   machinery stays in the repository
#     Case 19 used to assert install.sh, the bootstrap skill, the loader,
#     the core and the suites that only guard them were all present — the
#     branch of this criterion that held while issue 0022's own criterion 6
#     stayed open. That call is superseded: the human decided, recorded in
#     issue 0031, that the loader path is removed regardless. Case 19 now
#     asserts the opposite — none of that machinery may be present — which
#     is issue 0032's criterion 5, not this criterion 7. It is documented
#     here rather than moved so the supersession stays next to the criterion
#     it overrides.
#   Criterion 8 — test.sh names existing suites
#     Case 15: every path in test.sh's `suites` list exists, and no listed
#     suite is still pinned to the nested agent layout that this change
#     removes — a suite that moves `agents/<name>/agent.md` cannot exit 0
#     once agents are flat files, so test.sh could not exit 0 either.
#     Case 20: the other direction — every suite file in the tree is named
#     in test.sh, so a suite nobody wired in cannot hide behind a green
#     `test.sh`.
#
# Issue 0040 — a merged change reaches an installation, no version pinned:
#   Criterion 1 — neither manifest declares a version
#     Case 25: plugin.json has no `version` key and the metis entry in
#     marketplace.json has none either. A resolved version that never changes
#     is what makes an installation keep its cached copy.
#   Criterion 2 — an update delivers a change merged after the install
#     Case 26: a throwaway git repository holding this tree is added as a
#     marketplace and installed into a scratch config and a scratch HOME; a
#     further commit changes one tracked file the plugin ships;
#     `claude plugin marketplace update` and then `claude plugin update` must
#     leave the installed plugin directory — the installPath the CLI records
#     — carrying the changed content. The second commit touches that one file
#     and nothing under .claude-plugin/, so no version string is edited
#     anywhere on the way.
#   Criterion 3 — the two validations exit 0 (cases 3a-3b, above)
#   Criterion 4 — they still exit 1 on unparseable agent frontmatter
#     (case 3c, above)
#   Criterion 6 — README.md matches what an installation receives
#     Case 27: the README says what an update brings to an installation, and
#     wherever it mentions a version, a release, a bump or publishing, it
#     mentions it as something *not* required — none of it may stand as a
#     condition for a merged change to arrive.
#
# Criterion 6 is a measurement recorded in the issue, not behaviour, and has
# nothing to run here.
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

# --- Case 3a: the marketplace-manifest target ------------------------------
# `claude plugin validate <repo root>` validates .claude-plugin/marketplace.json
# and nothing else — it prints "Validating marketplace manifest:" and stops. It
# never opens a skill or an agent, so it cannot stand in for case 3b; keep both.
# No --strict: without a `version` key the validator warns "No version
# specified", and --strict would turn that warning into an error (issue 0040).
prior=$failures
if have_claude; then
  cfg=$(mktemp -d "$base/XXXXXX")
  if CLAUDE_CONFIG_DIR="$cfg" claude plugin validate "$repo_root" \
      >"$base/validate.log" 2>&1; then
    pass "claude plugin validate <repo root> exits 0 (marketplace manifest target)"
  else
    fail "claude plugin validate <repo root> exited non-zero: $(tr '\n' ' ' <"$base/validate.log" | cut -c1-400)"
  fi
else
  skip "claude plugin validate <repo root>: no claude binary on PATH"
fi

# --- Case 3b: the component-walking target ---------------------------------
# `claude plugin validate .claude-plugin/plugin.json` visits every
# skills/<name>/SKILL.md and every agents/<name>.md. This is the target that
# sees a component's frontmatter at all; case 3c is its proof. No --strict,
# for the reason case 3a gives.
prior=$failures
if have_claude; then
  cfg=$(mktemp -d "$base/XXXXXX")
  if CLAUDE_CONFIG_DIR="$cfg" claude plugin validate "$plugin_manifest" \
      >"$base/validate-components.log" 2>&1; then
    pass "claude plugin validate .claude-plugin/plugin.json exits 0 (walks every skill and agent)"
  else
    fail "claude plugin validate .claude-plugin/plugin.json exited non-zero: $(tr '\n' ' ' <"$base/validate-components.log" | cut -c1-400)"
  fi
else
  skip "claude plugin validate .claude-plugin/plugin.json: no claude binary on PATH"
fi

# --- Case 3c: that target rejects unparseable component frontmatter --------
# The defect this suite has to catch: an agent's `description:` written as an
# unquoted YAML scalar that holds ": ". The whole frontmatter then parses as
# nothing and the agent reaches a model with no description to select it by.
# On a scratch copy of the tree — the real agents/ is never touched — the same
# copy must validate clean before the break and be rejected after it, so a
# non-zero exit can only come from the broken frontmatter. If this case ever
# passes while 3b's target is swapped for the repository-root one, the swap has
# removed the only check that reads a component. Without --strict, so that
# dropping the flag (issue 0040) is not a silent loss of this coverage.
prior=$failures
if have_claude; then
  cfg=$(mktemp -d "$base/XXXXXX")
  broken_plug=$(copy_plugin)
  broken_agent="$broken_plug/agents/researcher.md"
  [ -f "$broken_agent" ] || broken_agent=$(ls "$broken_plug"/agents/*.md 2>/dev/null | head -1)
  if [ ! -f "$broken_agent" ]; then
    fail "component validation: the scratch copy has no agents/<name>.md to break"
  elif ! CLAUDE_CONFIG_DIR="$cfg" claude plugin validate "$broken_plug/.claude-plugin/plugin.json" \
      >"$base/validate-clean-copy.log" 2>&1; then
    fail "component validation: the untouched scratch copy was already rejected: $(tr '\n' ' ' <"$base/validate-clean-copy.log" | cut -c1-400)"
  else
    python3 -c '
import sys
p = sys.argv[1]
lines = open(p, encoding="utf-8").read().split("\n")
for i, l in enumerate(lines):
    if l.startswith("description:"):
        lines[i] = "description: a scalar that holds a colon: and a space, so YAML gives up"
        break
else:
    sys.exit("no description: line in %s" % p)
open(p, "w", encoding="utf-8").write("\n".join(lines))' "$broken_agent" 2>"$base/break.err" \
      || fail "component validation: could not break the copy: $(tail -1 "$base/break.err")"
    if [ $failures -eq $prior ]; then
      if CLAUDE_CONFIG_DIR="$cfg" claude plugin validate "$broken_plug/.claude-plugin/plugin.json" \
          >"$base/validate-broken.log" 2>&1; then
        fail "component validation: the validator accepted $(basename "$broken_agent") with unparseable frontmatter: $(tr '\n' ' ' <"$base/validate-broken.log" | cut -c1-400)"
      fi
    fi
  fi
  [ $failures -eq $prior ] \
    && pass "claude plugin validate .claude-plugin/plugin.json rejects an agent whose frontmatter does not parse"
else
  skip "component validation: no claude binary on PATH"
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

# --- Case 21: the centre cases 22-24 bracket ------------------------------
# An untouched copy of the tree, run through the same scratch machinery as
# the partial-loss cases below: the counts still equal the tree and the
# status still reports no problem. Without this, "name the unreachable part"
# could be satisfied by flagging every plugin root.
prior=$failures
plug=$(copy_plugin)
proj=$(new_project)
if hook_status "$plug" "$proj"; then
  got_skills=$(grep -oEi '[0-9]+ skills' "$status_file" | head -1 | cut -d' ' -f1)
  got_agents=$(grep -oEi '[0-9]+ agents' "$status_file" | head -1 | cut -d' ' -f1)
  [ "${got_skills:-x}" = "$skills_total" ] \
    || fail "intact copy: names ${got_skills:-no} skills, the tree has $skills_total: $(show "$status_file")"
  [ "${got_agents:-x}" = "$agents_total" ] \
    || fail "intact copy: names ${got_agents:-no} agents, the tree has $agents_total: $(show "$status_file")"
  says_success "$status_file" \
    || fail "intact copy: reports a problem on a complete plugin: $(show "$status_file")"
else
  fail "intact copy: $why"
fi
[ $failures -eq $prior ] && pass "intact copy of the tree: counts match, no problem reported"

# --- Cases 22-23: a part in the tree but unreachable ----------------------
# Neither of these two is absent from the tree: the skill directory is still
# there and the agent file is still there. Both are invisible to plugin
# discovery — discovery reads skills/<name>/SKILL.md and does not recurse
# into agents/ — so a session that is told "reachable" without a word about
# them is told the workflow is whole when half a component is gone. Which
# words the status uses is the implementer's choice; that the part is named
# and success withdrawn is the criterion. The nested agent path is built from
# a variable so that case 15's search for the removed nested layout does not
# match this file.
names_missing_part "skill directory without its SKILL.md" \
  'rm -f "$1/skills/plan/SKILL.md"' '\bplan\b'
names_missing_part "agent in a directory instead of a flat .md file" \
  'nest="$1/agents/planner"; mkdir -p "$nest" && cp "$1/agents/reviewer.md" "$nest/agent.md"' \
  '\bplanner\b'

# --- Case 24: the repeat — two unreachable parts at once -------------------
# Both are named, not just whichever the check happens to see first.
prior=$failures
plug=$(copy_plugin)
rm -f "$plug/skills/plan/SKILL.md"
nest="$plug/agents/planner"
mkdir -p "$nest"
cp "$plug/agents/reviewer.md" "$nest/agent.md"
proj=$(new_project)
if hook_status "$plug" "$proj"; then
  grep -Eqi '\bplan\b' "$status_file" \
    || fail "two unreachable parts: the skill is not named: $(show "$status_file")"
  grep -Eqi '\bplanner\b' "$status_file" \
    || fail "two unreachable parts: the agent is not named: $(show "$status_file")"
  says_failure "$status_file" \
    || fail "two unreachable parts: status still reports success: $(show "$status_file")"
else
  fail "two unreachable parts: $why"
fi
[ $failures -eq $prior ] && pass "two unreachable parts: both named, success withdrawn"

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

# --- Cases 16-18: whatever bytes the rulebook holds, the envelope holds ----
# Run the hook against a scratch plugin root whose AGENTS.md carries the given
# bytes and check three things: stdout parses as JSON, the rulebook text
# arrives in additionalContext, and the self-check status arrives beside it
# and reports no problem (the copy is complete).
# $1 = case label, $2 = file holding the bytes AGENTS.md gets,
# $3 = "exact" when every byte must survive, "cr-may-drop" when a CR may be
#      dropped on the way — a JSON string cannot carry a raw CR, so escaping
#      it and dropping it are both faithful; losing the text is not.
hostile_rulebook() {
  local label=$1 bytes=$2 mode=$3 plug proj d
  prior=$failures
  plug=$(copy_plugin)
  cp "$bytes" "$plug/AGENTS.md"
  proj=$(new_project)
  d=$(mktemp -d "$base/XXXXXX")
  if ! run_hook "$plug" "$proj" >"$d/out.json" 2>"$d/err"; then
    fail "$label: hook exited non-zero: $(tr '\n' ' ' <"$d/err" | cut -c1-200)"
  elif ! python3 - "$d/out.json" "$plug/AGENTS.md" "$mode" "$d/status" \
         >/dev/null 2>"$d/why" <<'PYEOF'
import json, sys
out_path, book_path, mode, status_out = sys.argv[1:5]
raw = open(out_path, "rb").read()
try:
    doc = json.loads(raw.decode("utf-8"))
except Exception as exc:
    sys.exit("stdout does not parse as JSON (%s); stdout=%r" % (exc, raw[:200]))
h = doc.get("hookSpecificOutput")
if not isinstance(h, dict) or h.get("hookEventName") != "SessionStart":
    sys.exit("envelope is not a SessionStart hookSpecificOutput: %r" % (doc,))
ctx = h.get("additionalContext")
if not isinstance(ctx, str) or not ctx.strip():
    sys.exit("additionalContext is %r, expected a non-empty string" % (ctx,))
book = open(book_path, "rb").read().decode("utf-8")
norm = (lambda s: s.replace("\r", "")) if mode == "cr-may-drop" else (lambda s: s)
want, got = norm(book).strip("\n"), norm(ctx)
if want not in got:
    for line in want.split("\n"):
        if line.strip() and line not in got:
            sys.exit("rulebook text did not arrive; first missing line %r; context=%r"
                     % (line[:80], got[:200]))
    sys.exit("rulebook lines arrived but not the text as a whole; context=%r" % (got[:200],))
status = got.replace(want, "", 1)
if "self-check" not in status:
    sys.exit("no self-check status beside the rulebook: %r" % (status[:200],))
open(status_out, "w", encoding="utf-8").write(status)
PYEOF
  then
    fail "$label: $(tail -2 "$d/why" | tr '\n' ' ' | cut -c1-400)"
  else
    says_failure "$d/status" \
      && fail "$label: status reports a problem on a complete plugin: $(show "$d/status")"
  fi
  [ $failures -eq $prior ] && pass "$label: stdout parses, rulebook text and status arrive"
}

printf 'The rulebook\r\nIntent first: criteria before code.\r\nLast line.\n' \
  >"$base/rulebook-crlf.md"
hostile_rulebook "CRLF line in AGENTS.md" "$base/rulebook-crlf.md" cr-may-drop

printf 'The rulebook\rIntent first: criteria before code.\nLast line.\n' \
  >"$base/rulebook-cr.md"
hostile_rulebook "lone CR in AGENTS.md" "$base/rulebook-cr.md" cr-may-drop

printf 'A "quoted" word, a backslash \\ and a\ttab.\nLast line.\n' \
  >"$base/rulebook-escapes.md"
hostile_rulebook 'quote, backslash and tab in AGENTS.md' "$base/rulebook-escapes.md" exact

# --- Case 19: no case here asserts the removed machinery is present -------
# (issue 0032 criterion 5). This reverses the case's old assertion: issue
# 0031's human decision overrides issue 0022's criterion 7, so install.sh,
# the bootstrap skill, the per-project loader and the suites that only
# guarded them must all be absent, not present.
prior=$failures
for p in install.sh \
         skills/bootstrap \
         .claude/hooks/session-start.sh \
         test-install.sh \
         skills/bootstrap/assets/test-session-start-core.sh \
         skills/bootstrap/assets/test-session-start-loader.sh; do
  [ -e "$repo_root/$p" ] \
    && fail "issue 0032 criterion 5: $p is still present — the loader path was removed"
done
[ $failures -eq $prior ] && pass "no loader/install.sh/bootstrap machinery remains in the repository (issue 0032 criterion 5)"

# --- Case 20: test.sh names every suite the tree holds --------------------
# Case 15 checks that what test.sh names exists; this is the other direction.
# A suite file in the tree that test.sh does not name never runs, so "the
# suite is green" would be a statement about a subset.
prior=$failures
found_suites=$(cd "$repo_root" && find . -path ./.git -prune -o -type f -name 'test*.sh' -print \
  | while IFS= read -r p; do p=${p#./}; [ "$p" = "test.sh" ] || echo "$p"; done | sort)
n_found=$(printf '%s\n' "$found_suites" | grep -c .)
[ "$n_found" -ge 2 ] \
  || fail "test.sh coverage: only $n_found suite file(s) found in the tree — the search is broken"
listed_norm=$(printf '%s\n' "$listed_suites" | tr -d "\"'")
while IFS= read -r suite; do
  [ -n "$suite" ] || continue
  printf '%s\n' "$listed_norm" | grep -qxF "$suite" \
    || fail "test.sh coverage: $suite exists in the tree but test.sh does not name it"
done <<EOF
$found_suites
EOF
[ $failures -eq $prior ] && pass "test.sh names every one of the $n_found suites in the tree"

# --- Case 25: neither manifest pins a version (issue 0040 criterion 1) -----
# Claude Code resolves a plugin's version from plugin.json first and falls
# back to the commit SHA; an installation whose resolved version is unchanged
# keeps its cached copy, so a declared version pins every installation to the
# commit that declared it. The marketplace entry can pin the same way.
prior=$failures
python3 - "$plugin_manifest" "$market_manifest" <<'PYEOF' 2>"$base/version-pin.err" \
  || fail "version pin: $(tail -1 "$base/version-pin.err")"
import json, sys
plugin_path, market_path = sys.argv[1:3]
problems = []
plugin = json.load(open(plugin_path, encoding="utf-8"))
if "version" in plugin:
    problems.append("plugin.json declares version %r" % (plugin["version"],))
market = json.load(open(market_path, encoding="utf-8"))
entries = [p for p in market.get("plugins", []) if p.get("name") == "metis"]
if not entries:
    problems.append("marketplace.json has no plugin entry named metis")
for e in entries:
    if "version" in e:
        problems.append("the metis entry in marketplace.json declares version %r"
                        % (e["version"],))
if problems:
    sys.exit("; ".join(problems))
PYEOF
[ $failures -eq $prior ] && pass "neither manifest declares a version key"

# --- Case 26: an update delivers a change merged after the install --------
# The whole point of issue 0040: a commit that lands after someone installed
# the plugin has to reach that installation. A throwaway git repository
# holding this tree plays the role of the published repository; the scratch
# CLAUDE_CONFIG_DIR and scratch HOME keep the real installation out of it.
# Nothing here edits a version string — the second commit touches one shipped
# file and nothing under .claude-plugin/, and that is asserted, not assumed.
prior=$failures
if ! have_claude; then
  skip "an update delivers a merged change: no claude binary on PATH"
else
  src=$(copy_plugin)
  git -C "$src" init --quiet --initial-branch=main
  git -C "$src" config user.email "test@example.invalid"
  git -C "$src" config user.name "Test"
  git -C "$src" add -A
  git -C "$src" -c commit.gpgsign=false commit --quiet -m "the plugin as this tree has it"
  cfg=$(mktemp -d "$base/XXXXXX")
  update_log="$base/update-path.log"
  marker="metis-update-marker-$$-$(date +%s)"
  : >"$update_log"
  if ! CLAUDE_CONFIG_DIR="$cfg" HOME="$base/home" claude plugin marketplace add "$src" \
       >>"$update_log" 2>&1; then
    fail "update path: marketplace add failed: $(tr '\n' ' ' <"$update_log" | cut -c1-400)"
  elif ! CLAUDE_CONFIG_DIR="$cfg" HOME="$base/home" claude plugin install metis@metis \
       >>"$update_log" 2>&1; then
    fail "update path: install failed: $(tr '\n' ' ' <"$update_log" | cut -c1-400)"
  else
    printf '\n%s\n' "$marker" >>"$src/AGENTS.md"
    git -C "$src" add -A
    git -C "$src" -c commit.gpgsign=false commit --quiet -m "change one file the plugin ships"
    changed=$(git -C "$src" diff --name-only HEAD~1 HEAD | tr '\n' ' ')
    [ "$changed" = "AGENTS.md " ] \
      || fail "update path: the commit had to change AGENTS.md alone, it changed: $changed"
    git -C "$src" diff --quiet HEAD~1 HEAD -- .claude-plugin \
      || fail "update path: the commit touched .claude-plugin/ — the delivery may not need a manifest edit"
    CLAUDE_CONFIG_DIR="$cfg" HOME="$base/home" claude plugin marketplace update metis \
      >>"$update_log" 2>&1 \
      || fail "update path: marketplace update exited non-zero: $(tr '\n' ' ' <"$update_log" | tail -c 400)"
    CLAUDE_CONFIG_DIR="$cfg" HOME="$base/home" claude plugin update metis@metis \
      >>"$update_log" 2>&1 \
      || fail "update path: plugin update exited non-zero: $(tr '\n' ' ' <"$update_log" | tail -c 400)"
    install_path=$(python3 - "$cfg/plugins/installed_plugins.json" 2>"$base/installpath.err" <<'PYEOF'
import json, sys
doc = json.load(open(sys.argv[1], encoding="utf-8"))
entries = doc.get("plugins", {}).get("metis@metis")
if isinstance(entries, dict):
    entries = [entries]
if not entries:
    sys.exit("no metis@metis entry in installed_plugins.json")
paths = sorted({e.get("installPath") for e in entries if e.get("installPath")})
if len(paths) != 1:
    sys.exit("expected one install path for metis@metis, got %r" % (paths,))
sys.stdout.write(paths[0])
PYEOF
    ) || fail "update path: cannot tell where the plugin is installed: $(tail -1 "$base/installpath.err")"
    if [ -n "${install_path:-}" ]; then
      if [ ! -f "$install_path/AGENTS.md" ]; then
        fail "update path: the installed plugin directory $install_path has no AGENTS.md"
      elif ! grep -qF "$marker" "$install_path/AGENTS.md"; then
        fail "update path: the installed AGENTS.md ($install_path) does not carry the change committed after the install: $(tr '\n' ' ' <"$update_log" | tail -c 300)"
      fi
    fi
    [ $failures -eq $prior ] \
      && pass "a commit made after the install reaches the installed plugin directory through marketplace update + plugin update"
  fi
fi

# --- Case 27: the README matches what an installation receives ------------
# Issue 0040 criterion 6. Two halves: the README says what an update brings to
# an installation, and it names no version bump, release or publishing step as
# a condition for a merged change to arrive. The second half is checked line by
# line: such a word may appear, but only in a sentence that says it is *not*
# needed — "no version bump required" is fine, "after the next release" is not.
prior=$failures
readme="$repo_root/README.md"
if [ ! -f "$readme" ]; then
  fail "README: $readme missing"
else
  python3 - "$readme" <<'PYEOF' 2>"$base/readme.err" || fail "README: $(tail -1 "$base/readme.err")"
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
problems = []

# Half one: what an installation receives, tied to an update.
paragraphs = [p for p in re.split(r"\n\s*\n", text) if p.strip()]
if not any(re.search(r"update", p, re.I)
           and re.search(r"\bmain\b|merged|change|session|install", p, re.I)
           for p in paragraphs):
    problems.append("no passage says what an update brings to an installation")

# Half two: no version bump, release or publishing step as a condition.
condition = re.compile(r"version|release|\bbump|publish", re.I)
denial = re.compile(r"\bno\b|\bnot\b|\bnever\b|without|\bkein|\bohne", re.I)
for i, line in enumerate(text.split("\n"), 1):
    if condition.search(line) and not denial.search(line):
        problems.append("line %d names a version/release step as a condition: %r"
                        % (i, line.strip()[:100]))
if problems:
    sys.exit("; ".join(problems))
PYEOF
fi
[ $failures -eq $prior ] \
  && pass "README says what an update brings and names no version or release step as a condition"

echo
[ $skips -gt 0 ] && echo "note: $skips case(s) skipped"
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
