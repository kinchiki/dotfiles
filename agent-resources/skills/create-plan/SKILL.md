---
name: create-plan
description: >-
  設計確定済みの design.md（sliced の変更では1スライス）を、fresh session でも実装できるタスク分解の実装プラン（plan.md）に変換し、human review、実行前確認付きの独立AIレビュー、finding ごとの採否、最終承認まで進める。
  prepare-implementation から plan 作成を委譲されたとき、または「この設計から実装プランを作って」と依頼されたときに使う。
  承認済みの plan.md は design.md と合わせて implement-plan の契約になる。
---

# create-plan

design.md の決定を変えずに、「どう・どの順で作るか」を plan.md に落とし、承認を得る。

## 参照先

- `../simple-design-doc/references/design-doc-template.md`: Step 1 で design.md を読む直前に読む。
- `references/task-decomposition.md`: Step 2 の影響範囲の調査とタスク分解を始める前に読む。
- `../ai-review/references/test-selection-policy.md`: Step 2 でテスト方針と各タスクの `test` を決める直前に読む。
- `references/plan-template.md`: Step 2 で plan.md を書く直前に読む。
- `../ai-review/references/review-gate.md`: Step 4 で plan review の実行確認を求める直前に読み、finding の採否まで従う。
- `../grill-design/references/decision-log.md`: フィードバックや指摘が確定済みの decision の変更を求めるときに読む。

## 必須制約

- production code を編集しない。
- 入力の design.md が `Status: designed` であることを確認する。`deciding` の場合は plan を作らず、grill-design へ戻す。
- design.md の決定事項、受入基準、やらないことを変更しない。変更を求めるフィードバックや指摘は、`../ai-review/references/review-gate.md` の指摘タグと同じ戻し先で扱う。
- design.md の内容を plan.md に書き写さず、受入基準と decision を ID で参照する。
- sliced の場合は、1回の起動で1スライスだけを plan にする。
- 発生可能性と影響に見合う事象だけを専用実装として計画し、低確率で単純なエラー処理で足りる事象は単純な処理で対処する。
- 計画 AI は AI review の指摘の採否や方針変更を単独で確定しない。
- 最終承認の履歴は保存せず、承認済みであることは plan.md の `Status` だけで表す。

## Workflow

### Step 1: 入力を確認する

design.md の全文と repo の convention file を読む。
sliced の場合は対象スライスを特定する。
指定が無い場合は、blocked_by がすべて完了済みで plan が未作成の最初のスライスを対象にする。

### Step 2: 影響範囲を調べてタスクへ分解する

`references/task-decomposition.md` に従って分解し、`references/plan-template.md` に従って plan.md を `Status: draft` で書く。

### Step 3: human review を受ける

plan.md の要約、タスク分解、各タスクと受入基準・decision の対応を提示してレビューを求める。
この時点で AI review が未実施であることを明記する。
このレビューで確定するのは「plan.md が design.md を忠実に実装していること」であり、design.md の決定は対象外であることを示す。
承認UIがある環境では、それを使う。

plan.md の範囲のフィードバックは仕様として扱い、前提が変わる場合は影響範囲を再調査して plan.md を更新し、再提示する。
design.md の変更を求めるフィードバックは、review-gate の指摘タグと同じ戻し先で扱う。
design.md の設計確定を経てから、この Step をやり直す。

### Step 4: plan review を実行する

`../ai-review/references/review-gate.md` に従い、実行前確認、ai-review の plan review mode、finding の採否を進める。
reviewer には、ユーザーレビュー済みの最新の plan.md と design.md を渡す。

### Step 5: 最終承認を得る

human review 以降の変更点（採用した指摘の反映内容）と、見送った指摘を提示して最終承認を得る。
変更点が無い場合は、その旨を示す。
追加のフィードバックは Step 3 と同じように扱い、plan.md が実質的に変わった場合は review-gate の再レビュー確認に従う。
承認後、plan.md を `Status: approved` にする。
sliced の場合は、plan.md の path を design.md の `## スライス` に記録するよう呼び出し元へ返す。
呼び出し元が prepare-implementation でない場合は、自分で記録する。
最終承認後も、実装は開始しない。

## Report

plan.md の path、`Status`、対象スライス、タスク数、AI review の結果と採否、次のステップを報告する。
