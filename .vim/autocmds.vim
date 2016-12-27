augroup vimrcEx
  autocmd!
  autocmd VimEnter * noremap <leader>t :wa \| silent make coverage \| redraw! \| cw 4 <cr>

  autocmd FileType text setlocal textwidth=78
  " jump to last cursor position unless it's invalid or in an event handler
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  " python

  autocmd FileType python noremap <buffer> <leader>w :w \| ! python % <cr>

  " *.fish is fish
  autocmd! BufNewFile,BufRead *.fish setlocal filetype=fish

  " *.swift is swift
  autocmd! BufNewFile,BufRead *.swift setlocal filetype=swift
  autocmd FileType swift set ai sw=4 sts=4 et
  autocmd FileType swift call SetUpSwift()

  function! SetUpSwift()
    " reset errorformat
    set efm=

    " swift test/build errors
    set efm+=%E%f:%l:%c:\ error:\ %m
    set efm+=%W%f:%l:%c:\ warning:\ %m
    set efm+=%I%f:%l:%c:\ note:\ %m
    set efm+=%+C%.%#
    set efm+=%+Z%p^
    set efm+=%f:%l:\ error:\ %m
    set efm+=fatal\ error:\ %m

    " custom codecov errors (zero-hit detection)
    " Example: Ignore zero-hit ending brackets
    " File /path/to/another.swift:104|            }
    set efm+=%-GFile\ %f:%l:\ %#}
    " Example: Detect other zero-hit lines
    " File /path/to/a.swift:56|    func remove(todo: ToDo) -> State {
    set efm+=File\ %f:%l:\ %#%m

    set efm+=%-G%.%#

    if !empty(glob("./Package.swift"))
      noremap <buffer> <leader>w :wa \| silent make \| redraw! \| cw 4 <cr>
    else
      noremap <buffer> <leader>w :w \| ! swift % <cr>
    endif

    noremap <buffer> <leader>t :wa \| silent make coverage \| redraw! \| cw 4 <cr>
  endfunction

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
