"vi互換をオフする
set nocompatible

"行番号の色を設定
autocmd ColorScheme * highlight LineNr ctermfg=12
hi CursorLineNr ctermbg=4 ctermfg=0
set cursorline
hi clear CursorLine

"色
set background=dark
let g:hybrid_use_iTerm_colors = 1
colorscheme hybrid
syntax on

"ビープ音すべてを無効にする
set visualbell t_vb=

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

"カーソル移動で行をまたげるようにする
set whichwrap=b,s,h,l,<,>,~,[,]

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

"変更中のファイルでも保存しないで他のファイルを表示する
set hidden

"バックアップファイルを作成しない
set nobackup
"バックアップファイルのディレクトリ指定
set backupdir=$HOME/.vim/backup
"アンドゥファイルを作成しない
set noundofile
"アンドゥファイルのディレクトリ指定
set undodir=$HOME/.vim/backup


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"Yで行末までヤンク
nnoremap Y y$

"カーソル移動
nnoremap j gj
nnoremap k gk
nnoremap gj j
nnoremap gk k
noremap <S-h> ^
noremap <S-j> }
noremap <S-k> {
noremap <S-l> $

"C-dでノーマルモード
inoremap <C-d> <esc>

"ノーマルモードのまま改行
nnoremap <CR> I<CR><ESC>
"ノーマルモードのままスペース
nnoremap <space> i<space><esc>

"rだけでリドゥ
nnoremap r <C-r>

"検索結果のハイライトをEsc連打でクリアする
nnoremap <ESC><ESC> :nohlsearch<CR>


filetype plugin indent on
