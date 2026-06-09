#!/bin/bash

# エラーにする
# -e コマンドが失敗したら止まる
# -u 未定義の変数でエラー
# -o パイプの途中の失敗を全体の失敗とする
set -euo pipefail

DOT_FILES_DIRECTORY="${HOME}/src/dotfiles"
cd "${DOT_FILES_DIRECTORY}"

echo "start making link..."
echo "===================="

# ==================== 設定 ====================

# symlink を張らないファイル
declare -a SKIP_FILES=(
  ".DS_Store"
  ".gitignore"
  ".claude/settings.local.json"
)

# symlink を張らないディレクトリ
declare -a SKIP_DIRS=(
  ".git"
  ".vscode"
  "archive"
)

# ==================== ヘルパー関数 ====================

# 値が配列に含まれているかチェック
contains_value() {
  local value="$1"
  shift
  local item
  for item in "$@"; do
    [ "$item" = "$value" ] && return 0
  done
  return 1
}

# ディレクトリをスキップすべきか判定
should_skip_dir() {
  contains_value "$1" "${SKIP_DIRS[@]}"
}

# ファイルをスキップすべきか判定
should_skip_file() {
  contains_value "$1" "${SKIP_FILES[@]}"
}

# find コマンド用のファイル名除外条件を生成
build_skip_file_conditions() {
  local conditions=""
  for skip in "${SKIP_FILES[@]}"; do
    conditions="${conditions}! -name '${skip}' "
  done
  echo "$conditions"
}

# find コマンド用のディレクトリパス除外条件を生成
build_skip_dir_path_conditions() {
  local conditions=""
  for skip in "${SKIP_DIRS[@]}"; do
    conditions="${conditions}-not -path '*/${skip}/*' "
  done
  echo "$conditions"
}

# 直下のドットファイルを ~/ に symlink する
# ln コマンドのオプション
  # -s シンボリックリンクを作る
  # -n リンク先がディレクトリへのシンボリックリンクでも、その中に入らずリンク自体を扱う
  # -f 既存の target があれば削除して上書きする
  # -v 実行内容を表示する
for file in .??*; do
  [ -d "$file" ] && continue
  should_skip_file "$file" && continue
  ln -snfv "${DOT_FILES_DIRECTORY}/${file}" "${HOME}/${file}"
done

# 直下のドットディレクトリを再帰的にたどり、ディレクトリは作成し、ファイルは個別に symlink する。
# ディレクトリごと symlink すると ~/.claude のようにアプリが生成物を書き込む実体ディレクトリと衝突し、管理したくないファイルもg管理されてしまう。
# （dotfiles に実在するファイルだけが対象になるので、.codex のように一部だけ管理したいディレクトリでも置いたファイルしかリンクされない）
for dir in .??*/; do
  dir="${dir%/}"
  should_skip_dir "$dir" && continue

  # ディレクトリ構造を作成（SKIP_DIRS 配下は除外）
  find "$dir" -type d $(build_skip_dir_path_conditions) -print0 |
    while IFS= read -r -d '' d; do
      mkdir -p "${HOME}/${d}"
    done

  # ファイルを symlink（SKIP_DIRS と SKIP_FILES の除外）
  find "$dir" -type f $(build_skip_dir_path_conditions) $(build_skip_file_conditions) -print0 |
    while IFS= read -r -d '' f; do
      should_skip_file "$f" && continue
      ln -snfv "${DOT_FILES_DIRECTORY}/${f}" "${HOME}/${f}"
    done
done

echo "===================="
echo "complete!"
