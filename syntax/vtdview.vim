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

syntax match jumpTo '<<[ipsc]\d\+>>'
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

let b:current_syntax = "vtdview"
