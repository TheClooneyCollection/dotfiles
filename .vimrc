source ~/.vim/settings.vim
" source ~/.vim/plugins.vim
" source ~/.vim/plugin-settings.vim
source ~/.vim/autocmds.vim
source ~/.vim/mappings.vim
source ~/.vim/local.vim " Put settings for diffrent machines here since this is not tracked by git.

""" Experimenting with vim-plug """

let s:vim_plug_path = '~/.vim/vim-plug'
if !isdirectory(s:vim_plug_path)
  silent exec "!mkdir -p ".s:vim_plug_path
  silent exec "!git clone --depth=1 https://github.com/junegunn/vim-plug.git "s:vim_plug_path
endif

exec "source ".s:vim_plug_path."/plug.vim"

call plug#begin('~/.vim/plugged')
call plug#end()
