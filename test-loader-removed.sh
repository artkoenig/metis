#!/bin/bash
# Tests for issue 0032 — issue 0031 was merged without doing what its own
# intent asked: the repository still shipped the loader alongside the
# plugin. This suite was first written for issue 0031; issue 0032 fixes two
# bugs found in it (see criterion 3 below) and adds a case for its
# criterion 6. Everything here reads the repository's own tracked tree;
# nothing is installed and nothing leaves the machine. Exit 0 = all cases
# pass.
#
# Which acceptance criterion of issue 0032 each block covers:
#
#   Criterion 1 — the loader files are absent, the plugin's own hook stays
#     Case: install.sh, .claude/hooks/session-start.sh (the installed loader
#     copy), skills/bootstrap/, test-install.sh, and the two suites nested
#     under skills/bootstrap/assets/ that guard only the loader are all gone.
#     hooks/session-start.sh and hooks/hooks.json — the plugin's own hook,
#     out of this issue's scope — are asserted still present.
#   Criterion 2 — this repository's settings declare no SessionStart hook
#   pointing at the loader, and its marketplace/plugin entries are unchanged
#     Case: .claude/settings.json either has no "hooks" key at all, or a
#     "hooks" key without a "SessionStart" entry in it, and its
#     extraKnownMarketplaces and enabledPlugins values are exactly what they
#     were before this issue: one "metis" directory-source marketplace, one
#     enabled plugin "metis@metis".
#   Criterion 3 — no reference to install.sh, the bootstrap skill or the
#   loader script outside docs/issues/, the two retained plugin-hook files
#   and this issue's own two verification scripts, and the check exempts no
#   OTHER tracked file from its own search
#     Case: grepping every tracked file except docs/issues/*,
#     hooks/session-start.sh, hooks/hooks.json, test-loader-removed.sh and
#     test-plugin.sh — named individually, not by a blanket self-exclusion —
#     for "install.sh", "bootstrap", or the loader script's own
#     installed-copy path (".claude/hooks/session-start.sh") finds nothing.
#     The previous version of this file excluded itself from the search by
#     name with no record of why; that undocumented self-exemption is the
#     bug issue 0032 names. The two exclusions here are instead named by the
#     criterion's own text (see the issue's Decisions) because both scripts
#     must contain these literal strings to check the paths are gone — no
#     other tracked file gets the same pass.
#   Criterion 4 — test.sh names only what remains
#     Case: `bash test.sh` exits 0, every suite it names exists on disk, and
#     none of the named suites is test-install.sh or either of the two
#     bootstrap suites this issue removes. The other half of criterion 4 —
#     that test.sh names every suite file the tree holds — is already
#     covered by test-plugin.sh's own case 20 ("test.sh coverage"); it is
#     not duplicated here.
#   Criterion 6 — issue 0024 is closed as moot, noting its file is gone;
#   issue 0023 is not closed on the false ground that its file is gone
#     Case: docs/issues/0024-*.md has moved off "status: backlog" and its
#     text both names the file it described (skills/bootstrap/SKILL.md) and
#     says it no longer exists. docs/issues/0023-*.md is not required to
#     stay open — criterion 6 allows closing it too, with a true reason —
#     only that, if it is closed, it does not carry a "no longer exist" note
#     about its own file, which would be false: hooks/session-start.sh, the
#     file 0023 reproduces against, stays (criterion 1 above pins that down).
#
# Criterion 5 (test-plugin.sh carries no case asserting the removed loader,
# install.sh, the bootstrap skill or their suites are present) is a case
# inside test-plugin.sh itself — see its case 19 — not here.
# Criterion 7 is about this suite and test-plugin.sh together carrying a
# test per criterion and none that overreaches; there is nothing separate to
# run for it — see the test-author's report for the mapping.
#
# The "Criterion 3" block below the loader-settings block (README.md and
# AGENTS.md naming the plugin install, not the loader's) is issue 0031's own
# criterion 3, which issue 0032 does not repeat — it is already met and is
# left as-is, unrenumbered, as regression coverage.
set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root" || exit 1

failures=0

fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
pass() { echo "ok:   $1"; }

# --- Criterion 1: the loader files are absent -------------------------------
removed_paths=(
  "install.sh"
  ".claude/hooks/session-start.sh"
  "skills/bootstrap"
  "test-install.sh"
  "skills/bootstrap/assets/test-session-start-core.sh"
  "skills/bootstrap/assets/test-session-start-loader.sh"
)
prior=$failures
for p in "${removed_paths[@]}"; do
  [ ! -e "$repo_root/$p" ] || fail "still present: $p"
done
# The plugin's own SessionStart hook is out of this issue's scope and must stay.
retained_paths=(
  "hooks/session-start.sh"
  "hooks/hooks.json"
)
for p in "${retained_paths[@]}"; do
  [ -e "$repo_root/$p" ] || fail "missing (should be retained, plugin's own hook): $p"
done
[ $failures -eq $prior ] && pass "loader files and suites are absent, plugin's own hook stays (issue 0032 criterion 1)"

# --- Criterion 2: this repo's settings declare no SessionStart hook, and
# its extraKnownMarketplaces/enabledPlugins entries are unchanged ----------
prior=$failures
if [ -f "$repo_root/.claude/settings.json" ]; then
  settings_err=$(python3 -c '
import json, sys
s = json.load(open(sys.argv[1]))
hooks = s.get("hooks")
if hooks is not None and "SessionStart" in hooks:
    sys.exit("still declares a SessionStart hook")
want_marketplaces = {"metis": {"source": {"source": "directory", "path": "."}}}
want_plugins = {"metis@metis": True}
if s.get("extraKnownMarketplaces") != want_marketplaces:
    sys.exit("extraKnownMarketplaces changed: %r" % (s.get("extraKnownMarketplaces"),))
if s.get("enabledPlugins") != want_plugins:
    sys.exit("enabledPlugins changed: %r" % (s.get("enabledPlugins"),))
' "$repo_root/.claude/settings.json" 2>&1) \
    || fail ".claude/settings.json: $settings_err"
else
  fail ".claude/settings.json is missing entirely"
fi
[ $failures -eq $prior ] && pass ".claude/settings.json declares no SessionStart hook and keeps its marketplace/plugin entries unchanged (issue 0032 criterion 2)"

# --- Criterion 3 (issue 0031, not one of issue 0032's own criteria — kept
# as regression coverage, unrenumbered): README.md instructs the plugin
# install, neither file names a step that installs the loader --------------
prior=$failures
if [ ! -f "$repo_root/README.md" ]; then
  fail "README.md: missing"
else
  grep -q "install\.sh" "$repo_root/README.md" \
    && fail "README.md: still names install.sh as an install step"
  grep -q "claude plugin install" "$repo_root/README.md" \
    || fail "README.md: does not instruct installing the plugin (expected 'claude plugin install')"
fi
[ $failures -eq $prior ] && pass "README.md: instructs the plugin install, names no loader step (issue 0031 criterion 3)"

prior=$failures
if [ ! -f "$repo_root/AGENTS.md" ]; then
  fail "AGENTS.md: missing"
else
  grep -q "install\.sh" "$repo_root/AGENTS.md" \
    && fail "AGENTS.md: still names install.sh as an install step"
fi
[ $failures -eq $prior ] && pass "AGENTS.md: names no loader install step (issue 0031 criterion 3)"

# --- Criterion 3 (issue 0032): no reference to the removed paths anywhere in
# the tree, and the search exempts no OTHER tracked file from itself -------
# Excludes exactly four things, all named by the criterion text itself (see
# the issue's Decisions — the human settled this): docs/issues/ (historical
# Log entries there are allowed to mention these paths); the two retained
# plugin-hook files named by criterion 1 (hooks/session-start.sh,
# hooks/hooks.json); and this issue's own two verification scripts,
# test-loader-removed.sh and test-plugin.sh, by name. Both of those two must
# contain the literal strings "install.sh"/"bootstrap" in their own source to
# check for the paths' absence (see their own removed-paths lists below and
# test-plugin.sh's case 19), so without this named exemption the criterion
# could never be met by any implementation. Unlike the original bug — a
# blanket self-exclusion the check carved out silently, with no record in
# the criterion it was checking — this exemption is bounded to exactly these
# two files and is spelled out in the criterion's own text; no other tracked
# file, including any other test suite, is exempt.
prior=$failures
tracked=$(git -C "$repo_root" ls-files \
  | grep -v '^docs/issues/' \
  | grep -v '^hooks/session-start\.sh$' \
  | grep -v '^hooks/hooks\.json$' \
  | grep -v '^test-loader-removed\.sh$' \
  | grep -v '^test-plugin\.sh$')
for pattern in 'install\.sh' 'bootstrap' '\.claude/hooks/session-start\.sh' 'skills/bootstrap/assets/session-start\.sh'; do
  hits=$(printf '%s\n' "$tracked" | xargs -I{} sh -c 'grep -lE "$1" "$2" 2>/dev/null' _ "$pattern" "$repo_root"/{} 2>/dev/null)
  if [ -n "$hits" ]; then
    fail "pattern '$pattern' still referenced in: $(printf '%s' "$hits" | tr '\n' ' ')"
  fi
done
[ $failures -eq $prior ] && pass "no reference to install.sh, bootstrap or the loader script's own path outside docs/issues/, the two retained hook files and this issue's own two verification scripts, and the search exempts no other tracked file (issue 0032 criterion 3)"

# --- Criterion 4 (issue 0032): test.sh names only what remains -------------
prior=$failures
if [ ! -f "$repo_root/test.sh" ]; then
  fail "test.sh is missing"
else
  suite_lines=$(sed -n '/^suites=(/,/^)/p' "$repo_root/test.sh" | sed '1d;$d')
  suites=()
  while IFS= read -r line; do
    line="$(echo "$line" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$line" ] && suites+=("$line")
  done <<<"$suite_lines"

  [ "${#suites[@]}" -gt 0 ] || fail "test.sh names no suites at all"

  for s in "${suites[@]}"; do
    [ -f "$repo_root/$s" ] || fail "test.sh names a suite that does not exist: $s"
    case "$s" in
      test-install.sh|skills/bootstrap/assets/test-session-start-core.sh|skills/bootstrap/assets/test-session-start-loader.sh)
        fail "test.sh still names a suite that guarded a removed part: $s"
        ;;
    esac
  done

  run_output=$(bash "$repo_root/test.sh" 2>&1)
  run_exit=$?
  [ "$run_exit" -eq 0 ] || fail "test.sh exited $run_exit, not 0"
fi
[ $failures -eq $prior ] && pass "test.sh exits 0 and names only surviving suites (issue 0032 criterion 4)"

# --- Criterion 6 (issue 0032): issue 0024 is closed as moot; issue 0023 is
# not closed on the false ground that its file is gone ----------------------
# The issue tracker's four states (backlog/active/waiting/done) have no
# dedicated "moot"/"won't do" state, so "marked resolved as moot" is checked
# here only by what the criterion's own text pins down: the file has moved
# off "status: backlog" and its own text says why. What exact status value
# that move should land on is not specified anywhere and is not guessed at
# here — see the test-author's report.
prior=$failures
issue_0024="$repo_root/docs/issues/0024-the-plugin-ships-a-skill-that-installs-the-other-path.md"
if [ ! -f "$issue_0024" ]; then
  fail "issue 0024's file is missing; it should still exist, closed in place"
else
  grep -q '^status: backlog$' "$issue_0024" \
    && fail "issue 0024: still status: backlog — not yet closed as moot"
  grep -q 'skills/bootstrap/SKILL\.md' "$issue_0024" \
    || fail "issue 0024: no note names the file it described (skills/bootstrap/SKILL.md)"
  grep -qi 'no longer exist' "$issue_0024" \
    || fail "issue 0024: no note says the file it described no longer exists"
fi
issue_0023="$repo_root/docs/issues/0023-the-plugin-hook-overwrites-a-projects-existing-hookspath.md"
if [ ! -f "$issue_0023" ]; then
  fail "issue 0023's file is missing; it must stay open or be closed in place, not deleted"
elif ! grep -q '^status: backlog$' "$issue_0023"; then
  # It was closed. Criterion 6 allows that, with a true reason — the one
  # ground it rules out is "its file is gone", which is false: criterion 1
  # above pins down that hooks/session-start.sh, the file 0023 reproduces
  # against, still exists.
  grep -qi 'no longer exist' "$issue_0023" \
    && fail "issue 0023: closed with a note that its file no longer exists — false, hooks/session-start.sh remains"
fi
[ $failures -eq $prior ] && pass "issue 0024 is closed as moot noting its file is gone; issue 0023 is not closed on that false ground (issue 0032 criterion 6)"

echo
if [ $failures -eq 0 ]; then
  echo "PASS: all cases"
else
  echo "FAIL: $failures case(s)"
  exit 1
fi
