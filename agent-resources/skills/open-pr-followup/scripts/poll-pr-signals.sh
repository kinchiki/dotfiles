#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  poll-pr-signals.sh --pr <number|url|branch> [--repo <owner/repo>] [--initial-wait-seconds <n>] [--poll-interval-seconds <n>] [--max-polls <n>]

Options:
  --pr <value>                    Pull request number, URL, or branch.
  --repo <owner/repo>             Optional repository override for gh commands.
  --metadata-only                 Print PR identity only, then exit. Skips wait, poll, and signal collection.
  --initial-wait-seconds <n>      Initial wait before first inspection. Default: 300.
  --poll-interval-seconds <n>     Poll interval while waiting. Default: 180.
  --max-polls <n>                 Maximum additional polls after first inspection. Default: 3.
  -h, --help                      Show help.

Environment variables:
  POLL_PR_SIGNALS_IGNORED_CHECK       Overrides the default ignored check name (ci/circleci: test).
  POLL_PR_SIGNALS_AI_AUTHOR_PATTERN   Overrides the default AI reviewer author regex pattern.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

parse_owner_repo_from_url() {
  local url="$1"
  if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/pull/[0-9]+/?$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

pr_ref=""
repo_override=""
metadata_only=false
initial_wait_seconds=300
poll_interval_seconds=180
max_polls=3
ignored_check="${POLL_PR_SIGNALS_IGNORED_CHECK:-ci/circleci: test}"

while (($#)); do
  case "$1" in
    --pr)
      (($# >= 2)) || die "--pr requires a value"
      pr_ref="$2"
      shift 2
      ;;
    --repo)
      (($# >= 2)) || die "--repo requires a value"
      repo_override="$2"
      shift 2
      ;;
    --metadata-only)
      metadata_only=true
      shift
      ;;
    --initial-wait-seconds)
      (($# >= 2)) || die "--initial-wait-seconds requires a value"
      initial_wait_seconds="$2"
      shift 2
      ;;
    --poll-interval-seconds)
      (($# >= 2)) || die "--poll-interval-seconds requires a value"
      poll_interval_seconds="$2"
      shift 2
      ;;
    --max-polls)
      (($# >= 2)) || die "--max-polls requires a value"
      max_polls="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
done

[[ -n "$pr_ref" ]] || die "missing --pr"
is_non_negative_integer "$initial_wait_seconds" || die "--initial-wait-seconds must be a non-negative integer"
is_non_negative_integer "$poll_interval_seconds" || die "--poll-interval-seconds must be a non-negative integer"
is_non_negative_integer "$max_polls" || die "--max-polls must be a non-negative integer"

require_cmd gh
require_cmd jq

gh_args=()
if [[ -n "$repo_override" ]]; then
  gh_args+=(--repo "$repo_override")
fi

if [[ "$metadata_only" == "true" ]]; then
  pr_meta_json="$(gh pr view "$pr_ref" ${gh_args[@]+"${gh_args[@]}"} --json number,url,headRefName,baseRefName,state,title)"
  echo "PR_URL=$(jq -r '.url' <<<"$pr_meta_json")"
  echo "PR_NUMBER=$(jq -r '.number' <<<"$pr_meta_json")"
  echo "HEAD_REF=$(jq -r '.headRefName' <<<"$pr_meta_json")"
  echo "BASE_REF=$(jq -r '.baseRefName' <<<"$pr_meta_json")"
  exit 0
fi

if ((initial_wait_seconds > 0)); then
  sleep "$initial_wait_seconds"
fi

pr_meta_json="$(gh pr view "$pr_ref" ${gh_args[@]+"${gh_args[@]}"} --json number,url,headRefName,baseRefName,state,title)"
pr_number="$(jq -r '.number' <<<"$pr_meta_json")"
pr_url="$(jq -r '.url' <<<"$pr_meta_json")"

if [[ -n "$repo_override" ]]; then
  owner_repo="$repo_override"
else
  owner_repo="$(parse_owner_repo_from_url "$pr_url" || true)"
  [[ -n "$owner_repo" ]] || die "failed to parse owner/repo from PR url: $pr_url"
fi
owner="${owner_repo%%/*}"
repo="${owner_repo##*/}"

poll_count=0
last_checks_json='[]'
last_reviews_json='[]'
last_threads_json='[]'
ai_review_detected=false
ai_author_pattern="${POLL_PR_SIGNALS_AI_AUTHOR_PATTERN:-(copilot|coderabbit|openai|gpt|claude|gemini|ai[-_]?review|ai[-_]?bot|\[bot\]$)}"

collect_signals() {
  last_checks_json="$(gh pr checks "$pr_ref" ${gh_args[@]+"${gh_args[@]}"} --json name,state,bucket,link,workflow,event 2>/dev/null || echo '[]')"
  last_checks_json="$(jq --arg ignored "$ignored_check" '[.[] | select(.name != $ignored)]' <<<"$last_checks_json")"
  last_reviews_json="$(gh pr view "$pr_ref" ${gh_args[@]+"${gh_args[@]}"} --json reviews --jq '.reviews // []')"
  last_threads_json="$(gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){ repository(owner:$owner,name:$repo){ pullRequest(number:$pr){ reviewThreads(first:100){ nodes{ id isResolved isOutdated } } } } }' -F owner="$owner" -F repo="$repo" -F pr="$pr_number" --jq '.data.repository.pullRequest.reviewThreads.nodes // []')"

  ai_review_count="$(jq --arg p "$ai_author_pattern" '[.[] | select(.author.login != null) | .author.login | ascii_downcase | select(test($p))] | length' <<<"$last_reviews_json")"
  if ((ai_review_count > 0)); then
    ai_review_detected=true
  fi

  pending_count="$(jq '[.[] | select(.bucket == "pending")] | length' <<<"$last_checks_json")"
}

collect_signals

while ((poll_count < max_polls)); do
  pending_count="$(jq '[.[] | select(.bucket == "pending")] | length' <<<"$last_checks_json")"
  if ((pending_count == 0)) && [[ "$ai_review_detected" == "true" ]]; then
    break
  fi
  ((poll_interval_seconds > 0)) && sleep "$poll_interval_seconds"
  poll_count=$((poll_count + 1))
  collect_signals
done

pass_count="$(jq '[.[] | select(.bucket == "pass" or .bucket == "skipping")] | length' <<<"$last_checks_json")"
fail_count="$(jq '[.[] | select(.bucket == "fail" or .bucket == "cancel")] | length' <<<"$last_checks_json")"
pending_count="$(jq '[.[] | select(.bucket == "pending")] | length' <<<"$last_checks_json")"
external_fail_count="$(jq '[.[] | select((.bucket == "fail" or .bucket == "cancel") and (.workflow | not))] | length' <<<"$last_checks_json")"
unresolved_thread_count="$(jq '[.[] | select(.isResolved == false)] | length' <<<"$last_threads_json")"
ai_review_count="$(jq --arg p "$ai_author_pattern" '[.[] | select(.author.login != null) | .author.login | ascii_downcase | select(test($p))] | length' <<<"$last_reviews_json")"

if ((fail_count > 0)); then
  checks_summary="fail"
elif ((pending_count > 0)); then
  checks_summary="pending"
elif ((pass_count > 0)); then
  checks_summary="pass"
else
  checks_summary="none"
fi

if ((pending_count > 0)); then
  wait_condition="checks-pending"
elif ((ai_review_count == 0)); then
  wait_condition="ai-review-missing"
else
  wait_condition="clear"
fi

echo "PR_URL=$pr_url"
echo "PR_NUMBER=$pr_number"
echo "HEAD_REF=$(jq -r '.headRefName' <<<"$pr_meta_json")"
echo "BASE_REF=$(jq -r '.baseRefName' <<<"$pr_meta_json")"
echo "CHECKS_STATUS=$checks_summary"
echo "CHECKS_FAIL_COUNT=$fail_count"
echo "CHECKS_PENDING_COUNT=$pending_count"
echo "CHECKS_EXTERNAL_FAIL_COUNT=$external_fail_count"
echo "UNRESOLVED_THREAD_COUNT=$unresolved_thread_count"
echo "AI_REVIEW_COUNT=$ai_review_count"
echo "AI_REVIEW_DETECTED=$([[ "$ai_review_count" -gt 0 ]] && echo true || echo false)"
echo "POLLS_USED=$poll_count"
echo "WAIT_CONDITION=$wait_condition"

echo "FAILING_CHECKS="
jq -r '.[] | select(.bucket == "fail" or .bucket == "cancel") | "- " + (.name // "(unknown)") + "\t" + (.link // "")' <<<"$last_checks_json"

echo "UNRESOLVED_THREADS="
jq -r '.[] | select(.isResolved == false) | "- " + .id' <<<"$last_threads_json"
