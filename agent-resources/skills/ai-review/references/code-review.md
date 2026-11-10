# Code Review

コード差分を独立レビューするときだけ使う。

## Preconditions

- target repository の convention file を読む。
- `change-necessity-policy.md` を読み、指摘の生成と対応推奨に共通基準を適用する。
- `test-selection-policy.md` を読む。
- 引数なしでは `git status --short` と `git diff --stat HEAD` で未コミット差分を確認する。
- 差分が空の場合は `UNTRUSTED: empty review range` として停止する。
- 呼び出し元から目的、受入基準、lint / test 結果、特別なリスクが渡された場合は保持する。
- lint / test 結果が不明な単独利用では、未確認であることを結果に記録してレビューを続ける。

## Review focus

- 引数なしでは `git diff --cached` と `git diff` の両方を確認する。`--base` 指定時は解決済み SHA から作業ツリーまでの差分と未追跡ファイルを確認する。
- correctness、要件適合、回帰、データ整合性、security、互換性、テスト不足を確認する。
- 指摘には severity、`file:line`、根拠、修正案を含める。
- linter に基づく指摘は repository の linter を正とし、未検証ならその旨を示す。
- 日本語などのマルチバイト文字列を byte count だけで行長違反と判定しない。
- `test-selection-policy.md` が除外する標準保証の直接テストを要求しない。
- 問題がない場合は、確認した差分の概要を示してから `No findings` と返す。

## Run Claude reviewer

Codex が実装した場合は、このスキルのディレクトリから実行する。

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
~/.claude/skills/ai-review/scripts/run-code-review-codex.sh --model gpt-6.1-terra --effort high
```

high risk の場合は `--model gpt-6.1-sol --effort high` を使う。
wrapper が `BLOCKED: nested sandbox-exec` を返した場合は、コマンド形を戻して1回だけ再実行し、再度 `BLOCKED` なら停止する。

## Result

- script が `TRUSTED` を返し、出力が実際の差分に言及した場合だけ結果を採用する。
- `change-necessity-policy.md` に基づく評価と対応推奨を、元の finding と severity に添える。
- trust 判定、形式不備、再実行の扱いは `reviewer-policy.md` に従う。
- wrapper が exit 7 を返した場合は `reviewer-policy.md` の trust 判定に従う。
- 任意の終点を持つ commit range または PR の取得は対象外とする。
- finding の修正、lint / test、再レビューは呼び出し元へ返す。

## Review target

- 引数なしでは未コミット差分だけをレビューする。コミット済みを含めるのはユーザーが明示した場合だけとし、比較元が不明なら確認する。
- 両 wrapper は `--base <ref>` を受け付け、ref をコミット SHA に解決して `git diff <SHA> --` と未追跡ファイルをレビューする。
- dirty な場合はコミット済みと未コミットの最終的な合算差分、クリーンな場合はコミット済み差分になる。相殺された変更は対象外とする。
- 分岐点との比較は、別コマンド `git merge-base origin/main HEAD` で SHA を先に取得し、その SHA をリテラルで `--base` に渡す。Codex wrapper の sandbox 除外を保つため、wrapper 呼び出しにはコマンド置換を含めない。
- 不正な引数・ref は `exit 2`、指定比較元との差分が空かつ未追跡ファイルもない場合は `UNTRUSTED: empty review range` と `exit 3` で停止する。引数なしの空判定は既存動作を維持する。
