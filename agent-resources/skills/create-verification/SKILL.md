---
name: create-verification
description: >-
  現在のブランチまたは指定した PR の差分を読み、変更内容に応じた動作確認手順を
  `.ai-local/verification/*.local.md` に生成または追記する。
  実装完了後やレビュー / CI 対応後に、手動確認が必要な差分を確認可能なチェックリストへ変換したいときに使う。
  例: 「変更分の動作確認手順を作る」「PR 123 の verification を更新する」。
---

# create-verification

変更差分を読み、手動確認に使う verification ドキュメントを作るスキルです。
初回は新規作成し、レビュー / CI 対応後は同じ verification ファイルへ必要分だけ追記します。

## Scope

- 現在のブランチ、または指定した PR の差分を読む。
- 変更された層から、手動確認が必要な確認観点を抽出する。
- `.ai-local/verification/*.local.md` に verification ドキュメントを新規作成または追記する。
- 既存 verification がある場合は、未完了項目を壊さずに保ちつつ新しい確認項目を追加する。

## Resources

- `references/verification-template.md`: 出力フォーマットと、変更種別ごとの確認観点を組み立てる直前に読む。

## Hard constraints

- 保存先は `.ai-local/verification/` 配下の `.local.md` に固定する。
- 新規作成時の保存名は `pr-<PR番号>-<ブランチ名スラッグ>.local.md` を優先し、PR番号が無い場合は `worktree-<ブランチ名スラッグ>.local.md` にする。
- 追記時は、同じブランチまたは同じ PR に対応する既存ファイルを優先して再利用する。
- 既存の `## チェックリスト` にある `✅` / `⏭️` / `□` は保持し、既存項目を勝手にリセットしない。
- 差分から手動確認が不要と判断できる場合は、空の verification を作らず、その理由を報告して止まる。
- 画面操作、GraphQL、REST、DB確認の手順は、差分から裏取りできる範囲だけを書く。
- 日本語で書く。クラス名、メソッド名、GraphQL field 名、path は実コードの表記を保つ。

## Workflow

### Step 1: Resolve the target diff

- 引数が PR 番号なら `gh pr view <番号> --json title,body,number`、`gh pr diff <番号> --name-only`、`gh pr diff <番号>` を使う。
- 引数が無ければ現在のブランチ名を取り、`git diff main...HEAD` を使う。
- PR 番号またはブランチ名から、保存先ファイル名と既存 verification 候補を決める。

### Step 2: Analyze what needs manual verification

- 変更ファイルと diff を読み、UI、GraphQL、REST、job、interaction、model のどこに挙動変更があるかを整理する。
- 自動テストで十分な変更か、実際の操作確認が必要な変更かを切り分ける。
- 手動確認が必要な場合だけ、確認観点、前提データ、期待結果を抽出する。

### Step 3: Load the reference format and existing verification

- `references/verification-template.md` を読み、出力構造を決める。
- 既存 verification がある場合はそのファイルを読み、前提、既存チェックリスト、未完了項目を確認する。
- 追記時は、今回の差分で追加になった確認だけを新しい `## 確認N` とチェック項目として足す。

### Step 4: Write the verification file

- 新規作成時は、前提、確認表、事前準備、確認セクション、チェックリストを含む完全なファイルを書く。
- 追記時は、必要な前提の差分だけを補足し、追加の確認セクションとチェック項目だけを足す。
- 保存後は対象ファイルの絶対パスを報告する。

## Report

日本語で次を報告してください。

- 対象 diff（現在ブランチ or PR 番号）
- 採用した verification ファイルの path
- 新規作成か追記か
- 追加した確認観点の要約
- verification 不要として止まった場合はその理由
