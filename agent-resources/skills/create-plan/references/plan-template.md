# Plan Template

plan.md を書く直前に読む。
plan.md は「どう・どの順で作るか」と進捗の source of truth であり、human が承認する実装契約と、実装者が参照する非拘束の情報を持つ。
ゴール、受入基準、決定事項、やらないことは design.md が持ち、plan.md は ID で参照する。
worker ごとの file allowlist と並列化は plan.md に書かず、implement-plan の orchestrator が実行時に決める。

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

## 拘束力

承認済みの plan.md のうち、次の項目を拘束項目とし、implement-plan が contract として扱う。

- `## 変更面`
- `## タスク` のタスク構成と、各タスクの `implements`、`depends_on`、`done_when`、`test` の検証する振る舞い
- `## テスト方針` の検証する振る舞いと edge case

次の項目は非拘束とし、実装者が実態に合わせて読み替える。

- `test` と `## テスト方針` の command
- `## 影響範囲と既存パターン`
- `## 実行メモ`

## Template

```markdown
# <プランのタイトル>

- **Plan ID:** <plan-id>
- **Design:** <design.md の絶対パス>
- **Slice:** - | S<N> <スライスのタイトル>
- **Status:** draft | approved
- **Risk:** low | medium | high — <理由>
- **計画者:** <AI agent 名 / モデル ID><上位推論モデルを使えなかった場合は、その旨と品質上の不利益>

## 変更面
<次の面のうち、この plan が変更するものだけを書く: DB schema・データ移行、公開 interface（HTTP / GraphQL / 他モジュールから呼ばれる API / イベント）、依存関係、設定・環境変数・権限、非同期処理（job / スケジュール）。>
<根拠の decision がある場合は ID を添える。該当が無い場合は「なし」と書く。>
- <面>: <変更内容> (D2)
- 上記以外の面は変更しない。

## タスク
<順序付きタスク。実装セッションが進捗に応じてこのチェックボックスを更新する。>
<このファイルが進捗の単一の真実なので、新しいセッションでもここから再開できる。>
<チェックボックスを更新するのはオーケストレーターのみ。>
<並列ワーカーはこのファイルに触れない。>

- [ ] **T1** <outcome を表すタスク名>
  - implements: AC1, D2
  - depends_on: -
  - done_when: <観測可能な完了条件。受入基準と同じ場合は AC の ID を書く。>
  - test: <検証する振る舞い> — `dip rspec spec/a_spec.rb`
- [ ] **T2** <outcome を表すタスク名>
  - implements: AC2
  - depends_on: T1
  - done_when: <観測可能な完了条件>
  - test: <検証する振る舞い> — `...`

## テスト方針
<追加/更新する test で検証する振る舞いと、カバーすべき edge case を書く。>
<実装 gate が何を走らせるか分かるよう、test と lint の command を明記する。>

## 影響範囲と既存パターン
<実装者が読み始める entry point と、想定する変更箇所をパス付きで、各1行メモを添える。>
<実装者がコードベースに合わせられるよう、踏襲すべき既存パターンも含める。>

## 実行メモ
<implement-plan の orchestrator だけが追記する。>
```

`## 実行メモ` は見出しだけを置き、plan 作成時は空にする。
それ以外で本当に該当しないセクションには、その理由を書く。
