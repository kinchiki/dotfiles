# Plan Template

plan.md を書く直前に読む。
plan.md は「どう・どの順で作るか」と進捗の source of truth であり、AI 実装者が実行に必要とする情報だけを持つ。
ゴール、受入基準、決定事項、やらないことは design.md が持ち、plan.md は ID で参照する。

## Path convention

```text
.ai-local/plans/<plan-id>/<YYYYMMDD>_<agent-name>_<slug>.md
```

design.md と同じディレクトリに置く。
sliced の場合は `<slug>` の末尾に `-s<N>` を付ける。

チケットをソースとする場合の例:

```text
.ai-local/plans/ENG-123/20260608_codex_oauth-token-refresh.md
```

sliced のユーザー依頼をソースとする場合の例:

```text
.ai-local/plans/request-change-x-to-y/20260616_claude_change-x-to-y-s2.md
```

## Template

```markdown
# <プランのタイトル>

- **Plan ID:** <plan-id>
- **Design:** <design.md の絶対パス>
- **Slice:** - | S<N> <スライスのタイトル>
- **Status:** draft | approved
- **Risk:** low | medium | high — <理由>
- **計画者:** <AI agent 名 / モデル ID><上位推論モデルを使えなかった場合は、その旨と品質上の不利益>

## 背景・影響するコード
<主要なファイル/モジュールをパス付きで、各1行メモを添える。>
<実装者がコードベースに合わせられるよう、踏襲すべき既存パターンも含める。>

## タスク
<順序付きタスク。実装セッションが進捗に応じてこのチェックボックスを更新する。>
<このファイルが進捗の単一の真実なので、新しいセッションでもここから再開できる。>
<チェックボックスを更新するのはオーケストレーターのみ。>
<並列ワーカーはこのファイルに触れない。>

- [ ] **T1** <タスク名>
  - implements: AC1, D2
  - files: `path/a.rb`, `path/b.rb`
  - depends_on: -
  - parallel: no
  - test: `dip rspec spec/a_spec.rb`
  - done_when: <観測可能な完了条件>
- [ ] **T2** <タスク名>
  - implements: AC2
  - files: `...`
  - depends_on: T1
  - parallel: yes
  - test: `...`
  - done_when: <観測可能な完了条件>

## テスト方針
<追加/更新する spec と実行方法を書く。>
<カバーすべき edge case を書く。>
<実装 gate が何を走らせるか分かるよう lint command も明記する。>
```

本当に該当しないセクションには、その理由を書く。
