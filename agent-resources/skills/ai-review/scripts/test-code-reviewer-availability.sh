#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/code-reviewer-availability-test.XXXXXX")"
fake_bin="$test_dir/bin"
repo="$test_dir/repo"
# CLI 不在ケースは実 PATH から codex / claude を隠すため最小 PATH を使う。
test_path="$fake_bin:/usr/bin:/bin"
# verdict ケースは fake_bin が実 CLI を shadow するため、jq などの実行環境を実 PATH から引く。
verdict_path="$fake_bin:$PATH"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

mkdir -p "$fake_bin" "$repo"

cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  status)
    printf ' M example.txt\n'
    ;;
  diff)
    case "$2" in
      --name-only)
        printf 'example.txt\n'
        ;;
      *)
        printf ' example.txt | 1 +\n'
        ;;
    esac
    ;;
esac
EOF

cat > "$fake_bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'Linux\n'
EOF

chmod +x "$fake_bin/git" "$fake_bin/uname"

run_case() {
  local name="$1"
  local expected_status="$2"
  local script="$3"
  local reviewer="$4"
  local output
  local status

  set +e
  output="$(cd "$repo" && \
    PATH="$test_path" \
    CLAUDE_REVIEW_CONSENT=yes \
    "$script" 2>&1)"
  status=$?
  set -e

  if [[ "$status" -ne "$expected_status" ]] || [[ "$output" != *"BLOCKED: "*"$reviewer"* ]]; then
    printf 'FAIL: %s: expected BLOCKED status %s, got %s\n%s\n' "$name" "$expected_status" "$status" "$output" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$name"
}

run_case \
  'Code review blocks when Codex CLI is unavailable' \
  127 \
  "$script_dir/run-code-review-codex.sh" \
  codex
run_case \
  'Code review blocks when Claude CLI is unavailable' \
  127 \
  "$script_dir/run-code-review-claude.sh" \
  claude

cat > "$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
exit 126
EOF
cat > "$fake_bin/claude" <<'EOF'
#!/usr/bin/env bash
exit 126
EOF
chmod +x "$fake_bin/codex" "$fake_bin/claude"

run_case \
  'Code review blocks when Codex CLI cannot execute' \
  126 \
  "$script_dir/run-code-review-codex.sh" \
  codex
run_case \
  'Code review blocks when Claude CLI cannot execute' \
  126 \
  "$script_dir/run-code-review-claude.sh" \
  claude

# `bash -n` は二重引用符内のコマンド置換を構文エラーとして検出しないため、
# reviewer prompt が展開エラーなしで codex へ届くことを実行時に確認する。
cat > "$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${@: -1}" > "$PROMPT_DUMP"
exit 0
EOF
chmod +x "$fake_bin/codex"

prompt_dump="$test_dir/prompt.txt"
prompt_output="$(cd "$repo" && \
  PATH="$verdict_path" \
  PROMPT_DUMP="$prompt_dump" \
  "$script_dir/run-code-review-codex.sh" 2>&1 || true)"

if [[ "$prompt_output" == *'command substitution'* ]] || [[ "$prompt_output" == *'syntax error'* ]]; then
  printf 'FAIL: Code review prompt triggers shell expansion\n%s\n' "$prompt_output" >&2
  exit 1
fi

if [[ ! -s "$prompt_dump" ]] || ! grep -q 'nice(5) failed: operation not permitted' "$prompt_dump"; then
  printf 'FAIL: Code review prompt lost the login shell noise guidance\n' >&2
  [[ -s "$prompt_dump" ]] && cat "$prompt_dump" >&2
  exit 1
fi

printf 'PASS: Code review sends the reviewer prompt without shell expansion\n'

cat > "$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
output_file=""
while (($#)); do
  case "$1" in
    -o)
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
chmod +x "$fake_bin/codex"

run_verdict_case() {
  local name="$1"
  local expected_status="$2"
  local script="$3"
  local expected_output="$4"
  local output
  local status

  set +e
  output="$(cd "$repo" && \
    PATH="$verdict_path" \
    CLAUDE_REVIEW_CONSENT=yes \
    "$script" 2>&1)"
  status=$?
  set -e

  if [[ "$status" -ne "$expected_status" ]] || [[ "$output" != *"$expected_output"* ]]; then
    printf 'FAIL: %s: expected status %s, got %s\n%s\n' "$name" "$expected_status" "$status" "$output" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$name"
}

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"git diff","aggregated_output":"diff --git a/example.txt b/example.txt\n","exit_code":0}}'

export FAKE_REVIEW_OUTPUT='BLOCKED: cannot read local files'
run_verdict_case \
  'Code review separates a self-blocked Codex response from a trusted review' \
  7 \
  "$script_dir/run-code-review-codex.sh" \
  'self-blocked despite successful local inspection'

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"pwd","aggregated_output":"/repo\n","exit_code":0}}'
run_verdict_case \
  'Code review keeps a blocked Codex response without diff inspection at status 4' \
  4 \
  "$script_dir/run-code-review-codex.sh" \
  'reviewer reported that the review is not trustworthy'

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"git diff --name-only","aggregated_output":"example.txt\n","exit_code":0}}'
run_verdict_case \
  'Code review rejects a file list as diff inspection evidence' \
  4 \
  "$script_dir/run-code-review-codex.sh" \
  'reviewer reported that the review is not trustworthy'

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"cat example.txt","aggregated_output":"diff --git a/example.txt b/example.txt\n","exit_code":0}}'
run_verdict_case \
  'Code review rejects file contents as diff inspection evidence' \
  4 \
  "$script_dir/run-code-review-codex.sh" \
  'reviewer reported that the review is not trustworthy'

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"git diff","aggregated_output":"diff --git a/example.txt b/example.txt\n","exit_code":0}}'

export FAKE_REVIEW_OUTPUT='UNTRUSTED: empty review range'
run_verdict_case \
  'Code review keeps a self-reported untrusted Codex response at status 4' \
  4 \
  "$script_dir/run-code-review-codex.sh" \
  'reviewer reported that the review is not trustworthy'

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"pwd","aggregated_output":"/repo\n","exit_code":0}}'
export FAKE_REVIEW_OUTPUT='No findings'
run_verdict_case \
  'Code review rejects a Codex review that skipped diff inspection' \
  4 \
  "$script_dir/run-code-review-codex.sh" \
  'rerun once'

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"git diff","aggregated_output":"diff --git a/example.txt b/example.txt\n","exit_code":0}}'
run_verdict_case \
  'Code review trusts a Codex review that inspected the working tree' \
  0 \
  "$script_dir/run-code-review-codex.sh" \
  'TRUSTED'

# 未追跡ファイルだけの差分では `git diff` に patch が現れないため、判定を落とさない。
cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  status)
    printf '?? untracked.txt\n'
    ;;
  diff)
    case "$2" in
      --name-only)
        ;;
      *)
        printf ' untracked.txt | 1 +\n'
        ;;
    esac
    ;;
esac
EOF
chmod +x "$fake_bin/git"

export FAKE_REVIEW_EVENTS='{"type":"item.completed","item":{"type":"command_execution","command":"cat untracked.txt","aggregated_output":"new file\n","exit_code":0}}'
run_verdict_case \
  'Code review trusts an untracked-only review without patch evidence' \
  0 \
  "$script_dir/run-code-review-codex.sh" \
  'TRUSTED'

# jq が無い環境では原因の分かる BLOCKED で停止する。
sys_bin="$test_dir/sysbin"
mkdir -p "$sys_bin"
for tool in bash env mktemp basename head grep cat dirname sed rm chmod printf ls; do
  for dir in /bin /usr/bin; do
    [[ -x "$dir/$tool" ]] && ln -sf "$dir/$tool" "$sys_bin/$tool"
  done
done

set +e
nojq_output="$(cd "$repo" && PATH="$fake_bin:$sys_bin" "$script_dir/run-code-review-codex.sh" 2>&1)"
nojq_status=$?
set -e

if [[ "$nojq_status" -ne 2 ]] || [[ "$nojq_output" != *'BLOCKED: jq is required'* ]]; then
  printf 'FAIL: Code review blocks when jq is unavailable: expected status 2, got %s\n%s\n' "$nojq_status" "$nojq_output" >&2
  exit 1
fi
printf 'PASS: Code review blocks when jq is unavailable\n'

cat > "$fake_bin/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${FAKE_REVIEW_OUTPUT:?}"
EOF
chmod +x "$fake_bin/claude"

export FAKE_REVIEW_OUTPUT='BLOCKED: cannot read local files'
run_verdict_case \
  'Code review rejects a blocked Claude response' \
  4 \
  "$script_dir/run-code-review-claude.sh" \
  'reviewer reported that the review is not trustworthy'

export FAKE_REVIEW_OUTPUT='No findings'
run_verdict_case \
  'Code review trusts a nonempty Claude review' \
  0 \
  "$script_dir/run-code-review-claude.sh" \
  'TRUSTED'
