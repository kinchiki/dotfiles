filetype plugin indent on

syntax on

set wrap

"インクリメンタルサーチしない
set noincsearch
set hlsearch
set ignorecase
set smartcase

set autoindent

"カーソルに位置表示
set ruler
set number
set list
set listchars=tab:>-,eol:↲,extends:»,precedes:«,nbsp:%

set wildmenu
"入力中のコマンドを表示
set showcmd

"インデント幅
set shiftwidth=4
set softtabstop=4
set tabstop=4
"タブをスペースに変換
set expandtab
set smarttab

set encoding=utf-8

"クリップボードの共有
set clipboard=unnamed,autoselect
set whichwrap=b,h,l,s,[,],<,>

"バックスペースの挙動変更
set backspace=indent,eol,start
set nrformats-=octal

"補完行数
set pumheight=10

"対応する括弧に一瞬移動
set showmatch
set matchtime=1

"長い行も表示
set display=lastline


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Yを行末までヤンクに
nnoremap Y y$
