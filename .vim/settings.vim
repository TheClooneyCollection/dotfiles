" prevent duplicate autocmd when souring .vimrc again
autocmd!

let g:brew_prefix = system('brew --prefix')

let g:python_host_prog = brew_prefix . '/bin/python'
let g:python3_host_prog = brew_prefix . '/bin/python3'

set nocompatible
filetype off

let g:fish = brew_prefix . '/bin/fish'

set shell=fish

set hidden
set history=10000

" UI
syntax enable

set number
set cursorline
set winwidth=81
set scrolloff=5
" always show status line
set laststatus=2
" show matching brackets
set showmatch

" Search
set hlsearch
" show matches when typing search pattern
set incsearch
set ignorecase smartcase

" Edit
set backspace=indent,eol,start

set expandtab
set tabstop=4 shiftwidth=4 softtabstop=4
set autoindent smartindent

" Behavior
set complete+=kspell
set list
set listchars=tab:>-,trail:·,extends:#,nbsp:. ",eol:¬ " end
set wildmode=longest,list
set switchbuf=useopen
" prevent vim from clobbering the scrollback buffer. see
" http://www.shallowsky.com/linux/noaltscreen.html
set t_ti= t_te=
" no startup message
set shortmess+=I
set showcmd
set noswapfile

" Encodings
set encoding=utf-8

" IO
set autoread

