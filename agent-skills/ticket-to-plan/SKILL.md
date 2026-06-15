---
name: ticket-to-plan
description: >-
  GitHub または Linear のチケットを十分に調査し、承認済みの実装プランファイルに変換して、実装を別セッションへ引き継ぐ。
  ユーザーがチケットを指しただけのとき、チケットを import したとき、またはコーディング前に plan / 計画を求めたときに使う。
  例: 「https://github.com/foo/bar/issues/42」「plan ENG-1234」「このissueの実装計画」「github.com/foo/bar/issues/42 のプラン」。
  issue / PR / Linear ID を参照して、すぐ実装するのではなく設計、スコープ確定、タスク分解を求める場合にも使う。
---

# ticket-to-plan

GitHub または Linear のチケットから、fresh session がそのまま実装できる durable plan file を作るスキルです。
Planning と implementation は分けてください。
このセッションでは実装せず、承認済み plan file を保存して実装セッションへ引き継ぎます。

## Scope

- チケットの full context を取得する。
- codebase を調査して設計と task breakdown を作る。
- ユーザー承認を得る。
- plan file を `.claude/plans/` に保存する。
- `implement-plan` を使う別セッションへ引き継ぐ。
- このセッションでは production code を編集しない。

## Resources

- `references/plan-template.md`: Step 5 で plan file を書く直前に読む。

## Hard constraints

- Planning quality が重要なので、orchestrator は可能なら最新 Opus を使う。
- Opus でない場合は停止し、`/model opus` または Opus session での再実行を推奨する。
- ticket title と body だけで plan を作らない。
- comments、labels、linked issues / PRs、acceptance criteria を確認する。
- source が曖昧な場合は 1 つだけ短く確認する。
- plan mode または read-only planning が使える場合は、調査中に code を編集しない。
- ユーザー承認は「この plan でよい」という意味であり、このセッションで実装を始める許可ではない。
- 承認後もこのセッションで実装しない。
- plan file は、ticket を再取得しなくても実装者が開始できる程度に self-contained にする。

## Workflow

### Step 0: Confirm model

- 自分の model を確認する。
- 最新 Opus 相当なら続行する。
- Opus でなければ、planning quality の理由を伝えて停止する。
- 使用 model を plan file の header に記録する。

### Step 1: Read the ticket

入力から source を特定し、full context を取得してください。

GitHub の recognized forms:

- `https://github.com/owner/repo/issues/123`
- `https://github.com/owner/repo/pull/123`
- `owner/repo#123`
- current repo が明らかな場合の `#123`

GitHub では `gh` CLI を優先してください。

```bash
gh issue view <number> --repo <owner/repo> --comments
gh pr view <number> --repo <owner/repo> --comments
```

`gh` が使えない場合は、ToolSearch で GitHub MCP read tool を探してください。

Linear の recognized forms:

- `ENG-123`
- `ABC-45`
- `https://linear.app/<team>/issue/ENG-123/...`

Linear では issue と discussion を取得し、requirements に関係する parent、sub-issues、project / milestone も確認してください。
ToolSearch で `linear issue` と `linear comments` を探してください。

取得後、3 から 6 行の理解 summary をユーザーに返してください。
ticket が薄い、矛盾している、または acceptance criteria が欠けている場合は、その gap を plan の open question として扱ってください。

### Step 2: Research and plan

read-only planning で codebase を調査してください。

- actual data flow を追う。
- models、services / interactions、controllers、serializers、GraphQL types、jobs、tests など、影響範囲を読む。
- exact file path を記録する。
- 既存 pattern と testing idiom を確認する。
- migration、backward compatibility、permission / auth、N+1、background-job idempotency、API surface、i18n など、該当する edge を検討する。
- target repo が `app/interactions/`、`packs/`、`CLAUDE.md` の convention を持つ場合は、それを尊重する。

plan は、ticket や codebase を読んでいない session でも正しく実装できる粒度にしてください。
曖昧な plan は失敗です。

### Step 3: Break the plan into tasks

`## タスク` に書く task breakdown を作ってください。
各 task には次を含めます。

- `files`: touch する file。
- `depends_on`: prerequisite task ID。
- `parallel`: 同時実行できる場合だけ `yes`。
- `test`: task を検証する command。
- `done_when`: 観測可能な完了条件。

`parallel: yes` は、同時に ready になる task と `files` が重ならない場合だけ使ってください。
overlap がある task は sequential にしてください。

### Step 4: Present and get approval

plan と task breakdown をユーザーに提示して承認を得てください。
plan mode の approval affordance がある環境では、それを使ってください。

- ユーザーが reject または feedback を返した場合は、feedback を spec として扱う。
- feedback が前提を変える場合は code を再調査する。
- 承認されるまで plan を更新する。
- 承認後も実装は始めない。

### Step 5: Write the plan file

承認後、`references/plan-template.md` を読んで plan file を保存してください。

Location:

```text
.claude/plans/<YYYY-MM-DD>-<source>-<ticket-id>-<slug>.md
```

- `<YYYY-MM-DD>` は `date +%F` で取得する。
- `<source>` は `gh` または `linear` にする。
- `<ticket-id>` は GitHub number または Linear key にする。
- `<slug>` は ticket title から 3 から 5 語の kebab-case にする。
- project が明確に別 convention を持つ場合は従い、保存先を報告する。

```bash
date +%F
```

### Step 6: Hand off implementation

implementation は separate session に引き継いでください。
引き継ぎ prompt は self-contained にし、absolute plan-file path、ticket reference、working directory を含めます。

Use `spawn_task` when available:

- title: `<ticket-id> を実装`
- tldr: one plain-English line describing the implementation task.
- prompt: Japanese prompt that says to use `implement-plan`, read the approved plan, create a feature branch, implement tasks with tests, run lint / test, perform risk-based AI review, commit, and open PR follow-up.

`spawn_task` が使えない場合は、manual command を提示してください。

```bash
cd <repo> && claude "プラン .claude/plans/<file>.md を implement-plan スキルで実装して"
```

最後に、plan の保存先と implementation task を起動したかどうかを報告して停止してください。

## Expected output

日本語で次を報告してください。

- ticket summary。
- plan の主要方針。
- task breakdown の概要。
- 保存した plan file の path。
- implementation session を起動したか、manual command が必要か。
- この session では実装していないこと。

## Quick reference

| Step | Action | Tool |
|------|--------|------|
| 0 | Confirm Opus | Self-check. |
| 1 | Fetch full ticket context | `gh` CLI / GitHub MCP / Linear MCP. |
| 2 | Research codebase | Read-only planning. |
| 3 | Break into tasks | `files`, `depends_on`, `parallel`, `test`, `done_when`. |
| 4 | Get approval | Plan approval affordance if available. |
| 5 | Write plan file | Read `references/plan-template.md`. |
| 6 | Hand off implementation | `spawn_task` or manual command. |
