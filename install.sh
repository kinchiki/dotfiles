#!/bin/bash

# 未定義変数を使おうとしたらエラーにする
set -u

DOT_FILES_DIRECTORY="${HOME}/src/dotfiles"
cd ${DOT_FILES_DIRECTORY}

echo "start making link..."
echo "===================="

# ./ ../ を除いて .から始まるファイルを対象にループ
for file in .??* ; do
    if [ -d "$file" ]; then continue; fi

    ln -snfv ${DOT_FILES_DIRECTORY}/${file} ${HOME}/${file}
    echo ${file}
done

for dir in .??*/ ; do
    # シンボリックリンクを作成しないディレクトリ
    [[ "$dir" == ".git/" ]] && continue
    [[ "$dir" == ".DS_Store/" ]] && continue
    [[ "$dir" == ".archive/" ]] && continue

    # ホームディレクトリに同名ディレクトリを作成
    mkdir -p "${HOME}/${dir}"

    # ディレクトリ内のファイル・ディレクトリに対してシンボリックリンクを作成
    for file in "${dir}"*; do
        ln -snfv "${DOT_FILES_DIRECTORY}/${file}" "${HOME}/${dir}$(basename "${file}")"
        echo "${dir}$(basename "${file}")"
    done
done

echo "===================="
echo "complete!"
