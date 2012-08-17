if exists("b:vtd_extra_highlights")
  finish
endif

"syntax match doneItem '.*DONE.*'
"highlight link doneItem Ignore

"syntax region doneItem start=/\^\z(\s*\)\S.*DONE.*/ end=/write/
"syntax region doneItem start=/^\z(\s\+\)\S.*DONE/ end=/(^\z1\S)\@=/
"syntax region doneItem start='^\z(\s\+\)\S.*DONE' skip='^\z1\s.*$' end='^'
"syntax region doneItem start='^\z(\s*\).*DONE' skip='^\z1' end='^' skipnl
"highlight link doneItem Error

syntax region doneItem start='^\z(\s*\)\S.*DONE.*$' skip='^\z1\s' end='^'me=e-1
syntax region doneItem start='^\z(\s*\)\S.*WONTDO.*$' skip='^\z1\s' end='^'me=e-1
highlight link doneItem Ignore

let b:vtd_extra_highlights = 1
