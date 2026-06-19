---
name: ticket-to-plan
description: >-
  GitHub や Linear のチケット、またはユーザーの自然言語の変更依頼を十分に調査し、承認済みの実装プランファイルに変換して、実装を別セッションへ引き継ぐ。
  ユーザーがチケットを指しただけのとき、チケットを import したとき、またはチケットなしでコーディング前に plan / 計画を求めたときに使う。
  例: 「https://github.com/foo/bar/issues/42」「plan ENG-1234」「このissueの実装計画」「github.com/foo/bar/issues/42 のプラン」「ticket-to-plan で X を Y にしたい」「X に変えるプラン」
  issue / PR / Linear ID または自然言語の変更依頼を参照して、すぐ実装するのではなく設計、スコープ確定、タスク分解を求める場合にも使う。
---

# ticket-to-plan

GitHub や Linear のタスク管理ツールのチケット、またはユーザーの自然言語の変更依頼から、fresh session がそのまま実装できる durable plan file を作るスキルです。
Planning と implementation は分けてください。
このセッションでは実装せず、承認済み plan file を保存して実装セッションへ引き継ぎます。

## Scope

- 入力 source を特定する。
- Ticket source の場合は full context を取得する。
- User request source の場合は依頼文と会話 context から目的、対象、制約、受入基準を抽出する。
- codebase を調査して設計と task breakdown を作る。
- ユーザー承認を得る。
- plan file を現在の AI agent に対応する plan directory の `<plan-id>/` 配下に保存する。
- `implement-plan` を使う別セッションへ引き継ぐ。
- このセッションでは production code を編集しない。

## Resources

- `references/planning-ai-review.md`: Step 4 でユーザー承認前の AI 相互レビューを行う直前に読む。
- `references/plan-template.md`: Step 6 で plan file を書く直前に読む。

## Hard constraints

- Planning quality が重要なので、orchestrator は top reasoning session（現在の AI agent で利用できる最上位推論モデル + 最大 reasoning / thinking 設定）を使い、そうでない、または確認できない場合は停止して再実行を推奨する。
- Ticket source では ticket title と body と body 記載の各URL先をもとにplanを作る。
- Ticket source では comments、labels、linked issues / PRs、acceptance criteria を確認する。
- User request source では依頼文と会話 context を source of truth とし、抽出した前提、受入基準、open questions を plan に明記する。
- source が曖昧な場合は 1 つだけ短く確認する。
- read-only planning が使える場合は、調査中に code を編集しない。
- ユーザー承認は「この plan でよい」という意味であり、このセッションで実装を始める許可ではない。
- 承認後もこのセッションで実装しない。
- plan file は、source を再取得しなくても実装者が開始できる程度に self-contained にする。
- ユーザー承認を求める前に、`references/planning-ai-review.md` に従って最新の draft plan と task breakdown を別 AI でレビューする。

## Workflow

### Step 0: Confirm model

- 自分の model と reasoning / thinking 設定を確認する。
- top reasoning session なら続行する。
- 条件を満たせない、または確認できない場合は、planning quality の理由を伝えて停止する。
- 使用 model と reasoning / thinking 設定を plan file の header に記録する。

### Step 1: Resolve the source

入力から source kind を特定し、実装要求の full context を取得または抽出してください。

Source kind は次のいずれかにしてください。

- GitHub issue / PR
- Linear issue
- その他タスク管理ツールのチケット
- User request

GitHub や Linear の recognized form がある場合は、ticket source として扱ってください。
recognized form がない場合は、User request source として扱ってください。
User request source では外部 ticket を要求せず、ユーザーの依頼文と会話 context から plan source を作ってください。
依頼が別 skill、local file、または repo 内概念を指す場合は、Step 2 で codebase と該当ファイルを調査してください。

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

User request source では次を抽出してください。

- requested change
- target area
- explicit constraints
- inferred acceptance criteria
- assumptions and open questions

取得または抽出後、3 から 6 行の source summary をユーザーに返してください。
source が薄い、矛盾している、または acceptance criteria が欠けている場合は、その gap を plan の open question として扱ってください。

### Step 2: Research and plan

read-only planning で codebase を調査してください。

- actual data flow を追う。
- models、services / interactions、controllers、serializers、GraphQL types、jobs、tests など、影響範囲を読む。
- exact file path を記録する。
- 既存 pattern と testing idiom を確認する。
- migration、backward compatibility、permission / auth、N+1、background-job idempotency、API surface、i18n など、該当する edge を検討する。
- target repo が `app/interactions/`、`packs/`、`CLAUDE.md` / `AGENTS.md` の convention を持つ場合は、それを尊重する。

plan は、source や codebase を読んでいない session でも正しく実装できる粒度にしてください。
曖昧な plan は失敗です。

### Step 3: Break the plan into tasks

`## タスク` に書く task breakdown を作ってください。
各 task には次を含めます。

- `files`: touch する file
- `depends_on`: prerequisite task ID
- `parallel`: 同時実行できる場合だけ `yes`
- `test`: task を検証する command
- `done_when`: 観測可能な完了条件

`parallel: yes` は、同時に ready になる task と `files` が重ならない場合だけ使ってください。
overlap がある task は sequential にしてください。

### Step 4: Run cross-AI planning review

ユーザー承認を求める前に、`references/planning-ai-review.md` を読んで draft plan をレビューしてください。
Planning AI は review 内容を確認し、採用する指摘を plan と task breakdown へ反映してください。
採用しない重要指摘は、理由を plan に残してください。

### Step 5: Present reviewed plan and get approval

review 済み plan と task breakdown をユーザーに提示して承認を得てください。
事前 AI review の reviewer、主要 findings、planning AI の採否判断も短く添えてください。
approval affordance がある環境では、それを使ってください。

- ユーザーが reject または feedback を返した場合は、feedback を spec として扱う。
- feedback が前提を変える場合は code を再調査する。
- feedback で plan または task breakdown が変わる場合は、再提示前に Step 4 を再実行する。
- 承認されるまで plan を更新する。
- 承認後も実装は始めない。

### Step 6: Write the plan file

承認後、`references/plan-template.md` を読んで plan file を保存してください。

保存先とファイル名は `references/plan-template.md` の Path convention に従ってください。
`<YYYYMMDD>` は `TZ=Asia/Tokyo date +%Y%m%d` で取得してください。
Project が明確に別 convention を持つ場合は従い、保存先を報告してください。

```bash
TZ=Asia/Tokyo date +%Y%m%d
```

### Step 7: Hand off implementation

implementation は新しいセッションに引き継いでください。
このセッションでは実装しません。
新しいセッションを開いてそこに貼り付ける self-contained な引き継ぎテキストを、1 つの fenced code block で提示してください。
特定 agent の CLI コマンドや起動ツールは使わないでください。

引き継ぎテキストには次を含めます。

- `implement-plan` スキルで実装する指示
- working directory
- absolute plan-file path
- source reference が ticket ではない場合は、source summary と plan-id

例:

```text
working directory: <repo>
plan file: <absolute-plan-file-path>
Implement this plan with the `implement-plan` skill.
```

最後に、plan の保存先と、引き継ぎテキストを提示したことを報告して停止してください。

## Expected output

日本語で次を報告してください。

- source summary
- plan の主要方針
- task breakdown の概要
- 事前 AI review の reviewer と planning AI の採否判断
- 保存した plan file の path
- 新規セッション用の引き継ぎテキストを提示したか
- この session では実装していないこと
