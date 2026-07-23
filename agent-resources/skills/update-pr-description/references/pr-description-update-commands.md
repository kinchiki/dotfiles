# PR Description Update Commands

対象 PR の特定、現在の本文の調査、確認済みの更新の適用には、これらのコマンドを使う。
`update-pr-description` における `gh pr view` と `gh pr edit` の使用方法については、このファイルを正典として扱う。

## Resolve The PR

明示的に指定された PR 識別子を優先する。
指定されていない場合は、現在の branch に対応する PR を特定する。

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
gh pr view <n-or-omit> --json number,url,title,body,headRefName,baseRefName,state
```

## Inspect Current Body

変更案を作成する前に、現在の本文を取得する。

```bash
gh pr view <n-or-omit> --json body -q .body
```

リポジトリがテンプレートを使っている可能性がある場合は、空のセクションを置き換える前に `.github/pull_request_template.md` または文書化されたローカル規約を調査する。

## Apply Confirmed Update

新しい本文を一時ファイルに書き込んでから PR を更新する。
ユーザーまたは呼び出し元の workflow が description の書き戻しを承認した後にだけ実行する。

```bash
gh pr edit <n-or-omit> --body-file BODY_FILE
```

編集後に本文を再取得し、永続化された内容が意図した更新と一致することを確認する。

```bash
gh pr view <n-or-omit> --json body -q .body
```
