" Keyboard shortcuts {{{1

" <CR> - Jump to this line in the original file {{{2
nnoremap <silent> <buffer> <CR> :call vtd#View_ActOnLine()<CR>

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
  autocmd BufDelete __VTD_VIEW_BUFFER__ call vtd#ViewForget()
  autocmd BufEnter __VTD_VIEW_BUFFER__ call vtd#View_EnterAndRefresh()
augroup END

" Buffer-local settings {{{1

setlocal conceallevel=3
setlocal concealcursor=nc
setlocal textwidth=0
