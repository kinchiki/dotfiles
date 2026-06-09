---
name: ticket-to-plan
description: >-
  Turn a GitHub or Linear ticket into a thoroughly-researched implementation plan, then hand
  implementation off to a separate session. Triggers whenever the user points at a ticket and
  wants a plan before coding — e.g. "plan ENG-1234", "このissueの実装プランを立てて",
  "github.com/foo/bar/issues/42 を読んでプランを作って", "このチケットから設計して別セッションで実装",
  or any time they reference an issue/PR/Linear ID and ask to design, scope, or plan the work
  rather than implement it immediately. Use it even when the user doesn't say the word "plan"
  but clearly wants the ticket understood and broken down before any code is written.
---

# ticket-to-plan

This skill takes one input — a reference to a GitHub or Linear ticket — and produces one durable
artifact: an implementation plan file that a *fresh* session can pick up and execute without
re-reading the ticket or re-discovering the codebase. Planning and implementation are split on
purpose: deep planning fills a context window with research, and starting implementation in a
clean session keeps that research from crowding out the actual coding work. It also lets the plan
be reviewed and committed before any change is made.

The flow is: **confirm model → read the ticket → plan (and break it into tasks) with max effort →
get the plan approved → write the plan file → spawn the implementation session.** Walk through the
steps in order.

## Step 0 — Confirm you are the right model

This skill asks for "the latest Opus, maximum effort." A skill cannot change the model that is
already running this session — that is fixed when the session starts. So check yourself:

- Look at your own model in the system prompt. If it is the latest Opus (e.g. `claude-opus-4-8`
  or newer), continue.
- If it is **not** Opus, stop and tell the user: planning quality depends heavily on the model,
  and they should switch with `/model opus` (or relaunch with Opus) and re-run this skill. Do not
  silently plan on a weaker model — that defeats the point of the request.

State which model you are running so the choice is visible, and record it in the plan file header
later (Step 4) for traceability.

## Step 1 — Read the ticket

Identify the source from the reference the user gave, then fetch the **full** context — not just
the title and body. Comments, labels, linked issues/PRs, and acceptance criteria often carry the
real requirements.

**GitHub** — recognized forms: a full URL (`https://github.com/owner/repo/issues/123` or
`/pull/123`), shorthand `owner/repo#123`, or a bare `#123` (use the current repo). Prefer the
`gh` CLI, which is reliable across machines:

```bash
gh issue view <number> --repo <owner/repo> --comments
gh pr view    <number> --repo <owner/repo> --comments
```

If `gh` is unavailable, fall back to the GitHub MCP read tools (`issue_read` / `pull_request_read`
/ `get_issue`). Search for them with ToolSearch (`select:` or keywords like `github issue`) since
they are deferred and their exact names vary by session.

**Linear** — recognized forms: an issue ID like `ENG-123` / `ABC-45`, or a Linear URL
(`https://linear.app/<team>/issue/ENG-123/...`). Use the Linear MCP tools — `get_issue` for the
issue and `list_comments` for discussion. Find them with ToolSearch (keywords `linear issue`,
`linear comments`). Also pull linked sub-issues, the parent, and the project/milestone if they
add requirements.

If the reference is ambiguous (could be either source, or no repo is implied), ask the user one
short clarifying question rather than guessing.

After fetching, write a 3–6 line summary back to the user so they can confirm you understood the
ticket before you spend effort planning. If the ticket is thin or contradictory, surface the gaps
now — those become open questions in the plan.

## Step 2 — Plan with maximum effort

Enter plan mode (read-only research) so you cannot accidentally edit while exploring. This is
where the "工数MAX" requirement lives — be genuinely thorough, not fast:

- **ultrathink.** Reason hard about the approach, alternatives, and failure modes before writing
  anything down.
- **Explore the codebase, don't assume it.** Trace the actual data flow: find the models,
  interactions/service objects, controllers, serializers, GraphQL types, jobs, and tests that
  this change touches. Read them. Note exact file paths — the implementing session will rely on
  them. (For this repo specifically, business logic lives in `app/interactions/`, modular code in
  `packs/`, and conventions are in `CLAUDE.md` — honor them.)
- **Find the seams.** Identify where the change plugs in, what existing patterns to mirror, and
  what must not break. Look at neighboring tests to learn the project's testing idioms.
- **Think about the edges.** Migrations, backward compatibility, permissions/auth, N+1s,
  background-job idempotency, multi-domain API surfaces, i18n — whatever applies.

The goal of this step is a plan detailed enough that someone who has *not* read the ticket or the
code could implement it correctly. Vague plans ("update the model, add a test") are a failure of
this step.

**Break the plan into tasks.** Decompose the design into an ordered task list the implementation
session can pick up directly. Give each task: the **files** it touches, its prerequisite tasks
(**depends_on**), whether it can run in **parallel**, the command(s) that **test** it, and a
**done_when** condition. A task may be marked `parallel: yes` only when its files don't overlap
with other tasks that could run at the same time — overlapping files force sequential execution.
This decomposition is written verbatim into the `## Tasks` section of the plan file (Step 4), and
it is part of what the user approves in Step 3.

## Step 3 — Present the plan and iterate until approved

Present the plan — **including the task breakdown** — with `ExitPlanMode` (find it via ToolSearch
if deferred). This gives the user the native approve / reject affordance and keeps the loop crisp.
The user is approving both the approach *and* how it is sliced into tasks, so make the `## Tasks`
list visible in what you present.

- If the user **rejects or gives feedback**, treat their comments as the spec. Stay in plan mode,
  revise — re-explore the code if the feedback reveals a wrong assumption — and present again.
- Repeat until the user **approves**. There is no iteration cap; quality of the approved plan
  matters more than speed.

Important: approval here means "the plan is good," **not** "start coding now in this session." Do
not begin implementing after approval. Continue to Step 4. (Say this plainly if the user seems to
expect immediate implementation — the whole point is to implement in a separate, clean session.)

## Step 4 — Write the plan file

Once approved, persist the plan so a fresh session can execute it cold.

**Location & naming** (create the directory if missing):

```
docs/plans/<YYYY-MM-DD>-<source>-<ticket-id>-<slug>.md
```

- `<YYYY-MM-DD>` — today's date. Get it from `date +%F` (do not guess).
- `<source>` — `gh` or `linear`.
- `<ticket-id>` — issue/PR number or Linear key (e.g. `1234`, `ENG-123`).
- `<slug>` — 3–5 word kebab-case summary from the title.

Example: `docs/plans/2026-06-08-linear-ENG-123-oauth-token-refresh.md`

Why `docs/plans/`: it is discoverable, lives beside the code, and can be committed so the team
(and the implementing session) shares one source of truth. If a project clearly uses a different
convention, follow that instead and tell the user where you put it.

**Use this template** — fill every section; omit one only if truly N/A and say why:

```markdown
# <Ticket title>

- **Ticket:** <full URL or ID>
- **Source:** GitHub | Linear
- **Planned by:** <model id, e.g. claude-opus-4-8>
- **Date:** <YYYY-MM-DD>
- **Status:** Approved — ready to implement

## Goal
<1–3 sentences: what done looks like, in plain terms.>

## Acceptance criteria
- [ ] <observable, testable outcomes — pulled from the ticket where possible>

## Context & affected code
<Key files/modules with paths and a one-line note on each, e.g.
`app/interactions/resources/foo.rb` — service object to extend.
Include the existing patterns to mirror so the implementer matches the codebase.>

## Tasks
<Ordered tasks. The implementation session updates these checkboxes as it progresses —
this file is the single source of truth for progress, so a fresh session can resume from it.
Only the orchestrator updates the checkboxes (parallel workers do not touch this file).>

- [ ] **T1** <task name>
  - files: `path/a.rb`, `path/b.rb`   # files this task touches (used for parallel-conflict detection)
  - depends_on: -                      # prerequisite task IDs, or - if none
  - parallel: no                       # yes only if `files` don't overlap with other concurrent tasks
  - test: `dip rspec spec/a_spec.rb`   # command(s) that verify this task
  - done_when: <observable completion condition>
- [ ] **T2** <task name>
  - files: `...`
  - depends_on: T1
  - parallel: yes
  - test: `...`
  - done_when: <...>

## Testing strategy
<Which specs to add/update, how to run them (e.g. `dip rspec spec/...`), edge cases to cover.
Name the lint command too (e.g. `dip rubocop`) so the implementation gate knows what to run.>

## Risks & open questions
<Things to watch, decisions deferred, anything the implementer should confirm.>

## Out of scope
<Explicitly what NOT to do, to stop scope creep in the implementation session.>
```

Keep the ticket summary in the file so the implementer doesn't have to re-fetch — but still link
the ticket so the source of truth stays reachable.

## Step 5 — Hand off to a separate implementation session

Spin off implementation as a background task so it runs in its own session and (typically) its own
worktree — isolated from this planning session's context.

Use the `spawn_task` tool with a **self-contained** prompt: the spawned session has no memory of
this conversation, so include the absolute plan-file path, the ticket reference, and the working
directory. The implementation session should drive the work with the **`implement-plan` skill**,
which owns the whole pipeline (feature branch → implement `## Tasks` with tests → lint/test gate →
Codex review → PR). Recommend the orchestrator run on **Opus**. Write the prompt in Japanese (the
user's preference) unless they indicate otherwise.

Suggested call:
- **title:** `<ticket-id> を実装` (imperative, < 60 chars)
- **tldr:** one plain-English line: implement the approved plan for this ticket.
- **prompt:** something like —
  > `<repo>` の実装タスクです。承認済みプランが `<absolute path to plan file>` にあります。
  > **`implement-plan` スキルを使って**実装してください（オーケストレーターは Opus 推奨）。
  > このスキルが、プラン読込 → feature ブランチ作成 → `## Tasks` を依存順に実装（テスト込み）→
  > lint / test を緑にする → Codex でレビュー → PR 作成、まで面倒を見ます。
  > 元チケット: `<URL/ID>`。プランから逸脱が必要になったら、勝手に進めず理由を添えて確認してください。

If `spawn_task` is **not** available in the session, fall back to printing the exact command for
the user to start a new session manually, e.g.:

```bash
cd <repo> && claude "プラン docs/plans/<file>.md を implement-plan スキルで実装して"
```

Then tell the user: the plan is saved at `<path>`, and the implementation task has been queued (or
give them the manual command). Stop there — do not implement in this session.

## Quick reference

| Step | Action | Key tool |
|------|--------|----------|
| 0 | Confirm latest Opus is running | (self-check) |
| 1 | Fetch full ticket context | `gh` CLI / GitHub MCP / Linear MCP |
| 2 | Deep plan + break into tasks, max effort | plan mode + ultrathink |
| 3 | Approve loop (plan + task breakdown) | `ExitPlanMode` |
| 4 | Write plan file (with `## Tasks`) | `docs/plans/<date>-<src>-<id>-<slug>.md` |
| 5 | Hand off implementation | `spawn_task` → `implement-plan` skill |
