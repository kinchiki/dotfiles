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
  # -U は alias の展開をしない＝元の文字列のまま補完？の関数定義を取り込む
    # 補完読込み時に、aliasと同じのものがあったら、aliasに置き換わってしまうことを防ぐ
    # 必ずつけるオプション
  # -z は関数を zsh 形式で読み込むというオプション
  # -X は autoload された関数の中で、自分自身の本体をロードするためのオプション
    # 基本使わない。
    # 実行中の autoload 関数を展開するためのもの
    # +X はその -X を明示的に無効にする

# fpath=(/usr/local/share/zsh-completions $fpath)
# fpath=(~/.zsh/completion $fpath)

# Bash用の補完も有効にする
# compinit のオプション
  # -i は insecure なものを無視＝警告を出さずに読み込まない
  # -u は insecure なものも警告を出さずに使うため、危険
autoload -Uz compinit bashcompinit
compinit
bashcompinit

command -v aws > /dev/null 2>&1 && complete -C '/usr/local/bin/aws_completer' aws

# 消しても補完が動くかも
# command -v kubectl > /dev/null 2>&1 && source <(kubectl completion zsh)
# command -v docker > /dev/null 2>&1 && source <(docker completion zsh)
# command -v helm > /dev/null 2>&1 && source <(helm completion zsh)
# command -v fzf > /dev/null 2>&1 && source <(fzf --zsh)
# command -v gcloud > /dev/null 2>&1 source "$GCLOUD/completion.zsh.inc"


# Preztoで多分設定されていないもの

# 時間を表示
# RPROMPT=%*
PROMPT="%* ${PROMPT}"
# プロンプトを変える
PURE_PROMPT_SYMBOL='$'

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


# '' と "" の使い分け
  # 代入時に $VAR を展開したいなら ""
  # 完全な文字列として固定したいなら ''
  # ただし値に '' を多く含むなら、可読性優先で ""

########## env ##########
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
WORDCHARS='*?[]~;=!#$%^(){}<>'

########## alias ##########
# ls
alias la='ls -A'
alias lg='ls -Agh'
alias ll='ls -Ahl'
alias ld='ls -dh .*'
alias lld='ls -ldh .*'

# grep
# export GREP_COLOR='mt01;31'
# alias -g grep='grep -i --color=auto'
alias -g grep='grep -i'

# 確認
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# abridgement
alias g=git
alias e=echo

# config, utility
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
alias tz='tmux source-file ~/.tmux.conf'
alias reload='exec $SHELL -l'

# sudo の後のコマンドでエイリアスを有効にする
# alias sudo='sudo '

# development
alias rb='ruby'
alias rails='bundle exec rails'
alias be='bundle exec'
alias ra='bundle exec rails'
alias rubocop='bundle exec rubocop'
alias va='vagrant'
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias mk='minikube'
alias ter='terraform'
alias terp='terraform plan'

# AI
alias cc='claude'
alias co='codex'

# Docker
alias dk='docker'
alias dc='docker compose'
alias dcu='docker compose up'
alias dkc='docker container'
alias dkn='docker network'
alias dk-rm-cache='docker buildx prune -f'
alias dk-rm-image='docker image prune -af'
#alias dk-rm-network='docker network prune -f'
#alias dc-local-up='docker compose -f docker-compose.yml -f docker-compose.local.yml up'

# podman
# alias docker='podman'
# alias docker-compose='podman compose'
# alias dk='podman'
# alias dc='podman compose'
# alias dcu='podman compose up'
# alias dkc='podman container'

# PostgreSQL
alias pgstt='pg_ctl start'
alias pgstp='pg_ctl stop'
alias pgres='pg_ctl restart'
alias pgsts='pg_ctl status'

# git
alias gau='git add -u'
alias gaa='git add -A'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gbr='git branch'
alias gl='git log --oneline'
alias glg='git log --graph --decorate --oneline'
alias gss='git status -sb'
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
alias gpush='git push'
alias gpl='git pull'
alias gshow='git show'
alias gtag='git tag'
alias gfp='git fetch --prune'
alias gbrdelete='git branch | grep -v master | grep -v main | xargs git branch -d'
alias gcb="git symbolic-ref --short HEAD | tr -d '\n' | pbcopy" # copy current branch
alias gitalias="git config --list | grep '^alias\.'"

disable r

########## key bind ##########
# 単語移動
bindkey '^[\e[C' forward-word
bindkey '^[\e[D' backward-word
bindkey ";5C" forward-word
bindkey ";5D" backward-word

FZF_CTRL_R_OPTS="--no-sort --layout=reverse --preview 'echo {}' --preview-window 'up:2:wrap'"
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf
# Homebrew版
fzf_base=''
if command -v brew >/dev/null 2>&1; then
  fzf_base="$(brew --prefix fzf 2>/dev/null)"
fi
if [ -n "$fzf_base" ] && [ -d "$fzf_base/shell" ]; then
  source "$fzf_base/shell/completion.zsh"
  source "$fzf_base/shell/key-bindings.zsh"
# GitHub版
elif [ -d ~/.fzf/shell ]; then
  [ -f ~/.fzf/shell/completion.zsh ] && source ~/.fzf/shell/completion.zsh
  [ -f ~/.fzf/shell/key-bindings.zsh ] && source ~/.fzf/shell/key-bindings.zsh
# apt版など
elif [ -d /usr/share/doc/fzf/examples ]; then
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
# 旧インストール方式
elif [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi
unset fzf_base

# select ghq
select-src() {
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
select-ssh() {
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


## node
# mise を使うためコメントアウト
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

## x env
# mise を使うためコメントアウト
# command -v rbenv > /dev/null 2>&1 && eval "$(rbenv init - zsh)"
# command -v goenv > /dev/null 2>&1 && eval "$(goenv init -)"
# command -v pyenv > /dev/null 2>&1 && eval "$(pyenv init - zsh)"

########## 長めのaliasや関数群 ##########
alias -g C='| pbcopy'
alias -g F='| fzf'
alias -g G='| grep -v grep | grep -i --color=auto'
alias -g SC="| tr ':' '\n'"

alias pb='pbcopy <'
alias updatecompletion='rm -f ~/.zcompdump; compinit'
alias sshlist="cat ~/.ssh/config | grep -e '^Host' | cut -d ' ' -f 2"
# prezto update
alias preup='cd $ZPREZTODIR && git pull && git submodule sync --recursive && git submodule update --init --recursive ; cd -'

cdgroot() {
  local -r ROOT_PATH=$(git rev-parse --show-toplevel| tr -d '\n')
  cd $ROOT_PATH
}

# autoSetupRemote = true の設定があれば不要
# gpush-u() {
#   local -r CURRENT_BRANCH=$(git symbolic-ref --short HEAD | tr -d '\n')
#   git push -u origin $CURRENT_BRANCH
# }

gtagpush() {
  local -r LATEST_TAG=$(git describe --tags --abbrev=0 | tr -d '\n')
  git push origin $LATEST_TAG
}

kill-grep() {
  local -r target_process=$1
  ps aux | grep -v grep | grep -i $target_process | awk '{ print "kill -9", $2 }' | sh
}

find-duplicates() {
  sed 's/[[:space:]]*,\?[[:space:]]*$//' |
  tr '[:upper:]' '[:lower:]' |
  sort |
  uniq -c |
  awk '$1 > 1' |
  sort -nr
}

print-symlink() {
  find . -maxdepth 1 -type l -exec sh -c 'for p; do printf "%s\t-> %s\n" "$p" "$(readlink "$p")"; done' sh {} +
}

# mise
command -v mise > /dev/null 2>&1 && eval "$(mise activate zsh)"

# マシン毎のローカルの設定読み込み
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# memo mise 公式は mise と direnv を一緒に使うことは推奨しない
  # https://mise.jdx.dev/direnv.html
# 末尾の記載がよい？
  # https://direnv.net/docs/hook.html
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
