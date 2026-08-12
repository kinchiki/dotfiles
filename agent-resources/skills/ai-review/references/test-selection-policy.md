# Test Selection Policy

計画、実装、コードレビュー、PR レビュー対応では、テストをアプリケーション固有の振る舞いに集中させる。

## Exclude direct guarantee checks

次の保証だけを直接再検証するテストは、作成・要求・不足指摘の対象から外す。

- DB の `NOT NULL`、一意制約、外部キー制約など、DB が保証する制約。
- Rails の `presence`、`maximum` など、標準バリデーションの既定動作。
- 利用ライブラリやフレームワークの公開済みの標準契約と既定動作。

たとえば `null: false` のカラムへ `nil` を保存できないことや、単純な `presence`・`maximum` の設定でレコードを保存できないことだけを確認するテストは対象外にする。

## Cover application behavior

条件付きの適用、独自バリデーション、独自メッセージ、エラー変換、業務上の副作用、API や画面に公開するアプリケーション固有の振る舞いはテスト対象にする。

## Keep existing tests

この方針だけを理由に既存テストを削除、弱体化、skip、pending にしない。
