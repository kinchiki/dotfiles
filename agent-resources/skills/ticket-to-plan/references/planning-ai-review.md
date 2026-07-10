# Planning AI Review Reference

Use this reference from `../SKILL.md` Step 5 after the user finished reviewing the draft plan and before the final approval request.
The goal is to improve the user-reviewed plan before final approval, not to approve the plan on the user's behalf.

## Contents

- Select the reviewer.
- Build the review packet.
- Run the reviewer.
- Handle findings.

## Select the reviewer

- If the user specified a reviewer AI, use that AI.
- If Claude Code created the draft plan, use Codex as the reviewer.
- If Codex created the draft plan, use Claude Code as the reviewer.
- If another AI created the draft plan, use a cost-effective independent reviewer that is different from the planner.
- If the requested or required reviewer is unavailable, stop before final approval and report the blocker.

## Select model and effort

Use cost-effective defaults for review.
Raise effort only when the plan involves auth, billing, permissions, data deletion, migration, security, production data, broad refactor, or unknown blast radius.
Prefer explicit environment overrides when the user or repo provides them.

- Codex reviewer default: `CODEX_REVIEW_MODEL=${CODEX_REVIEW_MODEL:-gpt-5.4}` and `CODEX_REVIEW_EFFORT=${CODEX_REVIEW_EFFORT:-medium}`. plain `codex exec` によるプラン文書レビューの default。`implement-plan` の diff review 専用モデル（`codex-auto-review`）とは意図的に別。
- Claude reviewer default: `CLAUDE_REVIEW_MODEL=${CLAUDE_REVIEW_MODEL:-sonnet}` and `CLAUDE_REVIEW_EFFORT=${CLAUDE_REVIEW_EFFORT:-medium}`.
- High-risk plan review default: set the selected reviewer effort env var to `high`.
- Use `xhigh` or `max` only when explicitly requested.

## Build the review packet

Pass only the context needed to evaluate the plan.
Include:

- Source kind and 3 to 6 line source summary.
- Original source reference or user request excerpt.
- User-reviewed intent changes, accepted behaviors, and explicit non-goals when the user clarified them during draft review.
- Draft plan, including goal, acceptance criteria, scoped approach, risks, and out-of-scope items.
- Draft `## タスク` breakdown with `files`, `depends_on`, `parallel`, `test`, and `done_when`.
- File paths and existing patterns the planner inspected.
- Assumptions, open questions, and known constraints.

Ask the reviewer to check:

- Missing requirements from the source.
- Whether the plan preserves explicit user intent and intentionally accepted behavior unless there is a concrete conflict with safety, data integrity, implementation feasibility, or repository constraints.
- For ticket sources, check comments, labels, linked issues / PRs, and acceptance criteria.
- For user request sources, check whether inferred assumptions and acceptance criteria are explicit enough for implementation.
- Missed affected files, data flow, auth / permission, background job, API, migration, or compatibility concerns.
- Task ordering, dependency, and `parallel: yes` safety.
- Test coverage, lint / test commands, and observable `done_when` conditions.
- Scope creep or unnecessary abstraction.
- Whether the plan is self-contained enough for a fresh implementation session.

Tell the reviewer to treat the original source and user-reviewed intent as the source of truth.
Tell the reviewer not to suggest changing behavior that the user explicitly asked to keep unless the finding cites a concrete risk such as security, data loss, implementation infeasibility, or a hard repository constraint.
Tell the reviewer to cite the relevant source excerpt, user-reviewed intent, or inspected codebase evidence for every P1 or P2 finding.

Ask the reviewer to return findings in this format:

```text
[P1] <blocking issue that would likely make implementation fail or violate requirements>
[P2] <important issue that should be addressed before final approval>
[P3] <nice-to-have improvement>
No findings
```

## Run the reviewer

Run every reviewer script below from this skill's own directory.
Use a read-only mode.
Tell the reviewer not to edit production code, skill files, or the plan file.
Write the review packet to `REVIEW_PROMPT_FILE` before running a reviewer script.
The review packet must already exist before script execution.
The reviewer scripts only run the selected reviewer; they do not select the reviewer, build the review packet, handle findings, or update the plan.
The reviewer scripts create their own fresh temporary directory for reviewer output and stderr.
If Claude Code is the selected reviewer, ask the user for explicit permission before sending the review packet.
Set `CLAUDE_REVIEW_CONSENT=yes` only after that permission is recorded.
If the run is blocked because consent has not been recorded yet, stop, obtain consent, set the variable, and rerun.

If Claude Code created the draft plan, use Codex as the reviewer:

```bash
REPO="<absolute repo path>"
REVIEW_PROMPT_FILE="<review packet file>"

scripts/run-codex-planning-review.sh \
  --repo "$REPO" \
  --prompt-file "$REVIEW_PROMPT_FILE"
```

If Codex created the draft plan, use Claude Code as the reviewer:

```bash
REPO="<absolute repo path>"
REVIEW_PROMPT_FILE="<review packet file>"

scripts/run-claude-planning-review.sh \
  --repo "$REPO" \
  --prompt-file "$REVIEW_PROMPT_FILE"
```

Use the common runner directly only as the low-level API:

```bash
scripts/run-planning-reviewer.sh \
  --repo "$REPO" \
  --reviewer codex \
  --prompt-file "$REVIEW_PROMPT_FILE"
```

If the current environment has a multi-agent or review tool that is more cost-effective and still uses the selected reviewer AI, use that tool instead.

## Handle findings

- Treat P1 and P2 findings as requiring either a plan update or an explicit planner rejection with rationale.
- Apply accepted findings to the draft plan and task breakdown before asking the user for final approval.
- If a finding changes assumptions or affected files, re-read the relevant ticket or code context before updating the plan.
- Address cheap P3 findings when they make the plan clearer.
- Record skipped P2 / P3 findings and the reason in `AIレビュー` or `リスク・未解決の論点`.
- If a P1 or P2 finding causes a material redesign, run the same reviewer once more on the updated draft.
- Present the reviewer, key findings, and planner disposition together with the final approval request.
