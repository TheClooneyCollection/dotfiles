source ~/.vim/settings.vim
source ~/.vim/plugins.vim
source ~/.vim/swift.vim
source ~/.vim/fastlane.vim
source ~/.vim/mappings.vim
source ~/.vim/autocmds.vim

let s:local_config_path = '~/.vim/local.vim'

if !filereadable(expand(s:local_config_path))
  execute '! touch '.s:local_config_path
endif

" Put settings for diffrent machines here since this is not tracked by git.
execute 'source '.s:local_config_path
