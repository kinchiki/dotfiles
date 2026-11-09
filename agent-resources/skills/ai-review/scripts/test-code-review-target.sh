#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/code-review-target.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/repo"
cat > "$test_dir/bin/uname" <<'FAKE'
#!/usr/bin/env bash
printf 'Linux\n'
FAKE
cat > "$test_dir/bin/claude" <<'FAKE'
#!/usr/bin/env bash
printf '%s' "${@: -1}" > "$PROMPT_DUMP"
printf 'REVIEW_TRUST: TRUSTED\nNo findings\n'
FAKE
cat > "$test_dir/bin/codex" <<'FAKE'
#!/usr/bin/env bash
printf '%s' "${@: -1}" > "$PROMPT_DUMP"
while (($#)); do
  if [[ "$1" == -o ]]; then out="$2"; shift 2; else shift; fi
done
printf 'REVIEW_TRUST: TRUSTED\nNo findings\n' > "$out"
jq -nc --arg command "$EVIDENCE" '{type:"item.completed",item:{type:"command_execution",command:$command,exit_code:0,aggregated_output:"diff --git a/example.txt b/example.txt\n"}}'
FAKE
chmod +x "$test_dir/bin/"*
export PATH="$test_dir/bin:$PATH" CLAUDE_REVIEW_CONSENT=yes
export PROMPT_DUMP="$test_dir/prompt" EVIDENCE='git diff'
cd "$test_dir/repo"
git init -q
git config user.email test@example.com
git config user.name Test
printf 'base\n' > example.txt
git add example.txt
git commit -qm base
base="$(git rev-parse HEAD)"
printf 'committed\n' > example.txt
git commit -qam change

run_case() {
  local expected="$1" name="$2" status=0
  shift 2
  rm -f "$PROMPT_DUMP"
  "$wrapper" "$@" > "$test_dir/output" 2>&1 || status=$?
  if [[ "$status" -ne "$expected" ]]; then
    printf 'FAIL: %s (%s): expected %s, got %s\n' "$name" "$reviewer" "$expected" "$status"
    cat "$test_dir/output"
    exit 1
  fi
  if [[ "$expected" -eq 2 || "$expected" -eq 3 ]]; then
    [[ ! -e "$PROMPT_DUMP" ]]
  fi
  printf 'PASS: %s (%s)\n' "$name" "$reviewer"
}

for reviewer in claude codex; do
  wrapper="$script_dir/run-code-review-$reviewer.sh"
  git reset --hard -q HEAD
  rm -f untracked.txt
  EVIDENCE="git diff $base --"
  export EVIDENCE
  run_case 3 'clean default excludes committed changes'
  run_case 0 'committed only' --base "$base"
  grep -q "git diff $base --" "$PROMPT_DUMP"
  run_case 0 'symbolic base resolves to SHA' --base HEAD^
  grep -q "git diff $base --" "$PROMPT_DUMP"
  printf 'staged\n' > example.txt
  git add example.txt
  printf 'working\n' > example.txt
  run_case 0 'committed and staged and unstaged' --base "$base"
  EVIDENCE='git diff'
  run_case 0 'uncommitted only'
  grep -q 'git diff --cached, git diff' "$PROMPT_DUMP"
  ! grep -q "$base" "$PROMPT_DUMP"
  printf 'base\n' > example.txt
  run_case 3 'changes cancel against base' --base "$base"
  printf 'new\n' > untracked.txt
  EVIDENCE='cat untracked.txt'
  run_case 0 'untracked only against base' --base "$base"
  grep -q 'git ls-files --others --exclude-standard' "$PROMPT_DUMP"
  git reset --hard -q HEAD
  rm untracked.txt
  run_case 3 'empty base HEAD' --base HEAD
  run_case 2 'invalid ref' --base missing-ref
  run_case 2 'missing value' --base
  run_case 2 'empty value' --base ''
  run_case 2 'duplicate base' --base HEAD --base HEAD
  run_case 2 'unknown argument' --unknown
  if [[ "$reviewer" == codex ]]; then
    EVIDENCE='git diff'
    run_case 4 'wrong comparison rejected' --base "$base"
    EVIDENCE="git diff --name-only $base --"
    run_case 4 'file list rejected' --base "$base"
  fi
done
