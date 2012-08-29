syntax region doneItem start='^\z(\s*\)\S.*DONE.*$' skip='^\z1\s' end='^'me=e-1
syntax region doneItem start='^\z(\s*\)\S.*WONTDO.*$' skip='^\z1\s' end='^'me=e-1
highlight link doneItem Ignore

syntax region projectSupport start='\v^\z(\s*)\*\s' skip='^\v\z1\s' end='\v^'me=e-1 contains=VimwikiLink
highlight link projectSupport Comment
