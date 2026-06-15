---
name: create-pr
description: >-
  コミット済みの現在ブランチを push して GitHub PR を作成する。
  PR を開きたいときに発火する。
  例:
    「PR作成」
    「PR作って」
    「プルリク」
  または implement-plan / commit-changes 完了後の PR 作成引き継ぎ。
  未コミット差分がある場合は commit-changes に引き渡す。
  外向きの操作(push / gh pr create)は実行前に確認する。
---

# create-pr

Open a pull request for an already-committed branch, the way the team expects. This is the last leg of the ticket-to-plan → implement-plan → commit-changes → create-pr pipeline, but it also works standalone when the branch is already committed.

**Project conventions win.** If the current repo has its own PR skill (e.g.
`.claude/skills/create-pr/local.SKILL.md`) or a documented PR template/convention, follow that — it overrides this generic skill. Check for it first.

**Scope boundary.** This skill never stages, commits, amends, rebases, or decides commit grouping.
If the working tree has uncommitted changes, stop and hand off to `commit-changes`.

**These are outward-facing actions.** Pushing and opening a PR publish the work and notify people.
Confirm with the user before the push/PR step. (`git push` and `gh pr create` are permission-gated, so you'll be prompted there — that's the intended human checkpoint.)

## Step 1 — Sanity-check the branch

- Confirm you're on a feature branch, not the default branch (`git branch --show-current`).
- Confirm the working tree is clean:

  ```bash
  git status --short
  ```

  If there are uncommitted changes, do not stage or commit them. Stop and invoke `commit-changes`.
- Confirm the branch has commits to ship relative to the target base branch.
- Confirm lint/test are green. If this skill was called by `implement-plan`, they already are; if invoked standalone, run or ask for the relevant checks before publishing.

## Step 2 — Push and open the PR

After user confirmation:

```bash
git push -u origin HEAD
gh pr create --base <default-branch> --title "<title>" --body "<body>" --assignee kinchiki
```

- **Assignees:** 必ず `kinchiki` を指定する（`--assignee kinchiki`）。
- **Title:** concise, in the repo's usual language (日本語 if the team writes PRs in Japanese).
  Include the ticket key if that's the convention.
- **Body:** generate from the plan and ticket. Suggested structure (日本語):

  ```markdown
  ## issue
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

- If the repo has a `.github/pull_request_template.md`, fill that instead of the structure above.

## Step 3 — Report

Give the user the PR URL (`gh pr view --web` to open it) and a one-line recap. Done.

## Quick reference

| Step | Action | Command |
|------|--------|---------|
| 0 | Prefer project's own PR skill if present | (check `.claude/skills`) |
| 1 | Confirm committed clean branch | `git status --short` |
| 2 | Push + open PR (after confirm) | `git push -u origin HEAD` / `gh pr create --assignee kinchiki` |
| 3 | Report PR URL | `gh pr view --web` |
