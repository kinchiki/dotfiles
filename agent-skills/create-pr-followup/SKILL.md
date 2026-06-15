---
name: create-pr-followup
description: >-
  PR を作成したあと一定時間待ち、GitHub Actions CI と PR に付いた AI レビュー / レビューコメントを確認し、既存スキルへ切り出して後追い対応する。
  PR 作成自体は create-pr を使い、CI 失敗は GitHub plugin の gh-fix-ci、レビューコメント対応は agent-skills の address-pr-comments（または GitHub plugin の gh-address-comments）を使う。
  例:
    「PR作って、CIとAIレビューまで見て」
    「PR作成後にレビュー指摘とCI失敗も対応して」
    「create-pr のあとしばらく待って後追いして」
  implement-plan / commit-changes 完了後に、PR作成だけで止めずにCI・AIレビューの初回フォローまで進めたいときに発火する。
---

# create-pr-followup

Create the PR, wait for the first round of automation and AI review, then route follow-up work to the existing specialist skills.
This skill is an orchestrator; do not duplicate the implementation logic owned by `create-pr`, `gh-fix-ci`, `address-pr-comments`, `commit-changes`, or `gh-address-comments`.

Flow: **create-pr → wait → inspect CI and AI review → split CI/comment work → verify → commit/push follow-up fixes if needed → report.**

## Step 0 — Confirm scope and prerequisites

- Confirm the user wants post-PR follow-up, not just PR creation.
- Confirm the working tree is clean or already ready for `create-pr`.
- If there are uncommitted changes, hand off to `commit-changes` first.
- Use `create-pr` for the initial push and PR creation.
- Treat every push and GitHub write as outward-facing, and keep the human confirmation checkpoints required by the child skills.

## Step 1 — Create and resolve the PR

Invoke the existing `create-pr` skill.
After it succeeds, resolve the PR URL, number, head branch, and base branch:

```bash
gh pr view --json number,url,headRefName,baseRefName,state,title
```

If `create-pr` fails or the PR cannot be resolved, stop and report the blocker.
Do not continue with CI or review follow-up without a concrete PR.

## Step 2 — Wait for automation and AI review

Use the wait interval requested by the user.
If the user did not specify one, wait 5 minutes before the first inspection.

```bash
sleep 300
```

After the first wait, poll at most 3 more times with 2 minutes between polls while checks are still queued/in progress or the expected AI review has not appeared.
Do not wait forever.
If no AI review appears after the wait budget, continue with CI inspection and report that no AI review was found yet.

## Step 3 — Inspect CI and review state

Inspect CI status first:

```bash
gh pr checks <pr-number-or-url>
```

- If all checks pass or are skipped, record that result.
- If GitHub Actions checks fail, route CI investigation and fixes to `gh-fix-ci`.
- If a failing check is external to GitHub Actions, report the URL and do not pretend `gh-fix-ci` can inspect it.

Inspect AI review and unresolved review comments next.
Prefer `address-pr-comments` because it already includes bot comments, unresolved GraphQL review threads, triage, parallel implementation, and local lint/test gating.
Use GitHub plugin `gh-address-comments` only if the local `address-pr-comments` skill is unavailable or the current environment provides only the plugin workflow.

## Step 4 — Split follow-up work into lanes

When both CI failures and unresolved actionable review comments exist, split the work into separate agents, sessions, or worktrees if the environment provides them.
Use one lane for CI with `gh-fix-ci` and one lane for review comments with `address-pr-comments` or `gh-address-comments`.

Parallelize only when the lanes can edit safely:

- Use separate git worktrees, separate sessions with isolated patches, or clearly disjoint file sets.
- Serialize the lanes if they touch overlapping files or the available tools share one working tree.
- Keep each lane scoped to its assigned failure or comment set.
- Respect child-skill approval points, especially `gh-fix-ci`'s requirement to summarize the root cause and get approval before editing.

If only one category has work, run only that specialist skill.
If neither category has work, skip to Step 7.

## Step 5 — Integrate and verify local follow-up fixes

Collect the outputs from the CI and review lanes.
If separate worktrees or sessions produced patches, integrate them one at a time and inspect the combined diff.

Run the relevant lint/test commands after integration.
If the child skills already ran them, still run the smallest combined check that proves the merged result is coherent.
Never weaken, skip, or delete tests to make the follow-up green.

## Step 6 — Commit and push follow-up fixes

If the follow-up work changed files, invoke `commit-changes` to create local commits.
After commits are created, push the current PR branch only after user confirmation:

```bash
git push
```

Do not call `create-pr` again for an already-open PR.
After pushing follow-up fixes, wait once more for CI and AI review using Step 2's defaults, then inspect again with Step 3.
Run at most 2 full follow-up cycles unless the user explicitly asks to keep iterating.

## Step 7 — Report

Report in Japanese:

- PR URL.
- CI status and any failing or external checks.
- AI review / unresolved comment status.
- Which specialist skills ran and what each changed.
- Final lint/test status.
- Whether follow-up commits were pushed.
- Any remaining items that need human action or another cycle.

End with a clear status: `完了`, `追加対応待ち`, or `ブロック中`.
