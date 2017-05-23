let g:neomake_swifttest_maker = {
    \ 'exe': 'swift',
    \ 'args': ['test'],
    \ 'errorformat': '%E%f:%l:%c: error: %m,%W%f:%l:%c: warning: %m,%Z%\s%#^~%#,%-G%.%#',
    \ }

let g:neomake_scan_maker = {
    \ 'exe': 'fastlane',
    \ 'args': ['scan'],
    \ 'errorformat': '%E%f:%l:%c: error: %m,%W%f:%l:%c: warning: %m,%Z%\s%#^~%#,%-G%.%#',
    \ }

let g:neomake_enabled_makers = [
    \ 'swifttest',
    \ 'scan',
    \ ]
