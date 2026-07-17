#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VALIDATOR="${SKILL_VALIDATOR:-"$ROOT/agent-resources/skills/scripts/quick_validate.py"}"
PYTHON_BIN="${PYTHON:-python3}"
PYTHONPATH_PREFIX="$ROOT/agent-resources/skills/scripts/pythonpath"

validate_script_names() {
  local skill_dir="$1"
  local scripts_dir="$skill_dir/scripts"
  local invalid_paths=()

  [[ -d "$scripts_dir" ]] || return 0

  while IFS= read -r path; do
    invalid_paths+=("$path")
  done < <(find "$scripts_dir" -type f ! -name '*.sh' -print | sort)

  if [[ "${#invalid_paths[@]}" -eq 0 ]]; then
    return 0
  fi

  echo "script file names must end with .sh:" >&2
  printf '  %s\n' "${invalid_paths[@]#$ROOT/}" >&2
  return 1
}

if [[ ! -f "$VALIDATOR" ]]; then
  echo "quick_validate.py not found: $VALIDATOR" >&2
  exit 1
fi

export PYTHONPATH="$PYTHONPATH_PREFIX${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONDONTWRITEBYTECODE=1

# 運用できないためコメントアウト
# echo "==> agent-resources/permissions.json sync check"
# node "$ROOT/agent-resources/scripts/generate-agent-permissions.mjs" --check

if [[ "$#" -gt 0 ]]; then
  skill_dirs=("$@")
else
  skill_dirs=()
  while IFS= read -r skill_md; do
    skill_dirs+=("$(dirname "$skill_md")")
  done < <(find "$ROOT/agent-resources/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print | sort)
fi

for skill_dir in "${skill_dirs[@]}"; do
  echo "==> ${skill_dir#$ROOT/}"
  "$PYTHON_BIN" "$VALIDATOR" "$skill_dir"
  validate_script_names "$skill_dir"
done
