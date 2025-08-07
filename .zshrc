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

# 補完はpreztoで設定されているため、コメントアウト

# Customize to your needs...

# 補完機能有効
# autoload はシェル関数を自動読み込みするシェルの組み込み関数
# compinit というシェル関数を自動読み込み
# compinit は補完機能を引き出してくれるコマンド
# autoload 探索するディレクトリは FPATH に入っている
# -U は alias の展開を「しない」ためのオプション
# -z は関数を zsh 形式で読み込むというオプション
# fpath=(/usr/local/share/zsh-completions $fpath)
# fpath=(~/.zsh/completion $fpath)

# [[ $commands[kubectl] ]] && source <(kubectl completion zsh)
# [[ $commands[docker] ]] && source <(docker completion zsh)
# [[ $commands[helm] ]] && source <(helm completion zsh)
# [[ $commands[fzf] ]] && source <(fzf --zsh)

# 実行 -u は compinitのテスト避ける
# -i はいらない？
# autoload -Uz compinit && compinit #-i

# Preztoで多分設定されていないもの

# 時間を表示
# RPROMPT=%*
export PROMPT="%* ${PROMPT}"

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
eval "$(/opt/homebrew/bin/brew shellenv)"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LESS='-i -g -s -F -M -R -X -W -N'
export EDITOR=vim
#export ARCHFLAGS='-arch x86_64'
export WORDCHARS="*?[]~;=!#$%^(){}<>"

########## alias ##########
# ユニバーサルエイリアス
alias -g C='| pbcopy'
alias -g G='| grep -v grep | grep -i --color=auto'

# ls
alias la='ls -A'
alias lg='ls -Agh'
alias ll='ls -Ahl'
alias ld='ls -dh .*'
alias lld='ls -ldh .*'

# grep
export GREP_COLOR='01;31'
alias -g grep='grep -i --color=auto'

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
alias envg='env | grep -v grep | grep -i'
alias -g zrc='~/.zshrc'
alias -g vrc='~/.vimrc'
alias -g zpro='~/.zprofile'
alias -g tmuxconf='~/.tmux.conf'
alias -g sshconf='~/.ssh/config'
alias vz='vim ~/.zshrc'
alias vv='vim ~/.vimrc'
alias vaws='vim ~/.aws/'
alias vzlocal='vim ~/.zshrc.local'
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
alias k=kubectl
alias kg='kubectl get'
alias kd='kubectl describe'
alias mk=minikube
alias ter=terraform
alias terp='terraform plan'
alias cop=copilot
alias cops='copilot svc'
alias cope='copilot env'
alias copsd='copilot svc deploy'
alias copse='copilot svc exec'

# app lauch
alias xcode='open -a /Applications/Xcode.app'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'

# Docker
export DOCKER_BUILDKIT=1
alias dk=docker
alias dc='docker compose'
alias dcu='docker compose up'
alias dkc='docker container'
alias dkn='docker network'
alias dk-rm-cache='docker buildx prune -f'
alias dk-rm-image='docker image prune -af'
#alias dk-rm-network='docker network prune -f'
#alias dc-local-up='docker compose -f docker-compose.yml -f docker-compose.local.yml up'

# PostgreSQL
alias pgstt='pg_ctl start'
alias pgstp='pg_ctl stop'
alias pgres='pg_ctl restart'
alias pgsts='pg_ctl status'

# prezto update
alias preup='cd ~/.zprezto && git pull && git submodule sync --recursive && git submodule update --init --recursive ; cd -'

# git
alias gau='git add -u'
alias gaa='git add -A'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gbr='git branch'
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
alias gsi='git switch'
alias gsic='git switch -c'
alias gsi-='git switch -'
alias gco='git checkout'
alias gcp='git cherry-pick'
# alias gcoma='git checkout master'
alias gpush='git push'
alias gpl='git pull'
alias gshow='git show'
alias gtag='git tag'
alias gfp='git fetch --prune'
alias gbrdelete='git branch | grep -v master | grep -v main | xargs git branch -d'
alias gcb="git symbolic-ref --short HEAD | tr -d '\n' | pbcopy" # copy current branch
alias gitalias="git config --list | grep '^alias\.'"

function cdgroot() {
    local -r ROOT_PATH=$(git rev-parse --show-toplevel| tr -d '\n')
    cd $ROOT_PATH
}
function gpush-u() {
    local -r CURRENT_BRANCH=$(git symbolic-ref --short HEAD | tr -d '\n')
    git push -u origin $CURRENT_BRANCH
}
function gtagpush() {
    local -r LATEST_TAG=$(git describe --tags --abbrev=0 | tr -d '\n')
    git push origin $LATEST_TAG
}

disable r

########## key bind ##########
# 単語移動
bindkey '^[\e[C' forward-word
bindkey '^[\e[D' backward-word
bindkey ";5C" forward-word
bindkey ";5D" backward-word

# select history
# function select-history() {
#     # local -r BUFFER="$(history -nr 1 | awk '!a[$0]++' | fzf --query "$LBUFFER" | sed 's/\\n/\n/')"
#     local -r BUFFER="$(history -nr 1 | awk '!a[$0]++' | peco --query "$LBUFFER" | sed 's/\\n/\n/')"
#     local -r CURSOR=$#BUFFER
#     zle -R -c
# }
# zle -N select-history
# bindkey '^R' select-history

export FZF_CTRL_R_OPTS="--no-sort --layout=reverse --preview 'echo {}' --preview-window 'up:2:wrap'"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# select ghq
function select-src () {
  local -r selected_dir=$(ghq list -p | fzf --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    local -r BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N select-src
bindkey '^]' select-src

# select ssh
function select-ssh () {
  local -r selected_host=$(awk '
    tolower($1)=="host" {
      for (i=2; i<=NF; i++) {
        if ($i !~ "[*?]" && $i !~ /ap-northeast-1/) {
          print $i
        }
      }
    }
  ' ~/.ssh/config | sort | fzf --query "$LBUFFER")
  if [ -n "$selected_host" ]; then
    local -r BUFFER="ssh ${selected_host}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N select-ssh
bindkey '^H' select-ssh

# マシン毎のローカルの設定読み込み
[ -f ~/.zshrc.local ] && source ~/.zshrc.local



########## PATH ##########
export PGDATA=/usr/local/var/postgres
export PATH="$PATH:$HOME/bin"

## node
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

#export VOLTA_HOME="$HOME/.volta"
#export PATH="$VOLTA_HOME/bin:$PATH"

## rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

## NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

## goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"

## pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
# eval "$(pyenv init --path)"
# alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew' # fix brew doctor warning

#gloud
export GCLOUD="$HOME/dev/google-cloud-sdk"
export PATH="$GCLOUD/bin:$PATH"
# source "$GCLOUD/completion.zsh.inc"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# autoload -U +X bashcompinit && bashcompinit
# if type terraform &> /dev/null; then
#  complete -o nospace -C /opt/homebrew/Cellar/tfenv/3.0.0/versions/1.3.9/terraform terraform
# fi

# if [[ ! -n $TMUX && $- == *l* ]]; then
#  # get the IDs
#  ID="`tmux list-sessions`"
#  if [[ -z "$ID" ]]; then
#    tmux new-session
#  fi
#  create_new_session="Create New Session"
#  ID="$ID\n${create_new_session}:"
#  ID="`echo $ID | $PERCOL | cut -d: -f1`"
#  if [[ "$ID" = "${create_new_session}" ]]; then
#    tmux new-session
#  elif [[ -n "$ID" ]]; then
#    tmux attach-session -t "$ID"
#  else
#    :  # Start terminal normally
#  fi
#fi

function kill-grep () {
  local -r target_process=$1
  ps aux | grep -v grep | grep -i $target_process | awk '{ print "kill -9", $2 }' | sh
}
