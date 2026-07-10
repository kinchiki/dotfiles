---
name: ask-user-questions
description: >-
  調査、設計、実装、レビュー対応の途中で、repo や既存資料だけでは解決できない不明点をユーザーへ短く確認する。
  スコープ、成功条件、互換性、優先順位、維持したい挙動など、ユーザー判断が必要な open question を整理するときに使う。
  例: 「この挙動は維持するか」「どの案を優先するか」「回答がない場合の default assumption は何か」。
---

# ask-user-questions

repo や source を調べても解けない判断だけを、短く、決定しやすい形でユーザーへ確認するスキルです。
調査で埋められる事実確認や、単なる進捗報告には使いません。

## Hard constraints

- 先に codebase、ticket、会話履歴、関連ドキュメントを調べる。
- 質問の前に、何が既知で何が未確定かを自分で整理する。
- 実装可否、受入基準、ユーザー意図に影響しない曖昧さは、質問せず assumption として処理する。
- 推測の default が妥当な場合は、それを先に示して確認する。
- 回答がないと作業を続けられない場合だけ、blocking question として扱う。
- source kind や対象範囲が曖昧なだけなら、短い確認を 1 問だけ送る。
- 1 回の確認は 1 から 3 問までに絞る。
- 各質問は短く、相互排他的な選択肢か、1 文で答えられる形にする。
- 既にユーザーが明示した意図を、確認の名目で聞き直さない。

## Workflow

### Step 1: Decide whether to ask

- その不明点が repo 調査で解けるか確認する。
- 解けるなら調査へ戻る。
- 解けない場合は、どの判断かを整理する。
- `scope or priority`
- `acceptance criteria`
- `backward compatibility or behavior choice`
- `operational constraint`
- `explicit approval for external or risky action`

### Step 2: Prepare the question

- 既知の事実を 1 から 3 行で要約する。
- なぜ判断が必要かを 1 行で書く。
- 推奨案がある場合は、理由つきで先頭に置く。
- 回答がない場合の default があるなら明記する。
- 選択肢を出す場合は 2 から 4 個に絞る。

使う形は次のどちらかにしてください。

- choice question: 複数案に明確な tradeoff があるとき。
- short direct question: 選択肢化すると意味が落ちるとき。

### Step 3: Ask and consume the answer

- 質問は簡潔に送る。
- 回答が来たら、その回答を source of truth として後続の plan や実装に反映する。
- 回答が partial なら、追加質問は本当に必要な分だけ 1 回にまとめる。
- 回答待ちで止める場合は、何が決まれば再開できるかを明記する。
- 回答なしで進める場合は、採用した assumption をユーザーに見える形で残す。

## Report

質問後または回答反映後は次を短く残してください。

- open question
- user answer or chosen assumption
- downstream impact
