

augroup vtd_wiki_files
  autocmd!
  execute 'autocmd FocusLost,BufLeave' g:vtd_wiki_path.'/* call vtd#WriteIfModified()'
  execute 'autocmd FocusGained,BufEnter' g:vtd_wiki_path.'/* setlocal autoread noswapfile'
augroup END
