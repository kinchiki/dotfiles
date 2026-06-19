---
name: implement-plan
description: >-
  承認済みの実装プランファイルを、新しいセッションで端から端まで実行する。
  feature branch を作成し、プランの `## タスク` をテスト込みで進め、lint / test を緑にする。
  リスクに応じた AI レビューを受け、commit-changes で論理コミットを作り、create-pr-followup で PR 作成後の CI と AI レビュー初回フォローまで進める。
  承認済みプランを渡されて実装を始めるときに使う。
  例: 「implement-plan スキルで実装して」「プランを実装して」
  ticket-to-plan がプランファイルを指す実装セッションを起動したときにも使う。
  これは ticket-to-plan → implement-plan → commit-changes → create-pr-followup パイプラインの実装フェーズである。
---

# implement-plan

Execute an approved plan end to end: branch, implement `## タスク` with tests, get lint/test green, run risk-based independent review, then hand off to commit-changes and create-pr-followup.
The approved plan is the contract. Do not re-plan unless implementation must leave `## スコープ外`.

## Resources

- `references/review-policy.md`: read only after lint/test is green and the actual diff is classified medium or high risk. Never load it for low risk.

## Load

Read the provided absolute plan file and the repo convention file (`CLAUDE.md` / `AGENTS.md`).
Extract only this execution state; do not summarize the full plan:
- goal: one line
- acceptance criteria: checklist ids
- unchecked tasks: id, deps, files, test, done_when, parallel
- scope_out: exact constraints
- lint/test commands (plan overrides the repo convention file)
- unresolved blocking risks

Use `## タスク` checkboxes as the only source of progress.

## Invariants

- If a planning or approval mode is active, exit with a one or two line execution outline only; do not re-present or re-discuss the plan.
- Do not work on the default branch.
- Only the orchestrator edits `## タスク` checkboxes.
- Do not leave `## スコープ外`; if a scope change is required, stop and explain why.
- Do not weaken, delete, or skip/pend tests.
- Use the most capable available model at the highest available reasoning effort for orchestration. Otherwise warn once before continuing, and proceed at a weaker setting only if the user explicitly accepts the trade-off.
- The lint/test fix loop is at most 3 rounds.

## Execute

1. Require a clean working tree except for plan file changes. Otherwise stop.
2. Create a feature branch from a clean tree: `git switch -c <type>/<plan-id>-<slug>`. Use `<type>` per repo convention; reuse the ticket branch if one already exists.
3. Implement unchecked tasks in dependency order. Prefer sequential.
4. Delegate to `task-implementer` workers only for ready tasks marked `parallel: yes` with disjoint `files`, and only at low/medium risk. Serialize everything else.
   - Worker brief: task name, intent, expected outcome, allowed file set, tests to add or update, local conventions.
   - Workers must not commit, create branches, or edit the plan file.
   - If a worker returns `status: blocked` or `needs-strong-implementer`, do not check the task off. Serialize it or ask the user.
5. Run targeted lint/test after a task only when it touches production code, changes behavior, is medium/high risk, or failures would be hard to localize later. Docs/copy/type-only tasks may be batched.
6. Mark a task `- [x]` only after its `test` and `done_when` pass.
7. Before review or handoff, run the relevant full lint/test suite. Fix failures and rerun, at most 3 rounds. If it still fails, stop and report the output.
8. After lint/test is green, classify the actual diff:
   - low: docs/comments/copy/tiny type/test/UI text/style → self-review only.
   - medium: normal feature/bugfix/UI behavior/API-adjacent → independent review once.
   - high: auth/billing/permissions/data deletion/migration/security/production data/broad refactor/unknown blast radius → independent review; after P1/P2 fixes, re-review once.
9. For medium/high only, read `references/review-policy.md` and run the independent reviewer. P1/P2 are blocking: fix, rerun lint/test, rerun review as required. Fix cheap P3; list skipped P3 in the PR body.
10. Finish only when all `## タスク` are checked, lint/test are green, and no blocking review finding remains.

## Report and hand off

Report in Japanese: 変更概要 / 主な変更ファイル / lint・test 最終結果 / risk 分類と AI review 結果 / 解決した blocking finding / 残した nit。
Then use `commit-changes` to create logical commits. After commit, use `create-pr-followup` for PR creation and the first follow-up.

## Stop conditions

Stop and report when:
- the plan is missing or ambiguous and the next unchecked task cannot be identified
- unrelated changes exist in the working tree
- an existing branch or ticket conflict cannot be resolved safely
- a scope change is required
- lint/test still fails after 3 fix rounds
- the required independent reviewer cannot run
- a blocking P1/P2 remains
