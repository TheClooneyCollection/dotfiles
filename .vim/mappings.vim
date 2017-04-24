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

noremap <c-j> <c-w>j
noremap <c-k> <c-w>k

nnoremap <leader>w :w<cr>

nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

nnoremap <tab> <c-u>
nnoremap <del> <c-u>
nnoremap <bs> <c-u>

nnoremap <space> za

nnoremap T :!ctags <cr>

" mappings start with <leader>
nnoremap <leader><leader> <c-^>

nnoremap <leader>h :help<space>

nnoremap <leader>s :%s/\<<C-r><C-w>\>/
vnoremap <leader>s :%s/\<<C-r><C-w>\>/

nnoremap <silent> <leader>c :nohlsearch<cr>

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
nnoremap <leader>rv :source $MYVIMRC<cr>

vnoremap <leader>p "*p
nnoremap <leader>p "*p

vnoremap <leader>y "*y
nnoremap <leader>y "*y

" FIXME: When sharing Vim with someone else
inoremap <esc> <nop>
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <right> <nop>
nnoremap <left> <nop>
