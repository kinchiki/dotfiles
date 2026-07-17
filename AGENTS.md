# AGENTS.md

このリポジトリ（`~/src/dotfiles`）固有の指示。全リポジトリ共通のグローバル guardrails は
`.codex/AGENTS.md` を正本とし、ホームの `~/.claude/CLAUDE.md` などから別途読み込まれる。

## このリポジトリについて

dotfiles 管理リポジトリ。`install.sh` がリポジトリ内のファイルをホームディレクトリへ symlink する。

- ルート直下の dot ファイルは `~/` 直下へ、dot ディレクトリ配下のファイル/symlink は個別に `~/` 配下へリンクされる。
- グローバル guardrails の正本は `.codex/AGENTS.md`。`.claude/CLAUDE.md`（`@../.codex/AGENTS.md` を import）と `.copilot/copilot-instructions.md`（symlink）がこれを参照する。
- ルートの `CLAUDE.md`/`AGENTS.md`（このファイル）は `.` 始まりでないためホームへはリンクされず、このリポジトリで作業するときだけ効く。

## agent / skill 定義

agent・skill 定義の実体は `agent-resources/` にあり、各ツール用ディレクトリ（`.claude`/`.codex`/`.agents`）から symlink して共有している。

skill や agent 定義を作成・更新するときは、skill ファイルを直接編集せず `manage-agent-skills` スキルを使うこと。

## 調査ルール
OpenAI API、ChatGPT、Codex、OpenAI SDK、OpenAI製品の仕様を調べる場合は、必ず `openaiDeveloperDocs` MCP を最初に使用する。

Docs MCP で必要な情報を取得できない場合に限り、OpenAI 公式ドメインへの直接アクセスを使用する。
