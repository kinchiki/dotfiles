# Decision Log

design.md の `## 決定事項`、`## 用語`、`## スライス` を書くとき、および確定済みの decision を差し戻すときに読む。

## Decision

```markdown
### D1 <判断の短いタイトル>
- status: open | decided | superseded by D5
- depends_on: - | D2, D3
- decision: <決まった内容。open の間は 未定>
- why: <選んだ理由と、根拠にした事実を1〜2文>
- rejected: <却下した案>: <却下理由>
- decided_by: user (grill R2) | user (design review F1) | user (plan review F3)
- ADR候補: no | yes — <3条件の根拠>
```

ID は design.md 内の連番にし、superseded になった ID も欠番にせず残す。
`decided_by` は常にユーザーの判断を指す。
調査で確定した事実は decision にせず、関連する decision の `why` か `## 要件` の制約に書く。
既存 pattern や制約から一意に決まる判断も decision にしない。
実行可能な案が1つだけの場合は、`rejected` に検討した主要な代替案と具体的な棄却理由を書く。

## 用語

確定した用語は、その時点で `## 用語` に書く。

- 同じ概念に複数の呼び方がある場合は1つを選び、他を `_Avoid_` に書く。
- 定義は1〜2文にし、何をするかではなく何であるかを書く。
- この project の文脈に固有の概念だけを書き、一般的なプログラミング概念を書かない。
- 実装の詳細を書かない。

## ADR候補

次の3条件をすべて満たす decision だけを、ADR候補にするかユーザーへ確認する。

1. 元に戻しにくい: 後で考えを変えるコストが大きい。
2. 理由なしでは驚く: 将来の読み手が「なぜこうしたのか」と疑問に思う。
3. 実際の trade-off の結果: 実際に代替案があり、具体的な理由で選んだ。

ADR候補は、design.md を Notion やチケットへ転記するときに長期保存する判断の目印として使う。
この workflow では ADR の別ファイルを作らない。

## スライス

sliced の変更では、分割方法を decision として決め、結果を `## スライス` に書く。

- 各スライスは全層を貫く narrow な vertical slice にし、単独で検証できるようにする。
- 各スライスを1 PR・1実装セッションに収まる大きさにする。
- 変更を容易にする prefactor は先頭のスライスにする。
- 1つの機械的な変更が広範囲に波及する wide refactor は、expand、呼び出し元の段階的な migrate、contract の順に分ける。
- 各スライスに blocked_by と delivers（担当する受入基準の ID）を書く。
- 全受入基準を、いずれかのスライスの delivers に含める。

## 差し戻し

`decided` の decision は、後続フェーズでは固定された入力として扱う。
変更は、次のいずれかをきっかけにした差し戻しだけで行う。

- decision の前提を崩す新しい事実
- ユーザーが採用した design review または plan review の指摘
- ユーザーの明示的な変更指示

差し戻しは次の順に進める。

1. 差し戻す decision、きっかけ、depends_on をたどって影響を受ける decision と plan のタスクを示し、差し戻しの承認を得る。
2. 承認後、元の decision を `superseded by D<新しい ID>` にし、新しい decision を open で追加する。
3. 影響を受ける decision は、前提が変わっても結論が保たれるかを次のラウンドで確認し、変わる場合は同じ手順で差し戻す。
4. design.md の `Status` を `deciding` に戻し、open の decision だけをラウンドで決める。
5. 決定後、設計確定ゲートをやり直す。
6. superseded の decision を参照する承認済み plan.md は `Status: draft` に戻し、create-plan の human review からやり直す。
