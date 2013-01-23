if exists("b:current_syntax")
  finish
endif

syntax match overdue '\v\(\s*Overdue\s*[^)]*\)'
syntax match overdue '\vOverdue\s*\(\s*[^)]*\)'
syntax match overdue '\v\(\s*Late\s*[^)]*\)'
syntax match overdue '\vLate\s*\(\s*[^)]*\)'
highlight link overdue Todo

syntax match due '\v\(\s*Due\s*[^)]*\)'
syntax match due '\vDue\s*\(\s*[^)]*\)'
highlight link due Special

syntax match jumpTo '<<[ipsc]\d\+>>' conceal
highlight link jumpTo Ignore

syntax match messages '\v\S@<!#.*$'
highlight link messages Comment

syntax match sectionHeader '\v^\s*[▸▾][^:]*'
highlight link sectionHeader Statement

syntax match contextHeader '^\v(In|Ex)clude:@='
highlight link contextHeader Special

" Highlight the contexts line/section
" Eventually this should be more sophisticated: highlight individual contexts,
" use different colors for included vs. excluded.  For now, keep it simple.
syntax region contextsYes start='\v(^Include:\s*)@<=' end='\n' contains=contextSeparator
highlight contextsYes ctermfg=Green guifg=Green
syntax region contextsNo start='\v(^Exclude:\s*)@<=' end='\n' contains=contextSeparator
highlight contextsNo ctermfg=LightRed guifg=LightRed
syntax match contextSeparator '\v(or|,)\s+' contained
highlight link contextSeparator Ignore

" Priority-based highlighting
syntax region priority0 matchgroup=pmark start='\v\[P0:' end='\v:P0\]' concealends
syntax region priority1 matchgroup=pmark start='\v\[P1:' end='\v:P1\]' concealends
syntax region priority2 matchgroup=pmark start='\v\[P2:' end='\v:P2\]' concealends
syntax region priority3 matchgroup=pmark start='\v\[P3:' end='\v:P3\]' concealends
syntax region priority4 matchgroup=pmark start='\v\[P4:' end='\v:P4\]' concealends
highlight priority0 ctermfg=Yellow guifg=Yellow gui=bold,italic term=bold,italic
highlight priority1 ctermfg=White guifg=White gui=bold term=bold
highlight priority2 ctermfg=LightGrey guifg=#bbbbbb
highlight priority3 ctermfg=DarkGrey guifg=#777777
highlight priority4 ctermfg=DarkGreen guifg=#445544

let b:current_syntax = "vtdview"
