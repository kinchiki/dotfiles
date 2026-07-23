# Repository Links

公開済み Skill と agent definition のリンクを作成または検証する Step 4 で、この reference を使う。
`ln` を直接呼び出さず、リポジトリのメンテナンススクリプトを実行する。
正しい symlink が既に存在する場合、スクリプトはそのまま保持する。
パスは存在するが意図した symlink でない場合、置き換え前に確認できるようスクリプトは失敗する。

## Skill Links

Skill の実体は `agent-resources/skills/<skill-name>/` 配下に置く。
更新した Skill は `scripts/maintain-skill.sh` を使い、`.agents/` と `.claude/` の両方へ公開する。

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-skill.sh <skill-name>
```

このスクリプトは `agent-resources/skills/<skill-name>/SKILL.md` を検証し、公開 symlink が存在することを確認して、skill validator を実行する。

## Agent Definition Links

Agent definition の実体は `agent-resources/agents/<agent-name>/` 配下に置く。
更新した agent definition は `scripts/maintain-agent-definition.sh` を使い、`.agents/`、`.claude/`、`.codex/` へ公開する。

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-agent-definition.sh <agent-name>
```

このスクリプトは `<agent-name>.md`（canonical）と `codex.toml` を検証した後、`.agents/agents/<agent-name>.md` と `.claude/agents/<agent-name>.md` が canonical file を参照する symlink であり、`.codex/agents/<agent-name>.toml` が `codex.toml` を参照する symlink であることを確認する。
