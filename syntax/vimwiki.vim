if exists("b:vtd_extra_highlights")
  finish
endif

syntax match doneItem '.*DONE.*'
highlight link doneItem Ignore

let b:vtd_extra_highlights = 1
