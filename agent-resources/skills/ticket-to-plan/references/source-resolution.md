# 入力の解決

Step 1 で入力種別を判定し、計画に必要な内容を取得または抽出するときに使う。

## 入力種別

入力を次のいずれかに分類する。

- GitHub issue / PR
- Linear issue
- その他のタスク管理ツールのチケット
- ユーザー依頼

GitHub または Linear の認識形式に一致する場合はチケットとして扱う。
一致しない場合はユーザー依頼として扱い、外部チケットを要求しない。

## 認識形式

GitHub は次の形式を認識する。

- `https://github.com/owner/repo/issues/123`
- `https://github.com/owner/repo/pull/123`
- `owner/repo#123`
- current repo が明らかな場合の `#123`

Linear は次の形式を認識する。

- `ENG-123`
- `ABC-45`
- `https://linear.app/<team>/issue/ENG-123/...`

## チケットの取得

GitHub では `gh` CLI を優先する。

```bash
gh issue view <number> --repo <owner/repo> --comments
gh pr view <number> --repo <owner/repo> --comments
```

`gh` が使えない場合は、ToolSearch で GitHub MCP の read tool を探す。
title、body、body に記載された各 URL、comments、labels、linked issues / PRs、受入基準を確認する。

Linear では ToolSearch で `linear issue` と `linear comments` を探す。
issue と discussion を取得し、要件に関係する parent、sub-issues、project / milestone を確認する。

その他のタスク管理ツールでは利用可能な connector、API、または CLI を使い、本文、discussion、関連チケット、受入基準を取得する。

## ユーザー依頼の抽出

依頼文と会話 context を情報源として次を抽出する。

- 依頼された変更
- 対象領域
- 明示された制約
- 推定した受入基準
- 前提と未解決事項

依頼が別 skill、local file、または repo 内概念を指す場合は、Step 2 で該当ファイルとコードベースを調査する。

## 入力要約と受入基準の抽出

取得または抽出した内容を3〜6行で要約し、ユーザーへ返す。
要約には目的、対象、主要な制約、受入基準、実装を左右する未解決事項を含める。
明示された受入基準を優先し、ユーザー依頼では観測可能な完了状態を推定して区別する。

入力が薄い、矛盾している、または受入基準が不足する場合は、その gap をユーザー向け情報ファイルの `リスク・未解決の論点` に記録する予定として扱う。
gap が計画の成否または実装範囲に影響する場合は、`../../ask-user-questions/SKILL.md` に従ってユーザーへ確認する。
