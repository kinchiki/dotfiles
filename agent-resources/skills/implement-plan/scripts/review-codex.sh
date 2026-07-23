#!/usr/bin/env bash
# Independent review via Codex CLI on the uncommitted working tree.
# Prints the review body and a trust verdict. Exit 0 only when TRUSTED.
set -uo pipefail

REVIEW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
REVIEW_OUT="$REVIEW_DIR/review.md"
REVIEW_JSON="$REVIEW_DIR/review.jsonl"
REVIEW_ERR="$REVIEW_DIR/review.err"
# Terra is the balanced default for the `codex exec review` subcommand.
# Set CODEX_REVIEW_MODEL=gpt-5.6-sol for high-risk diffs.
CODEX_REVIEW_MODEL="${CODEX_REVIEW_MODEL:-gpt-5.6-terra}"
CODEX_REVIEW_EFFORT="${CODEX_REVIEW_EFFORT:-medium}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_POLICY_FILE="$SCRIPT_DIR/../../ticket-to-plan/references/test-selection-policy.md"

if [[ ! -f "$TEST_POLICY_FILE" ]]; then
  echo "UNTRUSTED: missing test selection policy: $TEST_POLICY_FILE"
  exit 4
fi

TEST_SELECTION_POLICY="$(<"$TEST_POLICY_FILE")"
REVIEW_PROMPT="このリポジトリの未コミット差分をコードレビューしてください。
編集は禁止です。
まず git status --short, git diff --stat HEAD, git diff --cached, git diff を確認してください。
指摘は [P1]/[P2]/[P3] の重大度、file:line、根拠、修正案を含めて日本語で返してください。
Style / line-length 指摘は repo linter で確定検証し、byte count だけで日本語など multibyte text を違反判定しないでください。
次のテスト選定方針に従い、除外対象の直接保証チェックを追加するよう求めたり、不足テストとして指摘したりしないでください。

$TEST_SELECTION_POLICY

問題がなければ、確認した差分の概要を示してから no findings と書いてください。"

cleanup() {
  rm -rf "$REVIEW_DIR"
}
trap cleanup EXIT

git status --short
git diff --stat HEAD
PENDING="$(git status --porcelain --untracked-files=all)"
if [[ -z "$PENDING" ]]; then
  echo "UNTRUSTED: empty review range (no uncommitted changes)"
  exit 3
fi

codex exec review \
  --model "$CODEX_REVIEW_MODEL" \
  -c "model_reasoning_effort=\"$CODEX_REVIEW_EFFORT\"" \
  --json \
  -o "$REVIEW_OUT" \
  "$REVIEW_PROMPT" >| "$REVIEW_JSON" 2>| "$REVIEW_ERR"
CODEX_RC=$?

CMD_EXEC="$(grep -c '"type":"command_execution"' "$REVIEW_JSON" 2>/dev/null || true)"
CMD_EXEC="${CMD_EXEC:-0}"

echo "Codex exit=$CODEX_RC ; command_execution=$CMD_EXEC"

if [[ "$CODEX_RC" -eq 0 && "$CMD_EXEC" -ge 1 ]]; then
  echo "TRUSTED"
  echo "----- review -----"
  cat "$REVIEW_OUT"
  exit 0
fi

echo "UNTRUSTED: rerun once; if still untrusted, stop and report the blocker"
[[ -s "$REVIEW_ERR" ]] && { echo "----- stderr -----"; cat "$REVIEW_ERR"; }
exit 4
