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

let b:current_syntax = "vtdview"
