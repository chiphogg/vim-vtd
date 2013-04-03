" Keyboard shortcuts {{{1

" q - Write contexts and quit {{{2
nnoremap <buffer> q :wq<CR>

" Autocommands {{{1

augroup vtd_contexts
  autocmd!
  execute 'autocmd FocusLost,BufLeave' g:vtd_contexts_file 'call vtd#WriteIfModified()'
  execute 'autocmd FocusGained,BufEnter' g:vtd_contexts_file 'setlocal autoread noswapfile'
augroup END

" Buffer-local settings {{{1

setlocal textwidth=0
