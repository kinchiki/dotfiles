# Design Doc Template

design.md を作成・更新する skill が、書き込む直前に読む。
design.md は作業単位の「何を・なぜ」の source of truth であり、このファイルが書式と各セクションの書き手の正典である。
「どう・どの順で」と進捗は plan.md が持つ。

## Path convention

```text
.ai-local/plans/<plan-id>/<YYYYMMDD>_<slug>_design.md
```

チケットをソースとする場合は、`ENG-123` や `github-123` のようなチケット ID を `<plan-id>` に使う。
ユーザー依頼をソースとする場合は、`request-<slug>` を使う。
同じ `<plan-id>` の plan.md は同じディレクトリに置く。

## Section ownership

各セクションは表の書き手だけが書く。
書き手以外の skill は読むだけにし、変更が必要な場合は書き手の skill へ戻す。
単独起動で前段の書き手がいない場合は、起動された skill が該当セクションを同じ書式で書く。

| セクション | 書き手 |
|---|---|
| ヘッダー（`Status` を除く）、`## 要件` | `prepare-implementation` |
| `Status`、`## 用語`、`## 決定事項`、`## スライス` の定義 | `grill-design`（simple task では `prepare-implementation`） |
| `## 結論`、`## 設計`、`## リスク` | `simple-design-doc`（simple task では `prepare-implementation` が `## リスク` だけを書く） |
| `## スライス` の進捗と plan 欄 | `prepare-implementation` |
| `## レビュー記録` の design review | `prepare-implementation` |
| `## レビュー記録` の plan review | `create-plan` |

## Status

- `deciding`: open の decision が残っている、または設計確定ゲートを通過していない。
- `designed`: 設計確定ゲートを通過した。差し戻しが承認された場合は `deciding` に戻す。

## Template

```markdown
# <タイトル>

- **Plan ID:** <plan-id>
- **ソース:** GitHub | Linear | User request — <完全な URL、ID、または元依頼の短い引用>
- **Status:** deciding | designed
- **分類:** simple | non-simple / single | sliced — <判定理由>
- **作成:** <AI agent 名 / モデル ID>、<YYYY-MM-DD>

## 結論
<non-simple のみ。採用した設計とその理由を3行以内で書く。>

## 要件
- **ゴール:** <完了状態を1〜3文で書く。>
- **受入基準:**
  - AC1: <観測可能でテスト可能な成果。ユーザー依頼から推定したものは末尾に (推定) を付ける。>
- **制約:** <維持する挙動、互換性、運用上の制約。>
- **やらないこと:** <スコープ外。>

## 用語
<この作業で確定した用語だけを書く。該当がなければセクションごと省略する。>
- **<用語>**: <1〜2文の定義> _Avoid_: <使わない同義語>

## 決定事項
<書式は ../../grill-design/references/decision-log.md に従う。>
<simple task では「ユーザー判断が必要な設計判断なし: <理由>」の1行だけを書く。>

## 設計
<non-simple のみ。決定事項を組み合わせた結果の設計を、責務配置・data flow・interface の単位で書く。>
<個々の判断理由は書かず、D-ID で参照する。>

## スライス
<sliced のみ。>
- [ ] **S1** <タイトル> — blocked_by: - — delivers: AC1, AC2 — plan: <plan.md の path、または 未作成>

## リスク
- <リスク> — low | medium | high — <理由>

## レビュー記録
<タグと戻し先は ../../ai-review/references/review-gate.md の ## 指摘タグ に従う。>

### design review
- 実行: <reviewer / model / effort、または 未実施: <理由>>
- 信頼性: TRUSTED | UNTRUSTED | BLOCKED
- **F1** [P2][design:D3] <指摘の要約> — 採用: <反映内容> | 見送り: <理由>

### plan review: <plan.md のファイル名>
- <design review と同じ書式。>
```

該当しないセクションは、見出しごと省略する。

## 文体

design.md はレビューする人間が短時間で「何を・なぜ決めたか」を把握できることを最優先にする。
網羅的な説明書ではなく、意思決定の記録として書く。

- 「〜することができます」などの回りくどい語尾を使わず、「〜する」で言い切る。
- 採用しなかった選択肢の説明は、却下理由が伝わる最小限の長さにする。
- 自明なメリット・デメリット（「コード量が増える」「可読性が向上する」だけで終わる説明）を書かない。
- 同じ主張を複数のセクションで繰り返さない。要件と決定事項は ID で参照する。
- やらないことに、スコープ外の一般論や将来の拡張可能性の羅列を書かない。
- 用語定義や背景は、読み手がその用語を知らないと判断できる場合だけ書く。
- 書いた後、各セクションについて「これがなくてもレビュアーは意思決定を理解できるか」を確認し、理解できるなら削る。
- design.md は Notion やチケットへ転記できるよう、ローカル環境に依存するリンクや記法を使わない。
- 具体的なファイルパスは plan.md に書き、design.md ではモジュールや責務の名前で書く。
