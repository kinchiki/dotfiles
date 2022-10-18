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

# 補完機能有効
# autoload はシェル関数を自動読み込みするシェルの組み込み関数
# compinit というシェル関数を自動読み込み
# compinit は補完機能を引き出してくれるコマンド
# autoload 探索するディレクトリは FPATH に入っている
# -U は alias の展開を「しない」ためのオプション
# -z は関数を zsh 形式で読み込むというオプション
fpath=(/usr/local/share/zsh-completions $fpath)
# fpath=(~/.zsh/completion $fpath)

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# 実行 -u は compinitのテスト避ける
# -i はいらない？
autoload -Uz compinit # && compinit -i

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


########## env ##########
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LESS='-i -g -s -F -M -R -X -W -N'
export EDITOR=vim
#export ARCHFLAGS='-arch x86_64'
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

# config, utilty
alias topc='top -o cpu -s 2'
alias psg='ps aux | grep -v grep | grep -i'
alias -g zrc='~/.zshrc'
alias -g vrc='~/.vimrc'
alias -g zpro='~/.zprofile'
alias -g tmuxconf='~/.tmux.conf'
alias -g sshconf='~/.ssh/config'
alias vz='vim ~/.zshrc'
alias vv='vim ~/.vimrc'
alias sz='source ~/.zshrc'
alias updatecompletion='rm -f ~/.zcompdump; compinit'
alias sshlist="cat ~/.ssh/config | grep -e '^Host' | cut -d ' ' -f 2"
alias reload='exec $SHELL -l'

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
alias k=kubectl


# app lauch
alias xcode='open -a /Applications/Xcode.app'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'

# ユニバーサルエイリアス
alias -g C='| pbcopy'
alias -g G='| grep -v grep | grep'

# PostgreSQL
alias pgstt='pg_ctl start'
alias pgstp='pg_ctl stop'
alias pgres='pg_ctl restart'
alias pgsts='pg_ctl status'

# prezto update
alias preup='cd ~/.zprezto && git pull && git submodule sync --recursive && git submodule update --init --recursive ; cd -'

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
alias gbrdelete='git branch | grep -v master | xargs git branch -d'
alias gcb="git symbolic-ref --short HEAD | tr -d '\n' | pbcopy" # copy current branch
alias gitalias="git config --list | grep '^alias\.'"

function cdgroot() {
    ROOT_PATH=$(git rev-parse --show-toplevel| tr -d '\n')
    cd $ROOT_PATH
}
function gpush-u() {
    CURRENT_BRANCH=$(git symbolic-ref --short HEAD | tr -d '\n')
    git push -u origin $CURRENT_BRANCH
}
function gpush-tag() {
    LATEST_TAG=$(git describe --tags --abbrev=0 | tr -d '\n')
    git push origin $LATEST_TAG
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

# マシン毎のローカルの設定読み込み
[ -f ~/.zshrc.local ] && source ~/.zshrc.local



########## PATH ##########
export PGDATA=/usr/local/var/postgres
export PATH="$PATH:$HOME/.bin"
export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"

## rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

## NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

## goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"

## gvm`
# [[ -s ~/.gvm/scripts/gvm ]] && source ~/.gvm/scripts/gvm

## pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

#gloud
export GCLOUD="$HOME/dev/google-cloud-sdk"
export PATH="$GCLOUD/bin:$PATH"
source "$GCLOUD/completion.zsh.inc"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# autoload -U +X bashcompinit && bashcompinit
if type terraform &> /dev/null; then
  complete -o nospace -C terraform terraform
fi

if [[ ! -n $TMUX && $- == *l* ]]; then
  # get the IDs
  ID="`tmux list-sessions`"
  if [[ -z "$ID" ]]; then
    tmux new-session
  fi
  create_new_session="Create New Session"
  ID="$ID\n${create_new_session}:"
  ID="`echo $ID | $PERCOL | cut -d: -f1`"
  if [[ "$ID" = "${create_new_session}" ]]; then
    tmux new-session
  elif [[ -n "$ID" ]]; then
    tmux attach-session -t "$ID"
  else
    :  # Start terminal normally
  fi
fi
