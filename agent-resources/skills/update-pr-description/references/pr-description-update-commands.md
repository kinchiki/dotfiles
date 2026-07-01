# PR Description Update Commands

Use these commands to resolve the target PR, inspect the current body, and apply a confirmed update.
Treat this file as the canonical source for `gh pr view` and `gh pr edit` usage in `update-pr-description`.

## Resolve The PR

Prefer an explicit PR identifier.
If none is given, resolve the PR for the current branch.

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
gh pr view <n-or-omit> --json number,url,title,body,headRefName,baseRefName,state
```

## Inspect Current Body

Fetch the current body before drafting changes.

```bash
gh pr view <n-or-omit> --json body -q .body
```

If the repository may use a template, inspect `.github/pull_request_template.md` or documented local conventions before replacing empty sections.

## Apply Confirmed Update

Write the new body into a temporary file, then update the PR.
Run this only after the user or calling workflow has approved description writeback.

```bash
gh pr edit <n-or-omit> --body-file BODY_FILE
```

Re-read the body after editing to confirm the persisted content matches the intended update.

```bash
gh pr view <n-or-omit> --json body -q .body
```
