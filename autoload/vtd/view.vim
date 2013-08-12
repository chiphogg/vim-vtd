" This gives us access to all the python functions in vtd.py.
call vtd#EnsurePythonLoaded()

" The buffer number of the VTD View buffer.
let s:vtd_view_buffer_number = -1

" @section Classes and objects

""
" A keymap particular to a specific kind of VTD view.
"
" Its constructor sets up the keymap; its destructor removes the keymap.
let s:Keymap = {}

""
" Creates a keymap for {key} which performs {action}.  Caller can provide an
" optional human-readable [description], and also change the keymap's [modes]
" (see |:map-arguments|; defaults to "<buffer> <silent>").
function! s:Keymap.New(key, action, ...)
  " Optional parameters.
  let l:description = (a:0 >= 1) ? a:1 : ''
  let l:modes = (a:0 >= 2) ? a:2 : '<buffer> <silent>'

  let l:new = copy(s:Keymap)
  let l:new._key = a:key
  let l:new._modes = l:modes
  let l:new._description = l:description
  execute 'nnoremap' l:new._modes a:key a:action
  return l:new
endfunction

function! s:Keymap.delete()
  execute 'nunmap' self._modes self._key
endfunction

" @section Common functions

""
" Enter the VTD View buffer (creating it if it does not exist).
function! vtd#view#Enter()
  call vtd#UpdateSystem()

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

    " A new buffer should be populated with the Summary content.
    call s:FillWithSummary()
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

" @subsection Summary view functions

function! s:FillWithSummary()
  let l:text = [
      \ 'Contexts: <not implemented>',
      \ '',
      \ 'Next Actions: <not implemented>',
      \ ]
  call s:FillView(l:text)
endfunction
