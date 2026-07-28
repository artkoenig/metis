#!/bin/bash
# Wires the current project to metis without a Claude session: installs the
# SessionStart loader hook, merges its settings entry, commits both. Safe to
# re-run — a second run changes nothing and makes no commit.
#
# Usage, from the target project's root:
#   curl -fsSL https://raw.githubusercontent.com/artkoenig/metis/main/install.sh | bash
#
# METIS_SOURCE overrides where the loader asset comes from: a raw-URL base
# (fork users) or a local metis checkout path (tests, offline use). Default
# is the artkoenig/metis main branch on raw.githubusercontent.com.
set -euo pipefail

source_base="${METIS_SOURCE:-https://raw.githubusercontent.com/artkoenig/metis/main}"
asset_path="skills/bootstrap/assets/session-start.sh"
hook_cmd='$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh'

die() { echo "install.sh: $1" >&2; exit 1; }

# Preconditions: a git repo root to install into, python3 for the JSON merge.
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) \
  || die "run this from the root of a git repository."
[ "$toplevel" = "$(pwd -P)" ] \
  || die "run this from the repository root ($toplevel), not a subdirectory."
command -v python3 >/dev/null 2>&1 \
  || die "python3 is required to merge .claude/settings.json; install it and re-run."
if git check-ignore -q .claude/hooks/session-start.sh 2>/dev/null; then
  die ".claude/ is git-ignored here, but the hook only works committed — unignore it and re-run."
fi

# 1. The loader — fetched from the canonical asset, never inlined here.
mkdir -p .claude/hooks
tmp_hook=$(mktemp)
trap 'rm -f "$tmp_hook"' EXIT
if [ -d "$source_base" ]; then
  cp "$source_base/$asset_path" "$tmp_hook" \
    || die "loader asset not found at $source_base/$asset_path."
else
  curl -fsSL "$source_base/$asset_path" -o "$tmp_hook" \
    || die "could not fetch the loader from $source_base/$asset_path."
fi
grep -q 'session-start-core.sh' "$tmp_hook" \
  || die "fetched loader does not look like the metis loader; refusing to install it."
install -m 755 "$tmp_hook" .claude/hooks/session-start.sh
echo "Installed .claude/hooks/session-start.sh"

# 2. The settings entry — merged in, never clobbering what is already there.
HOOK_CMD="$hook_cmd" python3 - .claude/settings.json <<'PYEOF'
import json, os, sys

path = sys.argv[1]
cmd = os.environ["HOOK_CMD"]
try:
    with open(path) as f:
        settings = json.load(f)
except FileNotFoundError:
    settings = {}
except json.JSONDecodeError as e:
    sys.exit(f"install.sh: {path} is not valid JSON ({e}); fix it and re-run.")

entries = settings.setdefault("hooks", {}).setdefault("SessionStart", [])
present = any(
    h.get("type") == "command" and h.get("command") == cmd
    for entry in entries
    for h in entry.get("hooks", [])
)
if not present:
    entries.append({"hooks": [{"type": "command", "command": cmd}]})
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print(f"Merged SessionStart entry into {path}")
else:
    print(f"SessionStart entry already present in {path}")
PYEOF

# 3. The commit — a cloud session only benefits from a hook that was
# committed before it started.
git add .claude/hooks/session-start.sh .claude/settings.json
if git diff --cached --quiet -- .claude/hooks/session-start.sh .claude/settings.json; then
  echo "Nothing to commit; already installed."
else
  git commit --quiet -m "Install metis session-start hook" \
    -- .claude/hooks/session-start.sh .claude/settings.json
  echo "Committed the hook and its settings entry."
fi
echo "Done. The next Claude session in this project loads metis."
