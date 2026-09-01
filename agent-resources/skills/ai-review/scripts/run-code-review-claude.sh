#!/usr/bin/env bash
# Independent review via Claude Code on the uncommitted working tree.
# Prints the review body and a trust verdict. Exit 0 only when TRUSTED.
set -uo pipefail

CLAUDE_REVIEW_MODEL="${CLAUDE_REVIEW_MODEL:-sonnet}"
CLAUDE_REVIEW_EFFORT="${CLAUDE_REVIEW_EFFORT:-high}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_POLICY_FILE="$SCRIPT_DIR/../references/test-selection-policy.md"

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

if ! command -v claude >/dev/null 2>&1; then
  echo "BLOCKED: required reviewer CLI is unavailable: claude" >&2
  exit 127
fi

if [[ "${CLAUDE_REVIEW_CONSENT:-}" != "yes" ]]; then
  echo "BLOCKED: set CLAUDE_REVIEW_CONSENT=yes after explicit user consent to send the uncommitted diff to Claude Code"
  exit 5
fi

CLAUDE_REVIEW_PROMPT="読み取り専用でこのリポジトリの未コミット差分をコードレビューする。
まず git status --short, git diff --stat HEAD, git diff --cached, git diff を確認する。
指摘は [P1]/[P2]/[P3] の重大度、file:line、根拠、修正案を含めて日本語で返す。
Style / line-length 指摘は repo linter で確定検証する。
次のテスト選定方針に従い、除外対象の直接保証チェックを追加するよう求めたり、不足テストとして指摘しない。

$TEST_SELECTION_POLICY

問題がなければ、確認した差分の概要を示してから No findings と書く。"

# strict-mcp-config でMCP接続を止める
  # 利点: MCP 接続を止め、認証失敗を避けて外部状態に依存しないレビューにする。
  # 欠点: MCP 経由の issue・docs・監視情報など外部コンテキストを参照できない。
claude -p \
  --strict-mcp-config \
  --model "$CLAUDE_REVIEW_MODEL" \
  --effort "$CLAUDE_REVIEW_EFFORT" \
  --permission-mode plan \
  "$CLAUDE_REVIEW_PROMPT" >| "$CLAUDE_REVIEW_OUT" 2>| "$CLAUDE_REVIEW_ERR"
CLAUDE_RC=$?

if [[ "$CLAUDE_RC" -eq 126 || "$CLAUDE_RC" -eq 127 ]]; then
  [[ -s "$CLAUDE_REVIEW_ERR" ]] && cat "$CLAUDE_REVIEW_ERR" >&2
  echo "BLOCKED: reviewer CLI could not be executed: claude (status $CLAUDE_RC)" >&2
  exit "$CLAUDE_RC"
fi

echo "Claude Code exit=$CLAUDE_RC"

# この経路は stream-json を使わず tool 実行の記録を残さないため、inspection の成否を判定できない。
# 自己申告停止は exit 7 と区別せず、通常の trust failure として扱う。
if [[ -s "$CLAUDE_REVIEW_OUT" ]] && grep -Eq '^[[:space:]]*(BLOCKED|UNTRUSTED):' "$CLAUDE_REVIEW_OUT"; then
  echo "UNTRUSTED: reviewer reported that the review is not trustworthy"
  echo "----- review -----"
  cat "$CLAUDE_REVIEW_OUT"
  exit 4
fi

if [[ "$CLAUDE_RC" -eq 0 && -s "$CLAUDE_REVIEW_OUT" ]]; then
  echo "TRUSTED"
  echo "----- review -----"
  cat "$CLAUDE_REVIEW_OUT"
  exit 0
fi

echo "UNTRUSTED: rerun once after confirming CLAUDE_REVIEW_CONSENT=yes"
[[ -s "$CLAUDE_REVIEW_ERR" ]] && { echo "----- stderr -----"; cat "$CLAUDE_REVIEW_ERR"; }
exit 4
