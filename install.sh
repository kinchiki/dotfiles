#!/bin/bash

# 未定義変数を使おうとしたらエラーにする
set -u

DOT_DIRECTORY="${HOME}/src/dotfiles"
cd ${DOT_DIRECTORY}

echo "start making link"
echo

# ./ ../ を除いて .から始まるファイルを対象にループ
for f in .??*
do
    # シンボリックリンクリンクを作成しないファイル
    [[ "$f" == ".git" ]] && continue
    [[ "$f" == ".DS_Store" ]] && continue
    [[ "$f" == ".zshrc_old" ]] && continue

    ln -snfv ${DOT_DIRECTORY}/${f} ${HOME}/${f}
    echo "$f"
done

echo
echo "complete!"
