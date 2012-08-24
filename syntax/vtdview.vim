if exists("b:current_syntax")
  finish
endif

syntax match overdue '\v\(\s*Overdue\s*[^)]*\)'
syntax match overdue '\vOverdue\s*\(\s*[^)]*\)'
highlight link overdue Todo

syntax match due '\v\(\s*Due\s*[^)]*\)'
syntax match due '\vDue\s*\(\s*[^)]*\)'
highlight link due Special

syntax match jumpTo '<<[ipsc]\d\+>>'
highlight link jumpTo Ignore

syntax match messages '\v#.*$'
highlight link messages Comment

syntax match sectionHeader '\v^\s*[▸▾][^:]*'
highlight link sectionHeader Statement

" Highlight the contexts line/section
" Eventually this should be more sophisticated: highlight individual contexts,
" use different colors for included vs. excluded.  For now, keep it simple.
"syntax match contextsYes '\v(^[▸▾\s]*Contexts:\s*)\@<=.*(((but)?\s*NOT)$)\@='
syntax region contextsYes start='\v(Contexts:\s*)@<=' end='\v(^|((but)?\s*NOT))@='
highlight contextsYes ctermfg=Green guifg=Green
syntax region contextsNo start='\v((but)?\s*NOT)@<=' end='^'me=e-1
highlight contextsNo ctermfg=LightRed guifg=LightRed

let b:current_syntax = "vtdview"
