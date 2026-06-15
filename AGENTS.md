# AGENTS.md

**あなたはユーザーに日本語で応答すること。**

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

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

## 5. SKILL.md Rule — Use Only When Creating or Editing Skills

Use this section only for Skill documentation files:
`**/SKILL.md`.

### Formatting

- Preserve valid Markdown structure: frontmatter, headings, lists, tables, and fenced code blocks.
- Use one sentence per line for normal paragraphs when practical.
- Wrap lines only at sentence boundaries.
- Keep fenced code block line breaks intact.
- Keep one list item per line.

### AI Readability

- Put trigger conditions, scope, hard constraints, workflow, resources, and expected output where they are easy to find.
- Use direct imperative language.
- Prefer positive instructions that state the desired behavior.
- Use negative wording only for hard prohibitions, safety boundaries, data-loss risks, formatting risks, or non-negotiable constraints.
- Write conditional rules as: `If X, do Y. Otherwise, do Z.`
- Use exact relative paths for referenced files, scripts, and assets.
- State when each referenced resource should be consulted.
- Keep `SKILL.md` operational. Move long examples, schemas, background information, and reference material into separate files.
- Include only task-specific, non-obvious, or convention-specific guidance.

### Validation

- After creating or updating skills, run the repository validators before finishing.
- Prefer validating the current diff first (files changed in this task), then expand to wider checks only if needed.
- If a validator exists for agent skills (for example `scripts/validate-agent-skills`), use it and fix reported issues in the touched files.
- If validation cannot be run, state why and what was checked manually.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
