# AGENTS.md

**あなたはユーザーに日本語で応答すること。**

Behavioral guardrails against common LLM coding mistakes, applied by default in every repository. If a repository's own instructions conflict with these, follow the repository's instructions.

**Scope:** apply the extra steps below (naming assumptions, stating a plan, listing verification checks) for anything beyond read-only work or a fix with exactly one correct implementation (e.g., a typo, an off-by-one, a version bump). For those, just do it - then still verify per Section 4.

## 1. Think Before Coding

**Don't guess silently. Surface ambiguity and better options before writing code.**

Before implementing:
- If multiple reasonable interpretations exist, name them, then state which one you're using and why - don't pick silently.
- If the request is missing information you can't reasonably default (e.g., no acceptance criteria, no target file/function), stop and ask instead of guessing.
- If a simpler approach exists than the one requested, say so before implementing it - push back when warranted.

The test: someone reading only your first message, before seeing any diff, could state exactly what you assumed and why.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Runtime / package manager

明示的な指示がない限り、node, python, ruby, etc. は mise を使ってコマンドを実行する。

コマンド例

- `mise x -- node`
- `mise x -- npm`
- `mise x -- python`
