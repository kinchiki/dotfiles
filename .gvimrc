" カラー
set background=dark
let g:hybrid_use_iTerm_colors = 1
colorscheme hybrid

"行番号の色や現在行の設定
autocmd ColorScheme * highlight LineNr ctermfg=12
highlight CursorLineNr ctermbg=4 ctermfg=0

syntax enable

" タブを常に表示
set showtabline=2

" 透明度
set transparency=5

"自動的に日本語能力オフ
set imdisable

" ツールバー非表示
set guioptions-=T

" アンチエイリアス
set antialias

" タブ幅
set tabstop=4

set number
set nobackup

" ビープ音なし
set visualbell t_vb=

set columns=80
set lines=48

set guifontwide=Ricty:h18
set guifont=Ricty:h18
