# Follow-up Workflow Details

Step 0 から Step 5 を実行するときに、この reference を使う。
`SKILL.md` をオーケストレーションに集中させるため、コマンドの実行例と lane 統合の詳細をこのファイルに置く。
以下のすべての `scripts/` コマンドは、このスキル自身のディレクトリから実行する。

## Resolve PR Metadata

`open-pr` が成功した後、具体的な PR の識別情報を取得する。
最初に helper script を使う。このスクリプトは待機や signal の収集を行わず、`PR_URL`、`PR_NUMBER`、`HEAD_REF`、`BASE_REF` を出力する。

```bash
scripts/poll-pr-signals.sh --pr <pr-number-or-url-or-branch> --metadata-only
```

スクリプトを実行できない場合は、fallback command を使う。

```bash
gh pr view --json number,url,headRefName,baseRefName,state,title
```

## Wait And Poll

`SKILL.md` の Step 2 にある待機ポリシーを使う。
最初に helper script を使う。

```bash
scripts/poll-pr-signals.sh --pr <pr-number-or-url-or-branch> --initial-wait-seconds 300 --poll-interval-seconds 180 --max-polls 3
```

スクリプトは、`CHECKS_STATUS`、`CHECKS_FAIL_COUNT`、`CHECKS_PENDING_COUNT`、`UNRESOLVED_THREAD_COUNT`、`AI_REVIEW_DETECTED` を含む簡潔な要約を出力する。
ユーザーが待機間隔を指定した場合は `--initial-wait-seconds` を使う。

スクリプトを実行できない場合は、fallback command を使う。
既存の短縮コマンド例は次のとおり。

```bash
sleep 300
```

待機時間内に AI review を検出したか記録する。
検出しなかった場合も CI の調査を続け、review signal がなかったことを報告する。

## Inspect Checks

レビューコメントより先に CI を調査する。

利用できる場合は、`poll-pr-signals.sh` の出力を主要な CI signal として使う。
fallback として、または特定の check の詳細を掘り下げるために、以下のコマンドを使う。

```bash
gh pr checks <pr-number-or-url>
```

- pass と skipped の check は、記録済みの non-blocking state として扱う。
- `ci/circleci: test` は無視し、`gh-fix-ci` には委譲しない。この check は、すべての件数、pending の待機、失敗した check の要約から除外する。
- GitHub Actions の失敗は `gh-fix-ci` に委譲する。
- `gh-fix-ci` で調査できない外部 check の失敗は、URL とともに報告する。

## Integrate Follow-Up Lanes

- CI failure と対応可能なレビューコメントを別々の lane に分ける。
- CI は `gh-fix-ci` に委譲する。
- レビューコメントは `address-pr-comments` に委譲する。ローカルの Skill が利用できない場合は `gh-address-comments` に委譲する。
- review lane 自身が PR description を更新しなかった場合は、書き戻し完了を宣言する前に `update-pr-description` を別の lane として実行する。
- 並列化は、別々の worktree、別々の session、または重複しない file set を使う場合にだけ行う。
- 1つの working tree でファイルが重複する場合は、作業を直列化する。
- 各 follow-up lane は、修正を commit する前にユーザーの確認を得る。
- review lane が既に commit、push、PR description の更新、返信、thread の解決まで行っている場合は、その結果を記録し、それらの side effect を繰り返さない。

## Push Remaining Fixes

`commit-changes` がローカル commit を作成し、ユーザーが push を確認した後、review lane 以外で残っている commit にだけ使う。

```bash
git push
```
