# Design Review

設計確定済みの design.md を、plan 作成前に独立レビューするときだけ使う。
目的はユーザーに代わって設計を決めることではなく、要件とコードに照らして設計の欠陥を発見することである。

## Build the review packet

設計の評価に必要な次のコンテキストだけを review packet に含める。

- design.md の絶対パスと最新の全文
- ソース種別と、元ソースの参照先またはユーザー依頼の抜粋
- 設計者が調査した path と既存 pattern
- `## レビュー記録` で見送り済みの指摘

`decided` の decision はユーザーの判断であると reviewer へ伝える。
安全性、データ損失、実装不可能、要件違反、repository constraint の具体的な根拠がある場合を除き、decision の変更を提案させない。
各指摘に `review-gate.md` の `## 指摘タグ` のうち `[design:D<n>]`、`[design:要件]`、`[design:追加]` のいずれか1つを付けさせる。
見送り済みの指摘を再提起させない。

## Review focus

- 受入基準を満たさない設計、または決定事項同士の矛盾
- `## 決定事項` にない、ユーザー判断が必要な設計判断の漏れ
- 調査したコードや既存 pattern と食い違う前提
- data flow、auth / permission、background job、API、migration、互換性、運用特性の見落とし
- スライスの独立性、blocked_by、各スライスの単独での検証可能性
- `## 用語` の曖昧さ、`## 設計` と `## 決定事項` の不整合
- 過剰な設計、やらないことへの逸脱

P1 / P2 には、元ソース、design.md、または調査したコードの根拠を含めるよう reviewer へ指示する。
必須のローカル inspection 指示と `BLOCKED` を返してよい条件は wrapper が review packet へ追記するため、packet 本文では省略する。

## Run the reviewer

plan review と同じ wrapper を使う。
review packet の書き出し、reviewer ごとのコマンド、model、`BLOCKED` と exit 7 の扱いは `plan-review.md` の `## Run the reviewer` に従う。

## Result

- reviewer、主要 finding、risk、信頼性判定を返す。
- trust 判定、形式不備、再実行の扱いは `reviewer-policy.md` に従う。
- 指摘の採否、差し戻し、再レビューは呼び出し元へ返す。
