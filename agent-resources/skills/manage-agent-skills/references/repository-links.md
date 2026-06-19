# Repository Links

Use this reference in Step 4 when creating or verifying published Skill and agent definition links.
Run the repository maintenance scripts instead of calling `ln` directly.
If a correct symlink already exists, the script leaves it in place.
If the path exists but is not the intended symlink, the script fails so you can inspect it before replacing anything.

## Skill Links

Skill implementations live under `agent-resources/skills/<skill-name>/`.
Publish an updated Skill to both `.agents/` and `.claude/` with `scripts/maintain-skill.sh`.

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-skill.sh <skill-name>
```

This script verifies `agent-resources/skills/<skill-name>/SKILL.md`, ensures the published symlinks exist, and runs the skill validator.

## Agent Definition Links

Agent definition implementations live under `agent-resources/agents/<agent-name>/`.
Publish an updated agent definition to `.agents/`, `.claude/`, and `.codex/` with `scripts/maintain-agent-definition.sh`.

```bash
agent-resources/skills/manage-agent-skills/scripts/maintain-agent-definition.sh <agent-name>
```

This script verifies `instructions.md`, `CLAUDE.md`, and `codex.toml`, then ensures the published symlinks exist.
