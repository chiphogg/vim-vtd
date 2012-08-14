
" Keyboard shortcuts {{{1

" <CR> - Jump to this line in the original file {{{2
nnoremap <buffer> <CR> :call vtd#VTD_JumpToLine()<CR>

" D - Mark this item as "done"... *intelligently* {{{2
" That means a one-time thing, like a NextAction or Project, gets tagged as
" DONE, but a recurring thing, like an INBOX or a RECUR, gets its last-done
" time updated.  Timestamping is automatic in any case.
nnoremap <buffer> D :call vtd#VTD_Done()<CR>
