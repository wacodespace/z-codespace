" ~/.vimrc - 个人 Vim 配置
" ============================================================

" --- 基础设置 ---
if v:progname =~? "evim"
  finish
endif
set nocompatible
set backspace=indent,eol,start
set history=50
set mouse=a
set selection=exclusive
set selectmode=mouse,key
map Q gq

" --- Leader 键 ---
let mapleader = ";"
nnoremap <Leader>q :q<CR>
nnoremap <Leader>w :w<CR>
nnoremap <Leader>l :nohlsearch<CR>
" nnoremap <Leader>g :NERDTreeToggle<CR>
" nnoremap <Leader>t :NERDTreeFind<CR>

" --- 跨会话复制粘贴 ---
vmap <leader>y :w! /tmp/vitmp<CR>
nmap <leader>p :r! cat /tmp/vitmp<CR>

" --- 剪贴板 ---
set clipboard=unnamed

" --- 显示 ---
syntax enable
syntax on
set nu
set ruler
set showcmd
set showmatch
set matchtime=5
set laststatus=2
set cmdheight=2
set t_Co=256
set guifont=Monaco:h10

" --- 搜索 ---
set hlsearch
set incsearch
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

" --- 缩进 ---
set cindent
set autoindent
set smartindent
set shiftwidth=4
set ts=4
set expandtab

" --- 折叠 ---
set foldmethod=syntax
set foldlevel=100

" --- 备份文件 ---
set writebackup
set nobackup

" --- Tab 可视化 ---
set list
set listchars=tab:>-,trail:-

" --- 文件类型检测 ---
filetype on
filetype plugin on
filetype indent on
filetype plugin indent on

" --- 编码 ---
set fileencodings=utf-8,gb2312,gbk,gb18030
set termencoding=utf-8
set fileencoding=utf-8
set encoding=utf-8
set fileformat=unix

" --- 自动命令 ---
if has("autocmd")
  augroup vimrcEx
  au!
  autocmd FileType text setlocal textwidth=80
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
  augroup END
endif

" --- 插件 (暂时禁用，需要时取消注释并安装 vim-plug) ---
" call plug#begin('~/.vim/plugged')
" Plug 'morhetz/gruvbox'
" Plug 'preservim/nerdtree'
" Plug 'vim-airline/vim-airline'
" call plug#end()

" --- Tlist (暂时禁用) ---
" let Tlist_Exit_OnlyWindow = 1
" let Tlist_Auto_Open = 1
