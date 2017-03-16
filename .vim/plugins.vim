"" Bootstrap plugin manager """

let s:plugin_manager_git = 'https://github.com/junegunn/vim-plug.git'

let s:vim_plugins_path = '~/.vim-plugins'
let s:plugin_manager_path = s:vim_plugins_path.'/plugin-manager'

if !isdirectory(expand(s:plugin_manager_path))
  silent exec '!mkdir -p '.s:plugin_manager_path
  silent exec '!git clone --depth=1 '.s:plugin_manager_git.' '.s:plugin_manager_path
  let s:initialized_plugin_manager=1
endif

exec 'source '.s:plugin_manager_path.'/plug.vim'


if exists('s:initialized_plugin_manager') && s:initialized_plugin_manager
  unlet s:initialized_plugin_manager
  autocmd VimEnter * PlugInstall
endif

"" Manage plugins ""

call plug#begin(s:vim_plugins_path.'/plugins')

" UI
Plug 'altercation/vim-colors-solarized'
Plug 'bling/vim-airline'
Plug 'mhinz/vim-signify' " change indicator

" Behaviour
Plug 'Lokaltog/vim-easymotion'

Plug 'ervandew/supertab'

Plug 'majutsushi/tagbar'

Plug 'neomake/neomake'

Plug 'mbbill/undotree'

Plug 'pbrisbin/vim-mkdir' " create any non-existent directories before writing a buffer

" Editing

Plug 'junegunn/vim-easy-align'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise' " helps to end certain structures automatically
Plug 'tpope/vim-eunuch' " Move, Rename, Remove, etc...
Plug 'tpope/vim-repeat' " Enable repeat for certain/almost all tpope's plugins

Plug 'jiangmiao/auto-pairs' " () '', pairs, you get it

" Languages

Plug 'apple/swift', { 'rtp': 'utils/vim' }

Plug 'dag/vim-fish' " fishshell

" Autocomplete

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'zchee/deoplete-jedi'

call plug#end()

if exists("s:initialized_plugin_manager") && s:initialized_plugin_manager
  unlet s:initialized_plugin_manager
  autocmd VimEnter * PlugInstall
endif

"" Configure plugins ""

nnoremap <silent> <leader>ii :source $MYVIMRC \| PlugInstall <cr>
nnoremap <silent> <leader>iu :PlugUpdate <cr>

nnoremap <silent> T :w \| !ctags <cr>

" solarized
colorscheme solarized

"deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#sources#jedi#show_docstring = 1

" signify
let g:signify_vcs_list = [ 'git' ]

" airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" easy-align

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

source ~/.vim/fzf.vim
source ~/.vim/easy-motion.vim
source ~/.vim/tagbar.vim
source ~/.vim/neomake.vim
