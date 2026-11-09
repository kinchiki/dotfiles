#!/usr/bin/env bash

review_base_argument() {
  if [[ "${BASE_SEEN:-false}" == true || $# -lt 2 || -z "$2" || "$2" == --* ]]; then
    echo 'error: --base requires one nonempty ref and may only be specified once' >&2
    return 2
  fi
  BASE_REF="$2"
  BASE_SEEN=true
}

prepare_code_review_target() {
  REVIEW_TARGET='未コミット差分'
  REVIEW_COMMANDS='git status --short, git diff --stat HEAD, git diff --cached, git diff'
  REVIEW_DIFF_COMMAND='git diff'
  REVIEW_BASE_SHA=''
  git status --short || return 2
  if [[ "${BASE_SEEN:-false}" == true ]]; then
    REVIEW_BASE_SHA="$(git rev-parse --verify --end-of-options "${BASE_REF}^{commit}")" || {
      echo "error: invalid base commit: $BASE_REF" >&2
      return 2
    }
    REVIEW_TARGET="コミット $REVIEW_BASE_SHA から現在の作業ツリーまでの合算差分"
    REVIEW_DIFF_COMMAND="git diff $REVIEW_BASE_SHA --"
    REVIEW_COMMANDS="git status --short, git diff --stat $REVIEW_BASE_SHA --, $REVIEW_DIFF_COMMAND"
    git diff --stat "$REVIEW_BASE_SHA" -- || return 2
    local diff_status=0 untracked
    git diff --quiet "$REVIEW_BASE_SHA" -- || diff_status=$?
    [[ "$diff_status" -le 1 ]] || return 2
    untracked="$(git ls-files --others --exclude-standard)" || return 2
    if [[ "$diff_status" -eq 0 && -z "$untracked" ]]; then
      echo 'UNTRUSTED: empty review range'
      return 3
    fi
    INSPECTION_PATH="$(git diff --name-only "$REVIEW_BASE_SHA" -- | head -n 1)"
  else
    git diff --stat HEAD || return 2
    local pending
    pending="$(git status --porcelain --untracked-files=all)" || return 2
    if [[ -z "$pending" ]]; then
      echo 'UNTRUSTED: empty review range (no uncommitted changes)'
      return 3
    fi
    INSPECTION_PATH="$(git diff --name-only HEAD | head -n 1)"
  fi
  REVIEW_COMMANDS="$REVIEW_COMMANDS を確認する。git ls-files --others --exclude-standard で未追跡ファイルを列挙し、その内容も読む"
}
