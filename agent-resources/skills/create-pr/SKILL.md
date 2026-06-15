---
name: create-pr
description: >-
  コミット済みの現在ブランチを push して GitHub PR を作成する。
  PR を開きたいとき、または implement-plan / commit-changes 完了後の PR 作成引き継ぎで使う。
  例: 「PR作成」「PR作って」「プルリク」。
  未コミット差分がある場合は commit-changes に引き渡す。
  push / gh pr create は外向きの操作なので、実行前にユーザー確認を取る。
---

# create-pr

既に commit 済みの branch を push し、チームの期待に沿った pull request を作るスキルです。
`ticket-to-plan` → `implement-plan` → `commit-changes` → `create-pr` の最後の段階として使えます。

## Scope

- 現在 branch を remote に push する。
- GitHub PR を作成する。
- PR URL を報告する。
- stage、commit、amend、rebase、commit grouping は行わない。
- 未コミット差分がある場合は `commit-changes` に引き渡す。

## Hard constraints

- repo 固有の PR skill や PR template がある場合は、それを優先する。
- default branch から PR を作らない。
- working tree が dirty の場合は停止する。
- push と `gh pr create` の前にユーザー確認を取る。
- PR assignee には必ず `kinchiki` を指定する。

## Workflow

### Step 0: Prefer project conventions

- `.claude/skills/create-pr/local.SKILL.md` など、repo 固有の PR skill があるか確認する。
- `.github/pull_request_template.md` がある場合は、その template を使う。
- repo に明文化された convention がある場合は、この generic skill より優先する。

### Step 1: Sanity-check the branch

- 現在 branch が feature branch であることを確認する。
- working tree が clean であることを確認する。
- target base branch に対して ship する commit があることを確認する。
- standalone invocation で lint / test が未確認なら、publish 前に実行するかユーザーに確認する。

```bash
git branch --show-current
git status --short
```

### Step 2: Push and open the PR

ユーザー確認後に実行してください。

```bash
git push -u origin HEAD
gh pr create --base <default-branch> --title "<title>" --body "<body>" --assignee kinchiki
```

- Title は repo の通常言語に合わせて簡潔に書く。
- team が日本語で PR を書く場合は日本語にする。
- ticket key を title に含める convention がある場合は従う。
- Body は plan と ticket から生成する。
- `.github/pull_request_template.md` がある場合は、次の generic structure ではなく template を埋める。

Generic body structure:

```markdown
## チケット
<指定されたチケットの URL>

## 概要
<この PR で何を・なぜ変えたか（1〜3行）>

## 変更点
- <主要な変更を箇条書き>

## テスト
- lint: <コマンドと結果>
- test: <コマンドと結果>

## レビュー（AI）
- レビュー担当: <Claude Code実装時はCodex / Codex実装時はClaude Code / 低リスクskip>
- 解決済み blocking: <あれば>
- 残した nit: <あれば。なければ「なし」>
- レビュー方針: <低リスクskip / 独立AIレビュー1回 / P1-P2修正後の再レビュー など>

## 受入基準
- [x] <プランの Acceptance criteria を転記し、満たしたものをチェック>
```

### Step 3: Report

日本語で次を報告してください。

- PR URL。
- PR title。
- 何を publish したかの 1 行 recap。
- follow-up が必要なら `create-pr-followup` が次 step であること。

```bash
gh pr view --json url,title
```

## Quick reference

| Step | Action | Command |
|------|--------|---------|
| 0 | Prefer project conventions | Check local skill and PR template. |
| 1 | Confirm clean committed branch | `git status --short` |
| 2 | Push and open PR | `git push -u origin HEAD` / `gh pr create --assignee kinchiki` |
| 3 | Report PR URL | `gh pr view --json url,title` |
