# GitHub Review Thread Commands

未解決のレビュー指摘を取得する Step 1 と、対応済みのインラインレビュースレッドへ返信して解決する Step 8 では、これらのコマンドを使う。
レビュー要約の本文は実装の入力としてだけ扱い、インラインスレッドへの返信や解決の対象にはしない。
取得、返信、解決、書き戻しのコマンド規約については、このファイルを正典として扱う。

## Fetch Review Threads

GraphQL の `reviewThreads` を主要な情報源として使う。
`isResolved == false` のスレッドだけを残し、GraphQL の `id` を後続の返信・解決ステップへ引き継ぐ。
`isOutdated` と `comments.nodes` の完全なペイロードは、トリアージの入力として保持する。

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
}' -F owner=OWNER -F repo=REPO -F pr=N --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

レビュー要約の本文は別に取得する。

```bash
gh pr view N --json reviews --jq '.reviews[] | select(.body != "") | {author:.author.login, state:.state, body:.body}'
```

## Reply To Implemented Threads

実装した修正を push した後にだけ返信する。
対応済みのインラインレビュースレッドにだけ返信する。
レビュー要約の本文には返信しない。
ユーザーが書き戻しを明示的に承認した場合を除き、`recommend-skip` のスレッドには返信しない。

```bash
gh api graphql -f query='
mutation($thread:ID!,$body:String!){
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$thread,body:$body}){
    comment{url}
  }
}' -F thread=THREAD_ID -f body='対応済み'
```

## Resolve Replied Threads

同じインラインスレッドへの返信 mutation が成功した後にだけ解決する。

```bash
gh api graphql -f query='
mutation($thread:ID!){
  resolveReviewThread(input:{threadId:$thread}){
    thread{id isResolved}
  }
}' -F thread=THREAD_ID
```
