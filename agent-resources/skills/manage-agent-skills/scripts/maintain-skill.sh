#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  maintain-skill.sh <skill-name>
USAGE
}

die() {
  echo "error: $*" >&2
  exit 2
}

ensure_expected_symlink() {
  local path="$1"
  local target="$2"

  if [[ -L "$path" ]]; then
    local current_target
    current_target="$(readlink "$path")"
    [[ "$current_target" == "$target" ]] || die "$path points to $current_target; expected $target"
    return
  fi

  if [[ -e "$path" ]]; then
    die "$path exists and is not the intended symlink"
  fi

  ln -s "$target" "$path"
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

if [[ "$#" -ne 1 ]]; then
  usage >&2
  exit 2
fi

skill_name="$1"
[[ "$skill_name" =~ ^[a-z0-9-]+$ ]] || die "skill name must match ^[a-z0-9-]+$"

skill_dir="$ROOT/agent-resources/skills/$skill_name"
skill_md="$skill_dir/SKILL.md"
[[ -f "$skill_md" ]] || die "missing skill file: ${skill_md#$ROOT/}"

agents_link="$ROOT/.agents/skills/$skill_name"
claude_link="$ROOT/.claude/skills/$skill_name"
expected_target="../../agent-resources/skills/$skill_name"

ensure_expected_symlink "$agents_link" "$expected_target"
ensure_expected_symlink "$claude_link" "$expected_target"

test -e "$agents_link/SKILL.md"
test -e "$claude_link/SKILL.md"

echo "symlink ok: .agents/skills/$skill_name -> $expected_target"
echo "symlink ok: .claude/skills/$skill_name -> $expected_target"
echo "validate: agent-resources/skills/scripts/validate-agent-skills.sh agent-resources/skills/$skill_name"
(
  cd "$ROOT"
  agent-resources/skills/scripts/validate-agent-skills.sh "agent-resources/skills/$skill_name"
)
