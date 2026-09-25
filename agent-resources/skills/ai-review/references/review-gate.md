# Review Gate

design review または plan review を呼び出す skill が、実行前確認から finding の採否まで従う。
code review の扱いは `implement-plan` に従う。

## 実行前確認

review を実行する前に、対象ファイルの path、mode、reviewer / model / effort を示し、実行するかをユーザーに確認する。
同じ対象の2回目以降の review では、再レビューの理由と前回からの変更点も示す。
この確認を、`../SKILL.md` の起動に対する同意として扱う。
ユーザーが見送った場合は review を実行せず、design.md の `## レビュー記録` に `未実施: <理由>` を書いて次へ進む。

## 実行

`../SKILL.md` を読み、指定の mode で実行する。
reviewer には、各指摘に `## 指摘タグ` のいずれか1つを付けさせる。
review packet には、design.md の `## レビュー記録` で見送り済みの指摘を「見送り済み: 再提起しない」として含める。

## 指摘タグ

| タグ | 対象 | 採用時の戻し先 |
|---|---|---|
| `[plan:T<n>]` | plan.md のタスク、テスト方針、影響範囲 | 呼び出し元が plan.md に反映する |
| `[design:D<n>]` | 確定済みの decision | `../../grill-design/references/decision-log.md` の差し戻し |
| `[design:要件]` | design.md の `## 要件`（ゴール、受入基準、制約、やらないこと） | `prepare-implementation` が `## 要件` を更新する |
| `[design:追加]` | `## 決定事項` や `## 用語` にない判断、用語 | `grill-design` が open の decision または用語として追加する |

タグの無い指摘、または複数の対象にまたがる指摘は、計画 AI が対象を特定したタグを付けてから提示する。
対象を特定できない場合は、その旨を示してユーザーに戻し先を確認する。

## 採否

- 全指摘を severity、タグ、根拠、計画 AI の対応案とともに提示し、項目ごとに採用か見送りの判断を得る。
- ユーザーが採用を承認した指摘だけを、`## 指摘タグ` の戻し先で反映する。
- `[design:要件]` を反映した後は、変更した要件に依存する decision を示し、`decision-log.md` の差し戻しとして扱う。依存する decision が無い場合は、設計確定ゲートだけをやり直す。
- `[design:追加]` を反映した後は、`grill-design` のラウンドで決め、設計確定ゲートをやり直す。
- 単独起動で `prepare-implementation` や `grill-design` が呼び出し元にいない場合は、戻し先のスキルを読んで同じ手順で反映する。
- 見送った指摘は、理由とともに design.md の `## レビュー記録` に書く。
- `UNTRUSTED` または `BLOCKED` の結果は `reviewer-policy.md` に従って扱い、結果と原因を `## レビュー記録` に書く。
- 採用によって対象が実質的に変わった場合は、実行前確認と同じ形で再レビューするかを確認する。
