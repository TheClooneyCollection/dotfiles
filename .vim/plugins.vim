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

call plug#end()

if exists("s:initialized_plugin_manager") && s:initialized_plugin_manager
  unlet s:initialized_plugin_manager
  autocmd VimEnter * PlugInstall
endif

"" Configure plugins ""

nnoremap <silent> <leader>ii :PlugInstall <cr>
nnoremap <silent> <leader>iu :PlugUpdate <cr>

" solarized
colorscheme solarized

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

" easymotion
let g:EasyMotion_smartcase = 1 " turn on case insensitive feature
let g:EasyMotion_do_mapping = 0 " disable default mappings
let g:EasyMotion_use_smartsign_us = 1 " 1 will match 1 and !
let g:EasyMotion_use_upper = 1
let g:EasyMotion_keys = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ;'
let g:EasyMotion_space_jump_first = 1
let g:EasyMotion_enter_jump_first = 1

nmap <leader>g <Plug>(easymotion-bd-w)
nmap s <Plug>(easymotion-s2)
map t <Plug>(easymotion-bd-t)
map f <Plug>(easymotion-bd-f2)
omap t <Plug>(easymotion-tl)
omap f <Plug>(easymotion-fl)
vmap t <Plug>(easymotion-tl)
vmap f <Plug>(easymotion-fl)

" jk motions: line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
