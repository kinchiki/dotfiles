# 影響範囲の調査とタスク分解

Step 2 で影響範囲を調べ、design.md の決定をタスクへ分解するときに使う。

## 影響範囲の調査

read-only で実際の data flow を追う。
models、services / interactions、controllers、serializers、GraphQL types、jobs、tests などの影響範囲を読み、exact file path を記録する。
既存のパターン、テストの慣習、repository の `CLAUDE.md` / `AGENTS.md` を確認する。
target repo が `app/interactions/` または `packs/` の構成規約を持つ場合は、その構造を尊重する。

migration、後方互換性、permission / auth、N+1、バックグラウンドジョブの冪等性、API の公開範囲、i18n など、該当する edge を検討する。
調査で design.md の decision の前提を崩す事実が見つかった場合は、`../../grill-design/references/decision-log.md` の差し戻しとして扱う。
design.md で扱っていない、ユーザー判断が必要な設計判断が見つかった場合も、推測で埋めずに grill-design へ戻す。

## タスク分解

plan.md は、design.md と plan.md だけを読む fresh session でも正しく実装できる粒度にする。
各タスクには次を含める。

- `implements`: そのタスクが満たす受入基準の ID と、従う decision の ID
- `files`: touch する file
- `depends_on`: prerequisite task ID
- `parallel`: 同時実行できる場合だけ `yes`
- `test`: task を検証する command
- `done_when`: 観測可能な完了条件

`parallel: yes` は、同時に ready になるタスクと `files` が重ならない場合だけ使う。
overlap があるタスクは sequential にする。

分解後、対象範囲の全受入基準がいずれかのタスクの `implements` に含まれていることを確認する。
