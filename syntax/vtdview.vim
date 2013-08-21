" Context highlighting.
syn region Context matchgroup=contextEnds start="\v\[\@" end="\v\]"
    \ concealends
    \ contains=ContextInclude,ContextExclude,ContextOnly,ContextNone,
    \ ContextBare,ContextCount
syn match ContextCount "\v\(\d+\)" contained
syn match ContextBare "\v\@@<=\I\i* " contained
syn match ContextInclude "\v(\@\+)@<=\I\i* " contained
syn match ContextExclude "\v(\@-)@<=\I\i* " contained

highlight ContextCount guifg=#aaaaaa
highlight ContextBare guifg=LightBlue
highlight ContextInclude guifg=Green
highlight ContextExclude guifg=Red

" Keymap highlighting for single-key maps.
syn match Keymap "\v\[.\]"
highlight Keymap guifg=LightYellow gui=bold term=bold ctermfg=14
