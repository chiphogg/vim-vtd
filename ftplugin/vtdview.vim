" Keyboard shortcuts {{{1

" <CR> - Jump to this line in the original file {{{2
nnoremap <buffer> <CR> :call vtd#JumpToLine()<CR>

" D - Mark this item as "done"... *intelligently* {{{2
" That means a one-time thing, like a NextAction or Project, gets tagged as
" DONE, but a recurring thing, like an INBOX or a RECUR, gets its last-done
" time updated.  Timestamping is automatic in any case.
nnoremap <silent> <buffer> D :call vtd#Done()<CR>

" q - Quit: close the VTD view window {{{2
nnoremap <silent> <buffer> q :call vtd#View_Close()<CR>

" Autocommands {{{1

augroup vtd_view_buffer
  autocmd!
  autocmd BufDelete VTD\ View* call vtd#ViewForget()
  " I want to put an auto-refresh function here.  But I can't auto-refresh
  " until I can refresh, and I can't refresh until I can keep track of the
  " state of the buffer.  I think the way to handle this is to make a class for
  " the buffer which keeps track of state, but that's a down-the-road feature.
augroup END
