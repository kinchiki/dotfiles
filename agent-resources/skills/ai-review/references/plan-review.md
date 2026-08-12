# Plan Review

ユーザーレビュー済みの draft plan を最終承認前に独立レビューするときだけ使う。
目的はユーザーに代わって承認することではなく、元ソースとユーザー確認済みの意図に照らしてプランの問題を発見することである。

## Build the review packet

`test-selection-policy.md` を読み、プラン評価に必要な次のコンテキストだけを review packet に含める。

- draft plan file の絶対パスと最新の全文
- ソース種別と3〜6行のソース要約
- 元ソースの参照先またはユーザー依頼の抜粋
- ユーザーが確認した意図の変更、受け入れた振る舞い、明示的な non-goal
- ゴール、受入基準、アプローチ、risk、スコープ外
- `files`、`depends_on`、`parallel`、`test`、`done_when` を含む task breakdown
- planner が調査した path と既存 pattern
- 仮定、未解決の質問、既知の制約
- `test-selection-policy.md` の内容

元ソースとユーザー確認済みの意図を source of truth とするよう reviewer へ指示する。
具体的な安全性、データ損失、実装不可能、repository constraint がある場合を除き、ユーザーが維持を明示した挙動の変更を提案させない。

## Review focus

- ソース要件、コメント、label、linked issue / PR、受入基準の漏れ
- user request source の仮定と受入基準の明確さ
- data flow、auth / permission、background job、API、migration、互換性の見落とし
- task の順序、依存関係、`parallel: yes` の安全性
- テスト範囲、lint / test command、観測可能な `done_when`
- scope creep、不要な抽象化、fresh session に対する自己完結性
- `test-selection-policy.md` が除外する標準保証の直接テスト要求

P1 / P2 には、元ソース、ユーザー確認済み意図、または調査したコードの根拠を含めるよう reviewer へ指示する。
ローカルファイルを読めない場合は `BLOCKED: cannot read local files` と返すよう指示する。

## Run the reviewer

- review packet を一時ファイルへ先に書き、その絶対パスを `--prompt-file` に渡す。
- production code、skill、plan file の編集を禁止し、read-only mode を使う。
- script は reviewer 実行だけを行い、packet 構築やplan更新を行わない。

### Run Claude reviewer

Codex が plan を作成した場合は、Claude Code への送信同意を得た後、このスキルのディレクトリから実行する。

```bash
CLAUDE_REVIEW_CONSENT=yes \
scripts/run-plan-review-claude.sh \
  --repo "<absolute repo path>" \
  --prompt-file "<review packet file>" \
  --model sonnet \
  --effort high
```

high risk の場合は `--model opus` を使う。

### Run Codex reviewer

Claude Code が plan を作成した場合は、Claude Code の `sandbox.excludedCommands` と `permissions.allow` に登録された wrapper を単体コマンドで実行する。
環境変数の前置、パイプ、リダイレクト、`&&`、`tee` を付けず、展開済み絶対パスまたはdotfiles実体パスを使わない。

```bash
~/.claude/skills/ai-review/scripts/run-plan-review-codex.sh --repo "<absolute repo path>" --prompt-file "<review packet file>" --model gpt-5.6-terra --effort high
```

high risk の場合は `--model gpt-5.6-sol` を使う。
wrapper が `BLOCKED: nested sandbox-exec` を返した場合は、コマンド形を戻して1回だけ再実行し、再度 `BLOCKED` なら停止する。
結果を調査するときは `--keep-temp` を付け、一時ディレクトリの `review.err` と `review.jsonl` を読む。

## Result

- reviewer、主要finding、risk、信頼性判定を返す。
- P1 / P2 の採否、plan更新、再調査、再レビューは planning workflow へ返す。
- P3 は任意の改善として返す。
