# Code Review

未コミットの working tree を独立レビューするときだけ使う。

## Preconditions

- target repository の convention file を読む。
- `test-selection-policy.md` を読む。
- `git status --short` と `git diff --stat HEAD` で未コミット差分があることを確認する。
- 差分が空の場合は `UNTRUSTED: empty review range` として停止する。
- 呼び出し元から目的、受入基準、lint / test 結果、特別なリスクが渡された場合は保持する。
- lint / test 結果が不明な単独利用では、未確認であることを結果に記録してレビューを続ける。

## Review focus

- `git diff --cached` と `git diff` の両方を確認する。
- correctness、要件適合、回帰、データ整合性、security、互換性、テスト不足を確認する。
- 指摘には severity、`file:line`、根拠、修正案を含める。
- linter に基づく指摘は repository の linter を正とし、未検証ならその旨を示す。
- 日本語などのマルチバイト文字列を byte count だけで行長違反と判定しない。
- `test-selection-policy.md` が除外する標準保証の直接テストを要求しない。
- 問題がない場合は、確認した差分の概要を示してから `No findings` と返す。

## Run Claude reviewer

Codex が実装した場合は、Claude Code への送信同意を得た後、このスキルのディレクトリから実行する。

```bash
CLAUDE_REVIEW_CONSENT=yes \
CLAUDE_REVIEW_MODEL=sonnet \
CLAUDE_REVIEW_EFFORT=high \
scripts/run-code-review-claude.sh
```

high risk の場合は `CLAUDE_REVIEW_MODEL=opus` を使う。

## Run Codex reviewer

Claude Code が実装した場合は、Claude Code の `sandbox.excludedCommands` に登録された wrapper を単体コマンドで実行する。
環境変数の前置、パイプ、リダイレクト、`&&`、`tee` を付けず、model と effort は flag で渡す。

```bash
~/.claude/skills/ai-review/scripts/run-code-review-codex.sh --model gpt-5.6-terra --effort high
```

high risk の場合は `--model gpt-5.6-sol` を使う。
wrapper が `BLOCKED: nested sandbox-exec` を返した場合は、コマンド形を戻して1回だけ再実行し、再度 `BLOCKED` なら停止する。

## Result

- script が `TRUSTED` を返し、出力が実際の差分に言及した場合だけ結果を採用する。
- `UNTRUSTED` は1回だけ再実行し、再度失敗した場合は阻害要因を返す。
- wrapper が exit 7 を返した場合は `reviewer-policy.md` の trust 判定に従う。
- working tree 以外の commit range または PR review はこの workflow の対象外とする。
- finding の修正、lint / test、再レビューは呼び出し元へ返す。
