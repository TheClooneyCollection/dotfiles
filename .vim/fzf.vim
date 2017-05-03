" https://github.com/junegunn/fzf/wiki/Examples-(vim)
"
set rtp+=/usr/local/opt/fzf " Add fzf's vim plugin
nnoremap <silent> <c-f> :call fzf#run({
            \ 'source': 'git ls-files',
            \ 'sink': 'e',
            \ 'down': '~40%',
            \ }) <cr>
nnoremap <silent> <c-y> :call fzf#run({
            \ 'source': 'git ls-files',
            \ 'sink': 'e',
            \ 'down': '~40%',
            \ 'options': '-m --bind=ctrl-a:select-all,ctrl-d:deselect-all'
            \ }) <cr>
nnoremap <silent> <c-b> :call fzf#run({
            \ 'source': map(range(1, bufnr('$')),
            \ 'bufname(v:val)'),
            \ 'sink': 'e',
            \ 'down': '~40%',
            \ }) <cr>
nnoremap <silent> <c-t> :call Tags() <cr>
nnoremap <c-n> : w \| call Btags() <cr>

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

function! s:align_lists(lists)
  let maxes = {}
  for list in a:lists
    let i = 0
    while i < len(list)
      let maxes[i] = max([get(maxes, i, 0), len(list[i])])
      let i += 1
    endwhile
  endfor
  for list in a:lists
    call map(list, "printf('%-'.maxes[v:key].'s', v:val)")
  endfor
  return a:lists
endfunction

function! s:btags_source()
  let lines = map(split(system(printf(
    \ 'ctags -f - --sort=no --excmd=number --language-force=%s %s',
    \ &filetype, expand('%:S'))), "\n"), 'split(v:val, "\t")')
  if v:shell_error
    throw 'failed to extract tags'
  endif
  return map(s:align_lists(lines), 'join(v:val, "\t")')
endfunction

function! s:btags_sink(line)
  execute split(a:line, "\t")[2]
  TagbarClose
endfunction

function! Btags()
  try
    call fzf#run({
    \ 'source':  s:btags_source(),
    \ 'options': '+m -d "\t" --with-nth 1,4.. -n 1 --tiebreak=index',
    \ 'down':    '40%',
    \ 'sink':    function('s:btags_sink')})
  catch
    echohl WarningMsg
    echom v:exception
    echohl None
  endtry
endfunction

