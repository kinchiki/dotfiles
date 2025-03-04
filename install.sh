#!/bin/bash

# 未定義変数を使おうとしたらエラーにする
set -u

DOT_DIRECTORY="${HOME}/src/dotfiles"
cd ${DOT_DIRECTORY}

echo "start making link..."
echo "===================="

# ./ ../ を除いて .から始まるファイルを対象にループ
for file in .??* ; do
    # シンボリックリンクリンクを作成しないファイル
    [[ "$file" == ".git" ]] && continue
    [[ "$file" == ".DS_Store" ]] && continue
    [[ "$file" == ".zshrc_old" ]] && continue

    ln -snfv ${DOT_DIRECTORY}/${file} ${HOME}/${file}
    echo ${file}
done

echo "===================="
echo "complete!"
