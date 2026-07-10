# Verification Template Reference

`create-verification` から、verification ファイルの本文を組み立てる直前に読む。
新規作成でも追記でも、既存ファイルの構造を壊さずにこの形へ合わせる。

## File shape

```markdown
# 動作確認手順: <チケット番号または短い機能名>

> ブランチ: <ブランチ名>
> 日付: <YYYY-MM-DD>

## 前提

<確認対象の要約を 1 から 2 文>

| 機能 | トリガー | 確認場所 |
|---|---|---|
| **<機能名>** | <条件> | <画面 URL / endpoint / console> |

## 事前準備: テストデータの確認

<必要な場合だけ書く。不要なら「不要」と書く。>

## 確認1: <タイトル>

### セットアップ

<必要な場合だけ書く。不要ならこの小見出し自体を省く。>

### 操作手順

1. <操作>
2. <操作>

### 期待値

- <期待結果>

## 確認2: <タイトル>

...

## チェックリスト

□ <確認1に対応する項目>
□ <確認2に対応する項目>
```

## Manual verification heuristics

- `app/views/`, `app/controllers/`, フロントエンド UI の変更:
  実画面の表示条件、入力、送信結果、エラーメッセージを確認項目にする。
- `app/graphql/`, schema, resolver の変更:
  実行可能な query / mutation、正常系、主要な異常系、レスポンス field を確認項目にする。
- API controller, serializer の変更:
  curl または既存の API 実行手順で、status code、response body、副作用を確認項目にする。
- interaction, job, model の変更:
  条件分岐、非同期副作用、保存値の変化を console / DB確認として確認項目にする。
- 純粋な test、comment、文言のみの変更:
  手動確認不要の候補として扱う。

## Append rules

- 既存ファイルがある場合は、その header、前提、完了済みチェック項目を保持する。
- 新しい確認セクション番号は、既存の最後の `確認N` の次を使う。
- 追加した確認ごとに `## チェックリスト` に新しい `□` 項目を足す。
- 既存項目の文言は、今回の差分で意味が変わらない限り書き換えない。
