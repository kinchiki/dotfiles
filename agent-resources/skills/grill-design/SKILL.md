---
name: grill-design
description: >-
  実装前の設計判断を依存関係付きの design tree として整理し、前提が解決済みの decision だけをラウンドごとにユーザーへ聞いて、未解決の設計判断がなくなるまで shared understanding を詰める。
  事実調査は agent が行い、decision はユーザーが行い、確定した decision と用語をその場で design.md に記録する。
  prepare-implementation から non-simple task の設計判断を委譲されたとき、または「設計を詰めたい」「grill して」「設計判断を整理して」と依頼されたときに使う。
---

# grill-design

設計判断を design tree として整理し、ユーザーと shared understanding に達するまでラウンドを回す。
事実は agent が調べ、decision はユーザーが決め、結果を design.md に残す。

## 参照先

- `../simple-design-doc/references/design-doc-template.md`: Step 1 で design.md を読む、または作成する直前に読む。
- `references/decision-log.md`: Step 2 で design.md に decision を書く前に読み、差し戻しを扱うときにも従う。
- `../simple-design-doc/SKILL.md`: Step 4 で frontier が空になり、設計を記録する直前に読む。

## 必須制約

- production code を編集しない。書き込むのは design.md だけにする。
- 事実は agent が調べる。repo、チケット、ドキュメント、過去の design.md で分かることをユーザーへ聞かない。
- decision はユーザーが決める。推奨案を示しても、回答を得るまで `decided` にしない。
- 各ラウンドには frontier の decision だけを含める。同じラウンドの未回答の decision に依存する問いは、後のラウンドへ回す。
- `decided` の decision を聞き直さない。変更は `references/decision-log.md` の差し戻しだけで行う。
- このスキルの問いには `ask-user-questions` を使わず、Step 3 の形式で聞く。
- 回答はラウンドごとに design.md へ反映する。
- frontier が空になり、ユーザーが共有理解を確認するまで、plan 作成や実装へ進まない。

## Workflow

### Step 1: 入力と既存の判断を読む

- design.md があれば全文を読む。無ければ template に従って作成し、会話と入力からヘッダーと `## 要件` を書く。
- 呼び出し元から候補の decision が渡された場合は、初期の design tree に使う。
- 同じ repo の `.ai-local/plans/*/*_design.md` にある `## 用語` と `ADR候補: yes` の decision を読み、今回の用語と前提の照合に使う。
- repo の `AGENTS.md` / `CLAUDE.md` を読む。

### Step 2: design tree を作る

- ゴールと受入基準を満たすために必要な設計判断を列挙し、各 decision の depends_on を決める。
- interface、責務配置、data flow、状態管理、互換性、migration、運用特性、制約の優先順位、スコープの境界を観点として漏れを確認する。
- 呼び出し元が sliced の候補とした場合、または1 PR・1実装セッションに収まらないと判断した場合は、スライス分割を decision として加える。
- 列挙した decision を `status: open` で design.md に書く。

### Step 3: ラウンドを回す

frontier は、depends_on がすべて `decided` の open な decision である。
各ラウンドで frontier をすべて聞き、回答を待つ。

各問いには、既知の事実、判断が必要な理由、実行可能で実質的に異なる選択肢（最大3つ）とそれぞれの trade-off、推奨案とその理由を含める。
同じ設計 family の微修正版は1案にまとめ、既知の制約に反する案や明らかに劣る案を選択肢に含めない。

```text
### ラウンド <N>

❓ **Q1（D3）- <問いのタイトル>**: <既知の事実、判断が必要な理由、選択肢と trade-off>

➡️ 推奨: <推奨案と理由>

---

❓ **Q2（D4）- <問いのタイトル>**: <...>

➡️ 推奨: <推奨案と理由>
```

質問 UI がある環境で、frontier の問いが UI の上限に収まる場合は UI を使ってよい。

ラウンド中は次を行う。

- 問いに事実が必要な場合は、使えるなら sub-agent に調査させる。調査中の事実に依存する問いだけを待たせ、残りの frontier は先に聞く。
- ユーザーの用語が過去の `## 用語` とずれる場合や曖昧な場合は、正準の用語を提案して確認する。
- 概念の境界は、具体的なシナリオで確かめる。
- ユーザーの説明がコードと食い違う場合は、その食い違いを示して確認する。
- ADR候補の3条件を満たす decision は、次のラウンドで ADR候補にするかを聞く。

回答を得たら、次を行う。

- 回答した decision を `decided` にし、`decision`、`why`、`rejected`、`decided_by` を書く。
- 確定した用語を `## 用語` に書く。
- 回答から生じた新しい decision を tree に加え、次の frontier を計算する。
- 組み合わせ案や再検討を求められた場合は、その観点を調査して選択肢を更新し、同じ decision を次のラウンドで改めて聞く。

### Step 4: 記録して共有理解を確認する

- frontier が空になったら `../simple-design-doc/SKILL.md` に従い、`## 結論`、`## 設計`、`## リスク` を記録する。
- simple-design-doc が未解決の判断を返した場合は、tree に加えて Step 3 に戻る。
- 結論、decision の一覧、スライス、やらないことを提示し、共有理解に達したかを確認する。
- この確認で確定するのは design.md の要件、決定事項、設計、スライスであることを明示する。
- 修正があれば、該当する decision を差し戻すか、新しい decision としてラウンドを追加する。
- 確認を得たら `Status: designed` にする。

## Report

design.md の path、`decided` の decision 数、ADR候補、スライス、呼び出し元が次に行うことを報告する。
