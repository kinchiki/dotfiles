---
name: prepare-implementation
description: >-
  GitHub や Linear のチケット、またはユーザーの自然言語の変更依頼から、設計とタスクを1ファイルにまとめた承認済みの実装プラン（plan.md）を作り、implement-plan へ渡す。
  ユーザーが判断すべき設計判断だけを質問し、内容のブリーフィング、実行前承認付きの AI レビュー、最終承認を経て実装開始か引き継ぎへ進む。
  チケットや変更依頼を示して実装前の準備を求められたとき、「設計を詰めたい」「実装プランを作って」と依頼されたとき、途中まで進んだ plan.md から再開するとき、または sliced の次のスライスへ進むときに使う。
---

# prepare-implementation

チケットまたは依頼から承認済みの plan.md を作り、implement-plan へ渡す。
plan.md は「何を・なぜ」と「どう・どの順で」を1ファイルで持ち、このスキルだけが書く（`## タスク` のチェックボックスと `## 実行メモ` を除く）。

```text
入力の解決 → 調査と質問 → plan.md 作成 → self-check
  → [G1] 内容の理解 ＋ AIレビューの実行可否
  → AIレビュー（G1 で見送った場合は行わない）
  → [G2] 指摘の採否 ＋ 最終承認 ＋ 実装開始か引き継ぎか
```

## 参照先

- `references/source-resolution.md`: Step 1 で入力種別を判定して内容を取得する前に読む。
- `references/decisions.md`: Step 2 の調査と質問を始める前に読む。G1 や G2 で新しいユーザー判断が生じたときにも従う。
- `references/plan-template.md`: Step 0 で既存の plan.md を読む前、および Step 3 で plan.md を書く前に読む。
- `references/gates.md`: Step 4 の self-check を始める前に読み、G2 まで従う。
- `../implement-plan/SKILL.md`: Step 6 で同一セッションの実装開始が承認された後、実装へ進む直前に読む。

## 必須制約

- 現在の AI agent で利用できる上位推論モデルを使う。満たせない、または確認できない場合は一度警告し、ユーザーが明示的に品質上の不利益を受け入れた場合だけ続行する。
- 準備中は production code を編集しない。書き込むのは `.ai-local/plans/<plan-id>/` 配下だけにする。
- ユーザーに聞くのは `references/decisions.md` の「ユーザーに聞く判断」だけにする。repo、チケット、ドキュメントで分かる事実を聞かない。
- AI レビューは G1 でユーザーが実行を承認した場合だけ実行する。
- 承認は G2 の最終承認だけで行う。G1 では承認も実装開始も扱わない。
- AI レビューの指摘は1件ずつ採否の判断を得る。一括承認を受け付けない。
- 最終承認の前に `Status: approved`（sliced ではスライスの `approved`）にしない。

## Workflow

### Step 0: 再開位置を決める

入力が plan.md、plan ID、または plan.md のあるディレクトリの場合は、`references/plan-template.md` の `## 再開` に従って再開する Step を決める。
それ以外は Step 1 から始める。

### Step 1: 入力を解決する

`references/source-resolution.md` に従って入力の全内容を取得または抽出し、3〜6行の入力要約をユーザーへ返す。
調査を始められない gap だけをこの時点で確認する。

### Step 2: 調査して、ユーザー判断を質問する

`references/decisions.md` に従ってコードベースを read-only で調査し、判断をユーザー判断と AI判断に分ける。
ユーザー判断が残る間は質問ラウンドを回し、回答をその都度 plan.md に反映する。
plan.md がまだ無い場合は、最初の質問の前に `Status: draft` で作成し、`## 要件` と `## 未決事項` を書く。

### Step 3: plan.md を書く

`references/plan-template.md` に従い、残りのセクションとタスクを書く。
sliced の場合は、対象スライスのタスクだけを詳細に書き、後のスライスは `outline` のままにする。

### Step 4: self-check と G1

`references/gates.md` に従って self-check を行い、満たさない項目を直してから G1 のブリーフィングを示す。
修正のフィードバックは plan.md に反映し、新しいユーザー判断が生じた場合は Step 2 の質問ラウンドで決めてから G1 をやり直す。

### Step 5: AI レビューと G2

G1 で実行が承認された場合は、`references/gates.md` に従って ai-review の plan review mode を実行する。
G1 で見送った場合は、`## AIレビュー` に見送りと理由を書く。
どちらの場合も `references/gates.md` の G2 に進み、最終承認と実装開始か引き継ぎかの回答を得る。

### Step 6: 実装を続行または引き継ぐ

同一セッションでの実装開始が選ばれた場合は、`../implement-plan/SKILL.md` を読み、plan.md の絶対パスを入力にして従う。
引き継ぎが選ばれた場合、またはコンテキストが乏しい、大規模・high risk、sliced で同じセッションが直前のスライスを実装した場合は、working directory、plan.md の絶対パス、plan ID、対象スライス、次に使う skill（`implement-plan`）を含む自己完結した引き継ぎ文を1つの fenced code block で提示し、実装や別 agent の起動を行わずに停止する。
sliced の場合は、スライスの実装後に plan.md の path を渡してこのスキルを再開すると次のスライスへ進むことを伝える。

## Report

plan.md の path、対象スライス、主要なユーザー判断、タスク概要、AI レビューの結果と採否、選んだ経路と理由を報告する。
