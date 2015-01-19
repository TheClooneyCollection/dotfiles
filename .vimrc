" vim:set ts=2 sts=2 sw=2 expandtab:

" prevent duplicate autocmd when souring .vimrc again
autocmd!

set nocompatible
filetype off

set shell=/bin/bash

set hidden
set history=10000

" UI
syntax enable

set number relativenumber
set cursorline
set winwidth=85
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
set list
set listchars=tab:>.,trail:·,extends:#,nbsp:.
set wildmode=longest,list
set switchbuf=useopen
" prevent vim from clobbering the scrollback buffer. see
" http://www.shallowsky.com/linux/noaltscreen.html
set t_ti= t_te=
" no startup message
set shortmess+=I
set showcmd

" Encodings
set encoding=utf-8
set fileencodings=utf-8,gb2312,gbk,cp936,latin1

" IO
set autoread

" Vundle

" modified bootstrap, originally by John Whitley
" https://github.com/jwhitley/vimrc/blob/master/.vim/bootstrap/bundles.vim

let s:current_folder = expand("<sfile>:h")

" returns path inside .vim folder relative to this file
function! s:RelativePathWithinDotVim(path)
  return s:current_folder."/.vim/".a:path
endfunction

" Initialize Vundle if haven't yet
let s:bundle_path = s:RelativePathWithinDotVim("bundle")
let s:vundle_path = s:RelativePathWithinDotVim("bundle/Vundle.vim")
if !isdirectory(s:vundle_path."/.git")
  silent exec "!mkdir -p ".s:bundle_path
  silent exec "!git clone --depth=1 https://github.com/gmarik/Vundle.vim.git ".s:vundle_path
  let s:vundle_initialized=1
endif

exec "set rtp+=".s:vundle_path
call vundle#begin(s:bundle_path)

" let Vundle manage itself
Plugin 'gmarik/Vundle.vim'

" UI
Plugin 'altercation/vim-colors-solarized'
Plugin 'bling/vim-airline'

" Behaviour
Plugin 'wincent/command-t'
Plugin 'bufkill.vim'

Plugin 'ervandew/supertab'
let g:SuperTabDefaultCompletionType = "context"

Plugin 'tpope/vim-endwise' " helps to end certain structures automatically

Plugin 'vim-ruby/vim-ruby'
Plugin 'tpope/vim-cucumber'
Plugin 'thoughtbot/vim-rspec'

call vundle#end()

if exists("s:vundle_initialized") && s:vundle_initialized
  unlet s:vundle_initialized
  autocmd VimEnter * PluginInstall
endif

filetype plugin indent on

" Plugin Setup
colorscheme solarized
if !exists("s:background") " don't reset when re-souring .vimrc
  let s:background = "light"
  let &background=s:background
endif
call togglebg#map("<F5>") " solarized background toggle

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

let g:rspec_command = "!rspec --color --format doc --order defined {spec}"

" Autocmds

" modified from garybernhart's .vimrc
" https://github.com/garybernhardt/dotfiles/blob/master/.vimrc
augroup vimrcEx
  autocmd!
  autocmd FileType text setlocal textwidth=78
  " jump to last cursor position unless it's invalid or in an event handler
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  " for ruby, autoindent with two spaces, always expand tabs
  autocmd FileType ruby,yaml,html,javascript,cucumber set ai sw=2 sts=2 et

  autocmd BufRead *.mkd set ai formatoptions=tcroqn2 comments=n:&gt;
  autocmd BufRead *.markdown set ai formatoptions=tcroqn2 comments=n:&gt;

  " don't syntax highlight markdown because it's often wrong
  autocmd! FileType mkd setlocal syn=off

  " *.md is markdown
  autocmd! BufNewFile,BufRead *.md setlocal ft=
augroup END

" Key settings

nnoremap ; :
nnoremap : ;

inoremap <c-c> <esc>
inoremap kj <esc>
cnoremap kj <esc>

let mapleader = ","

nnoremap <leader>w :w<cr>
nnoremap <leader>q :q<cr>
nnoremap <leader>. :q<cr>

function! s:RubyKepMap()
  inoremap <buffer> <c-l> <space>=><space>
  " rspec
  noremap <buffer> <Leader>rf :w\|redraw\|call RunCurrentSpecFile()<CR>
  noremap <buffer> <Leader>rn :w\|redraw\|call RunNearestSpec()<CR>
  noremap <buffer> <Leader>rl :w\|redraw\|call RunLastSpec()<CR>
  noremap <buffer> <Leader>ra :w\|redraw\|call RunAllSpecs()<CR>
endfunction
autocmd FileType ruby call s:RubyKepMap()

nnoremap <silent> <Leader>t :CommandT .<CR>

nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk
" motions for splits
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

nnoremap <leader><leader> :bnext<cr>
nnoremap <leader>oa o<esc>k
nnoremap <leader>oi O<esc>j

nnoremap <leader>h :help

nnoremap <leader>s :%s/\<<C-r><C-w>\>/
vnoremap <leader>s :%s/\<<C-r><C-w>\>/

nnoremap <silent> <leader>c :nohlsearch<cr>

nnoremap <leader>ev :e $MYVIMRC<cr>
nnoremap <leader>rv :source $MYVIMRC<cr>

vnoremap <leader>p "*p
nnoremap <leader>p "*p

vnoremap <leader>y "*y
nnoremap <leader>y "*y

nnoremap <tab> >>
nnoremap <s-tab> <<

" FIXME: When sharing Vim with someone else
inoremap <esc> <nop>
inoremap <esc> <nop>
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <right> <nop>
nnoremap <left> <nop>
