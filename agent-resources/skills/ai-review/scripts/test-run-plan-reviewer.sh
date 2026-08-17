#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
reviewer_script="$script_dir/run-plan-reviewer.sh"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/run-plan-reviewer-test.XXXXXX")"
fake_bin="$test_dir/bin"
repo="$test_dir/repo"
prompt_file="$test_dir/prompt.md"
original_path="$PATH"
test_path="$fake_bin:$original_path"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

mkdir -p "$fake_bin" "$repo"
printf 'local repository evidence\nsecond line\n' > "$repo/target.txt"
printf 'Review the plan against target.txt.\n' > "$prompt_file"

cat > "$fake_bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'Linux\n'
EOF

cat > "$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${FAKE_REVIEWER_STATUS:-}" ]]; then
  exit "$FAKE_REVIEWER_STATUS"
fi
output_file=""
while (($#)); do
  case "$1" in
    --output-last-message)
      output_file="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
printf '%s\n' "${FAKE_REVIEW_OUTPUT:?}" > "$output_file"
printf '%s\n' "${FAKE_REVIEW_EVENTS:?}"
EOF

cat > "$fake_bin/claude" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${FAKE_REVIEWER_STATUS:-}" ]]; then
  exit "$FAKE_REVIEWER_STATUS"
fi
printf '%s\n' "${FAKE_REVIEW_EVENTS:?}"
EOF

chmod +x "$fake_bin/uname" "$fake_bin/codex" "$fake_bin/claude"

inspection_command="$(printf "sed -n '1,80p' %q" "$repo/target.txt")"
inspection_output="$(sed -n '1,80p' "$repo/target.txt")"

run_case() {
  local name="$1"
  local expected_status="$2"
  local reviewer="$3"
  local expected_output="${4:-}"
  local output
  local status

  set +e
  output="$(PATH="$test_path" \
    CLAUDE_REVIEW_CONSENT=yes \
    "$reviewer_script" \
      --repo "$repo" \
      --reviewer "$reviewer" \
      --prompt-file "$prompt_file" 2>&1)"
  status=$?
  set -e

  if [[ "$status" -ne "$expected_status" ]] || { [[ -n "$expected_output" ]] && [[ "$output" != *"$expected_output"* ]]; }; then
    printf 'FAIL: %s: expected status %s, got %s\n%s\n' "$name" "$expected_status" "$status" "$output" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$name"
}

mv "$fake_bin/codex" "$fake_bin/codex.disabled"
test_path="$fake_bin:/usr/bin:/bin"
run_case 'Plan review blocks when Codex CLI is unavailable' 127 codex 'BLOCKED:'
mv "$fake_bin/codex.disabled" "$fake_bin/codex"

mv "$fake_bin/claude" "$fake_bin/claude.disabled"
run_case 'Plan review blocks when Claude CLI is unavailable' 127 claude 'BLOCKED:'
mv "$fake_bin/claude.disabled" "$fake_bin/claude"
test_path="$fake_bin:$original_path"

export FAKE_REVIEWER_STATUS=126
run_case 'Plan review blocks when reviewer CLI is not executable' 126 codex 'BLOCKED:'
export FAKE_REVIEWER_STATUS=42
run_case 'Plan review keeps ordinary reviewer failures untrusted' 42 codex 'UNTRUSTED:'
unset FAKE_REVIEWER_STATUS

export FAKE_REVIEW_OUTPUT='No findings'
export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"pwd","aggregated_output":"'"$repo"'\n","exit_code":0}}'
run_case 'Codex rejects an arbitrary command' 4 codex

export FAKE_REVIEW_OUTPUT='BLOCKED: cannot read local files'
export FAKE_REVIEW_EVENTS="$(jq -nc \
  --arg command "$inspection_command" \
  --arg output "$inspection_output" \
  '{type:"item.completed",item:{type:"command_execution",command:$command,aggregated_output:($output + "\n"),exit_code:0}}')"
run_case 'Codex rejects a blocked final response' 4 codex

export FAKE_REVIEW_OUTPUT='No findings'
run_case 'Codex trusts successful file inspection' 0 codex

export FAKE_REVIEW_EVENTS='{"type":"result","result":"No findings"}'
run_case 'Claude rejects a nonempty response without inspection' 4 claude

export FAKE_REVIEW_EVENTS="$(jq -nc \
  --arg file "$repo/target.txt" \
  '[
    {type:"assistant",message:{content:[{type:"tool_use",name:"Read",id:"read-1",input:{file_path:$file}}]}},
    {type:"user",message:{content:[{type:"tool_result",tool_use_id:"read-1",is_error:false,content:"local repository evidence"}]}},
    {type:"result",result:"No findings"}
  ] | .[]')"
run_case 'Claude trusts successful Read inspection' 0 claude

export FAKE_REVIEW_EVENTS="$(jq -nc \
  --arg file "$repo/target.txt" \
  '[
    {type:"assistant",message:{content:[{type:"tool_use",name:"Read",id:"read-1",input:{file_path:$file}}]}},
    {type:"user",message:{content:[{type:"tool_result",tool_use_id:"read-1",is_error:false,content:"local repository evidence"}]}},
    {type:"result",result:"BLOCKED: cannot read local files"}
  ] | .[]')"
run_case 'Claude rejects a blocked final response' 4 claude
