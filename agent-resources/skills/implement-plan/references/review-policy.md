# Review policy

lint/test が green で、実際の差分が medium または high risk に分類された後にだけ読み込む。
low risk では読み込まない。

## Independence

- レビュアーは、変更を実装した AI セッションから独立させる。
- 別系統のレビュアーを優先する。Claude または Codex 以外による実装には `scripts/review-codex.sh` 経由で Codex CLI を使い、Codex または Claude 以外による実装には `scripts/review-claude.sh` 経由で Claude Code を使う。
- `scripts/review-claude.sh` を実行する前に、レビュー対象の未コミット差分を Claude Code へ送信することについてユーザーの明示的な同意を得る。
- 同意を得た後にだけ `CLAUDE_REVIEW_CONSENT=yes` を渡す。
- 同じ agent によるセルフレビューは独立レビューとして数えない。
- 目的、受入基準、特別なリスクだけを渡す。長い実装経緯は渡さない。
- レビュアーは `../../ticket-to-plan/references/test-selection-policy.md` に従う。レビュースクリプトはその内容をレビュアーへ渡す。
- 明示的な同意を得た後も必要なレビュアーを実行できない場合は停止し、`status: blocked` と報告する。

## Model and effort

- コードレビューには以下のモデルと推論を使う
  - Codex
    - デフォルト
      - `CODEX_REVIEW_MODEL=${CODEX_REVIEW_MODEL:-gpt-5.6-terra}`
      - `CODEX_REVIEW_EFFORT=${CODEX_REVIEW_EFFORT:-high}`
    - high-risk の差分
      - `CODEX_REVIEW_MODEL=gpt-5.6-sol`
      - `CODEX_REVIEW_EFFORT=high`
  - Claude
    - デフォルト
      - `CLAUDE_REVIEW_MODEL=${CLAUDE_REVIEW_MODEL:-sonnet}`
      - `CLAUDE_REVIEW_EFFORT=${CLAUDE_REVIEW_EFFORT:-high}`
    - high-risk の差分
      - `CLAUDE_REVIEW_MODEL=opus`
      - `CLAUDE_REVIEW_EFFORT=high`
- 明示的に依頼された場合にだけ `xhigh` または `max` を使う。
- 環境変数はデフォルト値より優先する。

## Run

- レビュースクリプト `scripts/review-codex.sh` と `scripts/review-claude.sh` は、このスキル自身のディレクトリ（この `references/` ディレクトリの1階層上にあるスキルルート）から実行する。
- sandbox 化された Claude 環境では、レビュースクリプトの呼び出しを実際の呼び出しと完全に同じ形で `sandbox.excludedCommands` に登録する。そうしないと Claude は sandbox 内に留まり、PTY ベースのコマンド実行が `UNTRUSTED` で失敗する。sandbox が設定されていない場合、この対応は不要で、上記の相対パスによる呼び出しをそのまま使える。
- 各スクリプトは未コミットの working tree をレビューし、レビュアーが実際に差分を調査したことを検証し、レビュー本文を出力して、対応する終了コードとともに `TRUSTED` または `UNTRUSTED` の判定を報告する。
- スクリプトが `TRUSTED` を報告し、出力が実際の差分に言及している場合にだけ、指摘なし（"no findings"）の結果を信頼する。
- `UNTRUSTED` の場合、同じレビュアーを新たな承認待ちなしで実行できるなら1回再実行する。
- 明示的な同意がまだ記録されていないため再実行が妨げられた場合は、停止して同意を得てから `CLAUDE_REVIEW_CONSENT=yes` を設定し、再実行する。
- 再実行でも `UNTRUSTED` が報告された場合は停止し、阻害要因を報告する。
- working tree の代わりにコミット済みの範囲をレビューするには、範囲を手動で調整する。このパイプラインはコミット前にレビューするため、デフォルトは working tree とする。

## Findings

- `[P1]` と `[P2]` は blocking として扱う。修正して lint/test を再実行し、独立レビューを1回再実行する。
- linter に基づく指摘については、リポジトリの linter を正とする。指摘を blocking として扱う前に linter で確認する。
- 日本語などのマルチバイト文字列の行長は、バイト数ではなく linter の結果で判定する。linter が green なら false positive と記録し、コードは変更しない。
- `test-selection-policy.md` が確認対象の直接保証を除外している場合、テスト不足を報告したり新しいテストを要求したりしない。
- 低コストで対応できる `[P3]` の指摘は修正する。見送った `[P3]` の指摘は PR 本文に記載する。
- 3回目のレビューは、high risk の変更または本当に曖昧な P1/P2 が残っている場合にだけ実行する。
- 実装がプランの `## 受入基準` を満たしていることを別途確認する。
