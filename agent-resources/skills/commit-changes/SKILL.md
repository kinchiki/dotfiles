---
name: commit-changes
description: >-
  未コミット差分を確認し、レビューしやすい粒度の論理コミットに分割して作成する。
  コミットしてほしいとき、PR 作成前に差分をコミットする必要があるとき、または implement-plan 完了後に open-pr / open-pr-followup へ渡す前に使う。
  例: 「コミットして」「変更をコミット」「commit」「PR 前にコミット」。
  push / PR 作成 / GitHub への書き戻しは行わない。
---

# commit-changes

検証済みの working tree を、レビューしやすい 1 つ以上の local commit に変えるスキルです。
このスキルが担当するのは commit planning、staging、commit message の作成だけです。

## Scope

- local commit を作る。
- レビューしやすくなる場合は複数 commit に分割する。
- push、PR 作成、GitHub への書き戻しは行わない。
- PR が必要な場合は、このスキルの後に `open-pr` または `open-pr-followup` を使う。

## Hard constraints

- default branch では commit しない。
- staging 前に `git status --short`、`git diff`、`git diff --staged` を確認する。
- 無関係なユーザー変更が混在していて安全に分離できない場合は、停止して確認する。
- secrets、debug print、生成物の noise、無関係な file を commit に含めない。
- repository の commit message 言語、prefix、Conventional Commit ルールに従う。
- ユーザーがこの turn で commit を明示的に許可していない場合は、実行前に commit plan を提示する。

## Workflow

### Step 1: Inspect pending state

- 現在の branch を確認する。
- pending diff の全体を読む。
- staged diff がある場合はそれも読む。
- standalone invocation で lint / test コマンドが明らかな場合は、commit 前に実行する。
- pending diff がなければ、commit するものがない旨を報告して停止する。

```bash
git branch --show-current
git status --short
git diff
git diff --staged
```

### Step 2: Plan logical commits

- レビューの流れが明確に保てる範囲で、最小の commit 数にする。
- 各 commit を、目的・影響・検証ポイントを含めて単独で理解できるようにする。
- reviewer が diff を自然に追える順序にする。
- 実装と docs、production code と test 専用の cleanup、意味のある生成物など、関心事が別なら分割する。
- semantic な変更と、機械的な移動・formatting・生成物更新は、分けたほうが review noise が減る場合に分割する。
- 密結合な code と test は同じ commit にまとめる。
- 1 つの挙動変更を理解するために reviewer が複数 commit をまたぐ必要が出る分割は避ける。
- file 単位、task checkbox 単位、小さな edit 単位での機械的な分割はしない。
- 1 つの commit は 1 つの一貫した関心事にする。

### Step 3: Stage and commit intentionally

各 commit ごとに staged diff を確認してください。

```bash
git add -p
git diff --staged
git commit
```

- `git add -p`、pathspec、またはその両方で意図的に stage する。
- `git add -A` は、残り diff 全体が明らかに次の commit に属する場合だけ使う。
- staged diff を空でない状態にし、それ単独で理解できるようにする。
- reviewer の視点で staged diff を読み直し、他の commit の context なしにレビューできることを確認する。
- 何が変わったかだけでなく、なぜその変更が必要かが伝わる message を書く。
- commit message はすべて日本語で書き、該当する場合は Conventional Commit 形式を使う（例: `feat: 新機能説明`、`fix: バグ修正説明`、`refactor: リファクタリング説明`、`docs: ドキュメント更新`、`test: テスト追加`）。
- 現実的な範囲で、各 commit を build / test 可能な状態に保つ。

### Step 4: Report

日本語で次を報告してください。

- 作成した commit hash と subject。
- working tree が clean か dirty か。
- PR に進む場合は、次の step が `open-pr` または `open-pr-followup` であること。
