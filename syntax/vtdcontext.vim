if exists("b:current_syntax")
  finish
endif

syntax match comment '\v^\s*#.*$'
highlight link comment Comment

let b:current_syntax = "vtdcontext"
