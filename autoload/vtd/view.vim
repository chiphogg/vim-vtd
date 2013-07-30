" @section Common functions

""
" Put the VTD View buffer in the current window, creating it if necessary.
function! vtd#view#Enter()
  " Find a buffer with the exact name given below.  (Don't give another buffer
  " this name; I don't know what would happen.)
  let l:vtd_view_buffer_name = '__VTD_VIEW__'
  let l:buffer_number = bufnr('^' . l:vtd_view_buffer_name . '$')

  if l:buffer_number > 0
    " If the VTD View buffer already exists, simply go to it.
    if bufwinnr(l:buffer_number) >= 0
      " We prefer to simply go to a window which already has that buffer, if
      " such a window exists.
      execute bufwinnr(l:buffer_number) . 'wincmd w'
    else
      " Otherwise, just open it in the current window.
      execute 'buffer' l:buffer_number
    endif
  else
    " If the buffer does not exist, we must create it.
    silent! execute 'badd' l:vtd_view_buffer_name
    " Switch to the new buffer, and setup appropriate VTD view buffer options.
    silent! execute 'buffer' bufnr(l:vtd_view_buffer_name)
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nofoldenable
    setlocal nobuflisted
    setlocal nospell
    setlocal nowrap
    setlocal filetype=vtdview
  endif
endfunction
