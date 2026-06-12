---
name: implement-plan
description: >-
  承認済みの実装プランファイルを、新しいセッションで端から端まで実行する: feature ブランチを作成し、プランの `## タスク` をテストを書きながら進め、lint/test を緑にし、Codex（別の AI）から独立したコードレビューを受け、PR を開く。
  承認済みプランを渡されて実装を始めるときに発火する。
  例:
    「implement-plan スキルで実装して」
    「プラン .claude/plans/....md を実装して」
    「このプランを実装して」
  または ticket-to-plan スキルがプランファイルを指す実装セッションを起動したとき。
  これは ticket-to-plan → implement-plan → create-pr パイプラインの実装フェーズ。
---

# implement-plan

This skill drives a single approved plan to a finished PR, autonomously, in one session. It is the
back half of the pipeline: `ticket-to-plan` produced a plan file with a `## タスク` list; this skill
executes it, and calls `create-pr` at the end. Human checkpoints are deliberately minimal — the
approved plan is the contract. The session only stops when (a) a quality gate fails after its retry
budget, (b) the plan would have to be deviated from, or (c) it reaches the outward-facing PR step.

Flow: **(exit plan mode if active) → confirm model & read plan → branch → implement tasks (with
tests) → lint/test gate → Codex review → report → create-pr.**

## Step 0a — If plan mode is active, exit it immediately

This skill is the *execution* phase, and the plan you were handed is **already approved** — so plan
mode being active is a mode mismatch, not a signal to plan. Do **not** re-plan (no codebase
re-verification, no re-checking the acceptance criteria, no rewriting the plan).

Instead, call `ExitPlanMode` right away with a body that is **only a 1–2 line execution outline** —
e.g. "承認済みプランを実行します: ブランチ作成 → タスク実装(+テスト) → lint/test → Codex レビュー
→ create-pr." Do not restate or re-litigate the plan's contents. Once approved (plan mode lifted),
continue straight into Step 0 below. If plan mode is not active, skip this step and start at Step 0.

## Step 0 — Confirm model and read the plan

- **Model.** The orchestrator should be the latest **Opus** for implementation judgment. Check your
  own model; if you are not on Opus, say so and recommend `/model opus`. (Parallel sub-workers run
  on Sonnet — see Step 2 — so only the orchestrator needs Opus.) If the user explicitly wants to
  proceed on a weaker model, you may, but flag the trade-off.
- **Read the plan file** at the absolute path you were given. Internalize `## ゴール`,
  `## 受入基準`, `## 背景・影響するコード`, `## タスク`, `## テスト方針`, and
  `## スコープ外`. The `## タスク` checkboxes are your single source of truth for progress.
- **Read the repo's `CLAUDE.md`** and note the project's conventions and the exact lint/test
  commands (e.g. `dip rubocop`, `dip rspec`). If the plan names commands, prefer those.
- If the plan file is missing, ambiguous, or already partially checked off, resolve that first
  (resume from the first unchecked task; don't redo `- [x]` tasks).

## Step 1 — Create a feature branch

Work on a branch, never the default branch. From a clean tree:

```bash
git switch -c <type>/<ticket-id>-<slug>    # e.g. feat/ENG-123-oauth-token-refresh
```

`<type>` follows the repo's convention (`feat`/`fix`/`chore`…). If a branch already exists for this
ticket, or the working tree has changes **other than the plan file** (`.claude/plans/**` is
git-ignored, so it won't show in `git status` anyway), stop and ask rather than guessing. The plan
file the planning session left is expected — just carry it onto the new branch.

## Step 2 — Work through the tasks

Execute `## タスク` **in dependency order** (respect `depends_on`). For each task: implement the
change in the listed `files` **and write/extend its tests** per the plan's `## テスト方針`.
When a task is done, flip its checkbox to `- [x]` in the plan file. **Only you (the orchestrator)
edit the plan file** — this keeps progress consistent.

**Sequential is the default.** Run tasks one at a time unless a batch is clearly independent.

**Parallel batches.** When two or more ready tasks are `parallel: yes` *and* their `files` sets do
not overlap, run them concurrently to save wall-clock:

- Spawn one `task-implementer` sub-agent per task with the Agent tool, `subagent_type:
  "task-implementer"`, `model: "sonnet"`. Give each worker only its task: the files it may touch,
  what to implement, and which tests to add. Workers return a summary; **workers do not edit the
  plan file**.
- When the batch returns, you integrate the results, run that batch's tests, and flip the
  checkboxes together.
- If `files` overlap, or a task depends on another in the same batch, **fall back to sequential** —
  correctness beats parallelism.
- Reserve git worktrees for the rare case where parallel tasks genuinely cannot share a working
  tree (conflicting global state). The default — disjoint files in one tree — needs no merge.

**Guardrails.** Stay inside `## スコープ外`. If you discover the plan is wrong or incomplete and
must deviate, **stop and ask the user** with the reason — don't silently improvise.

## Step 3 — Quality gate: lint + test until green

After each task (and after each parallel batch), run the project's lint and test commands:

```bash
<lint command, e.g. dip rubocop>
<test command, e.g. dip rspec spec/...>
```

- If something fails, fix the **code** and re-run. Repeat up to **3 rounds**.
- If still failing after 3 rounds, **stop** and report to the user with the failing output — do not
  loop forever.
- **Never** weaken, delete, skip, or `pending` a test to make the suite pass. If a test genuinely
  looks wrong, stop and ask — don't "fix" it by gutting it.

Run the full relevant suite once more before Step 4 so the whole change is green together.

## Step 4 — Independent review with Codex (a different AI)

Get a second opinion from Codex on the **uncommitted** working tree (no commit needed yet — review
first, commit later). A one-line "no issues" result is only trustworthy if Codex actually had a
diff to read AND actually explored it — so confirm both before believing it (Step 4a below):

```bash
# `codex` is at ~/.local/bin/codex — add it to PATH first if it isn't already.
REVIEW_OUT="/tmp/codex-review.md"     # Codex's LAST message = the review body, tagged [P1]/[P2]/[P3]
REVIEW_JSON="/tmp/codex-review.jsonl" # structured event stream, used to VERIFY the run (Step 4a)

# --- 1. Confirm there is actually something to review (guards the silent no-op) ---
# `--uncommitted` reviews staged + unstaged + UNTRACKED, so the "is it empty?" check must include
# untracked files too — a tasks-added-new-files-only diff has an empty `git diff` but is NOT empty.
git status --short                                # log the full uncommitted picture (incl. untracked)
git diff --stat HEAD                              # and the tracked (staged+unstaged) size
# `--untracked-files=all` so a repo with `status.showUntrackedFiles=no` still reports new files.
PENDING="$(git status --porcelain --untracked-files=all)"  # non-empty ⇔ there IS something to review
# If PENDING is EMPTY, `--uncommitted` reviews nothing and Codex returns a vacuous one-liner
# ("No application code changes were present to review") that LOOKS like a clean pass.
#   → If the change is already committed, switch to RANGE=(--base "<default-branch>").
#   → If still empty, report "nothing to review" to the user and STOP — do NOT treat it as a pass.
# RANGE is an ARRAY: in zsh an unquoted scalar does NOT word-split, so RANGE="--base main" would
# reach codex as one bogus arg. An array + "${RANGE[@]}" passes each word correctly in zsh and bash.
RANGE=(--uncommitted)

# --- 2. Run with --json alongside -o (-o = human-readable last message; --json = verification) ---
# Clear stale outputs first: these are FIXED paths, so a PREVIOUS run's file must never be mistaken
# for this run's result (the bug that makes a failed review look like a clean pass).
rm -f "$REVIEW_OUT" "$REVIEW_JSON"
# Use `>|` not `>`: zsh here often has `noclobber` set, and this step re-runs up to 3 rounds, so a
# plain `>` to an existing file fails with "file exists" and the review silently never runs.
codex exec review "${RANGE[@]}" --json -o "$REVIEW_OUT" >| "$REVIEW_JSON" 2>| "${REVIEW_JSON%.jsonl}.err"
CODEX_RC=$?                                        # CAPTURE codex's status — do not let `echo` mask it
echo "Codex exit=$CODEX_RC ; last message -> $REVIEW_OUT ; events -> $REVIEW_JSON"
# If Codex itself failed (non-zero exit), DON'T read the (now-deleted or partial) output and DON'T
# treat it as a pass — go straight to the /code-review fallback below.
[ "$CODEX_RC" -ne 0 ] && echo "Codex FAILED (see ${REVIEW_JSON%.jsonl}.err) — use the /code-review fallback, do not trust output."

# NOTES on this command (learned the hard way / verified empirically):
# - A range selector (--uncommitted / --base / --commit) CANNOT be combined with a custom [PROMPT];
#   Codex errors out. So the review runs with Codex's built-in criteria — you judge acceptance below.
# - `-o` writes the agent's LAST MESSAGE. For `codex exec review` that last message IS the review
#   body, and findings appear there tagged [P1]/[P2]/[P3] — so reading $REVIEW_OUT does surface them.
#   It does NOT honor --output-schema, so don't expect JSON from -o — read the text.
# - The RAW stdout (without --json) is polluted with terminal/binary noise in codex 0.139.0
#   (multi-MB). To check the run programmatically, always use --json (clean JSONL); never parse raw stdout.
# - Use DETERMINISTIC paths (not $(mktemp) buried in a one-off command, which is lost to the next step).
```

### Step 4a — Verify the review is trustworthy *before* reading its verdict

A clean one-liner is worthless if Codex never saw the diff. **First confirm Codex actually
explored**, using `$REVIEW_JSON` (the count of `command_execution` items it ran):

```bash
# How many command events Codex emitted while reviewing (0 ⇒ it read nothing).
# NOTE: codex emits COMPACT json — no space after the colon — so the pattern must have no space.
# This counts both item.started + item.completed per command, so the value ≥ 1 simply means "explored".
grep -c '"type":"command_execution"' "$REVIEW_JSON"
```

- The final verdict is the `agent_message` item — same text as `$REVIEW_OUT`.
- **Trust rule:** a "no findings" (one-line) result counts as a PASS **only if** `CODEX_RC` was `0`,
  **the selected `RANGE` was non-empty**, **and** the `command_execution` count is **≥ 1**. ("Non-empty"
  is what step 1 established: for `--uncommitted` that's `PENDING`; for `--base <branch>` it's
  `git diff --quiet <branch>...HEAD` reporting changes — so a clean working tree is normal there, not
  a false pass.) If any of the three is missing, treat it as a **false pass / failed run**: re-check
  the range, re-run, and if it still won't review anything (or Codex keeps erroring), fall back to
  `/code-review` (and tell the user the review came from Claude, not Codex).

Once the run is verified, **Read `$REVIEW_OUT`** and act on it (it's markdown; Codex tags findings
`[P1]`/`[P2]`/`[P3]`):

- **Acceptance is your job, not Codex's.** The range flag blocks a custom prompt, so Codex uses
  default criteria. Separately confirm the change meets the plan's `## 受入基準`; treat an
  unmet criterion as blocking.
- Treat **`[P1]`/`[P2]`** findings as **blocking**: fix them, re-run **Step 3** (lint/test), then
  **re-run this Codex review**. Repeat up to **3 rounds**. If P1/P2 findings remain after 3 rounds,
  stop and report to the user.
- **`[P3]`** (minor) findings: address the cheap ones; otherwise list them in the PR body for the
  human reviewer.
- `codex exec review` is read-only (it won't edit your code). Use `--base <default-branch>` instead
  of `--uncommitted` once you've committed (same rule: no custom PROMPT alongside a range flag). The
  model is Codex's configured default; override with `-m <model>` only if asked.
- **Fallback** if `codex` is unavailable or errors out: run the built-in `/code-review` skill at
  `high` effort instead, and tell the user the review came from Claude, not Codex.

## Step 5 — Report, then hand off to create-pr

Confirm the finish line: every task is `- [x]`, lint/test is green, and there are no remaining
Codex blocking findings. Then give the user a short Japanese summary:

- 変更概要（何をしたか / 触ったファイル）
- テスト結果（lint・test の最終状態）
- Codex レビュー要約（解決した blocking、残した nit）

Then invoke the **`create-pr`** skill to commit, push, and open the PR. That skill owns the
outward-facing confirmation (commit / push / `gh pr create` are gated), so do not commit or push
here — let `create-pr` handle it.

## Quick reference

| Step | Action | Notes |
|------|--------|-------|
| 0 | Confirm Opus, read plan + CLAUDE.md | `## タスク` = progress source of truth |
| 1 | `git switch -c <type>/<id>-<slug>` | never the default branch |
| 2 | Implement tasks (+ tests), in dep order | parallel via `task-implementer` (Sonnet), disjoint files only |
| 3 | lint + test until green | cap 3 rounds; never weaken tests |
| 4 | `codex exec review "${RANGE[@]}" --json -o FILE` | guard empty range (else `--base`); verify `CODEX_RC`=0 ∧ `command_execution`≥1 before trusting; a 1-line "clean" passes only if range≠∅ ∧ explored; fix [P1]/[P2], cap 3 rounds; `/code-review` fallback |
| 5 | Report, then call `create-pr` | create-pr owns commit/push/PR confirmation |
