noremap ; :
noremap : ;

cnoremap ; :
cnoremap : ;

" for python and ruby and swift
inoremap ; :
inoremap : ;

inoremap <c-c> <esc>
inoremap kj <esc>
cnoremap kj <c-c> " fix exit after typing :help in command
tnoremap kj <esc>

noremap <c-j> <c-w>j
noremap <c-k> <c-w>k

nnoremap <leader>w :w<cr>

nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

nnoremap T :!ctags (git ls) <cr>

nnoremap <leader><leader> <c-d>

nnoremap <leader>q :wqa <cr>

nnoremap <leader>d <c-d>
nnoremap <leader>u <c-u>

nnoremap <leader>a <c-^>
nnoremap <leader>o zA

nnoremap <leader>h :help<space>

nnoremap <leader>s :%s/\<<C-r><C-w>\>/
vnoremap <leader>s :%s/\<<C-r><C-w>\>/

nnoremap <silent> <leader>c :nohlsearch<cr>

" mappings for plugins
nnoremap <leader>g :silent grep <c-r><c-w>

nnoremap <silent> <leader>ii :source $MYVIMRC \| PlugInstall <cr>
nnoremap <silent> <leader>iu :PlugUpdate <cr>

" mappings for QuickFix

nnoremap <silent> <leader>cc :cc <cr>
nnoremap <silent> <leader>cn :cn <cr>
nnoremap <silent> <leader>cw :copen 4 <cr>
nnoremap <silent> <leader>cl :ccl <cr>

function! Next()
  let _ = "Prototyping the function for pressing `n`"
  let search = @/
  echom "Next start"
  echom search
  if empty(search)
    echom "go to next error"
  else
    echom "go to next search result"
  endif
endfunction

nnoremap <leader>ee :e %<cr>
nnoremap <leader>ev :e ~/.vim/<cr>
nnoremap <leader>em :e ~/.vim/mappings.vim<cr>
nnoremap <leader>ep :e ~/.vim/plugins.vim<cr>
nnoremap <leader>es :e ~/.vim/swift.vim<cr>
nnoremap <leader>ef :e ~/.vim/fzf.vim<cr>
nnoremap <leader>ea :e ~/.vim/autocmds.vim<cr>
nnoremap <leader>eg :e ~/.gitconfig<cr>
nnoremap <leader>eb :e ~/.Brewfile<cr>
nnoremap <leader>ec :e ~/.ctags<cr>
nnoremap <leader>rv :source $MYVIMRC<cr>

vnoremap <leader>p "*p
nnoremap <leader>p "*p

vnoremap <leader>y "*y
nnoremap <leader>y "*y

" FIXME: When sharing Vim with someone else
inoremap <esc> <nop>
noremap <up> <nop>
noremap <down> <nop>
noremap <right> <nop>
noremap <left> <nop>
