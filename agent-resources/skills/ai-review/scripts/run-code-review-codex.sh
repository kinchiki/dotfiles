#!/usr/bin/env bash
# Independent review via Codex CLI on the uncommitted working tree.
# Prints the review body and a trust verdict. Exit 0 only when TRUSTED.
set -uo pipefail

MODEL_FLAG=""
EFFORT_FLAG=""
while (($#)); do
  case "$1" in
    --model)
      (($# >= 2)) || { echo "error: --model requires a value" >&2; exit 2; }
      MODEL_FLAG="$2"
      shift 2
      ;;
    --effort)
      (($# >= 2)) || { echo "error: --effort requires a value" >&2; exit 2; }
      EFFORT_FLAG="$2"
      shift 2
      ;;
    *)
      echo "error: unexpected argument: $1" >&2
      exit 2
      ;;
  esac
done

REVIEW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
REVIEW_OUT="$REVIEW_DIR/review.md"
REVIEW_JSON="$REVIEW_DIR/review.jsonl"
REVIEW_ERR="$REVIEW_DIR/review.err"
# Terra is the balanced default for the `codex exec review` subcommand.
# Pass --model gpt-5.6-sol for high-risk diffs.
CODEX_REVIEW_MODEL="${MODEL_FLAG:-${CODEX_REVIEW_MODEL:-gpt-5.6-terra}}"
CODEX_REVIEW_EFFORT="${EFFORT_FLAG:-${CODEX_REVIEW_EFFORT:-high}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_POLICY_FILE="$SCRIPT_DIR/../references/test-selection-policy.md"

if [[ ! -f "$TEST_POLICY_FILE" ]]; then
  echo "UNTRUSTED: missing test selection policy: $TEST_POLICY_FILE"
  exit 4
fi

TEST_SELECTION_POLICY="$(<"$TEST_POLICY_FILE")"
REVIEW_PROMPT="read only でこのリポジトリの未コミット差分をコードレビューする。
まず git status --short, git diff --stat HEAD, git diff --cached, git diff を確認する。
指摘は [P1]/[P2]/[P3] の重大度、file:line、根拠、修正案を含めて日本語で返す。
Style / line-length 指摘は repo linter で確定検証する。
次のテスト選定方針に従い、除外対象の直接保証チェックを追加するよう求めたり、不足テストとして指摘しない。

$TEST_SELECTION_POLICY

問題がなければ、確認した差分の概要を示してから No findings と書く。"

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

if ! command -v codex >/dev/null 2>&1; then
  echo "BLOCKED: required reviewer CLI is unavailable: codex" >&2
  exit 127
fi

# codex exec review
  # 向いている用途: コード差分レビュー
  # --uncommitted、--base、--commitなどレビュー対象を理解する専用モード
  # codex exec review では --uncommitted、--base、--commit、カスタムpromptを同時指定できません。
  # 現在の wrapper はテスト選定方針を含むカスタムpromptが必要なので、--uncommittedを追加せず、prompt内で未コミット差分の確認を指示している。
# --ignore-user-config でMCP接続を止める
  # 利点: user config 由来の MCP 接続を止め、認証失敗を避けて外部状態に依存しないレビューにする。
  # 欠点: MCP の外部コンテキストに加え、provider・hook など user config 全体も適用されない。
# --ignore-user-config で認証設定 cli_auth_credentials_store = "keyring" が読めないため、明示する
# Codex の既定 sandbox は macOS で sandbox-exec を使うため、Claude Code の sandbox 内では入れ子適用に失敗する。
# 失敗しても Codex はローカルファイルを読めないまま所見を返すので、呼び出す前に停止する。
if [[ "$(uname -s)" == "Darwin" ]] && ! /usr/bin/sandbox-exec -p '(version 1)(allow default)' /usr/bin/true >/dev/null 2>&1; then
  echo "BLOCKED: nested sandbox-exec is unavailable; invoke ~/.claude/skills/ai-review/scripts/run-code-review-codex.sh as a single command with no env prefix and no pipe so it matches sandbox.excludedCommands" >&2
  exit 6
fi
codex exec review \
  --ignore-user-config \
  -c cli_auth_credentials_store="keyring" \
  --model "$CODEX_REVIEW_MODEL" \
  -c "model_reasoning_effort=\"$CODEX_REVIEW_EFFORT\"" \
  --json \
  -o "$REVIEW_OUT" \
  "$REVIEW_PROMPT" >| "$REVIEW_JSON" 2>| "$REVIEW_ERR"
CODEX_RC=$?

if [[ "$CODEX_RC" -eq 126 || "$CODEX_RC" -eq 127 ]]; then
  [[ -s "$REVIEW_ERR" ]] && cat "$REVIEW_ERR" >&2
  echo "BLOCKED: reviewer CLI could not be executed: codex (status $CODEX_RC)" >&2
  exit "$CODEX_RC"
fi

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
