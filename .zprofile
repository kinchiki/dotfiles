# 環境変数
# Preztoがやってるっぽいもの
#export LANG=ja_JP.UTF-8
#export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"

#export PATH="$HOME/.rbenv/shims:$PATH"
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
export PGDATA=/usr/local/var/postgres
export ARCHFLAGS="-arch x86_64"
export PATH="$PATH:$HOME/bin"
# export WORDCHARS="*?[]~;=!#$%^(){}<>" なぜか効かない
