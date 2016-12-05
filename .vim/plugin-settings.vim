" Plugin Setup
nnoremap <leader>vi :so $MYVIMRC\|PluginInstall<cr>
nnoremap <leader>vc :so $MYVIMRC\|PluginClean<cr>

" Ag
nnoremap <leader>aa :Ag "<C-r><C-w>" <cr>
vnoremap <leader>aa :Ag "<C-r><C-w>" <cr>

" CommandT

nnoremap <silent> <c-f> :CommandT .<cr>
nnoremap <silent> <c-b> :CommandTBuffer<cr>

" solarized
colorscheme solarized
call togglebg#map("<F5>") " solarized background toggle

" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" BufKill
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
