---
name: implement-plan
description: >-
  承認済みの実装プランファイルを、同一セッションの継続または新しいセッションで端から端まで実行する。
  feature branch を作成し、プランの `## タスク` をテスト込みで進め、lint / test を緑にする。
  リスクに応じた AI レビューを受け、commit-changes で論理コミットを作り、open-pr-followup で PR 作成後の CI と AI レビュー初回フォローまで進める。
  承認済みプランを渡されて実装を始めるときに使う。
  例: 「implement-plan スキルで実装して」「プランを実装して」
  ticket-to-plan がプランファイルを指す実装セッションを起動したときにも使う。
  これは ticket-to-plan → implement-plan → commit-changes → open-pr-followup パイプラインの実装フェーズである。
---

# implement-plan

承認済みプランを端から端まで実行する: feature branch を作成し、`## タスク` をテスト込みで実装し、lint / test を緑にし、risk に応じた独立レビューを受け、commit-changes と open-pr-followup へ引き継ぐ。
承認済みプランは contract である。`## スコープ外` に出る必要がない限り re-plan しない。
plan file に `## 動作確認` がある場合は、その指示も contract として扱う。

## Resources

- `references/review-policy.md`: lint / test が緑になり、実際の diff が medium または high risk に分類された後にだけ読む。low risk では読まない。
- `../create-verification/SKILL.md`: plan の `## 動作確認` が yes で、コミット前 verification の準備をする直前に読む。
- `../run-verification/SKILL.md`: plan の `## 動作確認` が yes で、コミット前 verification を実行する直前に読む。

## Hard constraints

- planning / approval mode が有効な場合は、1〜2行の実行 outline だけを示して終了し、plan を再提示・再議論しない。
- default branch では作業しない。
- `## タスク` のチェックボックスは orchestrator だけが編集し、進捗の唯一の source として使う。
- `## スコープ外` に出ない。scope change が必要な場合は停止して理由を説明する。
- test を弱める・削除する・skip / pending にしない。
- orchestration には top reasoning session（現在の AI agent で利用できる最上位推論モデル + 最大 reasoning / thinking 設定）を使う。満たせない、または確認できない場合は一度警告し、ユーザーが明示的にその trade-off を受け入れた場合だけ、弱い設定のまま続行する。
- lint / test の修正ループは最大 3 round。
- 次のいずれかに該当する場合は停止して報告する: plan が欠落・曖昧で次の未チェック task を特定できない / working tree に無関係な変更がある / 既存 branch や ticket の衝突を安全に解決できない / scope change が必要 / 3 round 経ても lint / test が失敗する / 明示的な同意後も必須の独立 reviewer が実行できない / blocking な P1 / P2 が残っている。

## Workflow

### Step 0: Load the plan and prepare the branch

- 指定された絶対パスの plan file と repo convention file（`CLAUDE.md` / `AGENTS.md`）を読む。
- plan 全体は要約せず、実行に必要な状態だけを抽出する。
  - goal: 1 行
  - acceptance criteria: checklist id
  - 未チェック task: id、depends_on、files、test、done_when、parallel
  - `## 動作確認`: 要否、対象、各確認ポイント、skip 承認ルール
  - `## スコープ外`: 具体的な制約
  - lint / test コマンド（plan が repo convention file より優先）
  - 未解決の blocking risk
- plan file の変更を除き、working tree が clean であることを要求する。そうでなければ停止する。
- clean な tree から feature branch を作る: `git switch -c <type>/<plan-id>-<slug>`。`<type>` は repo convention に従い、既存の ticket branch があれば再利用する。

### Step 1: Implement tasks in order

- 未チェック task を依存順に実装する。基本は sequential に進める。
- `parallel: yes` かつ `files` が重ならない ready な task で、かつ low・medium risk の場合に限り `task-implementer` worker へ委譲する。それ以外は serialize する。
  - worker brief には task 名、intent、期待する成果、許可された file set、追加・更新する test、local convention を含める。
  - worker は commit、branch 作成、plan file の編集を行わない。
  - worker が `status: blocked` または `needs-strong-implementer` を返した場合は、その task をチェックせず、serialize するかユーザーに確認する。

### Step 2: Run targeted checks and mark tasks done

- task が production code に触れる、挙動を変える、medium・high risk である、または後で失敗箇所の特定が難しくなる場合だけ、その task の後に targeted lint / test を実行する。docs / copy / type のみの task はまとめて実行してよい。
- task の `test` と `done_when` が通った場合だけ `- [x]` にする。

### Step 3: Run the full suite and classify risk

- review や引き継ぎの前に、該当する full lint / test suite を実行する。失敗した場合は修正して再実行し、最大 3 round までとする。それでも失敗する場合は停止して出力を報告する。
- plan の `## 動作確認` が yes の場合は、full lint / test が緑になった後、commit 前に `create-verification` で verification を生成または更新し、`run-verification` を実行するかスキップするかをユーザーに確認する。
- ユーザーが実行を選んだ場合は `run-verification` を進める。スキップを選んだ場合は、理由と承認を plan の運用記録として報告に残す。
- lint / test が緑になったら、実際の diff を分類する。
  - low: docs・comment・copy・軽微な type / test / UI 文言・style の変更 → self-review のみ。
  - medium: 通常の feature・bugfix・UI 挙動・API 隣接の変更 → 独立 review を 1 回。
  - high: auth・billing・permission・data 削除・migration・security・production data・広範な refactor・影響範囲不明 → 独立 review。P1 / P2 修正後にもう 1 回 re-review。

### Step 4: Run independent review for medium/high risk

- medium・high risk の場合だけ `references/review-policy.md` を読み、独立 reviewer を実行する。
- P1 / P2 は blocking として扱う。修正し、lint / test を再実行し、必要に応じて review も再実行する。
- 対応が安価な P3 は修正する。見送った P3 は PR body に列挙する。
- すべての `## タスク` がチェック済みで、lint / test が緑で、blocking な review finding が残っていない場合だけ完了とする。

## Report

日本語で報告: 変更概要 / 主な変更ファイル / lint・test 最終結果 / risk 分類と AI review 結果 / 解決した blocking finding / 残した nit。
その後 `commit-changes` で論理 commit を作る。commit 後、`open-pr-followup` で PR 作成と初回 follow-up を行う。
