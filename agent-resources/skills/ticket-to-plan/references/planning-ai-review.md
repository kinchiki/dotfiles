# Planning AI Review Reference

Use this reference from `../SKILL.md` Step 4 before asking the user to approve a draft plan.
The goal is to improve the plan before approval, not to approve the plan on the user's behalf.

## Contents

- Select the reviewer.
- Build the review packet.
- Run the reviewer.
- Handle findings.

## Select the reviewer

- If the user specified a reviewer AI, use that AI.
- If Claude Code created the draft plan, use Codex as the reviewer.
- If Codex created the draft plan, use Claude Code as the reviewer.
- If another AI created the draft plan, use the strongest available AI that is different from the planner.
- If the requested or required reviewer is unavailable, stop before user approval and report the blocker.

## Build the review packet

Pass only the context needed to evaluate the plan.
Include:

- Ticket source and 3 to 6 line ticket summary.
- Draft plan, including goal, acceptance criteria, scoped approach, risks, and out-of-scope items.
- Draft `## タスク` breakdown with `files`, `depends_on`, `parallel`, `test`, and `done_when`.
- File paths and existing patterns the planner inspected.
- Assumptions, open questions, and known constraints.

Ask the reviewer to check:

- Missing requirements from the ticket, comments, labels, linked issues / PRs, or acceptance criteria.
- Missed affected files, data flow, auth / permission, background job, API, migration, or compatibility concerns.
- Task ordering, dependency, and `parallel: yes` safety.
- Test coverage, lint / test commands, and observable `done_when` conditions.
- Scope creep or unnecessary abstraction.
- Whether the plan is self-contained enough for a fresh implementation session.

Ask the reviewer to return findings in this format:

```text
[P1] <blocking issue that would likely make implementation fail or violate requirements>
[P2] <important issue that should be addressed before user approval>
[P3] <nice-to-have improvement>
No findings
```

## Run the reviewer

Use read-only or plan mode.
Tell the reviewer not to edit production code, skill files, or the plan file.
Write the review packet to `REVIEW_PROMPT_FILE` before running either command.

If Claude Code created the draft plan, use Codex as the reviewer:

```bash
REPO="<absolute repo path>"
REVIEW_PROMPT_FILE="/tmp/planning-review-prompt.md"
CODEX_REVIEW_OUT="/tmp/planning-review-codex.md"
CODEX_REVIEW_EVENTS="/tmp/planning-review-codex.jsonl"
CODEX_REVIEW_ERR="/tmp/planning-review-codex.err"
: "${CODEX_REVIEW_MODEL:?Set CODEX_REVIEW_MODEL to the strongest Codex model available.}"

codex exec \
  --cd "$REPO" \
  --sandbox read-only \
  --model "$CODEX_REVIEW_MODEL" \
  --json \
  --output-last-message "$CODEX_REVIEW_OUT" \
  - < "$REVIEW_PROMPT_FILE" > "$CODEX_REVIEW_EVENTS" 2> "$CODEX_REVIEW_ERR"
```

If Codex created the draft plan, use Claude Code as the reviewer:

```bash
REPO="<absolute repo path>"
REVIEW_PROMPT_FILE="/tmp/planning-review-prompt.md"
CLAUDE_REVIEW_OUT="/tmp/planning-review-claude.md"
CLAUDE_REVIEW_ERR="/tmp/planning-review-claude.err"
: "${CLAUDE_REVIEW_MODEL:?Set CLAUDE_REVIEW_MODEL to the strongest Claude Code model available.}"

cd "$REPO"
claude -p \
  --permission-mode plan \
  --model "$CLAUDE_REVIEW_MODEL" \
  "標準入力の review packet を読み、ticket-to-plan の draft plan をレビューしてください。編集は禁止です。" \
  < "$REVIEW_PROMPT_FILE" > "$CLAUDE_REVIEW_OUT" 2> "$CLAUDE_REVIEW_ERR"
```

If the current environment has a multi-agent or review tool that is stronger and still uses the selected reviewer AI, use that tool instead.

## Handle findings

- Treat P1 and P2 findings as requiring either a plan update or an explicit planner rejection with rationale.
- Apply accepted findings to the draft plan and task breakdown before asking the user for approval.
- If a finding changes assumptions or affected files, re-read the relevant ticket or code context before updating the plan.
- Address cheap P3 findings when they make the plan clearer.
- Record skipped P2 / P3 findings and the reason in `事前AIレビュー` or `リスク・未解決の論点`.
- If a P1 or P2 finding causes a material redesign, run the same reviewer once more on the updated draft.
- Present the reviewer, key findings, and planner disposition together with the reviewed plan.
