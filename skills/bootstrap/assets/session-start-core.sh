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
skills_n=0
for skill in "${repo_dir}/skills"/*/; do
  [ -f "${skill}SKILL.md" ] || continue
  ln -sfn "${skill%/}" "${skills_dir}/$(basename "$skill")"
  echo "Linked skill: $(basename "$skill")"
  skills_n=$((skills_n + 1))
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
agents_n=0
for agent in "${repo_dir}/agents"/*/; do
  [ -f "${agent}agent.md" ] || continue
  ln -sfn "${agent%/}" "${agents_dir}/$(basename "$agent")"
  echo "Linked agent: $(basename "$agent")"
  agents_n=$((agents_n + 1))
done

# 3. The rulebook becomes the global instructions.
if [ -f "${repo_dir}/AGENTS.md" ]; then
  cp "${repo_dir}/AGENTS.md" "${CLAUDE_HOME}/CLAUDE.md"
  echo "Synced AGENTS.md -> ~/.claude/CLAUDE.md"
  rulebook=synced
else
  rulebook=missing
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

# 5. Self-check. Not just the links: an empty or half-cloned repo links
#    nothing and would otherwise pass, so every outcome above is verified —
#    something was linked, no clone directory was silently skipped, the
#    rulebook really got synced, and every link resolves. A crashed run
#    never reaches this line, so a missing status is itself a failure
#    signal; the rulebook says what a session does then.
errors=""
[ "$skills_n" -gt 0 ] || errors="${errors} no skills linked;"
[ "$agents_n" -gt 0 ] || errors="${errors} no agents linked;"
[ "$rulebook" = synced ] || errors="${errors} rulebook missing from clone;"
for dir in "${repo_dir}/skills"/*/; do
  [ -d "$dir" ] && [ ! -f "${dir}SKILL.md" ] && errors="${errors} skill without SKILL.md: $(basename "$dir");"
done
for dir in "${repo_dir}/agents"/*/; do
  [ -d "$dir" ] && [ ! -f "${dir}agent.md" ] && errors="${errors} agent without agent.md: $(basename "$dir");"
done
for link in "$skills_dir"/* "$agents_dir"/*; do
  [ -L "$link" ] && [ ! -e "$link" ] && errors="${errors} broken link: $(basename "$link");"
done
commit=$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo unknown)
status="Metis self-check: ${skills_n} skills and ${agents_n} agents linked; commit ${commit};"
if [ -z "$errors" ]; then
  status="${status} no errors."
else
  status="${status} FAILED:${errors} see .claude/hooks/session-start.log."
fi
# Filenames can carry anything; strip what would break the JSON embedding.
status=${status//\\/}
status=${status//\"/}
echo "$status"

# 6. Tell Claude Code to reload skills, and hand the status to the session.
printf '{"hookSpecificOutput": {"hookEventName": "SessionStart", "reloadSkills": true, "additionalContext": "%s"}}\n' "$status" >&3
