# Reviewer Policy

code review と plan review で reviewer を選び、結果を扱うときに使う。

## Independence

- 対象を作成した AI セッションから reviewer を独立させる。
- Codex が作成した場合は Claude Code を使う。
- Claude Code が作成した場合は Codex CLI を使う。
- その他の AI が作成した場合は、作成した AI とは異なる利用可能な reviewer を使う。
- 同じ系統の別 session または別 model は独立 reviewer として数えない。
- ユーザーが別系統の reviewer を指定した場合は、その reviewer を使う。
- ユーザーが同じ系統の reviewer を指定した場合は、独立レビューにならないことを説明して停止する。

## Risk and model

- docs、comment、copy、軽微な type / test / UI 文言、style だけの変更は low risk とする。
- 通常の feature、bugfix、UI 挙動、API 隣接の変更は medium risk とする。
- auth、billing、permission、データ削除、migration、security、本番データ、広範な refactor、影響範囲不明は high risk とする。
- low risk を明示的にレビューする場合も、medium risk と同じ reviewer model を使う。
- Codex reviewer のデフォルトは `gpt-5.6-terra` / `high`、high risk は `gpt-5.6-sol` / `high` とする。
- Claude reviewer のデフォルトは `sonnet` / `high`、high risk は `opus` / `high` とする。
- `xhigh` または `max` はユーザーが明示的に依頼した場合だけ使う。
- risk は選択済み reviewer の model だけを変更し、reviewer の種類を変更しない。

## Consent and isolation

- Claude Code へ差分または review packet を送信する前に、送信対象を示してユーザーの明示的な同意を得る。
- 同意を記録した後にだけ `CLAUDE_REVIEW_CONSENT=yes` を渡す。
- reviewer の user MCP 設定を無効にし、外部状態に依存しない read-only review を実行する。
- 必要な reviewer が利用できない場合は `BLOCKED` として阻害要因を報告する。

## Findings and trust

- finding は `[P1]`、`[P2]`、`[P3]`、または `No findings` として返す。
- P1 は実装失敗、要件違反、重大な安全性またはデータ整合性問題につながる blocking issue とする。
- P2 は完了または最終承認前に対処すべき重要な issue とする。
- P3 は任意の改善とする。
- reviewer がローカル対象を実際に調査したことを確認できた場合だけ `TRUSTED` とする。
- reviewer が成功してもローカル対象を調査できたと確認できない場合は `UNTRUSTED` とする。
- `UNTRUSTED` の場合は同じ reviewer を1回だけ再実行し、再度 `UNTRUSTED` なら停止する。
- sandbox または同意 gate が reviewer 実行前に停止した場合は `BLOCKED` とする。
- P1 / P2 の採否、修正、lint / test、再レビューは呼び出し元へ返す。
