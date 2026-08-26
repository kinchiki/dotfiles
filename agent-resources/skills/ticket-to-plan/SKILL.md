---
name: ticket-to-plan
description: >-
  GitHub や Linear のチケット、またはユーザーの自然言語の変更依頼を十分に調査し、承認済みの実装プランとユーザー向け情報ファイルに変換する。
  コンテキストに余裕があれば同一セッションで implement-plan による実装まで続け、コンテキスト不足が予想されるときだけ別セッションへ引き継ぐ。
  ユーザーがチケットを指しただけのとき、チケットを import したとき、またはチケットなしでコーディング前に plan / 計画を求めたときに使う。
  例: 「https://github.com/foo/bar/issues/42」「plan ENG-1234」「このissueの実装計画」「github.com/foo/bar/issues/42 のプラン」「ticket-to-plan で X を Y にしたい」「X に変えるプラン」
  issue / PR / Linear ID または自然言語の変更依頼を参照して、すぐ実装するのではなく設計、スコープ確定、タスク分解を求める場合にも使う。
---

# ticket-to-plan

GitHub や Linear のタスク管理ツールのチケット、またはユーザーの自然言語の変更依頼から、fresh session がそのまま実装できる durable な実装プランとユーザー向け情報ファイルを作るスキルです。
planning フェーズは read-only で行い、production code を編集しません。
承認と実装プラン・ユーザー向け情報ファイルの保存後は、コンテキスト状況に応じて同一セッションで `implement-plan` による実装まで続けるか、別セッションへ引き継ぎます。

## Scope

- 入力 source を特定する。
- Ticket source の場合は full context を取得する。
- User request source の場合は依頼文と会話 context から目的、対象、制約、受入基準を抽出する。
- codebase を調査して設計と task breakdown を作る。
- ユーザー承認を得る。
- 実装プランとユーザー向け情報ファイルを現在の AI agent に対応する plan directory の `<plan-id>/` 配下に保存する。
- 承認後、同一セッション継続か別セッション引き継ぎかを判断する。
- planning フェーズでは production code を編集しない。

## Resources

- `../ask-user-questions/SKILL.md`: Step 1 と Step 2 で、repo 調査では解けない open question をユーザーへ確認する直前に読む。
- `../ai-review/SKILL.md`: Step 5 でユーザーレビュー後の draft plan を独立レビューへ渡す直前に読む。
- `references/plan-template.md`: Step 7 で実装プランとユーザー向け情報ファイルを書く直前に読む。
- `../ai-review/references/test-selection-policy.md`: Step 2 でテスト方針と task の `test` を決める直前に読む。

## Hard constraints

- orchestrator は現在の AI agent で利用できる上位推論モデルを使う。満たせない、または確認できない場合は一度警告し、ユーザーが明示的にその trade-off を受け入れた場合だけ、その設定のまま続行する。
- Ticket source では ticket title と body と body 記載の各URL先をもとにplanを作る。
- Ticket source では comments、labels、linked issues / PRs、acceptance criteria を確認する。
- User request source では依頼文と会話 context を source of truth とし、実装に必要な前提と受入基準を実装プランに明記する。
- repo 調査では解けない open question の確認は `../ask-user-questions/SKILL.md` に従う。
- read-only planning が使える場合は、調査中に code を編集しない。
- ユーザー承認は plan 内容の承認であり、実装開始とセッション選択は Step 8 の判断に従う。
- 実装プランは、source やユーザー向け情報ファイルを再取得しなくても実装者が開始できる程度に self-contained にする。
- 発生可能性と影響に見合う事象だけを専用実装として計画する。低確率で単純なエラー処理で足りる事象は、専用実装の対象外とし、単純なエラー処理で対処する。
- AIレビュー、リスク・未解決の論点、スコープ外はユーザー向け情報ファイルに記録する。
- AIレビューの全 finding はユーザーへ提示し、項目ごとの採用または見送りの明示承認を得てから実装プランと task breakdown に反映する。
- planning AI は AIレビューの指摘に対する採否を単独で確定せず、ユーザーの判断が揃うまで実装プランを確定しない。
- 最終承認の履歴は保存ファイルに記録しない。
- planning 中に実装可否や受入基準を左右する不明点が見つかった場合は、推測で埋めずにユーザーへ確認する。
- ユーザーレビュー後、`../ai-review/SKILL.md` の plan review mode で、元の依頼内容とユーザー確認済みの意図を踏まえた最新の draft plan と task breakdown を別 AI でレビューする。
- 同一計画に対する2回目以降の AI review が必要なときは、再レビューの理由と対象を提示してユーザーの明示的な確認を得る。
- AI review 反映後に実装プランが変わった場合は、保存前に更新版をユーザーへ再提示して最終承認を得る。

## Workflow

### Step 0: Confirm model

- 自分の model を確認する。
- 上位推論モデルなら続行する。
- 満たせない、または確認できない場合は、planning quality への影響を伝えて一度警告する。ユーザーが明示的にその trade-off を受け入れた場合だけ、その設定のまま続行する。
- 使用 model を実装プランの header に記録する（弱い設定で続行した場合はその旨も記録する）。

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
source が薄い、矛盾している、または acceptance criteria が欠けている場合は、その gap をユーザー向け情報ファイルの `リスク・未解決の論点` に記録する予定として扱ってください。
その gap が plan の成否や実装範囲に影響する場合は、`../ask-user-questions/SKILL.md` を読んで、Step 2 の調査中または調査後すぐにユーザーへ確認してください。

### Step 2: Research and plan

read-only planning で codebase を調査してください。

テスト方針と task の `test` を決める前に `../ai-review/references/test-selection-policy.md` を読んでください。

- actual data flow を追う。
- models、services / interactions、controllers、serializers、GraphQL types、jobs、tests など、影響範囲を読む。
- exact file path を記録する。
- 既存 pattern と testing idiom を確認する。
- テストは `../ai-review/references/test-selection-policy.md` の対象に限り、DB・フレームワーク・ライブラリの標準保証だけを直接再検証する test を plan に含めない。
- migration、backward compatibility、permission / auth、N+1、background-job idempotency、API surface、i18n など、該当する edge を検討する。
- target repo が `app/interactions/`、`packs/`、`CLAUDE.md` / `AGENTS.md` の convention を持つ場合は、それを尊重する。

plan は、source や codebase を読んでいない session でも正しく実装できる粒度にしてください。
曖昧な plan は失敗です。
調査で実装に関わる不明点が見つかった場合は、`../ask-user-questions/SKILL.md` を読んで、draft plan を固め切る前にユーザーへ確認してください。

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

### Step 4: Present the draft plan and user information for review

独立AIレビューの前に、実装プランの要約、task breakdown、ユーザー向け情報の draft を画面に表示してレビューを求めてください。
この時点の `AIレビュー` は未実施であることを明記してください。
approval affordance がある環境では、それを使ってください。

- ユーザーが reject または feedback を返した場合は、feedback を spec として扱う。
- feedback が前提を変える場合は code を再調査する。
- feedback で plan または task breakdown が変わる場合は、更新版をもう一度ユーザーへ提示する。
- ユーザーレビュー完了後に AI review へ進む。

### Step 5: Run cross-AI planning review

ユーザーレビューが完了した draft plan に対して、`../ai-review/SKILL.md` を読み、plan review mode で AI review を実行してください。
同一計画に対する2回目以降の AI review では、再レビューの理由と対象、前回からの変更点を画面に表示してユーザーの明示的な確認を得てください。確認が得られない場合は再レビューを実行せず停止してください。
ai-review へ planner、元の依頼内容、ユーザー確認済みの意図、維持したい挙動、non-goal、draft plan、調査した path を渡してください。
ai-review は plan を編集せず、reviewer、信頼性判定、finding を返します。
planning AI は review 内容を確認し、各 finding の影響と対応案を整理してください。
各 finding の採用または見送りはユーザーへ提示して項目ごとに承認を得てください。
ユーザーが採用を承認した finding だけを plan と task breakdown へ反映し、見送りを承認した finding は理由とともにユーザー向け情報ファイルの `AIレビュー` に残してください。

- P1 または P2 で実装プランが実質的に変わる場合は、反映後の実装プランをユーザーへ再提示して最終承認を得る。

### Step 6: Get final approval after AI review

AI review 後の finding 一覧と各 finding の対応案を画面に表示し、項目ごとに採用または見送りの明示承認を得てください。
すべての finding の判断が揃ったら、採用承認済みの finding だけを反映した最終版の実装プラン要約、task breakdown、ユーザー向け情報を画面に表示して最終承認を得てください。
AI review の reviewer、主要 findings、planning AI の対応案、ユーザーの採否判断はユーザー向け情報の `AIレビュー` に記録してください。

- ユーザーが追加 feedback を返した場合は、feedback を spec として扱う。
- feedback が前提を変える場合は code を再調査する。
- feedback で plan または task breakdown が変わる場合は、必要に応じて Step 5 を再実行する。
- 最終承認されるまで plan を更新する。
- 承認後も実装は始めない。

### Step 7: Write the implementation plan and user information files

最終承認後、`references/plan-template.md` を読んで実装プランとユーザー向け情報ファイルを保存してください。

保存先とファイル名は `references/plan-template.md` の各 Path convention に従ってください。
`<YYYYMMDD>` は `TZ=Asia/Tokyo date +%Y%m%d` で取得してください。
Project が明確に別 convention を持つ場合は従い、保存先を報告してください。
保存後、ユーザー向け情報ファイルの全内容を画面に表示してください。

```bash
TZ=Asia/Tokyo date +%Y%m%d
```

### Step 8: Continue or hand off implementation

実装プランの保存後、同一セッションで実装を続けるか、別セッションへ引き継ぐかを判断してください。
デフォルトは同一セッションでの継続です。
別セッションを選ぶのは、そのほうがトークン効率と出力品質が上がると見込めるときだけです。

次のいずれかに当てはまる場合は、別セッションへ引き継いでください。

- planning でコンテキストを大きく消費した、または compaction / 要約が既に発生していて、残りコンテキストで実装まで通す余裕が乏しい。
- plan が大規模または high risk（タスク数が多い、touch するファイルが広い、risk 分類が high など）で、実装とレビューで残りコンテキストを超えると見込まれる。

同一セッションで続ける場合は、ユーザーに承認を得てください。
承認を得られた場合のみ `implement-plan` skill をこのセッションで起動し、保存した実装プランだけを contract として実装へ進んでください。

別セッションへ引き継ぐ場合は、このセッションでは実装せず、新しいセッションに貼り付ける self-contained な引き継ぎテキストを 1 つの fenced code block で提示してください。
特定 agent の CLI コマンドや起動ツールは使わないでください。

引き継ぎテキストには次を含めます。

- `implement-plan` スキルで実装する指示
- working directory
- absolute implementation-plan path
- source reference が ticket ではない場合は、source summary と plan-id

例:

```text
working directory: <repo>
implementation plan: <absolute-plan-file-path>
Implement this plan with the `implement-plan` skill.
```

選んだ経路とその理由を報告してください。
同一セッション継続を選んだ場合は、その旨と理由を報告してから `implement-plan` を起動してください。
別セッション引き継ぎを選んだ場合は、実装プランの保存先と引き継ぎテキストを提示したことを報告して停止してください。

## Report

日本語で次を報告してください。

- source summary
- plan の主要方針
- task breakdown の概要
- AI review の reviewer、planning AI の対応案、ユーザーの採否判断
- 保存した実装プランとユーザー向け情報ファイルの path
- 画面に表示したユーザー向け情報
- 選んだ経路（同一セッション継続 / 別セッション引き継ぎ）とその理由
- 同一セッション継続なら実装を続ける旨、別セッション引き継ぎなら引き継ぎテキストを提示して停止した旨
