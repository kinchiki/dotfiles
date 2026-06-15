# Plan Template Reference

Read this file from `../SKILL.md` Step 5 before writing the approved plan file.
Fill every section unless it is truly not applicable.
If a section is not applicable, say why in that section.

## Path convention

```text
.claude/plans/<YYYY-MM-DD>-<source>-<ticket-id>-<slug>.md
```

Example:

```text
.claude/plans/2026-06-08-linear-ENG-123-oauth-token-refresh.md
```

## Template

```markdown
# <チケットのタイトル>

- **チケット:** <完全な URL または ID>
- **ソース:** GitHub | Linear
- **計画者:** <モデル ID、例: claude-opus-4-8>
- **日付:** <YYYY-MM-DD>
- **ステータス:** 承認済み - 実装可能

## ゴール
<1〜3文: 完了状態を平易な言葉で。>

## 受入基準
- [ ] <観測可能でテスト可能な成果。可能ならチケットから引く>

## 背景・影響するコード
<主要なファイル/モジュールをパス付きで、各1行メモを添える。>
<実装者がコードベースに合わせられるよう、踏襲すべき既存パターンも含める。>

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

## リスク・未解決の論点
<注意点、先送りした判断、実装者が確認すべきことを書く。>
<想定 risk を low / medium / high で書き、その理由も書く。>

## スコープ外
<やらないことを明示し、実装セッションでの scope creep を防ぐ。>
```
