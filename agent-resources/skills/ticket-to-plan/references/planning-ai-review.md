# Planning AI Review Reference

ユーザーがドラフトプランのレビューを終えた後、最終承認を依頼する前に、`../SKILL.md` の Step 5 からこの reference を使う。
目的は、ユーザーに代わってプランを承認することではなく、ユーザーレビュー済みのプランを最終承認前に改善することである。

## Contents

- レビュアーを選ぶ。
- review packet を組み立てる。
- レビュアーを実行する。
- 指摘に対応する。

## Select the reviewer

- ユーザーが reviewer AI を指定した場合は、その AI を使う。
- Claude Code がドラフトプランを作成した場合は、Codex をレビュアーとして使う。
- Codex がドラフトプランを作成した場合は、Claude Code をレビュアーとして使う。
- その他の AI がドラフトプランを作成した場合は、planner とは異なる費用対効果の高い独立レビュアーを使う。
- 依頼された、または必要なレビュアーが利用できない場合は、最終承認の前に停止して阻害要因を報告する。

## Select model and effort

- レビューには費用対効果の高いデフォルト値を使う。
- プランが認証、請求、権限、データ削除、migration、セキュリティ、本番データ、広範な refactor、または不明な影響範囲に関わる場合は high-risk とする。
- レビューには以下のモデルと推論を使う。
  - Codex
    - デフォルト
      - `CODEX_REVIEW_MODEL=${CODEX_REVIEW_MODEL:-gpt-5.6-terra}`
      - `CODEX_REVIEW_EFFORT=${CODEX_REVIEW_EFFORT:-high}`
    - high-risk の差分
      - `CODEX_REVIEW_MODEL=gpt-5.6-sol`
      - `CODEX_REVIEW_EFFORT=high`
  - Claude
    - デフォルト
      - `CLAUDE_REVIEW_MODEL=${CLAUDE_REVIEW_MODEL:-sonnet}`
      - `CLAUDE_REVIEW_EFFORT=${CLAUDE_REVIEW_EFFORT:-high}`
    - high-risk の差分
      - `CLAUDE_REVIEW_MODEL=opus`
      - `CLAUDE_REVIEW_EFFORT=high`
    - high-risk の差分
      - `CLAUDE_REVIEW_MODEL=opus`
      - `CLAUDE_REVIEW_EFFORT=high`
- 明示的に依頼された場合にだけ `xhigh` または `max` を使う。
- 環境変数はデフォルト値より優先する。

## Build the review packet

プランの評価に必要なコンテキストだけを渡す。
次の内容を含める。

- ソース種別と3〜6行のソース要約。
- 元ソースの参照先またはユーザー依頼の抜粋。
- ドラフトレビュー中にユーザーが明確にした、ユーザーレビュー済みの意図の変更、受け入れた振る舞い、明示的な non-goal。
- ゴール、受入基準、スコープを限定したアプローチ、リスク、スコープ外の項目を含むドラフトプラン。
- `files`、`depends_on`、`parallel`、`test`、`done_when` を含むドラフトの `## タスク` 分解。
- planner が調査したファイルパスと既存パターン。
- 仮定、未解決の質問、既知の制約。
- `test-selection-policy.md` の内容。

レビュアーに次の点を確認させる。

- ソースにある要件の漏れ。
- 安全性、データ整合性、実装可能性、リポジトリの制約との具体的な衝突がない限り、プランがユーザーの明示的な意図と意図的に受け入れた振る舞いを維持しているか。
- チケットをソースとする場合は、コメント、label、リンクされた issue / PR、受入基準。
- ユーザー依頼をソースとする場合は、推測した仮定と受入基準が実装に十分なほど明示されているか。
- 影響を受けるファイル、data flow、認証 / 権限、background job、API、migration、互換性に関する懸念の見落とし。
- タスクの順序、依存関係、`parallel: yes` の安全性。
- テストカバレッジ、lint / test コマンド、観測可能な `done_when` 条件。
- テストが DB・フレームワーク・ライブラリの標準保証だけを直接再検証していないこと。
- scope creep または不要な抽象化。
- 新しい実装セッションが使えるほどプランが自己完結しているか。

元ソースとユーザーレビュー済みの意図を source of truth として扱うようレビュアーへ指示する。
セキュリティ、データ損失、実装不可能、リポジトリの強制的な制約など、具体的なリスクを指摘で示す場合を除き、ユーザーが維持を明示的に依頼した振る舞いの変更を提案しないようレビュアーへ指示する。
`test-selection-policy.md` で除外されているテストの不足を要求または報告しないようレビュアーへ指示する。
P1 または P2 の各指摘では、関連するソースの抜粋、ユーザーレビュー済みの意図、または調査したコードベースの根拠を引用するようレビュアーへ指示する。

レビュアーに次の形式で指摘を返させる。

```text
[P1] <blocking issue that would likely make implementation fail or violate requirements>
[P2] <important issue that should be addressed before final approval>
[P3] <nice-to-have improvement>
No findings
```

## Run the reviewer

- 以下のすべてのレビュアースクリプトは、このスキル自身のディレクトリから実行する。
- read-only mode を使う。
- production code、skill file、plan file を編集しないようレビュアーへ指示する。
- レビュアースクリプトを実行する前に、review packet を `REVIEW_PROMPT_FILE` へ書き込む。
- スクリプトの実行前に review packet が存在していなければならない。
- レビュアースクリプトは選択したレビュアーの実行だけを行い、レビュアーの選択、review packet の構築、指摘への対応、プランの更新は行わない。
- レビュアースクリプトは、レビュアーの出力と stderr のために新しい一時ディレクトリを自ら作成する。
- Claude Code をレビュアーとして選択した場合、review packet を送信する前にユーザーへ明示的な許可を求める。
- 許可を記録した後にだけ `CLAUDE_REVIEW_CONSENT=yes` を設定する。
- 同意がまだ記録されていないため実行が妨げられた場合は、停止して同意を得てから変数を設定し、再実行する。

Claude Code がドラフトプランを作成した場合は、Codex をレビュアーとして使う。

```bash
REPO="<absolute repo path>"
REVIEW_PROMPT_FILE="<review packet file>"

scripts/run-codex-planning-review.sh \
  --repo "$REPO" \
  --prompt-file "$REVIEW_PROMPT_FILE"
```

Codex がドラフトプランを作成した場合は、Claude Code をレビュアーとして使う。

```bash
REPO="<absolute repo path>"
REVIEW_PROMPT_FILE="<review packet file>"

scripts/run-claude-planning-review.sh \
  --repo "$REPO" \
  --prompt-file "$REVIEW_PROMPT_FILE"
```

共通 runner を直接使うのは、low-level API として使う場合だけにする。

```bash
scripts/run-planning-reviewer.sh \
  --repo "$REPO" \
  --reviewer codex \
  --prompt-file "$REVIEW_PROMPT_FILE"
```

現在の環境に、選択した reviewer AI を使用しつつ費用対効果がより高い multi-agent tool または review tool がある場合は、その tool を代わりに使う。

## Handle findings

- P1 と P2 の指摘には、プランの更新または理由を伴う planner の明示的な却下が必要であるものとして扱う。
- 採用した指摘は、ユーザーに最終承認を求める前にドラフトプランとタスク分解へ反映する。
- 指摘によって仮定や影響を受けるファイルが変わる場合は、プランを更新する前に関連するチケットまたはコードのコンテキストを読み直す。
- 低コストで対応でき、プランが明確になる P3 の指摘には対応する。
- 見送った P2 / P3 の指摘とその理由を `AIレビュー` または `リスク・未解決の論点` に記録する。
- P1 または P2 の指摘によって実質的な再設計が発生した場合は、更新したドラフトに対して同じレビュアーをもう1回実行する。
- レビュアー、主要な指摘、planner の判断を最終承認の依頼と一緒に提示する。
