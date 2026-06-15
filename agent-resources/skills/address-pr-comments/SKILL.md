---
name: address-pr-comments
description: >-
  GitHub PR の未解決レビューコメントとレビュー本文を取得し、実コードを読んで must-fix / recommend-fix / recommend-skip にトリアージして修正する。
  bot コメントも対象にし、解決済みスレッドは除外する。
  must-fix は自動で進め、任意対応はユーザー確認後に実装する。
  PR のレビュー指摘を処理したいときに使う。
  例: 「PRのコメントに対応して」「レビュー対応」「PRの指摘を直して」「レビューを反映」。
  作業ツリーが緑になった時点で止め、commit / push / GitHub への返信や resolve は行わない。
---

# address-pr-comments

GitHub PR のレビュー指摘を、実コードに照らして直すスキルです。
コメント本文だけで判断せず、対象行と周辺コードを読んでから対応可否を決めてください。

## Scope

- 未解決の inline review thread と review summary body を扱う。
- `coderabbitai`、`copilot` などの bot コメントも扱う。
- 通常の PR conversation コメントは対象外にする。
- 通常コメントに実質的な指摘がある場合は、範囲を広げるかユーザーに確認する。
- 作業ツリーが green になったところで止める。
- commit、push、GitHub への返信、thread resolve は行わない。

## Hard constraints

- Orchestrator は可能なら最新 Opus を使う。
- Opus でない場合は、その旨を伝えて `/model opus` を推奨する。
- すべての判定で、対象コードの `file:line` を確認して引用する。
- dirty tree で別ブランチに切り替える必要がある場合は、stash や破棄をせずに確認する。
- test を弱める、削除する、skip / pending にする行為は禁止する。
- 3 回修正しても lint / test が通らない場合は停止して失敗内容を報告する。

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
        isResolved isOutdated
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

コメントが 5 件以上ある場合は、可能なら Opus の並列 sub-agent に分けて判定させ、最後に統合してください。

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

### Step 6: Report

日本語で次を報告してください。

- コメントごとの source / author、verdict、実施内容または見送り理由、変更ファイル。
- lint / test の最終状態。
- commit / push は未実施であること。
- GitHub への reply / resolve は未実施であること。
- 次に進める場合は `commit-changes` の後に `create-pr` を使うこと。

## Quick reference

| Step | Action | Notes |
|------|--------|-------|
| 0 | Resolve PR and branch | Clean tree before checkout. |
| 1 | Fetch review threads and reviews | Unresolved only, bots included. |
| 2 | Triage after reading code | Cite `file:line`. |
| 3 | Present and confirm | Start clear `must-fix` items. |
| 4 | Implement approved work | Parallelize only disjoint files. |
| 5 | Run lint / test | Cap fixes at 3 rounds. |
| 6 | Report | No commit, push, or GitHub writeback. |
