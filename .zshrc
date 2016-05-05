HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# コマンド履歴検索
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

########################################
#for zsh-completions
fpath=(/usr/local/share/zsh-completions $fpath)
# 補完
# 補完機能を有効にする
autoload -Uz compinit
compinit -u

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
#zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
#                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
#zstyle ':completion:*:processes' command 'ps x -o pid,s,args'


########################################


# Ctrl+Dでzshを終了しない
setopt ignore_eof

# 先頭がスペースならヒストリーに追加しない。
setopt hist_ignore_space

# ディレクトリ名だけで移動できる。
setopt auto_cd

# rm * を実行する前に確認される。
setopt rmstar_wait

# 直前と同じコマンドラインはヒストリに追加しない
setopt hist_ignore_dups

# ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_all_dups

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 移動したディレクトリを記録しておく。"cd -[Tab]"で移動履歴を一覧
setopt auto_pushd

# コマンド訂正
setopt correct

# 補完候補を詰めて表示する
setopt list_packed

# 補完候補表示時などにピッピとビープ音をならないように設定
setopt nolistbeep

# rbenvの設定
if which rbenv > /dev/null; then eval "$(rbenv init -)" ; fi


###############alias###############

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

alias la="ls -a"
alias lg="ls -agh"
alias ll="ls -ahl"

alias rm="rm -i"
alias cp='cp -i'
alias mv='mv -i'

alias rb="ruby"
alias rails="bundle exec rails"
alias ra="bundle exec rails"
alias be="bundle exec"
alias rake="bundle exec rake"
alias xcode="open -a /Applications/Xcode.app"
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"