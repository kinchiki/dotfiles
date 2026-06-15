---
name: create-pr-followup
description: >-
  PR 作成後に一定時間待ち、GitHub Actions CI と AI レビュー / レビューコメントを確認して、既存スキルへ切り出して後追い対応する。
  PR 作成は create-pr、CI 失敗は GitHub plugin の gh-fix-ci、レビューコメント対応は address-pr-comments または GitHub plugin の gh-address-comments を使う。
  例: 「PR作って、CIとAIレビューまで見て」「PR作成後にレビュー指摘とCI失敗も対応して」「create-pr のあとしばらく待って後追いして」。
  implement-plan / commit-changes 完了後に、PR 作成だけで止めずに CI と AI レビューの初回フォローまで進めたいときに使う。
---

# create-pr-followup

PR を作成し、初回の CI と AI レビューを待って、必要な follow-up を専門スキルに委譲する orchestrator です。
`create-pr`、`gh-fix-ci`、`address-pr-comments`、`commit-changes`、`gh-address-comments` が持つ実装ロジックを重複させないでください。

## Scope

- `create-pr` を使って PR を作る。
- 初回の CI と AI review / unresolved review comment を確認する。
- CI failure は `gh-fix-ci` に委譲する。
- review comment は `address-pr-comments` を優先し、必要に応じて `gh-address-comments` に委譲する。
- follow-up fix が発生した場合は `commit-changes` で commit し、ユーザー確認後に push する。
- 既に open している PR に対して `create-pr` を再実行しない。

## Hard constraints

- PR 作成だけを求められている場合は、このスキルを使わず `create-pr` で止める。
- uncommitted changes がある場合は、先に `commit-changes` に引き渡す。
- push や GitHub writeback は外向き操作として扱い、子スキルの確認ポイントを守る。
- CI / review follow-up は concrete PR が解決できた場合だけ進める。
- test を弱める、削除する、skip / pending にする行為は禁止する。
- follow-up cycle は最大 2 回にする。
- ユーザーが明示的に継続を求めた場合だけ 3 回目以降を行う。

## Workflow

### Step 0: Confirm scope and prerequisites

- ユーザーが post-PR follow-up を求めていることを確認する。
- working tree が clean か、`create-pr` に渡せる状態であることを確認する。
- uncommitted changes がある場合は `commit-changes` を使う。
- initial push と PR 作成は `create-pr` に委譲する。

### Step 1: Create and resolve the PR

- `create-pr` を実行する。
- 成功後に PR URL、number、head branch、base branch、state、title を取得する。
- PR が解決できない場合は停止して blocker を報告する。

```bash
gh pr view --json number,url,headRefName,baseRefName,state,title
```

### Step 2: Wait for automation and AI review

- ユーザー指定の wait interval があればそれを使う。
- 指定がなければ最初に 5 分待つ。
- checks が queued / in progress の間、または期待する AI review がまだ出ていない間は、3 分間隔で最大 3 回追加 poll する。
- AI review が wait budget 内に出ない場合は、CI inspection だけ続けて、AI review が未検出だったことを報告する。

```bash
sleep 300
```

### Step 3: Inspect CI and review state

CI を先に確認してください。

```bash
gh pr checks <pr-number-or-url>
```

- checks が pass または skipped なら結果を記録する。
- GitHub Actions check が fail している場合は `gh-fix-ci` に委譲する。
- GitHub Actions 以外の external check が fail している場合は URL を報告し、`gh-fix-ci` で inspect できると仮定しない。

次に AI review と unresolved review comment を確認してください。

- local `address-pr-comments` が使える場合は優先する。
- local skill が使えない場合、または plugin workflow しかない環境では `gh-address-comments` を使う。
- bot comment と unresolved GraphQL review thread を含める。

### Step 4: Split follow-up work into lanes

- CI failure と actionable review comment が両方ある場合は、別 lane に分ける。
- CI lane は `gh-fix-ci` に委譲する。
- review lane は `address-pr-comments` または `gh-address-comments` に委譲する。
- separate worktree、separate session、または disjoint file set がある場合だけ並列化する。
- 同じ working tree で files が重なる場合は serialize する。
- 子スキルの approval point を守る。
- 作業が片方だけなら、その専門スキルだけ実行する。
- どちらも作業がなければ Step 7 に進む。

### Step 5: Integrate and verify

- CI lane と review lane の出力を集める。
- separate worktree / session が patch を作った場合は、1 つずつ適用して combined diff を確認する。
- 子スキルが既に lint / test を実行していても、統合後に最小の combined check を実行する。

### Step 6: Commit and push follow-up fixes

- file change がある場合は `commit-changes` で local commit を作る。
- commit 後、ユーザー確認を取ってから current PR branch に push する。
- already-open PR に対して `create-pr` を再実行しない。
- push 後に Step 2 の default で再度待ち、Step 3 で確認する。

```bash
git push
```

### Step 7: Report

日本語で次を報告してください。

- PR URL。
- CI status と failing / external checks。
- AI review / unresolved comment status。
- 実行した専門スキルと、各スキルが変更した内容。
- 最終 lint / test status。
- follow-up commit を push したかどうか。
- human action または次 cycle が必要な残件。
- 最終 status: `完了`、`追加対応待ち`、または `ブロック中`。

## Quick reference

| Step | Action | Notes |
|------|--------|-------|
| 0 | Confirm follow-up scope | Hand dirty tree to `commit-changes`. |
| 1 | Create and resolve PR | Use `create-pr`. |
| 2 | Wait and poll | Default 5 min, then 3 polls. |
| 3 | Inspect CI and review | CI first, comments second. |
| 4 | Split lanes | Parallelize only isolated work. |
| 5 | Integrate and verify | Run combined check. |
| 6 | Commit and push fixes | Confirm before push. |
| 7 | Report | End with clear status. |
