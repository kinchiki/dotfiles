---
name: ai-review
description: >-
  未コミットのコード差分またはユーザーレビュー済みの実装プランを、作成した AI とは別系統の AI で読み取り専用レビューする。
  risk に応じた reviewer model を選び、Claude Code への送信同意、Codex sandbox、review packet、TRUSTED / UNTRUSTED / BLOCKED の判定を扱う。
  単独で「AIレビューして」「未コミット差分を別AIでレビュー」「このプランをAIレビュー」と依頼されたときに使う。
---

# ai-review

未コミット差分または実装プランを別系統の AI でレビューし、指摘と信頼性判定を返す。
このスキルは対象を編集せず、指摘への対応を呼び出し元へ返す。

## Resources

- `references/reviewer-policy.md`: reviewer、risk、model、同意、共通の結果形式を決める前に読む。
- `references/code-review.md`: 未コミット差分をレビューするときだけ読む。
- `references/plan-review.md`: ユーザーレビュー済みの実装プランをレビューするときだけ読む。
- `references/test-selection-policy.md`: コードレビューの prompt またはプランレビューの review packet へテスト方針を含めるときに読む。

## Hard constraints

- review 中は production code、skill、plan file を編集しない。
- 指摘の修正、plan への反映、lint / test、再レビューは呼び出し元へ任せる。
- 作成者と同じ系統の AI を独立 reviewer として扱わない。
- Claude Code へ差分または review packet を送る前に、ユーザーの明示的な同意を得る。
- reviewer がローカル対象を調査できたと検証できる結果だけを信頼する。
- 必要な reviewer を実行できない場合は `BLOCKED` として停止する。

## Workflow

### Step 1: Select the review mode

- 未コミットの working tree を対象にする場合は code review を選ぶ。
- ユーザーレビュー済みの draft plan を対象にする場合は plan review を選ぶ。
- 対象が曖昧な場合は、どちらをレビューするか確認する。
- code review では `references/plan-review.md` を読まない。
- plan review では `references/code-review.md` を読まない。

### Step 2: Select the reviewer

`references/reviewer-policy.md` を読み、作成者の AI 系統と実際の対象から risk、reviewer、model、effort を決める。
作成者を会話、plan metadata、または呼び出し元から特定できない場合は確認する。

### Step 3: Run the selected review

- code review では `references/code-review.md` に従う。
- plan review では `references/plan-review.md` に従う。
- 選択した mode の reference と `references/test-selection-policy.md` だけを追加で読む。

### Step 4: Return the result

日本語で次を返す。

- mode と対象
- risk 分類
- reviewer、model、effort
- `TRUSTED` / `UNTRUSTED` / `BLOCKED`
- `[P1]` / `[P2]` / `[P3]` の指摘、または `No findings`
- 呼び出し元が次に判断すべき対応
