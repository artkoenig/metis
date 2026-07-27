#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Metis sync logic — always executed FROM the metis clone by the thin
# per-project loader (session-start.sh), never installed into a project.
# That is the point: editing this file changes what every bootstrapped
# project does on its next session start.
#
# Inherited from the loader: stdout already redirected to the session log,
# fd 3 = the real stdout, reserved for the final hook JSON.
# ---------------------------------------------------------------------------

failure_handler() {
  echo "❌ CRASH on line $1 (Exit Code: $?)"
}
trap 'failure_handler ${LINENO}' ERR

CLAUDE_HOME="${HOME}/.claude"
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
legacy_dir="${CLAUDE_HOME}/artkoenig-agents"   # the predecessor repo's clone
skills_dir="${CLAUDE_HOME}/skills"
agents_dir="${CLAUDE_HOME}/agents"
echo "=== Metis core running from ${repo_dir} ==="

# 1. Expose each skill at the one-level depth that skill discovery expects.
#    Symlink so updates are reflected without copying. Prune links we own —
#    including any left by the predecessor repo, so a migrated session does
#    not load both skill sets side by side.
mkdir -p "$skills_dir"
for link in "$skills_dir"/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "${repo_dir}/skills/"*|"${legacy_dir}/skills/"*) rm -f "$link" ;;
  esac
done
for skill in "${repo_dir}/skills"/*/; do
  [ -f "${skill}SKILL.md" ] || continue
  ln -sfn "${skill%/}" "${skills_dir}/$(basename "$skill")"
  echo "Linked skill: $(basename "$skill")"
done

# 2. Same treatment for subagents (agents/<name>/agent.md; Claude Code scans
#    ~/.claude/agents recursively and takes identity from the `name` field).
mkdir -p "$agents_dir"
for link in "$agents_dir"/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "${repo_dir}/agents/"*|"${legacy_dir}/agents/"*) rm -f "$link" ;;
  esac
done
for agent in "${repo_dir}/agents"/*/; do
  [ -f "${agent}agent.md" ] || continue
  ln -sfn "${agent%/}" "${agents_dir}/$(basename "$agent")"
  echo "Linked agent: $(basename "$agent")"
done

# 3. The rulebook becomes the global instructions.
if [ -f "${repo_dir}/AGENTS.md" ]; then
  cp "${repo_dir}/AGENTS.md" "${CLAUDE_HOME}/CLAUDE.md"
  echo "Synced AGENTS.md -> ~/.claude/CLAUDE.md"
fi

# 4. Guard the default branch: point the project's git hooks at metis's
#    .githooks so pre-push refuses a direct push to main/master. Nothing is
#    copied into the project; the hook is shared from the clone.
project_dir="${CLAUDE_PROJECT_DIR:-.}"
if [ -d "${repo_dir}/.githooks" ] && \
   git -C "$project_dir" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$project_dir" config core.hooksPath "${repo_dir}/.githooks"
  echo "Set core.hooksPath -> ${repo_dir}/.githooks"
fi

echo "✅ Metis core finished successfully."

# 5. Tell Claude Code to reload skills now that they're in place.
echo '{"hookSpecificOutput": {"hookEventName": "SessionStart", "reloadSkills": true}}' >&3
