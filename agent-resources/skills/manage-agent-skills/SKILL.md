---
name: manage-agent-skills
description: >-
  dotfiles リポジトリの agent-resources を作成、更新、整理するときに使う。
  SKILL.md 作成・編集ルールに従い、以下のディレクトリ構成を維持する。
    - agent-resources/skills 配下の実体と `.agents/skills` と `.claude/skills`
    - agent-resources/agents 配下の実体と `.agents/agents`、`.claude/agents`、`.codex/agents`
  例: 「新しいスキルを作って」「対応するスキルを更新して」
---

# manage-agent-skills

このリポジトリで agent skill を作成または更新するためのスキルです。
Skill 本体は `agent-resources/skills/` 配下に、Agent definition 本体は `agent-resources/agents/` 配下に置いてください。

## Scope

- `agent-resources/skills/<skill-name>/SKILL.md` を作成または更新する。
- Skill 実行時に参照資料が必要な場合は `agent-resources/skills/<skill-name>/references/`、再利用する補助コマンドが必要な場合は `agent-resources/skills/<skill-name>/scripts/`、画像・テンプレートなどの素材が必要な場合は `agent-resources/skills/<skill-name>/assets/` を追加する。
- UI metadata が必要な場合は `agent-resources/skills/<skill-name>/agents/openai.yaml` を作成または更新する。
- シンボリックリンクの作成・更新は Step 4 に従う。
- `agent-resources/skills/scripts/validate-agent-skills` で touched skill を検証する。

## Hard Constraints

- `SKILL.md` の Markdown 構造を壊さない。
- Frontmatter、headings、lists、tables、fenced code blocks を維持する。
- Normal paragraph は実用的な範囲で 1 sentence per line にする。
- Fenced code block の line break を維持する。
- List item は 1 item per line にする。
- Trigger conditions、scope、hard constraints、workflow、resources、expected output を見つけやすい場所に置く。
- Direct imperative language を使う。
- Positive instructions を優先する。
- Negative wording は hard prohibitions、safety boundaries、data-loss risks、formatting risks、non-negotiable constraints に限る。
- Conditional rule は `If X, do Y. Otherwise, do Z.` の形にする。
- Referenced files、scripts、assets は exact relative paths で書く。
- 参照リソースは、いつ読むべきかを明記する。
- `SKILL.md` は operational に保つ。
- Long examples、schemas、background information、reference material は separate files に移す。
- Task-specific、non-obvious、convention-specific guidance だけを含める。
- Single-use abstraction、speculative flexibility、不要な resource directory を追加しない。

## Workflow

### Step 1: Confirm scope

- Skill name と agent name は lowercase letters、digits、hyphens だけにする。
- Skill folder は `agent-resources/skills/<skill-name>/` にする。
- Agent definition folder は `agent-resources/agents/<agent-name>/` にする。
- User request が ambiguous な場合は、実装前に短く確認する。
- Existing skill または agent definition を更新する場合は、既存構造と style を読む。

### Step 2: Create or update the skill body

- New skill を作る場合は `skill-creator` の initializer を使う。
- `SKILL.md` frontmatter は原則 `name` と `description` だけにする。
- `description` には what the skill does と when to use it を含める。
- Body には trigger information を重複させず、実行時に必要な workflow と constraints を書く。
- Resources を作る場合は、`SKILL.md` から exact relative path で参照する。

### Step 3: Create or update agent definitions

Agent definition は `agent-resources/agents/<agent-name>/` に以下の 3 ファイルで構成する。

- `instructions.md` — AI 共通の実行指示。ツール非依存のロジック・制約・ワークフローを書く。
- `claude.md` — Claude Code 用定義。`instructions.md` を `@` で参照しつつ、Claude Code 固有の設定や指示を追加する。
- `codex.toml` — Codex 用定義。`instructions.md` を `instruction_file` で参照しつつ、Codex 固有の設定を TOML 形式で書く。

### Step 4: Create repository symlinks

#### Skill links

このリポジトリでは skill 実体を `agent-resources/skills/<skill-name>/` に置きます。
作成または更新した skill は、次のリンクで `.agents/` と `.claude/` の両方へ公開してください。

```bash
ln -sfn ../../agent-resources/skills/<skill-name> .agents/skills/<skill-name>
ln -sfn ../../agent-resources/skills/<skill-name> .claude/skills/<skill-name>
```

If a correct symlink already exists, leave it in place.
If the path exists but is not the intended symlink, stop and inspect it before replacing anything.

Verify links with:

```bash
ls -l .agents/skills/<skill-name> .claude/skills/<skill-name>
test -e .agents/skills/<skill-name>/SKILL.md
test -e .claude/skills/<skill-name>/SKILL.md
```

#### Agent definition links

このリポジトリでは agent definition 実体を `agent-resources/agents/<agent-name>/` に置きます。
作成または更新した agent definition は、次のリンクで `.agents/`、`.claude/`、`.codex/` へ公開してください。

```bash
ln -sfn ../../agent-resources/agents/<agent-name>/instructions.md .agents/agents/<agent-name>.md
ln -sfn ../../agent-resources/agents/<agent-name>/claude.md .claude/agents/<agent-name>.md
ln -sfn ../../agent-resources/agents/<agent-name>/codex.toml .codex/agents/<agent-name>.toml
```

If a correct symlink already exists, leave it in place.
If the path exists but is not the intended symlink, stop and inspect it before replacing anything.

Verify links with:

```bash
ls -l .agents/agents/<agent-name>.md .claude/agents/<agent-name>.md
test -e .agents/agents/<agent-name>.md
test -e .claude/agents/<agent-name>.md
test -e .codex/agents/<agent-name>.toml
```

### Step 5: Validate

After creating or updating skills, run the repository validator before finishing.
Prefer validating the current diff first.
Expand to wider checks only if needed.

```bash
agent-resources/skills/scripts/validate-agent-skills agent-resources/skills/<skill-name>
```

If validation reports issues in touched files, fix them and run the validator again.
If validation cannot be run, report why and state what was checked manually.
Agent definition changes currently have no dedicated validator.
For agent definitions, verify symlinks and read the linked files before finishing.

## Expected Output

- 変更した skill path を報告する。
- 変更した agent definition path を報告する。
- 作成または確認した symlink path を報告する。
- 実行した validator command と結果を報告する。
- Validation を省略した場合は理由を報告する。
