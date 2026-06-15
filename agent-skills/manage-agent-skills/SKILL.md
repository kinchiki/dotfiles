---
name: manage-agent-skills
description: >-
  dotfiles リポジトリの agent-skills を作成、更新、整理するときに使う。
  SKILL.md 作成・編集ルールに従い、agent-skills 配下の実体と .agents/skills および .claude/skills のシンボリックリンクを維持する。
  例: 「新しいスキルを作って」「SKILL.md を更新して」「AGENTS.md のスキル内容を移行して」「agent-skills のリンクを追加して」。
---

# manage-agent-skills

このリポジトリで agent skill を作成または更新するためのスキルです。
Skill 本体は `agent-skills/` 配下に置き、利用環境向けの公開リンクを `.agents/skills/` と `.claude/skills/` に作成してください。

## Scope

- `agent-skills/<skill-name>/SKILL.md` を作成または更新する。
- Skill 実行時に参照資料が必要な場合は `agent-skills/<skill-name>/references/`、再利用する補助コマンドが必要な場合は `agent-skills/<skill-name>/scripts/`、画像・テンプレートなどの素材が必要な場合は `agent-skills/<skill-name>/assets/` を追加する。
- UI metadata が必要な場合は `agent-skills/<skill-name>/agents/openai.yaml` を作成または更新する。
- `.agents/skills/<skill-name>` から `../../agent-skills/<skill-name>` へのシンボリックリンクは `mkdir -p .agents/skills` と `ln -sfn ../../agent-skills/<skill-name> .agents/skills/<skill-name>` で作成または更新する。
- `.claude/skills/<skill-name>` から `../../agent-skills/<skill-name>` へのシンボリックリンクは `mkdir -p .claude/skills` と `ln -sfn ../../agent-skills/<skill-name> .claude/skills/<skill-name>` で作成または更新する。
- `agent-skills/scripts/validate-agent-skills` で touched skill を検証する。

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

- Skill name は lowercase letters、digits、hyphens だけにする。
- Skill folder は `agent-skills/<skill-name>/` にする。
- User request が ambiguous な場合は、実装前に短く確認する。
- Existing skill を更新する場合は、既存構造と style を読む。

### Step 2: Create or update the skill body

- New skill を作る場合は `skill-creator` の initializer を使う。
- `SKILL.md` frontmatter は原則 `name` と `description` だけにする。
- `description` には what the skill does と when to use it を含める。
- Body には trigger information を重複させず、実行時に必要な workflow と constraints を書く。
- Resources を作る場合は、`SKILL.md` から exact relative path で参照する。

### Step 3: Create repository symlinks

このリポジトリでは skill 実体を `agent-skills/<skill-name>/` に置きます。
作成または更新した skill は、次のリンクで `.agents/` と `.claude/` の両方へ公開してください。

```bash
mkdir -p .agents/skills .claude/skills
ln -sfn ../../agent-skills/<skill-name> .agents/skills/<skill-name>
ln -sfn ../../agent-skills/<skill-name> .claude/skills/<skill-name>
```

If a correct symlink already exists, leave it in place.
If the path exists but is not the intended symlink, stop and inspect it before replacing anything.

Verify links with:

```bash
ls -l .agents/skills/<skill-name> .claude/skills/<skill-name>
test -e .agents/skills/<skill-name>/SKILL.md
test -e .claude/skills/<skill-name>/SKILL.md
```

### Step 4: Validate

After creating or updating skills, run the repository validator before finishing.
Prefer validating the current diff first.
Expand to wider checks only if needed.

```bash
agent-skills/scripts/validate-agent-skills agent-skills/<skill-name>
```

If validation reports issues in touched files, fix them and run the validator again.
If validation cannot be run, report why and state what was checked manually.

## Expected Output

- 変更した skill path を報告する。
- 作成または確認した symlink path を報告する。
- 実行した validator command と結果を報告する。
- Validation を省略した場合は理由を報告する。
