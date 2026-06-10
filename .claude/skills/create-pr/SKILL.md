---
name: create-pr
description: >-
  現在の変更をコミットし、ブランチを push して GitHub PR を作成、チーム規約に従ってレビュアーを割り当てる。
  PR を開きたいときに発火する。
  例:
    「PR作成」
    「PR作って」
    「プルリク」
  または implement-plan スキル完了後の PR 作成引き継ぎ。
  外向きの操作( commit / push / gh pr create / レビュアー割当 )は実行前に確認する。
---

# create-pr

Open a pull request for the current branch's work, the way the team expects, and assign the right
reviewers. This is the last leg of the ticket-to-plan → implement-plan → create-pr pipeline, but it
also works standalone.

**Project conventions win.** If the current repo has its own PR skill (e.g.
`.claude/skills/create-pr/local.SKILL.md`) or a documented PR template/convention, follow that — it
overrides this generic skill. Check for it first.

**These are outward-facing actions.** Pushing and opening a PR publish the work and notify people.
So confirm with the user before the push/PR step, and never assign reviewers without showing the
candidates first. (`git push` and `gh pr create` are permission-gated, so you'll be prompted there —
that's the intended human checkpoint. `git commit` runs without a prompt, so it's on you to show the
diff and get the user's nod *before* committing.)

## Step 1 — Sanity-check the change

- Confirm you're on a feature branch, not the default branch (`git branch --show-current`).
- Review what will ship: `git status` and `git diff` (and `git diff --staged`). Make sure nothing
  unintended (secrets, debug prints, unrelated files) is included.
- Confirm lint/test are green. If this skill was called by `implement-plan`, they already are; if
  invoked standalone, run them now.

## Step 2 — Commit

Stage and commit with a message that follows the repo's convention (read recent `git log` to match
style and language). Summarize the *why*, not just the *what*.

```bash
git add -A
git commit
```

If the repo uses Conventional Commits or a ticket-prefix convention, match it. Keep the subject
short; put detail in the body.

## Step 3 — Push and open the PR

After user confirmation:

```bash
git push -u origin HEAD
gh pr create --base <default-branch> --title "<title>" --body "<body>"
```

- **Title:** concise, in the repo's usual language (日本語 if the team writes PRs in Japanese).
  Include the ticket key if that's the convention.
- **Body:** generate from the plan and ticket. Suggested structure (日本語):

  ```markdown
  ## 概要
  <この PR で何を・なぜ変えたか（1〜3行）>

  ## チケット
  <URL または ID（GitHub なら `Closes #123` で自動クローズ）>

  ## 変更点
  - <主要な変更を箇条書き>

  ## テスト
  - lint: <コマンドと結果>
  - test: <コマンドと結果>

  ## レビュー（Codex）
  - 解決済み blocking: <あれば>
  - 残した nit: <あれば。なければ「なし」>

  ## 受入基準
  - [x] <プランの Acceptance criteria を転記し、満たしたものをチェック>
  ```

- If the repo has a `.github/pull_request_template.md`, fill that instead of the structure above.

## Step 4 — Assign reviewers

Derive candidate reviewers, **present them to the user, and only assign after confirmation** — never
ping people unprompted.

Derivation order (use what's available):
1. **CODEOWNERS** — check `.github/CODEOWNERS`, `CODEOWNERS`, `docs/CODEOWNERS`. Owners matching the
   changed paths are the strongest signal.
2. **Recent authors of the touched files** — `git log --format='%an <%ae>' -n 20 -- <changed files>`
   surfaces who knows this code. Map to GitHub handles (e.g. via `gh`), skipping the PR author.
3. **Ticket assignee / stakeholders** — whoever is on the ticket.

Present 1–4 candidates with a one-line reason each, get the user's pick, then:

```bash
gh pr edit <pr-number> --add-reviewer <login1>,<login2>
# team handles: gh pr edit <pr-number> --add-reviewer <org>/<team>
```

(`gh` has `read:org`, so team-slug reviewers resolve.) If reviewer derivation is inconclusive, ask
the user who should review rather than guessing.

## Step 5 — Report

Give the user the PR URL (`gh pr view --web` to open it), the assigned reviewers, and a one-line
recap. Done.

## Quick reference

| Step | Action | Command |
|------|--------|---------|
| 0 | Prefer project's own PR skill if present | (check `.claude/skills`) |
| 1 | Inspect the change | `git status` / `git diff` |
| 2 | Commit (repo convention) | `git add -A && git commit` |
| 3 | Push + open PR (after confirm) | `git push -u origin HEAD` / `gh pr create` |
| 4 | Assign reviewers (after confirm) | `gh pr edit --add-reviewer` |
| 5 | Report PR URL + reviewers | `gh pr view --web` |
