" Context highlighting.
syn region Context matchgroup=contextEnds start="\v\[\@" end="\v\]"
    \ concealends
    \ contains=ContextInclude,ContextExclude,ContextOnly,ContextNone,
    \ ContextBare,ContextCount
syn match ContextCount "\v\(\d+\)" contained
syn match ContextBare "\v\@@<=\I\i* " contained
syn match ContextInclude "\v(\@\+)@<=\I\i* " contained
syn match ContextExclude "\v(\@-)@<=\I\i* " contained
syn match ContextOnly "\v(\@\!)@<=\I\i* " contained
syn match ContextNone "\v(\@#)@<=\I\i* " contained

highlight ContextCount guifg=#aaaaaa
highlight ContextBare guifg=LightBlue
highlight ContextInclude guifg=Green
highlight ContextExclude guifg=Red
highlight link ContextOnly VtdPriority0
highlight link ContextNone Ignore

" Due/late time interval highlighting.
syn region TimeDifference start="\v\((Late|Due)@=" end="\v\)$"
    \ contains=LateInterval
syn match LateInterval "Late" contained
highlight link LateInterval Todo
highlight link TimeDifference Type

" Priority-based NextAction highlighting.
syn region NextAction start="\v^\@" end="\v$" matchgroup=nextActionEnds
    \ contains=ParentText,VtdPriority0,VtdPriority1,VtdPriority2,VtdPriority3,
    \ VtdPriority4,VtdPriorityX

""
" Declare a syntax-region between '[Pc:' and ':Pc]', where 'c' means a:char.
function! s:HighlightPriority(char)
  let l:priority_region = 'VtdPriority' . a:char
  let l:start = '\v\[P' . a:char . ':'
  let l:end = '\v:P' . a:char . '\]'
  execute 'syn region' l:priority_region 'matchgroup=contextEnds concealends'
        \ 'start="' . l:start . '" end="' . l:end . '"'
endfunction
for s:priority in extend(['X'], range(5))
  call s:HighlightPriority(s:priority)
endfor

highlight VtdPriority0 guifg=Yellow gui=bold,italic ctermfg=Yellow
    \ term=bold,italic
highlight VtdPriority1 guifg=White gui=bold ctermfg=White term=bold
highlight VtdPriority2 guifg=LightGrey ctermfg=LightGrey
highlight VtdPriority3 guifg=#777777 ctermfg=DarkGrey
highlight VtdPriority4 guifg=#445544 ctermfg=DarkGreen
highlight link VtdPriorityX WarningMsg

" Parent text highlighting.
syn region ParentText start="\v(\@ |:: )@<=[^[]" end="\v( ::)@="
highlight link ParentText Comment

" Keymap highlighting for single-key maps.
syn match Keymap "\v\[.\]"
highlight Keymap guifg=LightYellow gui=bold term=bold ctermfg=14
