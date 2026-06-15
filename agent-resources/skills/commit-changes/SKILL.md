---
name: commit-changes
description: >-
  未コミット差分を確認し、レビューしやすい粒度の論理コミットに分割して作成する。
  コミットしてほしいとき、PR 作成前に差分をコミットする必要があるとき、または implement-plan 完了後に create-pr / create-pr-followup へ渡す前に使う。
  例: 「コミットして」「変更をコミット」「commit」「PR 前にコミット」。
  push / PR 作成 / GitHub への書き戻しは行わない。
---

# commit-changes

検証済みの working tree を、1 つ以上の読みやすい local commit にまとめるスキルです。
このスキルは commit planning、staging、commit message だけを担当します。

## Scope

- local commit を作成する。
- 必要なら複数 commit に分割する。
- push、PR 作成、GitHub への書き込みは行わない。
- PR が必要な場合は、このスキルの後に `create-pr` または `create-pr-followup` を使う。

## Hard constraints

- default branch では commit しない。
- staging 前に `git status --short`、`git diff`、`git diff --staged` を確認する。
- unrelated な user change が混ざっていて安全に分けられない場合は停止して確認する。
- secrets、debug print、generated noise、無関係な file を commit に含めない。
- repo の commit message 言語、prefix、Conventional Commit 規約を優先する。
- ユーザーがこの turn で明示的に commit 許可を出していない場合は、commit plan を提示してから進める。

## Workflow

### Step 1: Inspect pending state

- 現在の branch を確認する。
- pending diff 全体を読む。
- staged diff がある場合も必ず読む。
- standalone invocation で lint / test コマンドが明らかな場合は、commit 前に実行する。
- pending diff がない場合は、commit するものがないと報告して停止する。

```bash
git branch --show-current
git status --short
git diff
git diff --staged
```

### Step 2: Plan logical commits

- review story が明確になる最小数の commit に分ける。
- reviewer が各 commit を単独で読んだときに、目的、影響範囲、検証ポイントを把握できる単位にする。
- reviewer が差分を追いやすい順序に並べる。
- implementation と docs、production code と test-only cleanup、実質的な generated output など、別 concern は分ける。
- semantic change と mechanical movement / formatting / generated update は、review noise を減らせる場合に分ける。
- 密結合した code と test は同じ commit に入れる。
- 1 つの behavior change を理解するために reviewer が複数 commit を往復する分割は避ける。
- file 単位、task checkbox 単位、小さすぎる edit 単位で機械的に分けない。
- 1 つの coherent concern なら 1 commit にする。

### Step 3: Stage and commit intentionally

各 commit ごとに staged diff を確認してください。

```bash
git add -p
git diff --staged
git commit
```

- `git add -p`、pathspec、またはその両方で意図的に stage する。
- 残りの diff 全体が次 commit に属すると明らかな場合だけ `git add -A` を使う。
- staged diff は non-empty で、単独で理解できる内容にする。
- staged diff を reviewer 目線で読み直し、別 commit の文脈なしに review できるか確認する。
- message は「何を」だけでなく「なぜ」が伝わるようにする。
- practical な範囲で各 commit を buildable / testable にする。

### Step 4: Report

日本語で次を報告してください。

- 作成した commit hash と subject。
- working tree が clean か dirty か。
- PR に進む場合は `create-pr` または `create-pr-followup` が次 step であること。

## Quick reference

| Step | Action | Command |
|------|--------|---------|
| 1 | Inspect pending diff | `git status --short` / `git diff` / `git diff --staged` |
| 2 | Plan logical commits | Read recent `git log`. |
| 3 | Commit intentionally | `git add -p` / `git diff --staged` / `git commit` |
| 4 | Report | Commit hashes and tree state. |
