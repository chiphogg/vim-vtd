" Disable auto-wrapping; it interferes with VTD usage patterns
set formatoptions-=t

" Wrapping obscures the hierarchical structure of outlines. Plus, it
" doesn't work quite right with conceal (Vim 7.3+) and long URLs.
setlocal nowrap

" Ctrl-Space as checkoff is a great idea...
" I just need it to work the 'VTD way'!
nmap <silent><buffer> <C-Space> <Plug>VTD_Done
