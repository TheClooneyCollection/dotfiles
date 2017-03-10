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
let g:CommandTFileScanner = "git"

Plugin 'bufkill.vim'

Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-commentary'
Plugin 'pbrisbin/vim-mkdir' " create any non-existent directories before writing a buffer
Plugin 'Lokaltog/vim-easymotion'
Plugin 'tpope/vim-endwise' " helps to end certain structures automatically
Plugin 'tpope/vim-eunuch' " Move, Rename, Remove, etc...
Plugin 'tpope/vim-repeat' " Enable repeat for certain/almost all tpope's plugins
Plugin 'rking/ag.vim'
Plugin 'jiangmiao/auto-pairs' " () '', pairs, you get it

Plugin 'ervandew/supertab'
let g:SuperTabDefaultCompletionType = "context"

" language

Plugin 'keith/swift.vim'

" Ruby
Plugin 'vim-ruby/vim-ruby'
" Plugin 'tpope/vim-cucumber'
" Plugin 'tpope/vim-rails'
" Plugin 'NicholasTD07/vim-rspec'

Plugin 'Valloric/YouCompleteMe'
Plugin 'nvie/vim-flake8'
Plugin 'hynek/vim-python-pep8-indent'

Plugin 'cespare/vim-toml'

Plugin 'dag/vim-fish' " fishshell

call vundle#end()

if exists("s:vundle_initialized") && s:vundle_initialized
  unlet s:vundle_initialized
  autocmd VimEnter * PluginInstall
endif

filetype plugin indent on
