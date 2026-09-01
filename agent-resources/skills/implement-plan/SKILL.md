---
name: implement-plan
description: >-
  承認済みの実装プランファイルを、同一セッションの継続または新しいセッションで端から端まで実行する。
  feature branch を作成し、プランの `## タスク` をテスト込みで進め、lint / test を緑にする。
  リスクに応じて ai-review で独立レビューを受け、commit-changes で論理コミットを作り、open-pr-followup で PR 作成後の CI と AI レビュー初回フォローまで進める。
  承認済みプランを渡されて実装を始めるときに使う。
  例: 「implement-plan スキルで実装して」「プランを実装して」
  ticket-to-plan がプランファイルを指す実装セッションを起動したときにも使う。
  これは ticket-to-plan → implement-plan → commit-changes → open-pr-followup パイプラインの実装フェーズである。
---

# implement-plan

承認済みプランを端から端まで実行する: feature branch を作成し、`## タスク` をテスト込みで実装し、lint / test を緑にし、risk に応じた独立レビューを受け、commit-changes と open-pr-followup へ引き継ぐ。
承認済みプランは contract である。ゴール、受入基準、タスク、対象 files、done_when から外れる必要がない限り re-plan しない。
plan file に `## 動作確認` がある場合は、その指示も contract として扱う。

## Resources

- `../ai-review/SKILL.md`: lint / test が緑になり、実際の diff が medium または high risk に分類された後にコードレビューを委譲する直前に読む。low risk では読まない。
- `../ai-review/references/test-selection-policy.md`: Step 0 でテスト方針を抽出する直前に読む。
- `../create-verification/SKILL.md`: plan の `## 動作確認` が yes で、コミット前 verification の準備をする直前に読む。
- `../run-verification/SKILL.md`: plan の `## 動作確認` が yes で、コミット前 verification を実行する直前に読む。

## Hard constraints

- planning / approval mode が有効な場合は、1〜2行の実行 outline だけを示して終了し、plan を再提示・再議論しない。
- default branch では作業しない。
- orchestrator は low・medium risk の実装コードを自分で書かず、worker へ委譲する。例外は per-task high risk の task、worker が `reason: needs-strong-implementer` を返した task、および1ファイル1〜2行程度で調査を伴わない単発の trivial な変更に限る。
- `## タスク` のチェックボックスは orchestrator だけが編集し、進捗の唯一の source として使う。
- ゴール、受入基準、タスク、対象 files、done_when から外れる scope change が必要な場合は停止して理由を説明する。
- 発生可能性と影響に見合う事象だけを専用実装として実装する。低確率で単純なエラー処理で足りる事象は、専用実装の対象外とし、単純なエラー処理で対処する。
- test を弱める・削除する・skip / pending にしない。
- AI review の全 finding は severity にかかわらずユーザーへ提示し、項目ごとの修正または見送りの明示承認を得てから対応する。
- ユーザーの承認前に AI review finding の修正、見送りの確定、PR body への記録を進めず、未承認の finding が残る場合は停止する。
- 同一実装に対する2回目以降の AI review が必要なときは、再レビューの理由と対象を提示してユーザーの明示的な確認を得る。
- orchestration には現在の AI agent で利用できる上位推論モデルを使う。満たせない、または確認できない場合は一度警告し、ユーザーが明示的にその trade-off を受け入れた場合だけ、弱い設定のまま続行する。
- lint / test の修正ループは最大 3 round。
- 次のいずれかに該当する場合は停止して報告する: plan が欠落・曖昧で次の未チェック task を特定できない / working tree に無関係な変更がある / 既存 branch や ticket の衝突を安全に解決できない / scope change が必要 / 3 round 経ても lint / test が失敗する / 明示的な同意後も必須の独立 reviewer が実行できない / AI review finding のユーザー判断が未完了 / blocking な P1 / P2 が残っている。

## Workflow

### Step 0: Load the plan and prepare the branch

- 指定された絶対パスの plan file と repo convention file（`CLAUDE.md` / `AGENTS.md`）を読む。
- `../ai-review/references/test-selection-policy.md` を読み、計画、実装、レビューで使うテスト選定基準として保持する。
- plan 全体は要約せず、実行に必要な状態だけを抽出する。
  - goal: 1 行
  - acceptance criteria: checklist id
  - 未チェック task: id、depends_on、files、test、done_when、parallel
  - `## 動作確認`: 要否、対象、各確認ポイント、skip 承認ルール
  - lint / test コマンド（plan が repo convention file より優先）
- 同じディレクトリにある `_info_for_user.md` は読み込まず、実装 contract として扱わない。
- plan file と同じディレクトリの今回の実装プランに対応する `_info_for_user.md` を除き、working tree が clean であることを要求する。そうでなければ停止する。
- clean な tree から feature branch を作る: `git switch -c <type>/<plan-id>-<slug>`。`<type>` は repo convention に従い、既存の ticket branch があれば再利用する。

### Step 1: Implement tasks in order

- 未チェック task を依存順に実装する。
- low・medium risk の task は `parallel` の有無にかかわらず原則すべて worker へ委譲する。`parallel: yes` かつ `files` が重ならない ready な task は同時に委譲し、それ以外は1件ずつ順に委譲する。
- 実装前に既存 pattern、影響範囲、data flow の調査が必要な場合は、`codebase-investigator` へ調査を委譲する。
- per-task high risk の task と、worker が `reason: needs-strong-implementer` を返した task だけ orchestrator が実装する。
- 委譲先はその環境で公開されているかで選ぶ:
  - `task-implementer` と `codebase-investigator` が公開されていればそれを使う（Claude では sub-agent、Codex では agent として公開されている場合）。
  - どちらかが無い環境では、その環境の標準 worker（sub-agent 相当）へ同じ brief を渡し、model と effort を明示する。model は Claude=`sonnet` / Codex=`gpt-5.6-luna`、effort は実装 `high` / 調査 `medium` とする。
  - worker 機構がまったく使えない環境: 下位モデルへの委譲が成立しないことを一度警告し、ユーザーが明示的にその trade-off を受け入れた場合だけ orchestrator が逐次実装する。逐次実行する session の既定モデルは Claude=`sonnet` / Codex=`gpt-5.6-luna`, effort=`high`（上位設定は明示指示があるときだけ）。
  - worker brief には task 名、intent、期待する成果、許可された file set、追加・更新する test、`test-selection-policy.md`、local convention を含める。
  - worker は commit、branch 作成、plan file の編集を行わない。
  - `task-implementer` が `reason: needs-strong-implementer` とともに `status: blocked` を返した場合は、その task を orchestrator が実装する。
  - `codebase-investigator` が `reason: needs-orchestrator-decision` とともに `status: blocked` を返した場合は、orchestrator がその判断を行い、判断後に必要な実装を worker へ改めて委譲する。
  - worker がそれ以外の `reason` で `status: blocked` を返した場合は、その task をチェックせず、不足した入力を補って再委譲するか、ユーザーに確認する。

### Step 2: Run targeted checks and mark tasks done

- task が production code に触れる、挙動を変える、medium・high risk である、または後で失敗箇所の特定が難しくなる場合だけ、その task の後に targeted lint / test を実行する。docs / copy / type のみの task はまとめて実行してよい。
- task の `test` と `done_when` が通った場合だけ `- [x]` にする。

### Step 3: Run the full suite and classify risk

- review や引き継ぎの前に、該当する full lint / test suite を実行する。失敗した場合は修正して再実行し、最大 3 round までとする。それでも失敗する場合は停止して出力を報告する。
- plan の `## 動作確認` が yes の場合は、full lint / test が緑になった後、commit 前に `create-verification` で verification を生成または更新し、`run-verification` を実行するかスキップするかをユーザーに確認する。
- ユーザーが実行を選んだ場合は `run-verification` を進める。スキップを選んだ場合は、理由と承認を plan の運用記録として報告に残す。
- lint / test が緑になったら、実際の diff を分類する。
  - low: docs・comment・copy・軽微な type / test / UI 文言・style の変更 → self-review のみ。
  - medium: 通常の feature・bugfix・UI 挙動・API 隣接の変更 → 独立 review を 1 回。
  - high: auth・billing・permission・data 削除・migration・security・production data・広範な refactor・影響範囲不明 → 独立 review。P1 / P2 修正後にもう一度 review をするかユーザーに確認する。

### Step 4: Run independent review for medium/high risk

- medium・high risk の場合だけ `../ai-review/SKILL.md` を読み、未コミット差分を code review mode でレビューする。
- ai-review へ実装した AI、risk、目的、受入基準、lint / test 結果、特別なリスクを渡す。
- ai-review は差分を編集せず、reviewer、信頼性判定、finding を返す。
- reviewer の全 finding を severity、対象、根拠、対応案とともにユーザーへ提示し、各 finding について修正または見送りの明示承認を得る。
- ユーザーが修正を承認した finding だけを実装し、lint / test を再実行する。
- ユーザーが見送りを承認した finding は理由とともに報告へ記録する。P1 / P2 の見送りは blocking finding として扱い、commit と PR 作成へ進まない。
- 修正後に再レビューが必要な場合は、再レビューの理由、前回からの変更点、レビュー対象をユーザーへ提示して明示的な確認を得てから AI review を再実行する。確認が得られない場合は再レビューを実行せず停止する。
- 修正後に必要な再レビューで新しい finding が返った場合も、同じ承認フローを繰り返す。
- すべての `## タスク` がチェック済みで、lint / test が緑で、全 review finding の判断が完了し、blocking な review finding が残っていない場合だけ完了とする。

## Report

日本語で報告: 変更概要 / 主な変更ファイル / lint・test 最終結果 / risk 分類と AI review 結果 / ユーザー承認に基づき対応した finding / 見送った finding / 残した blocking finding。
その後 `commit-changes` で論理 commit を作る。commit 後、`open-pr-followup` で PR 作成と初回 follow-up を行う。
