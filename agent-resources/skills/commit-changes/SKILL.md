---
name: commit-changes
description: >-
  未コミット差分を確認し、レビューしやすく独立して理解・revert できる論理コミットに分割して作成する。
  複数の独立した関心事がある場合は原則として複数 commit に分け、全差分が同じ変更理由・検証単位・revert 単位を共有する場合だけ 1 commit にまとめる。
  「コミットして」「変更をコミット」「commit」、または implement-plan 完了後に open-pr / open-pr-followup へ渡す前に使う。
---

# commit-changes

working tree を、独立して理解・レビュー・revert できる local commit に変える。
commit 数の少なさより、各 commit の論理的な独立性を優先する。

## Rules

* default branch では commit しない。
* staging 前に branch、status、unstaged diff、staged diff を確認する。
* 無関係なユーザー変更、secrets、debug print、生成物の noise を含めない。安全に分離できない場合は停止する。
* ユーザーがこの turn で commit を明示的に許可していない場合は、実行前に commit plan を提示する。
* commit message は日本語で書き、repository の prefix / Conventional Commit ルールに従う。

## Workflow

### 1. Inspect

```bash
git branch --show-current
git status --short
git diff
git diff --staged
```

pending diff がなければ停止する。

### 2. Plan logical commits

まず diff を変更理由ごとの candidate concern に分け、その後で必要なものだけ結合する。

別 commit にする強いシグナル:

* 変更理由が異なる。
* semantic change と rename / move / formatting などの mechanical change が分離できる。
* behavior を変えない prerequisite refactor と behavior change が分離できる。
* 独立した component / module の変更で、片方だけ revert しても意味が通る。
* feature と無関係な docs / test cleanup / tooling / configuration が混在する。

同じ commit に保つ:

* 同じ挙動変更の production code と、その挙動を直接検証する test。
* 分割すると中間 commit が壊れる schema / migration / call site などの一体変更。
* source と、それから直接再生成される artifact で、別々に扱う意味が薄い場合。

1 commit にするのは、meaningful な全 hunk が同じ「なぜ」に答え、同じ検証単位・revert 単位を共有する場合だけにする。
2 つ目の自然な commit subject を書ける、または一部だけ revert する合理的なケースがあるなら再分割する。
「同じ依頼」「同じ branch」「変更量が小さい」は結合理由にしない。

staging 前に ordered plan を作る。

```text
1. <subject> — <intent> — <scope>
2. <subject> — <intent> — <scope>
```

### 3. Stage and commit one concern at a time

```bash
git add -p
git diff --staged
git commit
```

* pre-staged diff が複数 commit にまたがる場合は unstage して plan に従って restage する。
* `git add -A` は、remaining diff 全体が明らかに次の 1 commit に属する場合だけ使う。
* staged diff がその commit の intent だけを含むことを確認する。
* 各 commit を現実的な範囲で build / test 可能に保つ。
* commit 後に `git status --short` と remaining diff を確認し、残りを最後にまとめない。
* staging 中に新しい分割点を見つけたら plan を更新する。

### 4. Report

日本語で、作成した commit hash と subject、各 commit の intent、working tree の clean / dirty を報告する。
1 commit の場合は、全差分を分割しなかった理由を 1 行で示す。
