let g:tagbar_type_swift = {
    \ 'ctagstype': 'swift',
    \ 'kinds' : [
        \'c:class',
        \'e:enum',
        \'f:function',
        \'p:protocol',
        \'s:struct',
        \'E:extension',
        \'t:typealias',
    \]
\}

nnoremap t :TagbarToggle <cr>
