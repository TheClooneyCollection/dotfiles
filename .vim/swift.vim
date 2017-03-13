augroup swift
  " *.swift is swift
  autocmd! BufNewFile,BufRead *.swift set filetype=swift
  autocmd FileType swift set ai sw=4 sts=4 et
  autocmd FileType swift call SetUpSwift()

  function! SetUpSwift()
    " set up swift compile
    if !empty(glob("./Package.swift"))
      noremap <buffer> <leader>w :wa \| silent make \| redraw! \| cw 4 <cr>
      noremap <buffer> <leader>t :wa \| silent make coverage \| redraw! \| cw 4 <cr>
    else
      noremap <buffer> <leader>w :w \| ! swift % <cr>
    endif

    " reset errorformat
    set efm=

    " swift test/build errors
    set efm+=%E%f:%l:%c:\ error:\ %m
    set efm+=%W%f:%l:%c:\ warning:\ %m
    set efm+=%I%f:%l:%c:\ note:\ %m
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

  endfunction
augroup END
