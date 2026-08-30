#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-plan-reviewer.sh --repo <absolute repo path> --reviewer <codex|claude> --prompt-file <review prompt file> [--model <model>] [--effort <effort>] [--keep-temp]

Options:
  --repo         Absolute path to the repository being reviewed.
  --reviewer    Reviewer CLI to run: codex or claude.
  --prompt-file Review packet file to pass on stdin.
  --model       Override the reviewer model.
  --effort      Override the reviewer reasoning effort.
  --keep-temp   Keep the temporary output directory.
  -h, --help    Show this help.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 2
}

repo=""
reviewer=""
prompt_file=""
model=""
effort=""
keep_temp=false

repo_seen=false
reviewer_seen=false
prompt_file_seen=false
model_seen=false
effort_seen=false

while (($#)); do
  case "$1" in
    --repo)
      "$repo_seen" && die "duplicate --repo"
      (($# >= 2)) || die "--repo requires a value"
      repo="$2"
      repo_seen=true
      shift 2
      ;;
    --repo=*)
      "$repo_seen" && die "duplicate --repo"
      repo="${1#--repo=}"
      [[ -n "$repo" ]] || die "--repo requires a value"
      repo_seen=true
      shift
      ;;
    --reviewer)
      "$reviewer_seen" && die "duplicate --reviewer"
      (($# >= 2)) || die "--reviewer requires a value"
      reviewer="$2"
      reviewer_seen=true
      shift 2
      ;;
    --reviewer=*)
      "$reviewer_seen" && die "duplicate --reviewer"
      reviewer="${1#--reviewer=}"
      [[ -n "$reviewer" ]] || die "--reviewer requires a value"
      reviewer_seen=true
      shift
      ;;
    --prompt-file)
      "$prompt_file_seen" && die "duplicate --prompt-file"
      (($# >= 2)) || die "--prompt-file requires a value"
      prompt_file="$2"
      prompt_file_seen=true
      shift 2
      ;;
    --prompt-file=*)
      "$prompt_file_seen" && die "duplicate --prompt-file"
      prompt_file="${1#--prompt-file=}"
      [[ -n "$prompt_file" ]] || die "--prompt-file requires a value"
      prompt_file_seen=true
      shift
      ;;
    --model)
      "$model_seen" && die "duplicate --model"
      (($# >= 2)) || die "--model requires a value"
      model="$2"
      model_seen=true
      shift 2
      ;;
    --model=*)
      "$model_seen" && die "duplicate --model"
      model="${1#--model=}"
      [[ -n "$model" ]] || die "--model requires a value"
      model_seen=true
      shift
      ;;
    --effort)
      "$effort_seen" && die "duplicate --effort"
      (($# >= 2)) || die "--effort requires a value"
      effort="$2"
      effort_seen=true
      shift 2
      ;;
    --effort=*)
      "$effort_seen" && die "duplicate --effort"
      effort="${1#--effort=}"
      [[ -n "$effort" ]] || die "--effort requires a value"
      effort_seen=true
      shift
      ;;
    --keep-temp)
      keep_temp=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      (($# == 0)) || die "unexpected argument: $1"
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
done

[[ -n "$repo" ]] || die "missing --repo"
case "$repo" in
  /*) ;;
  *) die "--repo must be an absolute path" ;;
esac
[[ -d "$repo" ]] || die "--repo is not a directory: $repo"

[[ -n "$prompt_file" ]] || die "missing --prompt-file"
[[ -f "$prompt_file" ]] || die "--prompt-file is not a file: $prompt_file"
[[ -r "$prompt_file" ]] || die "--prompt-file is not readable: $prompt_file"

case "$reviewer" in
  codex|claude) ;;
  "") die "missing --reviewer" ;;
  *) die "--reviewer must be codex or claude" ;;
esac

if ! command -v "$reviewer" >/dev/null 2>&1; then
  echo "BLOCKED: required reviewer CLI is unavailable: $reviewer" >&2
  exit 127
fi

case "$reviewer" in
  codex)
    # GPT-5.6 Terra is the balanced default for planning review;
    # this path runs a plain `codex exec` prompt review, not the `codex exec review` subcommand.
    model="${model:-${CODEX_REVIEW_MODEL:-gpt-5.6-terra}}"
    effort="${effort:-${CODEX_REVIEW_EFFORT:-high}}"
    ;;
  claude)
    model="${model:-${CLAUDE_REVIEW_MODEL:-sonnet}}"
    effort="${effort:-${CLAUDE_REVIEW_EFFORT:-high}}"
    ;;
esac

tmp_parent="${TMPDIR:-/tmp}"
review_dir="$(mktemp -d "${tmp_parent%/}/planning-review-${reviewer}.XXXXXX")"
review_out="$review_dir/review.md"
review_err="$review_dir/review.err"
review_events="$review_dir/review.jsonl"
review_prompt="$review_dir/prompt.md"

cleanup() {
  if [[ "$keep_temp" == false ]]; then
    rm -rf "$review_dir"
  else
    echo "review artifacts: $review_dir" >&2
  fi
}
trap cleanup EXIT

command -v jq >/dev/null 2>&1 || die "jq is required"

inspection_file=""
while IFS= read -r -d '' candidate; do
  if [[ -r "$candidate" ]] && grep -Iq . "$candidate"; then
    inspection_file="$candidate"
    break
  fi
done < <(find "$repo" -path "$repo/.git" -prune -o -type f -size +0c -print0)

if [[ -z "$inspection_file" ]]; then
  echo "UNTRUSTED: repository has no readable nonempty text file to inspect" >&2
  exit 4
fi

inspection_command="$(printf "sed -n '1,80p' %q" "$inspection_file")"
inspection_output="$(sed -n '1,80p' "$inspection_file")"

{
  cat "$prompt_file"
  printf '\n\n## Required local inspection\n'
  case "$reviewer" in
    codex)
      printf 'Before returning the review, run this exact command and use its output as local repository evidence:\n\n```sh\n%s\n```\n' "$inspection_command"
      ;;
    claude)
      printf 'Before returning the review, use the Read tool on this exact local repository file and use its contents as evidence:\n\n`%s`\n' "$inspection_file"
      ;;
  esac
  printf 'If local files cannot be read, return `BLOCKED: cannot read local files`.\n'
} > "$review_prompt"

status=0
case "$reviewer" in
  codex)
    # codex exec
      # 向いている用途: 計画書・設計・任意ファイルのレビュー
      # 標準入力やpromptで任意タスクを実行する汎用モード
    # --ignore-user-config でMCP接続を止める
      # 利点: user config 由来の MCP 接続を止め、認証失敗を避けて外部状態に依存しないレビューにする。
      # 欠点: MCP の外部コンテキストに加え、provider・hook など user config 全体も適用されない。
    # -c cli_auth_credentials_store="keyring"
      # --ignore-user-config で認証設定 cli_auth_credentials_store = "keyring" が読めないため、明示する
    # Codex の --sandbox は macOS で sandbox-exec を使うため、Claude Code の sandbox 内では入れ子適用に失敗する。
    # 失敗しても Codex はローカルファイルを読めないまま所見を返すので、呼び出す前に停止する。
    if [[ "$(uname -s)" == "Darwin" ]] && ! /usr/bin/sandbox-exec -p '(version 1)(allow default)' /usr/bin/true >/dev/null 2>&1; then
      echo "BLOCKED: nested sandbox-exec is unavailable; invoke ~/.claude/skills/ai-review/scripts/run-plan-review-codex.sh as a single command with no env prefix and no pipe so it matches sandbox.excludedCommands" >&2
      exit 6
    fi
    codex exec \
      --ignore-user-config \
      -c cli_auth_credentials_store="keyring" \
      --cd "$repo" \
      --sandbox read-only \
      --model "$model" \
      -c "model_reasoning_effort=\"$effort\"" \
      --json \
      --output-last-message "$review_out" \
      - < "$review_prompt" > "$review_events" 2> "$review_err" || status=$?
    ;;
  claude)
    if [[ "${CLAUDE_REVIEW_CONSENT:-}" != "yes" ]]; then
      echo "BLOCKED: set CLAUDE_REVIEW_CONSENT=yes after explicit user consent to send the review packet to Claude Code" >&2
      exit 5
    fi
    (
      cd "$repo"
      # 利点: MCP 接続を止め、認証失敗を避けて外部状態に依存しないレビューにする。
      # 欠点: MCP 経由の issue・docs・監視情報など外部コンテキストを参照できない。
      claude --print \
        --strict-mcp-config \
        --permission-mode plan \
        --model "$model" \
        --effort "$effort" \
        --output-format stream-json \
        --verbose \
        "標準入力の review packet を読み、 read only で実装用の draft plan をレビューする。" \
        < "$review_prompt" > "$review_events" 2> "$review_err"
    ) || status=$?
    ;;
esac

if ((status == 126 || status == 127)); then
  [[ -f "$review_err" ]] && cat "$review_err" >&2
  echo "BLOCKED: reviewer CLI could not be executed: $reviewer (status $status)" >&2
  exit "$status"
fi

if ((status != 0)); then
  [[ -f "$review_err" ]] && cat "$review_err" >&2
  echo "UNTRUSTED: reviewer exited with status $status" >&2
  exit "$status"
fi

if [[ "$reviewer" == "claude" ]]; then
  jq -s -r '[.[] | select(.type == "result") | .result // empty] | last // empty' "$review_events" > "$review_out" || {
    echo "UNTRUSTED: invalid Claude event stream" >&2
    exit 4
  }
fi

if [[ ! -s "$review_out" ]]; then
  echo "UNTRUSTED: empty review output" >&2
  exit 4
fi

if grep -Eq '^[[:space:]]*(BLOCKED|UNTRUSTED):' "$review_out"; then
  echo "UNTRUSTED: reviewer reported that the review is not trustworthy" >&2
  exit 4
fi

case "$reviewer" in
  codex)
    if ! jq -e \
      --arg command "$inspection_command" \
      --arg output "$inspection_output" \
      'select(
        .type == "item.completed"
        and .item.type == "command_execution"
        and .item.exit_code == 0
        and (.item.command | contains($command))
        and ((.item.aggregated_output // "") | sub("[\\r\\n]+$"; "") == $output)
      )' \
      "$review_events" >/dev/null; then
      echo "UNTRUSTED: reviewer did not demonstrate local file inspection" >&2
      exit 4
    fi
    ;;
  claude)
    read_tool_use_id="$(jq -s -r \
      --arg file "$inspection_file" \
      '[
        .[]
        | select(.type == "assistant")
        | .message.content[]?
        | select(.type == "tool_use" and .name == "Read" and .input.file_path == $file)
        | .id
      ] | last // empty' \
      "$review_events")"
    if [[ -z "$read_tool_use_id" ]] || ! jq -e -s \
      --arg id "$read_tool_use_id" \
      'any(
        .[];
        .type == "user"
        and any(
          .message.content[]?;
          .type == "tool_result"
          and .tool_use_id == $id
          and ((.is_error // false) | not)
        )
      )' \
      "$review_events" >/dev/null; then
      echo "UNTRUSTED: reviewer did not demonstrate successful local file inspection" >&2
      exit 4
    fi
    ;;
esac

echo "TRUSTED"
echo "----- review -----"
cat "$review_out"
