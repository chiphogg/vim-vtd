" @section Mappings


""
" Quit the VTD view window.
nnoremap <silent> <buffer> Q :call vtd#view#Exit()<CR>
nmap <silent> <buffer> q Q



" @section Autocmds


augroup vtd_view
  autocmd!
  autocmd FocusLost,BufLeave,FocusGained,BufEnter,CursorHold
      \ <buffer> call vtd#view#Enter()
augroup END
