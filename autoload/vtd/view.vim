" @section Common functions

" The buffer number of the VTD View buffer.
let s:vtd_view_buffer_number = -1

""
" Enter the VTD View buffer (creating it if it does not exist).
function! vtd#view#Enter()
  " We keep track of the VTD View buffer solely by its buffer number.  First, we
  " check whether the buffer already exists, and create it if it doesn't.
  if !bufexists(s:vtd_view_buffer_number)
    " Create a new buffer and capture its buffer number.
    enew
    let s:vtd_view_buffer_number = bufnr('$')
    " Set appropriate VTD View buffer options.
    setlocal noswapfile
    setlocal nomodifiable
    setlocal buftype=nofile
    setlocal nofoldenable
    setlocal nobuflisted
    setlocal nospell
    setlocal nowrap
    setlocal filetype=vtdview
    return
  endif

  let l:vtd_view_window = bufwinnr(s:vtd_view_buffer_number)
  if l:vtd_view_window >= 0
    " We prefer to simply go to a window which already has that buffer,
    " if such a window exists.
    execute l:vtd_view_window . 'wincmd w'
  else
    " Otherwise, just open it in the current window.
    execute 'buffer' s:vtd_view_buffer_number
  endif
endfunction

""
" Replace the VTD View window contents with the text in {lines}.
function! s:FillView(lines)
  call vtd#view#Enter()
  let l:text = join(a:lines, "\n")

  setlocal modifiable
  silent! 1,$ delete _
  silent! put =l:text
  silent! 1,1 delete _
  setlocal nomodifiable
endfunction
