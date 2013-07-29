syn region VtdSection start="\v^\z(\=+) .*\=$" end="\v(^\=\z1@!)@="
    \ fold
    \ contains=ALL
    \ keepend
