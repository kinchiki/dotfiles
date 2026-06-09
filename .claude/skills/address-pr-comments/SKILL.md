---
name: address-pr-comments
description: >-
  Triage a GitHub PR's review comments with the strongest model reading the actual code, then fix
  them in parallel. Fetches unresolved review comments + review bodies (bots included, resolved
  threads excluded), judges each as must-fix / recommend-fix / recommend-skip, auto-starts the
  must-fix set while asking the user about the discretionary ones, implements approved items in
  parallel via the task-implementer worker (Sonnet), and drives lint/test to green. Triggers when
  the user wants PR review feedback handled — e.g. "PRのコメントに対応して", "レビュー指摘を直して",
  "このPRの指摘を処理して", "PR #123 のレビューを反映して", "address the PR review comments". It stops
  at a green working tree — it does NOT commit, push, or write back to GitHub.
---

# address-pr-comments

Take a PR's review feedback and turn it into fixes — without missing the obvious must-fixes (typos,
real bugs, requirement violations) and without dutifully "fixing" comments that are outdated or
wrong. The strongest model reads the **actual code** each comment points at before deciding, the
clear must-fixes proceed on their own, and the judgment calls go back to you.

This skill reuses the team's existing machinery: parallel implementation runs through the
`task-implementer` sub-agent (the same worker `implement-plan` uses), the quality gate mirrors
`implement-plan`'s lint/test loop, and anything outward-facing (commit / push / PR) is left to
`create-pr`. It stops at a green working tree and reports — it never commits, pushes, or posts back
to GitHub.

Flow: **confirm model & resolve PR → fetch unresolved comments → judge each (read real code) →
present + auto-start must-fixes + confirm the rest → implement in parallel → lint/test to green →
report.**

## Step 0 — Confirm model and resolve the PR

- **Model.** Judgment is the heart of this skill, so the orchestrator should be the latest **Opus**.
  Check your own model; if you are not on Opus, say so and recommend `/model opus`. (Parallel
  implementation workers run on Sonnet — see Step 4 — so only the orchestrator needs Opus.)
- **Resolve the target PR.** Priority: an argument (PR number, `owner/repo#123`, or a PR URL). If
  none is given, use the current branch's PR. Derive `owner`, `repo`, and the PR number — you need
  all three for the GraphQL query in Step 1:

  ```bash
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)   # owner/repo (or take from a URL arg)
  gh pr view <n-or-omit> --json number,headRefName,baseRefName,url,state,title
  ```

- **Check out the PR branch from a clean tree.** Run `git status --porcelain`. If you're already on
  the target PR's branch (e.g. straight after `implement-plan`), stay put. Otherwise `gh pr checkout
  <n>`. If the tree is **dirty and you're on a different branch**, stop and ask — don't stash or
  discard someone's work.

## Step 1 — Fetch the comments (unresolved only, bots included)

Inline review comments carry their resolution state only via GraphQL, so that is the primary source:

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

- **Keep only threads where `isResolved == false`.** Each unresolved thread is one logical comment
  (use the first comment plus any replies as context). Note `isOutdated` for Step 2.
- **Also fetch review summary bodies** (the `CHANGES_REQUESTED` / `COMMENTED` text):

  ```bash
  gh pr view N --json reviews --jq '.reviews[] | select(.body != "") | {author:.author.login, state:.state, body:.body}'
  ```

- **Bots are in scope** — do not filter out `coderabbitai`, `copilot`, or similar authors. Pure
  conversation (issue) comments are **out of scope**; if the PR's substantive feedback is in plain
  PR comments, say so and offer to widen the scope rather than silently pulling them in.
- If there are no unresolved comments, report that and stop.

## Step 2 — Judge each comment (strongest model, max effort)

For every unresolved comment and review body, **do not judge from the comment text alone — read the
code it points at.** This is what "max effort" means here and it's how you catch comments that no
longer apply.

- Open the referenced code: `path` around `line` (Read), plus the `diffHunk` for context. If
  `isOutdated` is true, or the code no longer matches what the comment describes, lean toward skip
  and say why.
- Classify each into exactly one bucket:
  - **must-fix** (fixed without asking): typo · factual error · a real bug the comment correctly
    identifies · requirement violation · would error or fail to build · failing test · security
    issue.
  - **recommend-fix** (ask first, with a concrete approach): a valid improvement, but discretionary.
  - **recommend-skip** (ask first, with a reason): outdated / wrong / off-target comment ·
    out of scope · conflicts with the requirements · subjective preference · bot noise · already
    handled.
- For each, produce: `{ id, source (file:line or "review body"), author, summary, verdict,
  approach-or-reason, files_to_touch }`. **Every verdict must cite the `file:line`** it's about.
- **Scale with the comment count.** With many comments (~5+), fan out judgment to parallel
  sub-agents — one thread per agent, `model: "opus"` — each reading its referenced code and
  returning a structured verdict; then consolidate and de-duplicate. With only a few, judge inline.

## Step 3 — Present, auto-start the must-fixes, confirm the rest

Present a categorized table to the user: **must-fix** (will do now), **recommend-fix** (proposed
approach), **recommend-skip** (reason). Then, in the same turn:

- **Start the must-fix set immediately, in the background.** Group must-fix items into batches whose
  `files_to_touch` do not overlap, and spawn one `task-implementer` per item with the Agent tool:
  `subagent_type: "task-implementer"`, `model: "sonnet"`, `run_in_background: true`. This honors
  "必ず対応するものは進めておく" — the clear fixes run while the user is still deciding.
- **Confirm the discretionary items with `AskUserQuestion`.** If there are ≤4 of them, use a
  `multiSelect` question listing each recommend-fix / recommend-skip item so the user can flip any
  decision. If there are more than 4, present the numbered table and ask a coarse question instead
  ("proposalどおり対応 / 例外を指定する") — the tool allows at most 4 questions × 4 options, so don't
  try to cram one option per item.

If a recommend-skip would actually break things (you only flagged it skip because it's subjective),
say so plainly — the user's call still wins, but don't let a real defect ride out silently.

## Step 4 — Implement the approved set in parallel

- **Collect the background must-fix results** (they may still be running — wait for them).
- For the items the user approved, implement in parallel the same way `implement-plan` does:
  group by non-overlapping `files_to_touch`, spawn one `task-implementer` (`model: "sonnet"`) per
  item. Each worker edits **only its assigned files**, writes/updates the relevant tests, and
  returns a structured summary; workers don't commit or branch.
- **Serialize on overlap.** If an approved item touches a file a must-fix item already changed (or
  two approved items share files), run those sequentially — correctness beats parallelism. This is
  the same disjoint-files rule `implement-plan` Step 2 uses.

## Step 5 — Quality gate: lint + test until green

- Determine the target repo's lint/test commands from its `CLAUDE.md` (e.g. `dip rubocop`,
  `dip rspec`), the same way `implement-plan` does.
- Run them. If something fails, fix the **code** and re-run — up to **3 rounds**. If still failing
  after 3, **stop** and report with the failing output; don't loop forever.
- **Never** weaken, delete, skip, or `pending` a test to go green. If a test genuinely looks wrong,
  stop and ask.
- Run the full relevant suite once more so the whole change is green together.

## Step 6 — Report (no commit, no push, no GitHub writeback)

Give the user a Japanese summary table mapping each comment to its outcome:

- コメント（source / author）→ verdict → 実施内容 or 見送り理由 → 変更ファイル
- lint・test の最終状態

Then state the next step explicitly: **commit/push は未実施**（`create-pr` skill か手動で）、
**GitHub への返信・resolve もしていない**（報告のみ）。If the user wants to ship it, hand off to the
`create-pr` skill.

## Quick reference

| Step | Action | Notes |
|------|--------|-------|
| 0 | Confirm Opus, resolve PR, checkout | clean tree only; stay if already on the PR branch |
| 1 | Fetch via GraphQL `reviewThreads` + `gh pr view --json reviews` | unresolved only, bots in, issue comments out |
| 2 | Judge each — **read the real code** | must-fix / recommend-fix / recommend-skip; cite `file:line`; fan-out (Opus) at scale |
| 3 | Present + auto-start must-fixes (background) + confirm rest | `task-implementer` Sonnet, `run_in_background`; `AskUserQuestion` for discretionary |
| 4 | Implement approved set in parallel | disjoint files only; serialize overlaps |
| 5 | lint + test until green | cap 3 rounds; never weaken tests |
| 6 | Report (日本語表) | no commit/push/GitHub writeback; hand off to `create-pr` if wanted |
