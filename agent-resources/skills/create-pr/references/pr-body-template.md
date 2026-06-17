# PR Body Template

Use this template in Step 2 when the repository does not provide `.github/pull_request_template.md` or a more specific local PR convention.
Fill it from the plan, ticket, and verification results.

```markdown
## チケット
<指定されたチケットの URL>

## 概要
<この PR で何を・なぜ変えたか（1〜3行）>

## 変更点
- <主要な変更を箇条書き>

## テスト
- <ユーザーが記載するためなにも記載しない>

## レビュー（AI）
- レビュー担当: <Claude Code実装時はCodex / Codex実装時はClaude Code / 低リスクskip>
- 残した nit: <あれば。なければ「なし」>
- レビュー方針: <低リスクskip / 独立AIレビュー1回 / P1-P2修正後の再レビュー など>

## 受入基準
- [x] <プランの Acceptance criteria を転記し、満たしたものをチェック>
```
