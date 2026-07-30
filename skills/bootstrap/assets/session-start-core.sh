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
if ! git -C "$project_dir" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Skipping hooksPath: project is not a git repo (${project_dir})"
elif [ ! -d "${repo_dir}/.githooks" ]; then
  echo "Skipping hooksPath: no .githooks in clone"
else
  git -C "$project_dir" config core.hooksPath "${repo_dir}/.githooks"
  echo "Set core.hooksPath -> ${repo_dir}/.githooks"
fi

echo "✅ Metis core finished successfully."

# 5. Self-check. Verify the END STATE, not the steps: for every skill and
#    agent in the clone, the link discovery needs must sit at its expected
#    path and point at its expected target. Enumerating failure modes one
#    by one (dangling links, empty clones, collisions with a real
#    directory, ...) kept missing the next one; comparing expected against
#    actual catches them all at once. A crashed run never reaches this
#    line, so a missing status is itself a failure signal; the rulebook
#    says what a session does then.
errors=""
[ "$skills_n" -gt 0 ] || errors="${errors} no skills linked;"
[ "$agents_n" -gt 0 ] || errors="${errors} no agents linked;"
[ "$rulebook" = synced ] || errors="${errors} rulebook missing from clone;"
skills_ok=0
for dir in "${repo_dir}/skills"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ ! -f "${dir}SKILL.md" ]; then
    errors="${errors} skill without SKILL.md: ${name};"
  elif [ "$(readlink "${skills_dir}/${name}" 2>/dev/null)" != "${dir%/}" ]; then
    errors="${errors} skill not reachable: ${name};"
  else
    skills_ok=$((skills_ok + 1))
  fi
done
agents_ok=0
for dir in "${repo_dir}/agents"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ ! -f "${dir}agent.md" ]; then
    errors="${errors} agent without agent.md: ${name};"
  elif [ "$(readlink "${agents_dir}/${name}" 2>/dev/null)" != "${dir%/}" ]; then
    errors="${errors} agent not reachable: ${name};"
  else
    agents_ok=$((agents_ok + 1))
  fi
done
for link in "$skills_dir"/* "$agents_dir"/*; do
  [ -L "$link" ] && [ ! -e "$link" ] && errors="${errors} broken link: $(basename "$link");"
done
# The push guard, same principle — end state, not steps: what does the
# project's core.hooksPath say now? A project that is no git repo cannot be
# pushed from, so an absent guard there is a note, not an error; everywhere
# else an absent guard means an unguarded push is possible — that is a
# failure, and the status names the cause.
if ! git -C "$project_dir" rev-parse --git-dir >/dev/null 2>&1; then
  guard="push guard n/a (project not a git repo)"
elif [ "$(git -C "$project_dir" config core.hooksPath 2>/dev/null)" = "${repo_dir}/.githooks" ]; then
  guard="push guard set"
else
  if [ ! -d "${repo_dir}/.githooks" ]; then
    guard="push guard not set (no .githooks in clone)"
  else
    guard="push guard not set (hooksPath mismatch)"
  fi
  errors="${errors} ${guard};"
fi
commit=$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo unknown)
# The counts state what a session can rely on — links that resolve at their
# expected path — not how many ln calls ran.
status="Metis self-check: ${skills_ok} skills and ${agents_ok} agents reachable; ${guard}; commit ${commit};"
if [ -z "$errors" ]; then
  status="${status} no errors."
else
  status="${status} FAILED:${errors} see .claude/hooks/session-start.log."
fi
# Filenames can carry anything; the status may not. Whitelist, don't
# blacklist: keep only printable ASCII minus the two JSON delimiters —
# every byte not on the list is dropped, including the ones nobody
# thought of yet.
status=$(printf '%s' "$status" | LC_ALL=C tr -dc '\040-\176' | tr -d '\\"')
echo "$status"

# 6. Tell Claude Code to reload skills, and hand the status to the session.
printf '{"hookSpecificOutput": {"hookEventName": "SessionStart", "reloadSkills": true, "additionalContext": "%s"}}\n' "$status" >&3
