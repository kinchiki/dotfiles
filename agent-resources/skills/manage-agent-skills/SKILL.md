---
name: manage-agent-skills
description: >-
  dotfiles リポジトリの agent-resources で skill または agent definition を作成・更新・整理するときに使う。
  `agent-resources/skills` と `agent-resources/agents` を source of truth とし、skill は `.agents/skills` と `.claude/skills`、agent definition は `.agents/agents`、`.claude/agents`、`.codex/agents` への公開 symlink と検証を維持する。
  例: 「新しいスキルを作って」「対応するスキルを更新して」「agentを追加して」
disable-model-invocation: true
---

# manage-agent-skills

dotfiles リポジトリで agent skill と agent definition を作成・更新する。

## Scope

- Skill: `agent-resources/skills/<skill-name>/SKILL.md`（付随 resource: `references/`, `scripts/`, `assets/`, `agents/openai.yaml`）
- Agent definition: `agent-resources/agents/<agent-name>/<agent-name>.md`（canonical）と `codex.toml`
- 公開 skill symlink: `.agents/skills`, `.claude/skills`
- 公開 agent symlink: `.agents/agents`, `.claude/agents`, `.codex/agents`
- `<skill-name>` / `<agent-name>` には小文字英数字とハイフンだけを使う。

## Resources

- `references/repository-links.md`: 公開 symlink を作成・検証する前に読む。
- `scripts/maintain-skill.sh <skill-name>`: skill の symlink 作成と検証に使う。
- `scripts/maintain-agent-definition.sh <agent-name>`: agent definition の symlink 作成に使う。

## Hard constraints

- Markdown 構造・YAML frontmatter・見出し・リスト・表・fenced code block・コードブロック内の改行を保持する。
- 通常の段落は概ね1文1行、リスト項目は1項目1行にする。
- 直接的な命令形・肯定形の指示・正確な相対パス・「X ならば Y。そうでなければ Z。」の条件文を使う。
- 否定形の表現は、ハード禁止・安全境界・データ損失リスク・フォーマット崩壊リスク・交渉不可の制約にだけ使う。
- `SKILL.md` は運用的な内容に保ち、長い例・スキーマ・対応表・コマンド規約・背景・詳細ルールは reference file に移す。
- 各規約の正典となる置き場所は1つだけにし、単発利用の抽象化・投機的な柔軟性・不要な resource ディレクトリを避ける。
- shell script は `scripts/*.sh` としてだけ追加する。
- shell や validator の出力は、コマンド・pass/fail・必要なエラー行だけを報告する。

## Workflow

### Step 1: Confirm scope

依頼が曖昧な場合は、編集前に短く確認する。
既存内容を更新する場合は、まず現在の構成とスタイルを読む。
skill を更新する場合は、関連する `SKILL.md` セクション・reference・script・asset を探し、canonical な置き場所を決めてから編集する。

### Step 2: Create or update skill

新しい skill を作る場合は `skill-creator` initializer を使う。
`SKILL.md` の frontmatter は `name` と `description` だけにする。
skill が何をするか・いつ使うかは `description` に書く。
実行時の workflow・制約・resource の使い方は本文に書く。
反復的で決定論的な作業は `scripts/` に切り出して実行する。
resource が必要なら skill 配下に作り、`SKILL.md` から正確な相対パスで参照する。
詳細が `SKILL.md` と reference file の両方に該当する場合、詳細は reference file に置き、`SKILL.md` には読むタイミングと短い指示だけを残す。

### Step 3: Create or update agent definition

- `<agent-name>.md`: 単一の canonical contract。YAML frontmatter（`name`, `description`, `model`, `tools` などの Claude Code サブエージェント項目）を含め、canonical source と Claude Code サブエージェント定義を1ファイルで兼ねる。
- `codex.toml`: Codex 用メタデータ（`name`, `description`, `model`, `sandbox_mode` など）と、`.agents/agents/<agent-name>.md`（canonical への symlink）を読んで primary contract として従わせる短い `developer_instructions` bootstrap。Codex の config schema には per-agent の instructions ファイル参照キーが無いため、契約全文を `developer_instructions` に複製しない。

### Step 4: Link and validate

touched skill には次を実行する:

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-skill.sh <skill-name>
```

touched agent definition には次を実行する:

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-agent-definition.sh <agent-name>
```

既存の公開パスが期待する symlink でない場合は、置き換える前に停止して確認する。
validation が touched-file の issue を報告したら、直して再実行する。
agent definition 専用の validator は無いため、`maintain-agent-definition.sh` を実行し、リンク先ファイルを読んでから終える。
validation を実行できない場合は、理由と手動で確認した内容を報告する。
終える前に diff を見直し、概念の重複・コピーされた例・path / command 規約の繰り返しを確認する。
standalone 実行のための意図的な重複を残す場合は、その理由を報告する。

## Report

変更した skill path、変更した agent definition path、作成・確認した symlink path、script のコマンドと結果、validator のコマンドと結果、validation を省略した理由、意図的な重複とその理由を報告する。
