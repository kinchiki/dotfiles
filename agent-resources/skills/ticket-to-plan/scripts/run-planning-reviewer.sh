#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-planning-reviewer.sh --repo <absolute repo path> --reviewer <codex|claude> --prompt-file <review prompt file> [--model <model>] [--effort <effort>] [--keep-temp]

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

case "$reviewer" in
  codex)
    model="${model:-${CODEX_REVIEW_MODEL:-gpt-5.4}}"
    effort="${effort:-${CODEX_REVIEW_EFFORT:-medium}}"
    ;;
  claude)
    model="${model:-${CLAUDE_REVIEW_MODEL:-sonnet}}"
    effort="${effort:-${CLAUDE_REVIEW_EFFORT:-medium}}"
    ;;
esac

tmp_parent="${TMPDIR:-/tmp}"
review_dir="$(mktemp -d "${tmp_parent%/}/planning-review-${reviewer}.XXXXXX")"
review_out="$review_dir/review.md"
review_err="$review_dir/review.err"
review_events="$review_dir/review.jsonl"

cleanup() {
  if [[ "$keep_temp" == false ]]; then
    rm -rf "$review_dir"
  fi
}
trap cleanup EXIT

status=0
case "$reviewer" in
  codex)
    codex exec \
      --cd "$repo" \
      --sandbox read-only \
      --model "$model" \
      -c "model_reasoning_effort=\"$effort\"" \
      --json \
      --output-last-message "$review_out" \
      - < "$prompt_file" > "$review_events" 2> "$review_err" || status=$?
    ;;
  claude)
    if [[ "${CLAUDE_REVIEW_CONSENT:-}" != "yes" ]]; then
      echo "BLOCKED: set CLAUDE_REVIEW_CONSENT=yes after explicit user consent to send the review packet to Claude Code" >&2
      exit 5
    fi
    (
      cd "$repo"
      claude -p \
        --permission-mode plan \
        --model "$model" \
        --effort "$effort" \
        "標準入力の review packet を読み、ticket-to-plan の draft plan をレビューしてください。編集は禁止です。" \
        < "$prompt_file" > "$review_out" 2> "$review_err"
    ) || status=$?
    ;;
esac

if ((status != 0)); then
  [[ -f "$review_err" ]] && cat "$review_err" >&2
  exit "$status"
fi

cat "$review_out"
