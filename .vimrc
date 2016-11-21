" vim:set ts=2 sts=2 sw=2 expandtab:

source ~/.vim/settings.vim
source ~/.vim/plugins.vim
source ~/.vim/local.vim

" Plugin Setup
nnoremap <leader>vi :so $MYVIMRC\|PluginInstall<cr>
nnoremap <leader>vc :so $MYVIMRC\|PluginClean<cr>

" solarized
colorscheme solarized
call togglebg#map("<F5>") " solarized background toggle

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

nmap <leader>. <Plug>BufKillBd

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

" end of easymotion

nnoremap <silent> <c-f> :CommandT .<cr>
nnoremap <silent> <c-b> :CommandTBuffer<cr>

" Autocmds

augroup vimrcEx
  autocmd!
  autocmd VimEnter * noremap <leader>t :wa \| silent make coverage \| redraw! \| cw 4 <cr>

  autocmd FileType text setlocal textwidth=78
  " jump to last cursor position unless it's invalid or in an event handler
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  " for ruby, autoindent with two spaces, always expand tabs
  autocmd FileType ruby,eruby,yaml,html,haml,javascript,cucumber,json set ai sw=2 sts=2 et

  " *.md is markdown
  autocmd! BufNewFile,BufRead *.md setlocal filetype=markdown

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
    set efm+=%Z%\s%#^~%#
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
    noremap <buffer> <leader>w :wa \| silent make \| redraw! \| cw 4 <cr>
    noremap <buffer> <leader>t :wa \| silent make coverage \| redraw! \| cw 4 <cr>
  endfunction

  " *.podspec is ruby
  autocmd! BufNewFile,BufRead *.podspec setlocal filetype=ruby

  " Podfile is ruby
  autocmd! BufNewFile,BufRead Podfile setlocal filetype=ruby

  " wrap at 80 characters and spell check markdown
  autocmd FileType markdown setlocal textwidth=80 spell

  " wrap at 72 characters and spell check git commit messages
  autocmd FileType gitcommit setlocal textwidth=72 spell
  autocmd FileType gitcommit noremap <buffer> <leader>w :wq<cr>

  autocmd FileType vim noremap <buffer> <leader>w :w \| source $MYVIMRC <cr>
augroup END

source ~/.vim/mappings.vim
