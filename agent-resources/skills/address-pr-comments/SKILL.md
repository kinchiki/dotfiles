---
name: address-pr-comments
description: >-
  GitHub PR の未解決レビューコメントとレビュー本文を取得し、実コードを読んで must-fix / recommend-fix / recommend-skip にトリアージして修正する。
  bot コメントも対象にし、解決済みスレッドは除外する。
  must-fix は自動で進め、任意対応はユーザー確認後に実装する。
  PR のレビュー指摘を処理したいときに使う。
  例: 「PRのコメントに対応して」「レビュー対応」「PRの指摘を直して」「レビューを反映」。
  対応実装後に commit / push し、対象レビューコメントへ対応済み reply を返して thread を resolve する。
---

# address-pr-comments

GitHub PR のレビュー指摘を、実コードに照らして直すスキルです。
コメント本文だけで判断せず、対象行と周辺コードを読んでから対応可否を決めてください。

## Scope

- 未解決の inline review thread と review summary body を扱う。
- `coderabbitai`、`copilot` などの bot コメントも扱う。
- 通常の PR conversation コメントは対象外にする。
- 通常コメントに実質的な指摘がある場合は、範囲を広げるかユーザーに確認する。
- 承認済み review 対応の実装、quality gate、local commit、push、対象 thread への reply、thread resolve まで扱う。
- Review summary body は実装対象に含めるが、inline thread ではないため reply / resolve の対象外にする。

## Hard constraints

- Orchestrator は top reasoning session（現在の AI agent で利用できる最上位推論モデル + 最大 reasoning / thinking 設定）を使い、そうでない場合はその旨を伝えて再実行を推奨する。
- すべての判定で、対象コードの `file:line` を確認して引用する。
- dirty tree で別ブランチに切り替える必要がある場合は、stash や破棄をせずに確認する。
- test を弱める、削除する、skip / pending にする行為は禁止する。
- 3 回修正しても lint / test が通らない場合は停止して失敗内容を報告する。
- GitHub writeback は、実装して push 済みの inline review thread だけに行う。
- `recommend-skip` の thread は、ユーザーが明示的に承認した場合だけ reply / resolve する。

## Workflow

### Step 0: Resolve the PR

- PR 番号、`owner/repo#123`、PR URL の順に優先して対象 PR を決める。
- 指定がなければ current branch の PR を使う。
- `owner`、`repo`、PR number を確定する。
- `git status --porcelain` を確認する。
- 既に対象 PR ブランチにいる場合はそのまま進める。
- 別ブランチなら clean tree のときだけ `gh pr checkout <n>` を実行する。

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
gh pr view <n-or-omit> --json number,headRefName,baseRefName,url,state,title
```

### Step 1: Fetch unresolved feedback

GraphQL の `reviewThreads` を主ソースにして、解決済み thread を除外してください。

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){ nodes{
        id isResolved isOutdated
        comments(first:50){ nodes{ databaseId path line originalLine diffHunk body author{login} } }
      }}
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=N
```

Review summary body も取得してください。

```bash
gh pr view N --json reviews --jq '.reviews[] | select(.body != "") | {author:.author.login, state:.state, body:.body}'
```

- `isResolved == false` の thread だけを対象にする。
- 1 つの unresolved thread を 1 つの論理コメントとして扱う。
- inline thread は GraphQL `id` を保持し、reply / resolve の対象 thread として後続 step に渡す。
- reply は判断材料として使う。
- `isOutdated` は triage の材料として残す。
- unresolved feedback が 0 件なら報告して停止する。

### Step 2: Triage each item

- 各コメントの `path` と `line` 周辺、`diffHunk`、関連する現行コードを読む。
- `isOutdated` が true か、現行コードがコメント内容と一致しない場合は skip 寄りに判断し、理由を書く。
- 各項目を必ず 1 つの bucket に分類する。

| Bucket | Meaning |
|--------|---------|
| `must-fix` | typo、事実誤認、実バグ、要件違反、build / test failure、security issue など、修正すべき明確な問題。 |
| `recommend-fix` | 妥当だが裁量のある改善。 |
| `recommend-skip` | outdated、誤指摘、範囲外、要件との衝突、主観的 preference、bot noise、対応済み。 |

各判定は次の形にしてください。

```text
{ id, source, author, summary, verdict, approach_or_reason, files_to_touch }
```

コメントが 5 件以上ある場合は、可能なら top reasoning session の parallel sub-agent に分けて判定させ、最後に統合してください。

### Step 3: Present and confirm

- `must-fix`、`recommend-fix`、`recommend-skip` の表をユーザーに出す。
- `must-fix` は同じ turn で着手する。
- `files_to_touch` が重ならない `must-fix` は、可能なら `task-implementer` sub-agent で並列に進める。
- `recommend-fix` と `recommend-skip` はユーザーに確認する。
- 確認用の質問ツールがある場合は使い、ない場合は番号付きの短い質問で確認する。

### Step 4: Implement approved work

- background の `must-fix` があれば完了を待つ。
- 承認された項目を実装する。
- `files_to_touch` が重ならない項目だけ並列化する。
- overlap がある項目は順番に実装する。
- 各 worker は割り当てられた files だけを編集し、必要な test を追加または更新する。
- worker は commit、branch 作成、push を行わない。

### Step 5: Run quality gate

- 対象 repo の lint / test コマンドを `CLAUDE.md` や既存設定から特定する。
- 失敗した場合は code を直して再実行する。
- 修正と再実行は最大 3 round にする。
- 最後に関連する full suite を 1 回通す。

### Step 6: Commit and push

- file change がある場合は `commit-changes` を使って local commit を作る。
- comment と commit の対応関係を記録する。
- 1 つの commit が複数コメントを直した場合は、各コメントに同じ commit URL を使う。
- 1 つのコメントに複数 commit が必要な場合は、そのコメントの修正を最も直接含む commit URL を使う。
- commit 後、current PR branch に push する。
- push 後に commit が PR 上で参照できることを確認する。

```bash
git push
```

Commit URL は PR URL に対する commit URL にしてください。

```text
<pr-url>/commits/<commit-sha>
```

### Step 7: Reply and resolve review threads

- 実装した inline review thread ごとに、対象 commit URL を含めて reply する。
- Reply body は `対応済み <当該PRコミットのURL>` の形にする。
- reply が成功した thread だけを resolve する。
- Review summary body 由来の項目は、reply / resolve 対象なしとして report に含める。

```bash
gh api graphql -f query='
mutation($thread:ID!,$body:String!){
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$thread,body:$body}){
    comment{url}
  }
}' -F thread=THREAD_ID -f body='対応済み COMMIT_URL'
```

```bash
gh api graphql -f query='
mutation($thread:ID!){
  resolveReviewThread(input:{threadId:$thread}){
    thread{id isResolved}
  }
}' -F thread=THREAD_ID
```

### Step 8: Report

日本語で次を報告してください。

- コメントごとの source / author、verdict、実施内容または見送り理由、変更ファイル。
- lint / test の最終状態。
- 作成した commit hash と push 結果。
- reply / resolve した inline thread。
- reply / resolve 対象外にした review summary body または skipped thread。
- 残件がある場合は、理由と次の action。

## Quick reference

| Step | Action | Notes |
|------|--------|-------|
| 0 | Resolve PR and branch | Clean tree before checkout. |
| 1 | Fetch review threads and reviews | Unresolved only, bots included. |
| 2 | Triage after reading code | Cite `file:line`. |
| 3 | Present and confirm | Start clear `must-fix` items. |
| 4 | Implement approved work | Parallelize only disjoint files. |
| 5 | Run lint / test | Cap fixes at 3 rounds. |
| 6 | Commit and push | Use `commit-changes`, then `git push`. |
| 7 | Reply and resolve | Reply `対応済み <commit-url>` before resolving. |
| 8 | Report | Include pushed commits and thread status. |
