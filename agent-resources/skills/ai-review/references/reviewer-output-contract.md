# Reviewer Output Contract

reviewer の最終メッセージには、次のどちらか1つだけを独立した1行で含める。

- `REVIEW_TRUST: TRUSTED`
- `REVIEW_TRUST: UNTRUSTED`

宣言は最終メッセージの任意の位置に置く。先頭行でなくてもよい。
宣言を説明文の一部、コードフェンス内、引用文の中に置かない。
ローカル対象を読めない、またはレビュー結果の信頼性を確保できない場合は `UNTRUSTED` を選ぶ。
finding や行番号付き引用があっても、この判定を変更しない。
