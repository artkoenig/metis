#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Metis loader — the ONLY file installed per project, kept deliberately thin
# and stable: it clones or updates the metis repo, then hands over to the
# sync logic INSIDE the clone (session-start-core.sh). Workflow changes
# therefore reach already-bootstrapped projects on their next session start,
# without anyone re-running the bootstrap skill there.
#
# Installed by the `bootstrap` skill in https://github.com/artkoenig/metis.
# Re-run that skill to update this file rather than hand-editing it.
# ---------------------------------------------------------------------------

# stdout is reserved for the final hook JSON; everything else goes to the log.
CLAUDE_HOME="${HOME}/.claude"
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/session-start.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 3>&1            # fd 3 = real stdout (hook JSON only)
exec 1>"$LOG_FILE" 2>&1
echo "=== Metis loader initialized: $(date) ==="

failure_handler() {
  echo "❌ CRASH on line $1 (Exit Code: $?)"
}
trap 'failure_handler ${LINENO}' ERR

# Only manage skills/agents in the remote (Claude Code on the web) environment;
# locally the user owns their own ~/.claude.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  echo "Executed locally. Skipping remote skill/agent setup."
  exit 0
fi

repo_url="https://github.com/artkoenig/metis.git"
repo_dir="${CLAUDE_HOME}/metis"

# Clone, or update — and on a failed update, re-clone rather than silently
# serving a stale cache: a session that loads yesterday's workflow because a
# pull failed is exactly the drift this loader exists to prevent.
if [ -d "${repo_dir}/.git" ]; then
  echo "Updating metis repo..."
  git -C "$repo_dir" pull --quiet --ff-only || {
    echo "⚠️  Pull failed; re-cloning for a fresh copy."
    rm -rf "$repo_dir"
  }
fi
if [ ! -d "${repo_dir}/.git" ]; then
  echo "Cloning metis repo..."
  rm -rf "$repo_dir"
  git clone --quiet --depth 1 "$repo_url" "$repo_dir"
fi

# Hand over to the current sync logic from the clone. `exec bash` keeps the
# log redirection and fd 3, so the core script inherits both.
core="${repo_dir}/skills/bootstrap/assets/session-start-core.sh"
if [ ! -f "$core" ]; then
  echo "❌ Core script missing at ${core}."
  exit 1
fi
exec bash "$core"
