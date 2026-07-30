#!/bin/bash
# Tests for issue 0031 — the repository ships exactly one delivery
# mechanism (the plugin) once the loader is removed. Everything here reads
# the repository's own tracked tree; nothing is installed and nothing
# leaves the machine. Exit 0 = all cases pass.
#
# Which acceptance criterion each block covers:
#
#   Criterion 1 — the loader files are absent, the plugin's own hook stays
#     Case: install.sh, .claude/hooks/session-start.sh (the installed loader
#     copy), skills/bootstrap/, test-install.sh, and the two suites nested
#     under skills/bootstrap/assets/ that guard only the loader are all gone.
#     hooks/session-start.sh and hooks/hooks.json — the plugin's own hook,
#     out of this issue's scope — are asserted still present.
#   Criterion 2 — this repository's own settings declare no SessionStart hook
#     Case: .claude/settings.json either has no "hooks" key at all, or a
#     "hooks" key without a "SessionStart" entry in it.
#   Criterion 3 — README.md instructs the plugin install; neither file names
#   a step that installs the loader
#     Case: README.md does not name "install.sh" (the loader's install step)
#     and does name the plugin's own install command instead — the literal
#     CLI invocation `claude plugin install`, the documented installation per
#     issue 0022's own record (`claude plugin marketplace add artkoenig/metis`
#     followed by `claude plugin install metis@metis`). AGENTS.md never
#     carried install instructions of either kind, so it is only checked for
#     the absence of "install.sh" — it is not required to newly gain plugin
#     install instructions it never had.
#   Criterion 4 — no reference to the removed paths anywhere in the tree
#     Case: grepping the tracked tree, excluding docs/issues/ (historical Log
#     entries there are allowed to mention these paths), this test's own file
#     (it necessarily contains the path strings it searches for) and
#     test-plugin.sh (whose own case checks these exact paths are absent, and
#     so must name them too), for "install.sh", "bootstrap", or the loader
#     script's own path (".claude/hooks/session-start.sh" or
#     "skills/bootstrap/assets/session-start.sh") finds nothing. A bare
#     mention of "hooks/session-start.sh" (the plugin's own, retained hook)
#     or of "hooks/hooks.json"'s own command string is not a hit.
#   Criterion 5 — test.sh names only what remains
#     Case: every suite test.sh names exists on disk, and none of them is
#     test-install.sh or either of the two bootstrap suites this issue
#     removes. Whether `bash test.sh` itself exits 0 is not re-checked here:
#     this file is one of the suites test.sh runs, so re-invoking test.sh
#     from inside it would recurse into itself. test.sh's own runner already
#     establishes that fact by summing every suite's exit code.
#
# Criterion 6 (closing issues 0023/0024 as moot) is bookkeeping, not
# behaviour, and has nothing to run here.
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
[ $failures -eq $prior ] && pass "loader files and suites are absent, plugin's own hook stays (criterion 1)"

# --- Criterion 2: this repo's settings declare no SessionStart hook --------
prior=$failures
if [ -f "$repo_root/.claude/settings.json" ]; then
  python3 -c '
import json, sys
s = json.load(open(sys.argv[1]))
hooks = s.get("hooks")
if hooks is not None and "SessionStart" in hooks:
    sys.exit(1)
' "$repo_root/.claude/settings.json" \
    || fail ".claude/settings.json still declares a SessionStart hook"
else
  fail ".claude/settings.json is missing entirely"
fi
[ $failures -eq $prior ] && pass "own settings.json declares no SessionStart hook (criterion 2)"

# --- Criterion 3: README.md instructs the plugin install, neither file
# names a step that installs the loader -------------------------------------
prior=$failures
if [ ! -f "$repo_root/README.md" ]; then
  fail "README.md: missing"
else
  grep -q "install\.sh" "$repo_root/README.md" \
    && fail "README.md: still names install.sh as an install step"
  grep -q "claude plugin install" "$repo_root/README.md" \
    || fail "README.md: does not instruct installing the plugin (expected 'claude plugin install')"
fi
[ $failures -eq $prior ] && pass "README.md: instructs the plugin install, names no loader step (criterion 3)"

prior=$failures
if [ ! -f "$repo_root/AGENTS.md" ]; then
  fail "AGENTS.md: missing"
else
  grep -q "install\.sh" "$repo_root/AGENTS.md" \
    && fail "AGENTS.md: still names install.sh as an install step"
fi
[ $failures -eq $prior ] && pass "AGENTS.md: names no loader install step (criterion 3)"

# --- Criterion 4: no reference to the removed paths anywhere in the tree ---
prior=$failures
tracked=$(git -C "$repo_root" ls-files | grep -v '^docs/issues/' | grep -v '^test-loader-removed\.sh$' | grep -v '^test-plugin\.sh$')
for pattern in 'install\.sh' 'bootstrap' '\.claude/hooks/session-start\.sh' 'skills/bootstrap/assets/session-start\.sh'; do
  hits=$(printf '%s\n' "$tracked" | xargs -I{} sh -c 'grep -lE "$1" "$2" 2>/dev/null' _ "$pattern" "$repo_root"/{} 2>/dev/null)
  if [ -n "$hits" ]; then
    fail "pattern '$pattern' still referenced in: $(printf '%s' "$hits" | tr '\n' ' ')"
  fi
done
[ $failures -eq $prior ] && pass "no reference to install.sh, bootstrap or the loader script's own path outside docs/issues/ (criterion 4)"

# --- Criterion 5: test.sh names only what remains ---------------------------
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

fi
[ $failures -eq $prior ] && pass "test.sh names only existing, surviving suites (criterion 5)"

echo
if [ $failures -eq 0 ]; then
  echo "PASS: all cases"
else
  echo "FAIL: $failures case(s)"
  exit 1
fi
