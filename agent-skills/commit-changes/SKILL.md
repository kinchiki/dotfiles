---
name: commit-changes
description: >-
  未コミット差分を確認し、一般的に適切な粒度の論理コミットに分割して作成する。
  コミットしてほしいとき、PR 作成前に差分をコミットする必要があるとき、または implement-plan 完了後に create-pr へ渡す前のコミット作成で発火する。
  例:
    「コミットして」
    「変更をコミット」
    「commit」
    「PR 前にコミット」
  push / PR 作成 / GitHub への書き戻しは行わない。
---

# commit-changes

Turn a verified working tree into one or more clean local commits. This skill owns commit planning, staging, and commit messages only. It never pushes, opens PRs, or writes to GitHub; call `create-pr` after the branch is committed.

**Project conventions win.** Read recent `git log` before writing messages, and follow the repo's language, prefix, and Conventional Commit conventions if present.

## Step 1 — Sanity-check the change

- Confirm you're on a feature branch, not the default branch (`git branch --show-current`).
- Review the full pending state: `git status --short`, `git diff`, and `git diff --staged`.
- Make sure nothing unintended is included: secrets, debug prints, generated noise, or unrelated files. If unrelated user changes are mixed in and cannot be separated confidently, stop and ask.
- Confirm lint/test are green. If this skill was called by `implement-plan`, they already are; if invoked standalone and the right commands are obvious, run them before committing.

If there is no pending diff, report that there is nothing to commit and stop.

## Step 2 — Plan logical commits

Split the pending diff into the smallest number of commits that still tells a clear review story:

- Separate unrelated concerns, even if they came from the same task (e.g. implementation vs docs, production code vs test-only fixture cleanup, generated lockfile/vendor output when substantial).
- Keep tightly coupled code and its tests in the same commit when that is easier to review and bisect.
- Do not split mechanically by file, task checkbox, or tiny edit. Avoid commits that only make sense  when squashed with the next one.
- If the whole change is one coherent concern, use one commit.

Before committing, show the user the proposed commit plan unless the user already gave explicit permission to commit in this turn.

## Step 3 — Commit intentionally

For each planned commit:

```bash
git add -p
git diff --staged
git commit
```

- Use `git add -p`, pathspecs, or both. Stage intentionally; do not rely on `git add -A` unless the entire remaining diff belongs in the next commit.
- Inspect the staged diff before every commit. It must be non-empty and independently understandable.
- Write a message that follows repo convention and summarizes the *why*, not just the *what*.
- Prefer each commit to be buildable/testable when practical, but do not contort the history into artificial micro-commits.

## Step 4 — Report

Report the created commit hashes and subjects, and state whether the working tree is clean. If the user wants a PR, hand off to `create-pr`.

## Quick reference

| Step | Action | Command |
|------|--------|---------|
| 1 | Inspect pending diff | `git status --short` / `git diff` / `git diff --staged` |
| 2 | Plan logical commits | read `git log`, group by concern |
| 3 | Commit intentionally | `git add -p` / `git diff --staged` / `git commit` |
| 4 | Report | commit hashes + clean/dirty status |
