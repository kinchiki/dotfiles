---
name: prepare-implementation
description: >-
  GitHub や Linear のチケット、またはユーザーの自然言語の変更依頼を受け取り、要件の解決、分類、grill-design による設計判断、design review、create-plan による実装プラン作成を順に進めて、承認済みの design.md と plan.md を作る入口の orchestrator。
  ユーザーがチケットや変更依頼を示して実装前の準備を求めたとき、または途中まで進んだ design.md / plan.md から再開するときに使う。
  承認後は実装開始の確認を得て implement-plan へ進むか、別セッションへ引き継ぐ。
---

# prepare-implementation

チケットまたは依頼から承認済みの design.md と plan.md を作り、implement-plan へ渡す。
各フェーズは専門 skill に委譲し、このスキルは入力の解決、分類、フェーズの順序、design review と実装開始のゲート、引き継ぎを持つ。

```text
Resolve → 分類 ─ simple ────────────────────────────────────┐
                └ non-simple → grill-design → design review ─┴→ create-plan → 実装開始
```

sliced の変更では、design.md を1つ作り、create-plan と実装開始をスライスごとに繰り返す。

## 参照先

- `references/source-resolution.md`: Step 1 で入力種別を判定して内容を取得する前に読む。
- `../simple-design-doc/references/design-doc-template.md`: Step 0 で既存の design.md を読む、または Step 1 で design.md を作成する直前に読む。
- `../ask-user-questions/SKILL.md`: Step 1 で入力の不足をユーザーへ確認する直前に読む。
- `references/triage.md`: Step 2 の調査と分類を始める前に読む。
- `../grill-design/SKILL.md`: Step 3 で設計判断へ進む直前に読む。
- `../ai-review/references/review-gate.md`: Step 4 で design review の実行確認を求める直前に読み、finding の採否まで従う。
- `../grill-design/references/decision-log.md`: design review の指摘を採用して decision を差し戻すときに読む。
- `../create-plan/SKILL.md`: Step 5 で plan 作成へ進む直前に読む。
- `../implement-plan/SKILL.md`: Step 6 で同一セッションの実装開始が承認された後、実装へ進む直前に読む。

## 必須制約

- orchestrator は現在の AI agent で利用できる上位推論モデルを使う。満たせない、または確認できない場合は一度警告し、ユーザーが明示的に品質上の不利益を受け入れた場合だけ続行する。
- 準備中は production code を編集しない。書き込むのは `.ai-local/plans/<plan-id>/` 配下だけにする。
- design.md は template の section ownership に従って書き、他の skill が書き手のセクションを直接書き換えない。
- 確定済みの decision と承認済みの plan を後続のゲートで聞き直さない。変更は差し戻しだけで行う。
- 各ゲートでは、次の表の「確定するもの」だけを承認の対象として提示する。
- 最終承認は計画内容の承認として扱い、実装開始は Step 6 で別途確認する。

| ゲート | 持つ skill | 確定するもの |
|---|---|---|
| 設計方針の選択 | grill-design | 各ラウンドの decision |
| 設計確定 | grill-design | design.md の要件、決定事項、設計、スライス（`Status: designed`） |
| design review の実行確認と指摘の採否 | prepare-implementation | review を実行するか、各指摘の採用・見送り |
| plan の human review | create-plan | plan.md が design.md を忠実に実装していること |
| plan review の実行確認と指摘の採否 | create-plan | review を実行するか、各指摘の採用・見送り |
| 最終承認 | create-plan | human review 以降の変更点と plan.md 全体（`Status: approved`） |
| 実装開始 | prepare-implementation | 同一セッションで実装するか、引き継ぐか |
| commit / push / PR | implement-plan 以降の各 skill | 外部への操作 |

## オーケストレーション

- **Step 0: モデルを確認し、再開位置を決める。** 上位推論モデルであることを確認し、使用モデルと品質上の不利益を design.md のヘッダーの `作成` に残す。入力が design.md、plan.md、または plan ID の場合は、design.md の `Status`、`## スライス` の進捗、plan.md の `Status` と未チェックのタスクから再開する Step を決める。完了したスライスは、plan.md のタスクがすべてチェック済みなら `## スライス` のチェックボックスを付ける。
- **Step 1: 入力を解決する。** 入力の全内容を取得または抽出し、3〜6行の入力要約をユーザーへ返して、計画を左右する不足を確認する。design.md を `Status: deciding` で作成し、ヘッダーと `## 要件` を書く。
- **Step 2: 調査して分類する。** コードベースを read-only で調査し、simple / non-simple と single / sliced を判定して、分類と理由をヘッダーに書き、ユーザーへ示す。simple の場合は `## 決定事項` と `## リスク` を書き、`Status: designed` にして Step 5 へ進む。
- **Step 3: 設計判断を詰める。** grill-design に design.md と設計判断の候補を渡し、`Status: designed` になるまで任せる。
- **Step 4: design review を実行する。** review-gate に従い、実行前確認、ai-review の design review mode、指摘の採否を進める。採用した指摘は review-gate の指摘タグに応じた戻し先で反映し、設計確定後に review-gate の再レビュー確認へ進む。
- **Step 5: plan を作る。** create-plan に design.md を渡し、sliced の場合は対象スライスを指定する。返された plan.md の path を `## スライス` に記録する。
- **Step 6: 実装を続行または引き継ぐ。** デフォルトは同一セッションとし、実装開始の承認を得てから `implement-plan` を起動する。コンテキストが乏しい、大規模・high risk、または sliced で同じセッションが直前のスライスを実装した場合は、working directory、design.md と plan.md の絶対パス、plan ID、次に使う skill を含む自己完結した引き継ぎ文を1つの fenced code block で提示し、実装や別 agent の起動を行わず停止する。sliced の場合は、スライスの実装後に design.md の path を渡してこの skill を再開すると次のスライスへ進むことを伝える。選んだ経路、理由、入力要約、保存先、分類、主要な decision、タスク概要、AI review の結果を報告する。
