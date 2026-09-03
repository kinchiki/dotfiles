# 方針選択とタスク分解

Step 2 の codebase 調査と実装方針の選択、および Step 3 のタスク分解で使う。

## コードベース調査

read-only planning で実際の data flow を追う。
models、services / interactions、controllers、serializers、GraphQL types、jobs、tests などの影響範囲を読み、exact file path を記録する。
既存のパターン、テストの慣習、repository の `CLAUDE.md` / `AGENTS.md` を確認する。
target repo が `app/interactions/` または `packs/` の構成規約を持つ場合は、その構造を尊重する。

migration、後方互換性、permission / auth、N+1、バックグラウンドジョブの冪等性、API の公開範囲、i18n など、該当する edge を検討する。
調査で実装可否または受入基準を左右する不明点が見つかった場合は、`../../ask-user-questions/SKILL.md` に従ってユーザーへ確認する。

## Simple / non-simple の判定

次の条件をすべて満たす場合だけ `simple` とする。

- 変更が局所的かつ low risk である。
- 既存 pattern から実装方針が一意に決まる。
- interface、責務配置、data flow、状態管理、互換性、migration、運用特性、重要な制約の優先順位に実質的な設計選択がない。

いずれかを満たさない、または判定に迷う場合は `non-simple` とする。
`simple` の場合は判定理由と代替案比較を省略した理由を記録し、タスク分解へ進む。

## 実行可能で実質的に異なる代替案

`non-simple` の場合は、実装方針を確定する前に実行可能で実質的に異なる代替案を探索する。
要件と既知の制約を満たし、target repo で実装可能で、既知の致命的な欠点がない案を実行可能とする。
interface、責務配置、data flow、状態管理、互換性、migration、運用特性、または重要な制約の優先順位が異なる案を実質的に異なるものとする。
同じ設計 family の微修正版は1案にまとめる。

意味のある実行可能な代替案だけを最大3案提示する。
2案だけが実行可能なら2案を提示する。
1案だけが実行可能なら、その案と検討した主要な代替案の具体的な棄却理由を提示する。
微修正版、既知の制約に反する案、明らかな劣化案を候補に含めない。

各案は次の観点を同じ粒度で比較する。

- 設計上の違い
- メリット
- trade-off
- リスク
- 選択基準

## 選択、組み合わせ案、再検討

推奨案がある場合は理由とともに示す。
推奨案を自動選択せず、`../../ask-user-questions/SKILL.md` に従ってユーザーに方針選択を求める。
ユーザーが提示案の選択、要素を指定した組み合わせ案、または観点を指定した再検討を回答できるようにする。

組み合わせ案は整合性と実行可能性を確認し、実質的に新しい方針になる場合は選択案として再提示して確認を得る。
再検討を求められた場合は、指定された観点を調査して比較を更新し、改めて選択を求める。
実行可能な案が1つだけの場合も、その案の受諾または再検討をユーザーへ確認する。

選択後、タスク分類、選択した方針、選択根拠、受け入れた不利益、主要な棄却案と理由を草案の `## 設計判断` に残す。

## タスク分解

non-simple task はユーザーが方針を選択した後にだけ分解する。
実装プランは、入力やコードベースを読んでいない session でも正しく実装できる粒度にする。
テスト方針と各タスクの `test` を決める前に `../../ai-review/references/test-selection-policy.md` を読む。

各タスクには次を含める。

- `files`: touch する file
- `depends_on`: prerequisite task ID
- `parallel`: 同時実行できる場合だけ `yes`
- `test`: task を検証する command
- `done_when`: 観測可能な完了条件

`parallel: yes` は、同時に ready になるタスクと `files` が重ならない場合だけ使う。
overlap があるタスクは sequential にする。
