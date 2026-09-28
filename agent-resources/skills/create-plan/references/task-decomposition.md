# 影響範囲の調査とタスク分解

Step 2 で影響範囲を調べ、design.md の決定をタスクへ分解するときに使う。

## 影響範囲の調査

read-only で実際の data flow を追う。
models、services / interactions、controllers、serializers、GraphQL types、jobs、tests などの影響範囲を読み、entry point と想定する変更箇所の path を記録する。
既存のパターン、テストの慣習、repository の `CLAUDE.md` / `AGENTS.md` を確認する。
target repo が `app/interactions/` または `packs/` の構成規約を持つ場合は、その構造を尊重する。

migration、後方互換性、permission / auth、N+1、バックグラウンドジョブの冪等性、API の公開範囲、i18n など、該当する edge を検討する。
調査結果から、plan-template の `## 変更面` に挙げた面のうち、この変更が触れるものを特定する。
調査で design.md の decision の前提を崩す事実が見つかった場合は、`../../grill-design/references/decision-log.md` の差し戻しとして扱う。
design.md で扱っていない、ユーザー判断が必要な設計判断が見つかった場合も、推測で埋めずに grill-design へ戻す。

## タスク分解

plan.md は、design.md と plan.md だけを読む fresh session の上位モデルが、どこから読み始め、何ができたら完了かを判断できる粒度にする。
この粒度は file の列挙ではなく、entry point、既存パターン、`done_when` で満たす。
1タスクは独立に検証できる outcome 1つにし、file やレイヤーの単位で分割しない。
各タスクには次を含める。

- `implements`: そのタスクが満たす受入基準の ID と、従う decision の ID
- `depends_on`: 先に完了している必要がある task ID
- `done_when`: 観測可能な完了条件
- `test`: 検証する振る舞いと、実行する command

## Risk による粒度

plan.md の `Risk` に応じて、次の粒度にする。

- low: タスクは通常1〜2個にする。`done_when` は受入基準の ID で書いてよい。`## 影響範囲と既存パターン` は entry point を数行で書く。
- medium: outcome ごとにタスクを分け、各タスクの `test` で targeted に検証できるようにする。
- high: 外部に影響する順序（migration の後にコードを切り替えるなど）を `depends_on` で明示し、`## 変更面` を具体的に書き、変更面に触れる変更を独立したタスクにする。

分解後、対象範囲の全受入基準がいずれかのタスクの `implements` に含まれていることを確認する。
