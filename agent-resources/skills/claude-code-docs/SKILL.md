---
name: claude-code-docs
description: >-
  Claude Code の設定、権限、sandbox、CLAUDE.md、rules、Skills、agents、hooks、MCP、CLI、
  Desktop・IDE・Web の差異、最近の変更について、回答時点の Anthropic 公式情報を調査して回答するときに使う。
---

# Claude Code Docs

Claude Code の製品仕様は記憶だけで答えず、実行時に最新の公式情報を確認する。
ドキュメント本文をローカルへ保存せず、回答ごとに参照する。

## Workflow

1. 質問が対象とする Claude Code の機能、実行 surface、環境、バージョンを整理する。
2. `https://code.claude.com/docs/llms.txt` を最初に確認し、関連ページを特定する。
3. 必要な情報を特定できない場合は `https://code.claude.com/docs/en/claude_code_docs_map` を確認する。
4. さらに探索が必要な場合は `https://code.claude.com/docs/` から関連ページを探す。
5. Claude Code Docs だけでは不足する場合に限り、Anthropic 公式 GitHub、Platform Docs、Support の順で補足する。
6. 関連ページの本文を読み、設定名、設定範囲、優先順位、既定値、surface ごとの差異を原文で検証する。
7. 最新性が回答を左右する場合は、Claude Code changelog と関連する最近の変更を確認する。
8. 公式情報同士に差異がある場合は、その差異と確認日を明示し、より対象が具体的で新しい情報を優先する。

## Answer

- 結論を先に述べる。
- 公式ドキュメントで確認した事実、事実から導いた推論、運用上の推奨を明確に分ける。
- 確認した各ページのタイトルと URL を示す。
- 設定名や既定値を公式情報で確認できない場合は、「公式ドキュメントでは確認できない」と明記する。
