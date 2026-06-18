# Review policy

Load this only after lint/test is green and the actual diff is classified medium or high risk.
Never load it for low risk.

## Independence

- The reviewer must be independent from the AI session that implemented the change.
- Claude or non-Codex implementation: review with Codex CLI via `scripts/review-codex`.
- Codex or non-Claude implementation: review with Claude Code via `scripts/review-claude`.
- Never count the same agent's self-review as independent review.
- Pass only purpose, acceptance criteria, and special risks. Do not pass a long implementation narrative.
- If the required independent reviewer cannot run, stop and report `status: blocked`.

## Model and effort

- Codex code review default: `CODEX_REVIEW_MODEL=${CODEX_REVIEW_MODEL:-codex-auto-review}` and `CODEX_REVIEW_EFFORT=${CODEX_REVIEW_EFFORT:-medium}`.
- Claude code review default: `CLAUDE_REVIEW_MODEL=${CLAUDE_REVIEW_MODEL:-sonnet}` and `CLAUDE_REVIEW_EFFORT=${CLAUDE_REVIEW_EFFORT:-medium}`.
- Use `CODEX_REVIEW_EFFORT=high` or `CLAUDE_REVIEW_EFFORT=high` for high-risk diffs.
- Use `xhigh` or `max` only when explicitly requested.
- Environment variables override the defaults.

## Run

- Run from the repo root: `agent-resources/skills/implement-plan/scripts/review-codex` or `.../scripts/review-claude`.
- Each script reviews the uncommitted working tree, verifies the reviewer actually explored the diff, prints the review body, and reports a `TRUSTED` or `UNTRUSTED` verdict with a matching exit code.
- Trust a clean ("no findings") result only when the script reports `TRUSTED` and the output references the actual diff.
- If `UNTRUSTED`, rerun once. If still `UNTRUSTED`, stop and report the blocker.
- To review an already committed range instead of the working tree, adjust the range manually; this pipeline reviews pre-commit, so the working tree is the default.

## Findings

- Treat `[P1]` and `[P2]` as blocking. Fix them, rerun lint/test, then rerun the independent review once.
- For linter-backed findings, the repo linter is the source of truth; confirm with it before treating a finding as blocking.
- Judge line length on multibyte text such as Japanese by the linter result, not byte counts. If the linter is green, record it as a false positive and leave the code unchanged.
- Fix cheap `[P3]` findings. List skipped `[P3]` findings in the PR body.
- Run a third review only for high risk changes or genuinely ambiguous remaining P1/P2.
- Separately confirm the implementation meets the plan's `## 受入基準`.
