---
name: update-pr-description
description: >-
  既存の GitHub PR description/body を、現在の実装内容と検証結果に合わせて最小差分で更新する。
  PR 本文だけを単独で更新したいときや、レビュー対応・CI 対応の後に本文の整合性を取り直したいときに使う。
  例: 「PR本文を更新して」「PR description を最新実装に合わせて」「レビュー対応後に PR 本文も直して」。
---

# update-pr-description

GitHub PR の description/body を、現在の実装内容に合わせて更新するスキルです。
既存の構成をできるだけ保持し、矛盾した section だけを直してください。

## Scope

- 既存 PR の特定と現在の body 取得を行う。
- 現在の実装、検証結果、ユーザー指示に照らして、PR body の更新要否を判断する。
- 必要な場合だけ `gh pr edit` で PR body を更新する。
- 更新内容または「変更なし」を報告する。
- code edit、commit、push、review thread reply / resolve は行わない。

## Resources

- `references/pr-description-update-commands.md`: PR 特定、body 取得、更新前確認、`gh pr edit` 実行条件が必要になったら読む。
- `../open-pr/references/pr-body-template.md`: 現在の PR body が空で、repo 固有 template も見当たらない場合だけ読む。

## Hard constraints

- PR 番号、`owner/repo#123`、PR URL の順で対象 PR を優先して解決する。
- 指定がなければ current branch の PR を使う。
- 実装と矛盾しない既存 section は保持する。
- 実装と矛盾する section、古い検証結果、見出しだけ残って中身が空の section だけを更新または整理する。
- 本文更新が不要なら `gh pr edit` を実行しない。
- 単独実行時は `gh pr edit` の前に、更新要約をユーザーへ示して確認を取る。
- 呼び出し元 skill が PR description 更新まで承認済みなら、その承認を使ってよい。
- コマンド出力は全文を貼らず、対象 PR、更新有無、更新要点、失敗要点だけを報告する。

## Workflow

### Step 0: Resolve the PR

- 対象 PR を解決する。
- current branch の PR を使う場合も、PR number と URL は明示的に確定する。
- 現在の PR title と body を取得する。

### Step 1: Gather update context

- 現在の実装差分、ユーザーが明示した補足を集める。
- PR body にすでに書かれている内容と、現在の実装で変わった点を比較する。
- repo 固有の PR template や section 構成が見える場合は、それを維持する。
- 現在の PR body が空で、repo 固有 template も見当たらない場合だけ `../open-pr/references/pr-body-template.md` を読む。

### Step 2: Draft the minimal update

- 読み手が最終実装を理解するために必要な差分だけを body に反映する。
- 非自明な設計判断、意図的に見送った項目、レビュワーに再確認してほしい点がある場合だけ短い note を足す。
- テスト欄や検証欄は、実行していないことを完了済みのように書き換えない。
- 更新後 body の要約を作る。
- 差分がなければ「変更なし」と判定して Step 4 へ進む。

### Step 3: Apply the update

- 単独実行で本文更新承認がまだ無い場合は、更新要約を示して確認を取る。
- 承認済みなら `gh pr edit --body-file` で更新する。
- 更新後に PR body を再取得し、意図した内容になっていることを確認する。

### Step 4: Report

日本語で次を報告してください。

- 対象 PR
- PR description を更新したか、変更なしで終えたか
- 更新した section または維持した理由
- 更新前確認の有無
- 失敗した場合は要点と次の action
