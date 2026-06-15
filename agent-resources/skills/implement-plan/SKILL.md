---
name: implement-plan
description: >-
  承認済みの実装プランファイルを、新しいセッションで端から端まで実行する。
  feature branch を作成し、プランの `## タスク` をテスト込みで進め、lint / test を緑にする。
  リスクに応じた AI レビューを受け、commit-changes で論理コミットを作り、create-pr-followup で PR 作成後の CI と AI レビュー初回フォローまで進める。
  承認済みプランを渡されて実装を始めるときに使う。
  例: 「implement-plan スキルで実装して」「プラン .claude/plans/....md を実装して」「このプランを実装して」。
  ticket-to-plan がプランファイルを指す実装セッションを起動したときにも使う。
  これは ticket-to-plan → implement-plan → commit-changes → create-pr-followup パイプラインの実装フェーズである。
---

# implement-plan

承認済み plan file を読み、実装、検証、AI review、commit、PR follow-up まで進めるスキルです。
承認済み plan が契約なので、勝手に再計画せず、`## タスク` を進捗の単一の真実として扱ってください。

## Scope

- 承認済み plan file を実装する。
- feature branch を作る。
- `## タスク` を dependency order で進める。
- task ごとに必要な test を追加または更新する。
- lint / test を green にする。
- risk に応じて independent AI review を行う。
- 最後に `commit-changes` と `create-pr-followup` へ引き継ぐ。

## Resources

- `references/independent-ai-review.md`: Step 4 で medium / high risk の independent AI review が必要になったら読む。

## Hard constraints

- Plan mode が active なら、実装開始前に短い実行 outline だけで plan mode を抜ける。
- Plan mode 中に plan を再検証、再作成、書き換えしない。
- Orchestrator は top reasoning session（現在の AI agent で利用できる最上位推論モデル + 最大 reasoning / thinking 設定）を使い、そうでない場合はその旨を伝えて再実行を推奨する。
- ユーザーが弱い model または低い reasoning 設定で続行を明示した場合だけ、その trade-off を明記して進める。
- default branch では作業しない。
- `## タスク` checkbox を更新するのは orchestrator だけにする。
- parallel worker は plan file を編集しない。
- `## スコープ外` から逸脱しない。
- plan から逸脱が必要な場合は、理由を添えて停止し、ユーザーに確認する。
- test を弱める、削除する、skip / pending にする行為は禁止する。
- lint / test 修正 loop は最大 3 round にする。

## Workflow

### Step 0a: Exit plan mode if active

このスキルは execution phase です。
plan mode が active なら、1 から 2 行の実行 outline だけを出して plan mode を終了してください。

Example outline:

```text
承認済みプランを実行します: ブランチ作成 → タスク実装(+テスト) → lint/test → リスク別AIレビュー → commit-changes → create-pr-followup。
```

plan の内容を再提示したり、再議論したりしないでください。

### Step 0: Read the plan and repo conventions

- 渡された absolute path の plan file を読む。
- `## ゴール`、`## 受入基準`、`## 背景・影響するコード`、`## タスク`、`## テスト方針`、`## スコープ外` を確認する。
- `## タスク` checkbox を進捗管理の単一ソースにする。
- repo の `CLAUDE.md` を読み、convention と lint / test command を確認する。
- plan に command が書かれている場合は、それを優先する。
- plan file が missing、ambiguous、または一部 checked off の場合は、最初の unchecked task から再開できるか確認する。

### Step 1: Create a feature branch

clean tree から feature branch を作ってください。

```bash
git switch -c <type>/<ticket-id>-<slug>
```

- `<type>` は repo convention に合わせる。
- ticket 用 branch が既にある場合は確認する。
- plan file 以外の変更が working tree にある場合は、勝手に進めず確認する。
- `.claude/plans/**` が git-ignored の場合、その plan file は branch 作成を妨げない。

### Step 2: Implement tasks

- `## タスク` を dependency order で実装する。
- 各 task の `files` だけを中心に変更する。
- 各 task の `test` と `done_when` を満たす。
- task 完了後、orchestrator が checkbox を `- [x]` に変える。
- sequential execution を default にする。
- ready task が `parallel: yes` で、`files` が重ならない場合だけ parallel worker を使う。
- parallel worker には担当 task、触ってよい files、実装内容、追加または更新する test だけを渡す。
- parallel worker は commit、branch 作成、plan file 編集を行わない。
- files が重なる場合や dependency がある場合は serialize する。

### Step 3: Run quality gate

各 task または parallel batch の後に、対象範囲の lint / test を実行してください。

```bash
<lint command>
<test command>
```

- 失敗した場合は code を直して再実行する。
- 修正と再実行は最大 3 round にする。
- 3 round 後も失敗する場合は停止し、失敗 output を報告する。
- Step 4 の前に、関連する full suite をもう一度実行する。

### Step 4: Run risk-based AI review

lint / test が green になった後で、実 diff を見て risk を分類してください。

- Low risk: docs、comments、copy-only、small type / test fix、tiny UI text / styling。
  Self-review と green lint / test でよい。
- Medium risk: 通常の feature、small bug fix、UI behavior、API-adjacent change。
  Independent AI review を 1 回行う。
- High risk: auth、billing、permissions、data deletion、migration、security、production data、broad refactor、blast radius 不明。
  Independent AI review を 1 回行い、P1 / P2 修正後に最大 1 回 re-review する。

- `## リスク・未解決の論点` を参考にする。
- 最終判断は actual diff から行う。
- Medium / high risk の場合は `references/independent-ai-review.md` を読んで実行する。
- Claude Code 実装時は Codex に review させる。
- Codex 実装時は Claude Code に review させる。
- 同じ agent に自己レビューさせて independent review と呼ばない。
- P1 / P2 は blocking として修正する。
- P3 は cheap なものだけ直し、残す場合は PR body に書く。
- high risk または曖昧な P1 / P2 の確認が必要な場合だけ 3 回目の review を行う。

### Step 5: Report and hand off

finish line を確認してください。

- すべての `## タスク` が `- [x]` である。
- lint / test が green である。
- 必要な AI review の blocking finding が残っていない。

日本語で次を報告してください。

- 変更概要。
- 主な変更ファイル。
- lint / test の最終結果。
- risk 分類と AI review 結果。
- 解決した blocking finding。
- 残した nit。

その後、`commit-changes` を使って logical commit を作成してください。
commit 完了後、`create-pr-followup` を使って PR 作成と初回 follow-up を進めてください。

## Quick reference

| Step | Action | Notes |
|------|--------|-------|
| 0a | Exit plan mode if active | Approved plan is the contract. |
| 0 | Read plan and `CLAUDE.md` | `## タスク` is the progress source. |
| 1 | Create feature branch | Never work on default branch. |
| 2 | Implement tasks with tests | Parallelize only disjoint ready tasks. |
| 3 | Run lint / test | Cap fixes at 3 rounds. |
| 4 | Run AI review by risk | Read `references/independent-ai-review.md` for medium / high risk. |
| 5 | Report and hand off | Use `commit-changes`, then `create-pr-followup`. |
