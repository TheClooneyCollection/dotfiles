augroup vimrcEx
  autocmd!

  autocmd FileType text setlocal textwidth=78

  " jump to last cursor position unless it's invalid or in an event handler
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  " python

  autocmd FileType python noremap <buffer> <leader>w :w \| ! python3 % <cr>

  " haskell
  autocmd FileType haskell noremap <buffer> <leader>w :w \| ! ghci % <cr>

  " *.fish is fish
  autocmd! BufNewFile,BufRead *.fish setlocal filetype=fish

  " for ruby, autoindent with two spaces, always expand tabs
  autocmd FileType ruby,eruby,yaml,html,haml,javascript,cucumber,json set ai sw=2 sts=2 et

  " *.md is markdown
  autocmd! BufNewFile,BufRead *.md setlocal filetype=markdown

  " *.podspec is ruby
  autocmd! BufNewFile,BufRead *.podspec setlocal filetype=ruby

  " Podfile is ruby
  autocmd! BufNewFile,BufRead Podfile setlocal filetype=ruby

  " wrap at 80 characters and spell check markdown
  autocmd FileType markdown setlocal textwidth=80 spell

  " wrap at 72 characters and spell check git commit messages
  autocmd FileType gitcommit setlocal textwidth=72 spell
  autocmd FileType gitcommit noremap <buffer> <leader>w :wq<cr>

  autocmd FileType vim set ai ts=2 sts=2 sw=2 expandtab
  autocmd FileType vim noremap <buffer> <leader>w :w \| source $MYVIMRC <cr>
augroup END
