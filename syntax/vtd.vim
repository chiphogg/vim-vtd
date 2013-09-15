syntax region VtdSection start="\v^\z(\=+) .*\=$" end="\v(^\=\z1@!)@="
    \ fold
    \ contains=ALL
    \ keepend

syntax region doneItem start='^\z(\s*\)\S.*(DONE.*)' skip='^\z1\s' end='^'me=e-1
highlight link doneItem Ignore
syntax region wontdo start='^\z(\s*\)\S.*(WONTDO.*)' skip='^\z1\s' end='^'me=e-1
highlight link wontdo doneItem

syntax region recur start='^\z(\s*\)\S.*\<EVERY\>' skip='^\z1\s' end='^'me=e-1
    \ contains=lastDone,vtdComment
highlight link recur SpecialKey
syntax match lastDone '\v\(LASTDONE \d{4}-\d{2}-\d{2} \d{1,2}:\d{2}\)' contained
highlight link lastDone doneItem

syntax region vtdComment start='^\z(\s*\)\* ' skip='^\v(\z1\s|$)' end='^'me=e-1
highlight link vtdComment Comment
