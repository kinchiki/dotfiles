# GitHub Review Thread Commands

Use these commands in Step 1 to fetch unresolved review feedback and in Step 8 to reply and resolve implemented inline review threads.
Keep review summary bodies as implementation inputs only; they are not inline thread reply or resolve targets.

## Fetch Review Threads

Use GraphQL `reviewThreads` as the primary source and filter out resolved threads.

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

Fetch review summary bodies separately.

```bash
gh pr view N --json reviews --jq '.reviews[] | select(.body != "") | {author:.author.login, state:.state, body:.body}'
```

## Reply To Implemented Threads

Reply only after the implemented fix has been pushed and the commit URL is available.

```bash
gh api graphql -f query='
mutation($thread:ID!,$body:String!){
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$thread,body:$body}){
    comment{url}
  }
}' -F thread=THREAD_ID -f body='対応済み COMMIT_URL'
```

## Resolve Replied Threads

Resolve only after the reply mutation succeeds.

```bash
gh api graphql -f query='
mutation($thread:ID!){
  resolveReviewThread(input:{threadId:$thread}){
    thread{id isResolved}
  }
}' -F thread=THREAD_ID
```
