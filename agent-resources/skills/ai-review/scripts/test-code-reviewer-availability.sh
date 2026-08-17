#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/code-reviewer-availability-test.XXXXXX")"
fake_bin="$test_dir/bin"
repo="$test_dir/repo"
test_path="$fake_bin:/usr/bin:/bin"

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
    printf ' example.txt | 1 +\n'
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
