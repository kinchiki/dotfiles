# Follow-up Workflow Details

Use this reference when executing Steps 0 through 5.
It holds command recipes and lane integration details so `SKILL.md` stays focused on orchestration.
Run every `scripts/` command below from this skill's own directory.

## Resolve PR Metadata

After `open-pr` succeeds, fetch the concrete PR identity.
Use the helper script first; it prints `PR_URL`, `PR_NUMBER`, `HEAD_REF`, and `BASE_REF` without waiting or collecting signals.

```bash
scripts/poll-pr-signals.sh --pr <pr-number-or-url-or-branch> --metadata-only
```

If the script cannot run, use the fallback command.

```bash
gh pr view --json number,url,headRefName,baseRefName,state,title
```

## Wait And Poll

Use the wait policy in `SKILL.md` Step 2.
Use the helper script first.

```bash
scripts/poll-pr-signals.sh --pr <pr-number-or-url-or-branch> --initial-wait-seconds 300 --poll-interval-seconds 180 --max-polls 3
```

The script prints a compact summary including `CHECKS_STATUS`, `CHECKS_FAIL_COUNT`, `CHECKS_PENDING_COUNT`, `UNRESOLVED_THREAD_COUNT`, and `AI_REVIEW_DETECTED`.
Use `--initial-wait-seconds` when the user specifies a custom wait interval.

If the script cannot run, use fallback commands.
The existing quick command example is:

```bash
sleep 300
```

Record whether AI review was detected within the wait budget.
If it is not detected, continue CI inspection and report the missing review signal.

## Inspect Checks

Inspect CI before review comments.

When available, use `poll-pr-signals.sh` output as the primary CI signal.
Use the command below as a fallback or to drill into specific check details.

```bash
gh pr checks <pr-number-or-url>
```

- Treat pass and skipped checks as recorded non-blocking states.
- `ci/circleci: test` is ignored and never delegated to `gh-fix-ci`; this check is excluded from all counts, pending waits, and failing check summaries.
- Delegate GitHub Actions failures to `gh-fix-ci`.
- Report failing external checks by URL when `gh-fix-ci` cannot inspect them.

## Integrate Follow-Up Lanes

- Split CI failure and actionable review comments into separate lanes.
- Delegate CI to `gh-fix-ci`.
- Delegate review comments to `address-pr-comments`, or to `gh-address-comments` when the local Skill is unavailable.
- If the review lane did not update the PR description itself, run `update-pr-description` as a separate lane before declaring writeback complete.
- Parallelize only with separate worktrees, separate sessions, or disjoint file sets.
- Serialize work in one working tree when files overlap.
- Each follow-up lane must obtain user confirmation before committing its fixes.
- If a review lane already committed, pushed, updated the PR description, replied, and resolved threads, record that result and do not repeat those side effects.

## Push Remaining Fixes

Use this only for remaining non-review-lane commits after `commit-changes` has created local commits and the user has confirmed push.

```bash
git push
```
