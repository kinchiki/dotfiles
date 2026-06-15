# Independent AI Review Reference

Use this reference from `../SKILL.md` Step 4 when a medium or high risk change needs independent AI review.
Do not load it for low risk changes.

## Contents

- Trust rules.
- Claude Code session: review with Codex.
- Verify Codex review.
- Codex session: review with Claude Code.
- Handle findings.

## Trust rules

- Review the actual diff or working tree.
- Confirm there is a non-empty range before trusting a clean result.
- Confirm the reviewer explored the diff before treating "no findings" as a pass.
- Do not pass a long implementation narrative.
- Pass only concise context: purpose, acceptance criteria, and special risks.
- If the independent reviewer cannot run, stop and report that independent review could not be completed.
- Do not replace the required independent review with the same agent's self-review.

## Claude Code session: review with Codex

Use Codex to review the uncommitted working tree before commit.
If the change is already committed, use `--base <default-branch>` instead of `--uncommitted`.

```bash
REVIEW_OUT="/tmp/codex-review.md"
REVIEW_JSON="/tmp/codex-review.jsonl"

git status --short
git diff --stat HEAD
PENDING="$(git status --porcelain --untracked-files=all)"

RANGE=(--uncommitted)

rm -f "$REVIEW_OUT" "$REVIEW_JSON" "${REVIEW_JSON%.jsonl}.err"
codex exec review "${RANGE[@]}" --json -o "$REVIEW_OUT" >| "$REVIEW_JSON" 2>| "${REVIEW_JSON%.jsonl}.err"
CODEX_RC=$?
echo "Codex exit=$CODEX_RC ; last message -> $REVIEW_OUT ; events -> $REVIEW_JSON"
```

Important details:

- `--uncommitted` reviews staged, unstaged, and untracked changes.
- A repo with only untracked new files may have an empty `git diff`, so use `git status --porcelain --untracked-files=all`.
- A range selector such as `--uncommitted`, `--base`, or `--commit` cannot be combined with a custom prompt.
- `-o` writes Codex's last message, which is the review body for `codex exec review`.
- `--json` produces the event stream used to verify that Codex actually explored.
- Fixed output paths must be deleted before each run to avoid reading stale results.
- Capture `CODEX_RC`; do not let another command mask a failed review.

## Verify Codex review

Confirm Codex explored before reading a clean verdict as a pass.

```bash
grep -c '"type":"command_execution"' "$REVIEW_JSON"
```

A clean Codex result counts as pass only when all conditions are true:

- `CODEX_RC` is `0`.
- The selected range is non-empty.
- The `command_execution` count is at least `1`.

If any condition is false, treat the result as a false pass or failed run.
Re-check the range and run once more.
If Codex still cannot review, stop and report the blocker.

Read `$REVIEW_OUT` only after the run is trustworthy.
Findings are expected as `[P1]`, `[P2]`, or `[P3]`.

## Codex session: review with Claude Code

Use Claude Code to review the uncommitted working tree before commit.
If the change is already committed, use `claude ultrareview <default-branch>` instead.

```bash
CLAUDE_REVIEW_OUT="/tmp/claude-review.md"
CLAUDE_REVIEW_ERR="/tmp/claude-review.err"

git status --short
git diff --stat HEAD
PENDING="$(git status --porcelain --untracked-files=all)"

rm -f "$CLAUDE_REVIEW_OUT" "$CLAUDE_REVIEW_ERR"
CLAUDE_REVIEW_PROMPT="このリポジトリの未コミット差分をコードレビューしてください。
編集は禁止です。
まず git status --short, git diff --stat HEAD, git diff --cached, git diff を確認してください。
指摘は [P1]/[P2]/[P3] の重大度、file:line、根拠、修正案を含めて日本語で返してください。
問題がなければ、確認した差分の概要を示してから no findings と書いてください。"
claude -p --model opus --permission-mode plan "$CLAUDE_REVIEW_PROMPT" >| "$CLAUDE_REVIEW_OUT" 2>| "$CLAUDE_REVIEW_ERR"
CLAUDE_RC=$?
echo "Claude Code exit=$CLAUDE_RC ; review -> $CLAUDE_REVIEW_OUT ; err -> $CLAUDE_REVIEW_ERR"
```

A clean Claude Code result counts as pass only when all conditions are true:

- `CLAUDE_RC` is `0`.
- `PENDING` is non-empty, unless reviewing an already committed range.
- The output shows Claude Code inspected the diff.

If any condition is false, re-run with the explicit prompt above.
If Claude Code still cannot review, stop and report the blocker.

## Handle findings

- Treat `[P1]` and `[P2]` as blocking.
- Fix blocking findings, rerun lint / test, and rerun the independent review once.
- Run a third review only for high risk changes or genuinely ambiguous remaining P1 / P2 findings.
- Address cheap `[P3]` findings.
- List skipped `[P3]` findings in the PR body.
- Separately confirm the implementation meets the plan's `## 受入基準`.
