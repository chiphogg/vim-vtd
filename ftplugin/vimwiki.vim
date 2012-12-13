

augroup vtd_wiki_files
  autocmd!
  let s:escaped_path = escape(g:vtd_wiki_path, ' ')
  execute 'autocmd FocusLost,BufLeave' s:escaped_path.'/* call vtd#WriteIfModified()'
  execute 'autocmd FocusGained,BufEnter' s:escaped_path.'/* setlocal autoread noswapfile'
augroup END
