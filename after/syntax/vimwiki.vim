syntax region projectSupport start='\v^\z(\s*)\*\s' skip='^\v\z1\s' end='\v^'me=e-1 contains=VimwikiLink
highlight link projectSupport Comment

syntax region doneItem start='^\z(\s*\)\S.*DONE.*$' skip='^\z1\s' end='^'me=e-1
syntax region doneItem start='^\z(\s*\)\S.*WONTDO.*$' skip='^\z1\s' end='^'me=e-1
highlight link doneItem Ignore

syntax match context '\v\s@<=\@{1,2}[a-zA-Z0-9]+(:[a-zA-Z0-9]+)?[a-zA-Z0-9]@!'
syntax match contextMarker '\v\@{1,2}|:' containedin=context contained
syntax match contextNameInvis '\v\@@<=[a-zA-Z0-9]+' containedin=context contained
syntax match contextNameVis '\v(\@\@)@<=[a-zA-Z0-9]+' containedin=context contained

" "Special" contexts have a colon in the middle, and name-value semantics
syntax match contextSpecialName '\v\@@<=[a-zA-Z0-9]+:@=' containedin=context contained
syntax match contextSpecialValue '\v:@<=[a-zA-Z0-9]+' containedin=context contained

highlight link contextMarker Ignore
highlight contextNameVis ctermfg=LightBlue guifg=LightBlue
highlight contextNameInvis ctermfg=DarkCyan guifg=DarkCyan
highlight contextSpecialName ctermfg=Yellow guifg=Yellow
highlight contextSpecialValue ctermfg=Green guifg=Green

syntax match id '\v#[a-zA-Z0-9]+[a-zA-Z0-9]@!'
syntax match idMarker '\v#' containedin=id contained

highlight id ctermfg=Magenta guifg=Magenta
highlight link idMarker Ignore

let s:date_regex = '\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?'
exec 'syntax match date ''\v'.s:date_regex."'"
exec 'syntax match dateVis ''\v\>'.s:date_regex."'"
exec 'syntax match dateDue ''\v\<'.s:date_regex."'"
highlight date ctermfg=Cyan guifg=Cyan
highlight dateVis ctermfg=Green guifg=#aaffaa
highlight dateDue ctermfg=Red guifg=#ffaaaa
