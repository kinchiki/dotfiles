# PR Body Template

リポジトリに `.github/pull_request_template.md` またはより具体的なローカル PR 規約がない場合、Step 2 でこのテンプレートを使う。
プラン、チケット、動作確認結果をもとに記入する。

```markdown
## チケット
<指定されたチケットの URL>

## 概要
<この PR で何を・なぜ変えたか（1〜3行）>

## 変更点
- <主要な変更を箇条書き>

## テスト
- <本PRが影響するテストの実行コマンド（例: dip rspec x1.rb x2.rb）>

## 受入基準
- [x] <プランの Acceptance criteria を転記し、満たしたものをチェック>
```
