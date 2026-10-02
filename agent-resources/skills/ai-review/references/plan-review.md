# Plan Review

設計とタスクをまとめた実装プラン（plan.md）を、最終承認前に独立レビューするときだけ使う。
目的はユーザーに代わって承認することではなく、元ソースとユーザーの判断に照らして設計とプランの問題を発見することである。

## Build the review packet

`test-selection-policy.md` を読み、プラン評価に必要な次のコンテキストだけを review packet に含める。

- plan.md の絶対パスと最新の全文
- 元ソースの参照先またはユーザー依頼の抜粋
- planner が調査した path と既存 pattern
- plan.md の `## AIレビュー` で見送り済みの指摘
- `test-selection-policy.md` の内容

元ソース、plan.md の `## 要件`、`### ユーザー判断` を source of truth とするよう reviewer へ指示する。
`### ユーザー判断` はユーザーが決めた判断であると reviewer へ伝える。
具体的な安全性、データ損失、実装不可能、要件違反、repository constraint の根拠がある場合を除き、ユーザー判断の変更やユーザーが維持を明示した挙動の変更を提案させない。
sliced の場合は、対象スライスを伝え、`outline` のスライスのタスクを指摘の対象にさせない。
見送り済みの指摘を再提起させない。

## Review focus

- 受入基準（sliced では対象スライスの delivers）を満たさない設計、またはどのタスクの `implements` にも含まれない受入基準
- 決定事項同士の矛盾、決定事項に反する設計やタスク、やらないことへの逸脱
- ユーザー判断が必要なのに `### AI判断` で決めている判断、またはどこにも記録されていない判断
- 調査したコードや既存 pattern と食い違う前提
- data flow、auth / permission、background job、API、migration、互換性、運用特性の見落とし
- `## 変更面` の宣言漏れ、宣言した面を実装するタスクの欠落、`## 展開順` の誤りや欠落
- タスクの順序と依存関係、sliced ではスライスの独立性と blocked_by
- テスト範囲、lint / test command、観測可能な `done_when`
- まれなケースへの過剰な実装（低確率で単純なエラー処理で足りる事象への専用の処理）
- scope creep、不要な抽象化、fresh session に対する自己完結性（entry point、既存 pattern、`done_when` で判断し、想定変更箇所は非拘束として扱う）
- `test-selection-policy.md` が除外する標準保証の直接テスト要求

P1 / P2 には、元ソース、plan.md、または調査したコードの根拠を含めるよう reviewer へ指示する。
各指摘には、対象のセクションまたは ID（AC、D、A、T など）を示させる。
必須のローカル inspection 指示と `BLOCKED` を返してよい条件は wrapper が review packet へ追記するため、packet 本文では省略する。

## Run the reviewer

- review packet を一時ファイルへ先に書き、その絶対パスを `--prompt-file` に渡す。
- production code、skill、plan file の編集を禁止し、read-only mode を使う。
- script は reviewer 実行だけを行い、packet 構築や plan の更新を行わない。

### Run Claude reviewer

Codex がレビュー対象を作成した場合は、このスキルのディレクトリから実行する。

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

Claude Code がレビュー対象を作成した場合は、Claude Code の `sandbox.excludedCommands` と `permissions.allow` に登録された wrapper を単体コマンドで実行する。
環境変数の前置、パイプ、リダイレクト、`&&`、`tee` を付けず、展開済み絶対パスまたはdotfiles実体パスを使わない。

```bash
~/.claude/skills/ai-review/scripts/run-plan-review-codex.sh --repo "<absolute repo path>" --prompt-file "<review packet file>" --model gpt-6-luna --effort high
```

high risk の場合は `--model gpt-6-luna --effort xhigh` を使う。
wrapper が `BLOCKED: nested sandbox-exec` を返した場合は、コマンド形を戻して1回だけ再実行し、再度 `BLOCKED` なら停止する。
wrapper が exit 7 を返した場合は `reviewer-policy.md` の trust 判定に従う。
結果を調査するときは `--keep-temp` を付け、一時ディレクトリの `review.err` と `review.jsonl` を読む。

## Result

- reviewer、主要finding、risk、信頼性判定を返す。
- trust 判定、形式不備、再実行の扱いは `reviewer-policy.md` に従う。
- P1 / P2 の採否、plan更新、差し戻し、再レビューは呼び出し元へ返す。
- P3 は任意の改善として返す。
