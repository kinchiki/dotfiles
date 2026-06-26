---
name: manage-agent-skills
description: >-
  dotfiles リポジトリの agent-resources で skill または agent definition を作成・更新・整理するときに使う。
  `agent-resources/skills` と `agent-resources/agents` を source of truth とし、`.agents`、`.claude`、`.codex` への公開 symlink と検証を維持する。
  例: 「新しいスキルを作って」「対応するスキルを更新して」「agentを追加して」
disable-model-invocation: true
---

# manage-agent-skills

このリポジトリで agent skill と agent definition を作成・更新する。

## Canonical paths

* Skill: `agent-resources/skills/<skill-name>/SKILL.md`
* Optional skill resources: `references/`, `scripts/`, `assets/`, `agents/openai.yaml`
* Agent definition: `agent-resources/agents/<agent-name>/instructions.md`, `CLAUDE.md`, `codex.toml`
* Public skill links: `.agents/skills`, `.claude/skills`
* Public agent links: `.agents/agents`, `.claude/agents`, `.codex/agents`

Use lowercase letters, digits, and hyphens only for `<skill-name>` and `<agent-name>`.

## Rules

* Preserve Markdown structure, YAML frontmatter, headings, lists, tables, fenced code blocks, and code-block line breaks.
* Keep normal paragraphs mostly one sentence per line and list items one item per line.
* Use direct imperative language, positive instructions, exact relative paths, and `If X, do Y. Otherwise, do Z.` conditionals.
* Use negative wording only for hard prohibitions, safety boundaries, data-loss risks, formatting risks, and non-negotiable constraints.
* Keep `SKILL.md` operational; move long examples, schemas, mappings, command conventions, background, and detailed rules into reference files.
* Keep each convention in one canonical location and avoid single-use abstractions, speculative flexibility, and unnecessary resource directories.
* Add shell scripts only as `scripts/*.sh`.
* Report shell or validator output as command, pass/fail, and required error lines only.

## Resources

* Read `references/repository-links.md` before creating or validating public symlinks.
* Use `scripts/maintain-skill.sh <skill-name>` for skill symlinks and validation.
* Use `scripts/maintain-agent-definition.sh <agent-name>` for agent definition symlinks.

## Workflow

### 1. Confirm scope

If the request is ambiguous, ask a short clarification before editing.
If updating existing content, read the current structure and style first.
If updating a skill, find related `SKILL.md` sections, references, scripts, and assets, then choose the canonical location before editing.

### 2. Create or update skill

If creating a new skill, use the `skill-creator` initializer.
Keep `SKILL.md` frontmatter to `name` and `description`.
Put what the skill does and when to use it in `description`.
Put runtime workflow, constraints, and resource usage in the body.
If work is repetitive and deterministic, move it into `scripts/` and run it.
If a resource is needed, create it under the skill and reference it from `SKILL.md` with an exact relative path.
If detail belongs in both `SKILL.md` and a reference file, keep the detail in the reference file and keep only read timing plus short instruction in `SKILL.md`.

### 3. Create or update agent definition

Create or update:

* `instructions.md`: shared tool-independent logic, constraints, and workflow.
* `CLAUDE.md`: Claude Code-specific settings; reference `instructions.md` with `@`.
* `codex.toml`: Codex-specific TOML config; reference `instructions.md` with `instruction_file`.

### 4. Link and validate

For a touched skill, run:

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-skill.sh <skill-name>
```

For a touched agent definition, run:

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-agent-definition.sh <agent-name>
```

If an existing public path is not the expected symlink, stop before replacing it and ask for confirmation.
If validation reports touched-file issues, fix them and rerun.
Agent definitions have no dedicated validator; run `maintain-agent-definition.sh` and read linked files before finishing.
If validation cannot run, report why and state what was checked manually.
Before finishing, review the diff for duplicated concepts, copied examples, and repeated path or command conventions.
If intentional duplication remains for standalone execution, report why.

## Expected output

Report changed skill paths, changed agent definition paths, created or verified symlink paths, script commands and results, validator commands and results, skipped validation reasons, and intentional duplication reasons.
