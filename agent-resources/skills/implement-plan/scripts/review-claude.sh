#!/usr/bin/env bash
# Independent review via Claude Code on the uncommitted working tree.
# Prints the review body and a trust verdict. Exit 0 only when TRUSTED.
set -uo pipefail

CLAUDE_REVIEW_MODEL="${CLAUDE_REVIEW_MODEL:-sonnet}"
CLAUDE_REVIEW_EFFORT="${CLAUDE_REVIEW_EFFORT:-medium}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_POLICY_FILE="$SCRIPT_DIR/../../ticket-to-plan/references/test-selection-policy.md"

if [[ ! -f "$TEST_POLICY_FILE" ]]; then
  echo "UNTRUSTED: missing test selection policy: $TEST_POLICY_FILE"
  exit 4
fi

TEST_SELECTION_POLICY="$(<"$TEST_POLICY_FILE")"

REVIEW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/claude-review.XXXXXX")"
CLAUDE_REVIEW_OUT="$REVIEW_DIR/review.md"
CLAUDE_REVIEW_ERR="$REVIEW_DIR/review.err"

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

if [[ "${CLAUDE_REVIEW_CONSENT:-}" != "yes" ]]; then
  echo "BLOCKED: set CLAUDE_REVIEW_CONSENT=yes after explicit user consent to send the uncommitted diff to Claude Code"
  exit 5
fi

CLAUDE_REVIEW_PROMPT="このリポジトリの未コミット差分をコードレビューしてください。
編集は禁止です。
まず git status --short, git diff --stat HEAD, git diff --cached, git diff を確認してください。
指摘は [P1]/[P2]/[P3] の重大度、file:line、根拠、修正案を含めて日本語で返してください。
Style / line-length 指摘は repo linter で確定検証し、byte count だけで日本語など multibyte text を違反判定しないでください。
次のテスト選定方針に従い、除外対象の直接保証チェックを追加するよう求めたり、不足テストとして指摘したりしないでください。

$TEST_SELECTION_POLICY

問題がなければ、確認した差分の概要を示してから no findings と書いてください。"
claude -p \
  --model "$CLAUDE_REVIEW_MODEL" \
  --effort "$CLAUDE_REVIEW_EFFORT" \
  --permission-mode plan \
  "$CLAUDE_REVIEW_PROMPT" >| "$CLAUDE_REVIEW_OUT" 2>| "$CLAUDE_REVIEW_ERR"
CLAUDE_RC=$?

echo "Claude Code exit=$CLAUDE_RC"

if [[ "$CLAUDE_RC" -eq 0 && -s "$CLAUDE_REVIEW_OUT" ]]; then
  echo "TRUSTED"
  echo "----- review -----"
  cat "$CLAUDE_REVIEW_OUT"
  exit 0
fi

echo "UNTRUSTED: rerun once after confirming CLAUDE_REVIEW_CONSENT=yes"
[[ -s "$CLAUDE_REVIEW_ERR" ]] && { echo "----- stderr -----"; cat "$CLAUDE_REVIEW_ERR"; }
exit 4
