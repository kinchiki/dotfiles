# Plan Template Reference

承認済みのプランファイルを書く前に、`../SKILL.md` の Step 7 からこのファイルを読む。
本当に該当しない場合を除き、すべてのセクションを記入する。
該当しないセクションには、その理由を書く。

## Path convention

```text
.ai-local/plans/<plan-id>/<YYYYMMDD>_<agent-name>_<slug>.md
```

チケットをソースとする場合の例:

```text
.ai-local/plans/ENG-123/20260608_codex_oauth-token-refresh.md
```

ユーザー依頼をソースとする場合の例:

```text
.ai-local/plans/request-change-x-to-y/20260616_codex_change-x-to-y.md
```

チケットをソースとする場合は、`ENG-123` や `github-123` のようなチケット ID を使う。
ユーザー依頼をソースとする場合は、`request-<slug>` を使う。

## Template

```markdown
# <プランのタイトル>

- **ソース:** GitHub | Linear | User request
- **参照:** <完全な URL、ID、または元依頼の短い引用>
- **Plan ID:** <plan-id>
- **計画者:** <AI agent 名、モデル ID。例: codex / gpt-5.6-sol>
- **日付:** <YYYY-MM-DD>
- **ステータス:** 承認済み - 実装可能

## ゴール
<1〜3文: 完了状態を平易な言葉で。>

## 受入基準
- [ ] <source から導いた観測可能でテスト可能な成果>

## 背景・影響するコード
<主要なファイル/モジュールをパス付きで、各1行メモを添える。>
<実装者がコードベースに合わせられるよう、踏襲すべき既存パターンも含める。>

## AIレビュー
- reviewer: <AI agent 名、model、review 実行方法>
- findings: <P1/P2/P3 の要約、または no findings>
- planner disposition: <採用 / 一部採用 / 不採用と理由>
- plan updates: <review 後に反映した変更>

## 最終承認
- reviewer sequence: <ユーザーレビュー完了後に AI review を実施したこと>
- approved by: <ユーザー>
- approval note: <最終承認時の短いメモ、または承認メッセージの要約>

## タスク
<順序付きタスク。実装セッションが進捗に応じてこのチェックボックスを更新する。>
<このファイルが進捗の単一の真実なので、新しいセッションでもここから再開できる。>
<チェックボックスを更新するのはオーケストレーターのみ。>
<並列ワーカーはこのファイルに触れない。>

- [ ] **T1** <タスク名>
  - files: `path/a.rb`, `path/b.rb`
  - depends_on: -
  - parallel: no
  - test: `dip rspec spec/a_spec.rb`
  - done_when: <観測可能な完了条件>
- [ ] **T2** <タスク名>
  - files: `...`
  - depends_on: T1
  - parallel: yes
  - test: `...`
  - done_when: <観測可能な完了条件>

## テスト方針
<追加/更新する spec と実行方法を書く。>
<カバーすべき edge case を書く。>
<実装 gate が何を走らせるか分かるよう lint command も明記する。>

## 動作確認
<手動 verification が必要かを yes / no で明記する。>
<yes の場合は、確認対象、`create-verification` を実行するタイミング、`run-verification` を聞くタイミングを具体的に書く。>
<少なくとも「コミット前」と「レビュー / CI 対応後」の各ポイントで、run / skip をユーザー承認で決めることを書く。>
<no の場合は、不要と判断した根拠を書く。>

## リスク・未解決の論点
<注意点、先送りした判断、実装者が確認すべきことを書く。>
<想定 risk を low / medium / high で書き、その理由も書く。>

## スコープ外
<やらないことを明示し、実装セッションでの scope creep を防ぐ。>
```
