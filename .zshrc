#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi


# Customize to your needs...

# マシン毎のローカルの設定読み込み
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# 補完機能有効
# autoload はシェル関数を自動読み込みするシェルの組み込み関数
# compinit というシェル関数を自動読み込み
# compinit は補完機能を引き出してくれるコマンド
# autoload 探索するディレクトリは FPATH に入っている
# -U は alias の展開を「しない」ためのオプション
# -z は関数を zsh 形式で読み込むというオプション
fpath=(/usr/local/share/zsh-completions $fpath)
# fpath=(~/.zsh/completion $fpath)

# 実行 -u は compinitのテスト避ける
# -i はいらない？
autoload -Uz compinit && compinit -i

# Preztoで多分設定されていないもの

# 右に時間を表示
RPROMPT=%*

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# Ctrl+Dでzshを終了しない
setopt ignore_eof

# 先頭がスペースならヒストリーに追加しない。
setopt hist_ignore_space

# rm * を実行する前に確認される。
setopt rmstar_wait

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# ベープ音を消す
setopt no_beep

# 区切り文字設定 zprofileに書くとなぜか反映されなかった
export WORDCHARS="*?[]~;=!#$%^(){}<>"

########## alias ##########
# ls
alias la='ls -A'
alias lg='ls -Agh'
alias ll='ls -Ahl'
alias ld='ls -dh .*'
alias lld='ls -ldh .*'

# 確認
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# abridgement
alias g=git
alias e=echo
alias cn='cat -n'
alias pb='pbcopy <'
alias th=touch

# utilty
alias topc='top -o cpu -s 2'

# sudo の後のコマンドでエイリアスを有効にする
# alias sudo='sudo '

# development
alias rb=ruby
alias rails='bundle exec rails'
alias be='bundle exec'
alias ra='bundle exec rails'
alias rubocop='bundle exec rubocop'
# alias nb=nodebrew
alias va=vagrant
alias dk=docker
alias dc='docker-compose'

# app lauch
alias xcode='open -a /Applications/Xcode.app'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'

# ユニバーサルエイリアス
alias -g C='| pbcopy'
alias -g G='| grep -v grep | grep'

# config file
alias -g zrc='~/.zshrc'
alias -g vrc='~/.vimrc'
alias -g zpro='~/.zprofile'
alias vz='vim ~/.zshrc'
alias vv='vim ~/.vimrc'
alias sz='source ~/.zshrc'
alias updatecompletion='rm -f ~/.zcompdump; compinit'
alias -g sshconf='~/.ssh/config'
alias sshlist="cat ~/.ssh/config | grep -e '^Host' | cut -d ' ' -f 2"

# PostgreSQL
alias pgstt='pg_ctl start'
alias pgstp='pg_ctl stop'
alias pgres='pg_ctl restart'
alias pgsts='pg_ctl status'

# prezto update
alias preup='cd ~/.zprezto && git pull && git submodule update --init --recursive ; cd -'

# git
alias gad='git add'
alias gau='git add -u'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gbr='git branch'
alias gbrd='git branch -d'
alias gl='git log --oneline'
alias glg='git log --graph --decorate --oneline'
alias gs='git status -sb'
alias gg='git grep'
alias ggi='git grep -i'
alias ggc='git grep -C'
alias ggci='git grep -i -C'
alias gd='git diff'
alias gdw='git diff -w'
alias gdc='git diff --cached'
alias gdcw='git diff --color-words'
alias gco='git checkout'
alias gsta='git stash'
alias gstalist='git stash list'
alias gstalistp='git stash list -p'
alias gco='git checkout'
alias gco.='git checkout .'
alias gcoma='git checkout master'
alias gpush='git push'
alias gpl='git pull'
alias gshow='git show'
alias gfp='git fetch --prune'
alias gcb="git symbolic-ref --short HEAD | tr -d '\n' | pbcopy" # copy current branch
alias gitalias="git config --list | grep '^alias\.'"
function cdgroot() {
    ROOTPATH=$(git rev-parse --show-toplevel| tr -d '\n')
    cd $ROOTPATH
}
function gpush-u() {
    BRANCH=$(git symbolic-ref --short HEAD | tr -d '\n')
    git push -u origin $BRANCH
}

disable r

########## key bind ##########
# 単語移動
bindkey '^[\e[C' forward-word
bindkey '^[\e[D' backward-word
bindkey ";5C" forward-word
bindkey ";5D" backward-word

# peco history
function peco-select-history() {
    BUFFER="$(history -nr 1 | awk '!a[$0]++' | peco --query "$LBUFFER" | sed 's/\\n/\n/')"
    CURSOR=$#BUFFER
    zle -R -c
}
zle -N peco-select-history
bindkey '^R' peco-select-history

# peco ghq
function peco-src () {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src

# peco ssh
function peco-ssh () {
  local selected_host=$(awk '
  tolower($1)=="host" {
    for (i=2; i<=NF; i++) {
      if ($i !~ "[*?]") {
        print $i
      }
    }
  }
  ' ~/.ssh/config | sort | peco --query "$LBUFFER")
  if [ -n "$selected_host" ]; then
    BUFFER="ssh ${selected_host}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-ssh
bindkey '^H' peco-ssh
