#!/usr/bin/env bash
# Independent review via Codex CLI on the uncommitted working tree.
# Prints the review body and a trust verdict. Exit 0 only when TRUSTED.
set -uo pipefail

REVIEW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
REVIEW_OUT="$REVIEW_DIR/review.md"
REVIEW_JSON="$REVIEW_DIR/review.jsonl"
REVIEW_ERR="$REVIEW_DIR/review.err"
CODEX_REVIEW_MODEL="${CODEX_REVIEW_MODEL:-codex-auto-review}"
CODEX_REVIEW_EFFORT="${CODEX_REVIEW_EFFORT:-medium}"

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
  --uncommitted \
  --model "$CODEX_REVIEW_MODEL" \
  -c "model_reasoning_effort=\"$CODEX_REVIEW_EFFORT\"" \
  --json \
  -o "$REVIEW_OUT" >| "$REVIEW_JSON" 2>| "$REVIEW_ERR"
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
