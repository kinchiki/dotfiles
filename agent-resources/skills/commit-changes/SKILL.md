---
name: commit-changes
description: >-
  未コミット差分を確認し、レビューしやすい粒度の論理コミットに分割して作成する。
  コミットしてほしいとき、PR 作成前に差分をコミットする必要があるとき、または implement-plan 完了後に create-pr / create-pr-followup へ渡す前に使う。
  例: 「コミットして」「変更をコミット」「commit」「PR 前にコミット」。
  push / PR 作成 / GitHub への書き戻しは行わない。
---

# commit-changes

Use this skill to turn a verified working tree into one or more readable local commits.
This skill owns only commit planning, staging, and commit messages.

## Language policy

- Keep UI-facing metadata, including the frontmatter `description`, in Japanese.
- Write commit messages in Japanese (repository language).
- Keep this `SKILL.md` body in English for shared reference across agents.
- Report results to the user in Japanese unless a more specific instruction overrides it.

## Scope

- Create local commits.
- Split changes into multiple commits when that makes the review easier.
- Do not push, create PRs, or write to GitHub.
- If a PR is needed, use `create-pr` or `create-pr-followup` after this skill.

## Hard constraints

- Do not commit on the default branch.
- Inspect `git status --short`, `git diff`, and `git diff --staged` before staging.
- If unrelated user changes are mixed in and cannot be separated safely, stop and ask.
- Keep secrets, debug prints, generated noise, and unrelated files out of commits.
- Follow the repository's commit message language, prefixes, and Conventional Commit rules.
- If the user has not explicitly authorized commits in this turn, present the commit plan before proceeding.

## Workflow

### Step 1: Inspect pending state

- Check the current branch.
- Read the full pending diff.
- Read the staged diff when one exists.
- If this is a standalone invocation and the lint / test commands are obvious, run them before committing.
- If there is no pending diff, report that there is nothing to commit and stop.

```bash
git branch --show-current
git status --short
git diff
git diff --staged
```

### Step 2: Plan logical commits

- Use the smallest number of commits that keeps the review story clear.
- Make each commit understandable on its own, including purpose, impact, and verification points.
- Order commits so the reviewer can follow the diff naturally.
- Split separate concerns such as implementation and docs, production code and test-only cleanup, or meaningful generated output.
- Split semantic changes from mechanical movement, formatting, or generated updates when doing so reduces review noise.
- Keep tightly coupled code and tests in the same commit.
- Avoid splits that force the reviewer to jump across multiple commits to understand one behavior change.
- Do not split mechanically by file, task checkbox, or tiny edit.
- Use one commit for one coherent concern.

### Step 3: Stage and commit intentionally

Inspect the staged diff for each commit.

```bash
git add -p
git diff --staged
git commit
```

- Stage intentionally with `git add -p`, pathspecs, or both.
- Use `git add -A` only when the entire remaining diff clearly belongs to the next commit.
- Make the staged diff non-empty and understandable on its own.
- Reread the staged diff from the reviewer's perspective and confirm that it can be reviewed without context from another commit.
- Write messages that communicate why the change exists, not just what changed.
- Write all commit messages in Japanese, using Conventional Commit format where applicable (e.g., `feat: 新機能説明`, `fix: バグ修正説明`, `refactor: リファクタリング説明`, `docs: ドキュメント更新`, `test: テスト追加`).
- Keep each commit buildable / testable where practical.

### Step 4: Report

Report the following in Japanese.

- Created commit hashes and subjects.
- Whether the working tree is clean or dirty.
- If moving to a PR, state that `create-pr` or `create-pr-followup` is the next step.
