# Repository Links

Use this reference in Step 4 when creating or verifying published Skill and agent definition links.
If a correct symlink already exists, leave it in place.
If the path exists but is not the intended symlink, stop and inspect it before replacing anything.

## Skill Links

Skill implementations live under `agent-resources/skills/<skill-name>/`.
Publish an updated Skill to both `.agents/` and `.claude/`.

```bash
ln -sfn ../../agent-resources/skills/<skill-name> .agents/skills/<skill-name>
ln -sfn ../../agent-resources/skills/<skill-name> .claude/skills/<skill-name>
```

Verify the links.

```bash
ls -l .agents/skills/<skill-name> .claude/skills/<skill-name>
test -e .agents/skills/<skill-name>/SKILL.md
test -e .claude/skills/<skill-name>/SKILL.md
```

## Agent Definition Links

Agent definition implementations live under `agent-resources/agents/<agent-name>/`.
Publish an updated agent definition to `.agents/`, `.claude/`, and `.codex/`.

```bash
ln -sfn ../../agent-resources/agents/<agent-name>/instructions.md .agents/agents/<agent-name>.md
ln -sfn ../../agent-resources/agents/<agent-name>/claude.md .claude/agents/<agent-name>.md
ln -sfn ../../agent-resources/agents/<agent-name>/codex.toml .codex/agents/<agent-name>.toml
```

Verify the links.

```bash
ls -l .agents/agents/<agent-name>.md .claude/agents/<agent-name>.md
test -e .agents/agents/<agent-name>.md
test -e .claude/agents/<agent-name>.md
test -e .codex/agents/<agent-name>.toml
```
