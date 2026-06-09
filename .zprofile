#
# Executes commands at login pre-zshrc.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

#
# Editors
#

export PAGER='less'

#
# Language
#

# if [[ -z "$LANG" ]]; then
#   export LANG='en_US.UTF-8'
# fi

#
# Paths
#

# Ensure path arrays do not contain duplicates.
# -g
  # global の意味
  # ローカル関数内で使っても、変数をグローバルに宣言する
  # .zprofile ではほぼ不要だが、明示的にグローバルにしたいときに使います
# -U
  # unique の意味
  # 配列に重複が入らないようにする
  # path 配列や PATH 変数に同じディレクトリが複数回入ったとき、自動で1つにする
typeset -U cdpath fpath mailpath path PATH

# Set the the list of directories that cd searches.
# cdpath=(
#   $cdpath
# )

# Set the list of directories that Zsh searches for programs.
path=(
  # $HOME/dev/google-cloud-sdk/bin
  $HOME/.pyenv/bin
  $HOME/.goenv/bin
  $HOME/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  /usr/local/sbin
  $path
)

#
# Less
#

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
# export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

#
# Temporary Files
#
#
# Set TMPDIR if the variable is not set/empty or the directory doesn't exist
if [[ -z "${TMPDIR}" ]]; then
  export TMPDIR="/tmp/zsh-${UID}"
fi

if [[ ! -d "${TMPDIR}" ]]; then
  mkdir -m 700 "${TMPDIR}"
fi

# ENV
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=vim
export VISUAL=$EDITOR
export LESS='-i -g -s -F -M -R -X -W -N'

## dev
export DOCKER_BUILDKIT=1

export NVM_DIR="$HOME/.nvm"
export GOENV_ROOT="$HOME/.goenv"
export PYENV_ROOT="$HOME/.pyenv"

export GCLOUD="$HOME/dev/google-cloud-sdk"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
