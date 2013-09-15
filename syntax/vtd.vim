syntax region VtdSection start="\v^\z(\=+) .*\=$" end="\v(^\=\z1@!)@="
    \ fold
    \ contains=ALL
    \ keepend

syntax region doneItem start='^\z(\s*\)\S.*(DONE.*)' skip='^\z1\s' end='^'me=e-1
highlight link doneItem Ignore
syntax region wontdo start='^\z(\s*\)\S.*(WONTDO.*)' skip='^\z1\s' end='^'me=e-1
highlight link wontdo doneItem
