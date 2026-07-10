---
name: open-pr-followup
description: >-
  PR 作成後に一定時間待ち、GitHub Actions CI と AI レビュー / レビューコメントを確認して、既存スキルへ切り出して後追い対応する。
  PR 作成は open-pr、CI 失敗は GitHub plugin の gh-fix-ci、レビューコメント対応は address-pr-comments または GitHub plugin の gh-address-comments を使い、必要なら `update-pr-description` で PR 本文も同期する。
  例: 「PR作って、CIとAIレビューまで見て」「PR作成後にレビュー指摘とCI失敗も対応して」「open-pr のあとしばらく待って後追いして」。
  implement-plan / commit-changes 完了後に、PR 作成だけで止めずに CI と AI レビューの初回フォローまで進めたいときに使う。
---

# open-pr-followup

PR を作成し、初回の CI と AI レビューを確認して、必要な follow-up を専門スキルに委譲する orchestrator です。

## Scope

- `open-pr` で PR を作る。
- CI と AI review / unresolved review comments を確認する。
- CI failure は `gh-fix-ci` に委譲する。
- review comments は `address-pr-comments` 優先、または `gh-address-comments` に委譲する。
- 必要なら `update-pr-description` で PR description の整合性を取り直す。
- 残った未コミット差分は `commit-changes` で commit し、ユーザー確認後に push する。

## Resources

- `references/followup-workflow-details.md`: PR metadata、poll fallback、CI inspection、lane integration、push command が必要なとき読む。
- `scripts/poll-pr-signals.sh`: wait / poll / CI / AI review / unresolved thread の集約に使う。
- `../create-verification/SKILL.md`: レビュー / CI 対応後の verification を追記する直前に読む。
- `../run-verification/SKILL.md`: レビュー / CI 対応後の verification を実行する直前に読む。

## Hard constraints

- PR 作成だけなら `open-pr` で止める。
- dirty tree は `commit-changes` に引き渡す。
- follow-up 修正 (review 指摘・CI 失敗) の commit は、実行前にユーザー確認を取る。
- review 指摘や CI failure を直した後に手動 verification が必要なら、commit / push 前に run / skip をユーザー確認で決める。
- push と GitHub writeback は確認ポイントを守る。
- concrete PR が必要。
- test を弱める・削除・skip する行為は禁止。
- follow-up cycle は最大 2 回。
- 報告は CI status、review status、失敗要点、URL、commit hash だけ。

## Workflow

### Step 0: Prerequisites

ユーザーが post-PR follow-up を求めているか確認する。
working tree が clean か `open-pr` に渡せるなら進める。
dirty tree は `commit-changes` に引き渡し、initial PR 作成は `open-pr` に委譲する。

### Step 1: Create PR and get identity

`open-pr` を実行する。
`scripts/poll-pr-signals.sh --pr <pr> --metadata-only` で PR URL、number、head branch、base branch を取得する。
Script 実行不可なら `references/followup-workflow-details.md` の fallback (`gh pr view`) を使う。

### Step 2: Wait and poll

`scripts/poll-pr-signals.sh` を実行し、初回 signals (checks、AI review、unresolved threads) を待つ。
Script 実行不可なら `references/followup-workflow-details.md` の fallback を使う。
AI review が検出できなくても CI inspection は続ける。

### Step 3: Delegate follow-up work

CI failure がある場合は `gh-fix-ci` に委譲する。
Actionable review comments がある場合は `address-pr-comments` 優先、または `gh-address-comments` に委譲する。
委譲先には、修正後の commit を実行する前にユーザー確認を取るよう指示する。
review lane が `address-pr-comments` 以外の場合は、PR description 更新まで完了したか確認する。
review lane が PR description 更新を扱わない場合は、`update-pr-description` を追加で実行する。
各スキルが commit / push / PR description 更新 / reply / resolve を完了するまで待つ。

### Step 4: Commit and push remaining changes

review 指摘または CI failure を受けて挙動が変わる修正を行った場合は、`create-verification` で既存 verification へ必要な確認を追記する。
その後、`run-verification` を実行するかスキップするかをユーザーに確認する。
スキップが選ばれた場合は、理由を報告へ残す。
Delegated work 以外に未コミット差分がある場合は `commit-changes` で local commit を作る。
ユーザー確認後に push する。
次 cycle のため Step 2 で再度待つ。

### Step 5: Report

日本語で報告：
- PR URL
- CI status と failing / external checks
- AI review / unresolved comment status
- 委譲した専門スキル と実施内容
- 最終 lint / test status
- push / writeback 完了状況
- 残件と最終 status (`完了`、`追加対応待ち`、`ブロック中`)
