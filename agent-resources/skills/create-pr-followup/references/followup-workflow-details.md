# Follow-up Workflow Details

Use this reference when executing Steps 1 through 6.
It holds command recipes and lane integration details so `SKILL.md` stays focused on orchestration.

## Resolve PR Metadata

After `create-pr` succeeds, fetch the concrete PR identity.

```bash
gh pr view --json number,url,headRefName,baseRefName,state,title
```

## Wait And Poll

Use the wait policy in `SKILL.md` Step 2.
The existing quick command example is:

```bash
sleep 300
```

Record whether AI review was detected within the wait budget.
If it is not detected, continue CI inspection and report the missing review signal.

## Inspect Checks

Inspect CI before review comments.

```bash
gh pr checks <pr-number-or-url>
```

- Treat pass and skipped checks as recorded non-blocking states.
- Delegate GitHub Actions failures to `gh-fix-ci`.
- Report failing external checks by URL when `gh-fix-ci` cannot inspect them.

## Integrate Follow-Up Lanes

- Split CI failure and actionable review comments into separate lanes.
- Delegate CI to `gh-fix-ci`.
- Delegate review comments to `address-pr-comments`, or to `gh-address-comments` when the local Skill is unavailable.
- Parallelize only with separate worktrees, separate sessions, or disjoint file sets.
- Serialize work in one working tree when files overlap.
- If a review lane already committed, pushed, updated the PR description, replied, and resolved threads, record that result and do not repeat those side effects.

## Push Remaining Fixes

Use this only for remaining non-review-lane commits after `commit-changes` has created local commits and the user has confirmed push.

```bash
git push
```
