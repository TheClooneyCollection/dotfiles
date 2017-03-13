set rtp+=/usr/local/opt/fzf " Add fzf's vim plugin
nnoremap <silent> <c-f> :call fzf#run({
            \ 'source': 'git ls-files',
            \ 'sink': 'e',
            \ 'down': '~40%',
            \ }) <cr>
nnoremap <silent> <c-b> :call fzf#run({
            \ 'source': map(range(1, bufnr('$')),
            \ 'bufname(v:val)'),
            \ 'sink': 'e',
            \ 'down': '~40%',
            \ }) <cr>
function! s:tags_sink(line)
  let parts = split(a:line, '\t\zs')
  let excmd = matchstr(parts[2], '\/\^.*\ze;')
  let filename = fnameescape(parts[1][:-2])
  execute "silent e" filename
  " echo parts
  " echo excmd
  let [magic, &magic] = [&magic, 0]
  execute excmd
  let &magic = magic
endfunction

function! Tags()
  if empty(tagfiles())
    echohl WarningMsg
    echom 'Preparing tags'
    echohl None
    call system('ctags -R')
  endif

  call fzf#run({
        \ 'source':  'cat '.join(map(tagfiles(), 'fnamemodify(v:val, ":S")')).
        \            '| grep -v -a ^!',
        \ 'options': '+m -d "\t" --with-nth 1,4.. --tiebreak=index',
        \ 'down':    '~40%',
        \ 'sink':    function('s:tags_sink')})
endfunction

nnoremap <silent> <c-t> :call Tags() <cr>
" https://github.com/junegunn/fzf/wiki/Examples-(vim)
