filetype plugin indent on

syntax on

"色
set background=dark
colorscheme solarized

set wrap

"インクリメンタルサーチしない
set noincsearch
"その他検索のなんか
set hlsearch
set ignorecase
set smartcase

"インデント
set autoindent

"カーソル位置表示
set ruler
"行数
set number

"不可視文字の設定
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

"エンコーディング
"GUI版のために無効
"set encoding=utf-8

"クリップボードの共有
set clipboard=unnamed,autoselect

set whichwrap=b,h,l,s,[,],<,>

"バックスペースを使いやすく
set backspace=indent,eol,start
set nrformats-=octal

"補完行数
set pumheight=10

"対応する括弧に一瞬移動
set showmatch
set matchtime=1

"長い行も表示
set display=lastline

"変更中のファイルでも、保存しないで他のファイルを表示する
set hidden

"vi互換をオフする
set nocompatible

" バックアップファイルを作成しない
set nobackup
" バックアップファイルのディレクトリ指定
set backupdir=$HOME/.vim/backup


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Yを行末までヤンクに
nnoremap Y y$

"ノーマルモードのまま改行
nmap <CR> i<CR><ESC>

" 検索結果のハイライトをEsc連打でクリアする
nnoremap <ESC><ESC> :nohlsearch<CR>
