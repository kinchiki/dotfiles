# 調査と分類

Step 2 でコードベースを調べ、設計とデリバリーを分類するときに使う。

## コードベース調査

read-only で実際の data flow を追い、影響するモジュールと既存 pattern、repository の `CLAUDE.md` / `AGENTS.md` を確認する。
migration、後方互換性、permission / auth、バックグラウンドジョブ、API の公開範囲など、設計判断を生む edge を確認する。
この調査の目的は、ユーザーが選ぶべき設計判断の候補を洗い出して分類することである。
タスク単位の file 調査は create-plan が行う。

## 設計の分類: simple / non-simple

ユーザーが選ぶべき設計判断の候補を列挙する。
候補とは、interface、責務配置、data flow、状態管理、互換性、migration、運用特性、重要な制約の優先順位に、実行可能で実質的に異なる選択肢がある判断である。
既存 pattern や制約から一意に決まる判断は候補に含めない。

次の条件をすべて満たす場合だけ `simple` とする。

- 候補が0個である。
- 変更が局所的かつ low risk である。

いずれかを満たさない、または判定に迷う場合は `non-simple` とし、候補を grill-design へ初期の design tree として渡す。

## デリバリーの分類: single / sliced

次のいずれかに当たる場合は `sliced` の候補とし、分割方法を grill-design の decision として決める。

- 1 PR としてレビューするには大きすぎる。
- 1実装セッションのコンテキストに収まらない見込みである。
- 独立してリリースしたい段階がある、または expand / contract のような段階的な移行が必要である。

それ以外は `single` とする。
`sliced` の候補は `non-simple` として扱う。

## セッション

single-session / multi-session は分類しない。
各ゲートの通過時点で design.md と plan.md から再開できるため、引き継ぐかどうかは Step 6 とゲートの時点のコンテキスト残量で決める。
