#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  maintain-agent-definition.sh <agent-name>
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

agent_name="$1"
[[ "$agent_name" =~ ^[a-z0-9-]+$ ]] || die "agent name must match ^[a-z0-9-]+$"

agent_dir="$ROOT/agent-resources/agents/$agent_name"
instructions_file="$agent_dir/instructions.md"
claude_file="$agent_dir/CLAUDE.md"
codex_file="$agent_dir/codex.toml"

[[ -f "$instructions_file" ]] || die "missing agent file: ${instructions_file#$ROOT/}"
[[ -f "$claude_file" ]] || die "missing agent file: ${claude_file#$ROOT/}"
[[ -f "$codex_file" ]] || die "missing agent file: ${codex_file#$ROOT/}"

agents_link="$ROOT/.agents/agents/$agent_name.md"
claude_link="$ROOT/.claude/agents/$agent_name.md"
codex_link="$ROOT/.codex/agents/$agent_name.toml"

ensure_expected_symlink "$agents_link" "../../agent-resources/agents/$agent_name/instructions.md"
ensure_expected_symlink "$claude_link" "../../agent-resources/agents/$agent_name/CLAUDE.md"
ensure_expected_symlink "$codex_link" "../../agent-resources/agents/$agent_name/codex.toml"

test -e "$agents_link"
test -e "$claude_link"
test -e "$codex_link"

echo "symlink ok: .agents/agents/$agent_name.md -> ../../agent-resources/agents/$agent_name/instructions.md"
echo "symlink ok: .claude/agents/$agent_name.md -> ../../agent-resources/agents/$agent_name/CLAUDE.md"
echo "symlink ok: .codex/agents/$agent_name.toml -> ../../agent-resources/agents/$agent_name/codex.toml"
