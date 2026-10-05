@../.codex/AGENTS.md

## sandbox の excludedCommands

`~/.claude/settings.json` の `sandbox.excludedCommands` に載っているコマンドは、
パイプ・リダイレクト・env 前置・`cd ... &&` などを付けると除外が外れるので、コマンド単体の素の形で実行する。
