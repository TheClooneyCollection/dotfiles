source ~/.vim/settings.vim
" source ~/.vim/plugins.vim
" source ~/.vim/plugin-settings.vim
source ~/.vim/autocmds.vim
source ~/.vim/mappings.vim
source ~/.vim/local.vim " Put settings for diffrent machines here since this is not tracked by git.

""" Experimenting with vim-plug """

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

call plug#end()

"" Configure plugins ""

