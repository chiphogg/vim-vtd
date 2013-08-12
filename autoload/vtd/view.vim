" This gives us access to all the python functions in vtd.py.
call vtd#EnsurePythonLoaded()

" The buffer number of the VTD View buffer.
let s:vtd_view_buffer_number = -1

" The current VTD View object.
let s:current_vtd_view = {}


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

" @subsection VTD View functions
let s:VtdView = {}


""
" Construct a VTD view window.
function! s:VtdView.New()
  let l:new = copy(s:VtdView)
  let l:new._keymaps = []
  return l:new
endfunction


""
" Make sure the current buffer is the vtdview buffer, creating it if necessary.
function! s:VtdView.switchToViewBuffer()
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
" Enter the VTD View buffer and display the contents.
function! s:VtdView.enter()
  call self.switchToViewBuffer()
  call self.display()
endfunction


""
" Special setup tasks specific to a particular type of VTD view window.
"
" Since this is the (purely abstract) superclass, this function does nothing;
" base classes should override it.
function! s:VtdView.setUp()
  return
endfunction


""
" Special teardown tasks specific to a particular type of VTD view window.
"
" This default implementation simply deletes all the keymaps.
function! s:VtdView.tearDown()
  call self.removeKeymaps()
endfunction


""
" Remove all view-type-specific keymaps from this buffer.
"
" TODO(chiphogg): Document that this function sanity-checks the maps... after
" this function is extended to sanity-check the maps.
function! s:VtdView.removeKeymaps()
  while len(self._keymaps) > 0
    let l:map = remove(self._keymaps, 0)
    " TODO(chiphogg): Add assertion using maparg().
    call l:map.delete()
  endwhile
endfunction


""
" Replace contents of current buffer with the given {lines} of text.
function! s:VtdView.fill(lines)
  let l:text = join(a:lines, "\n")

  setlocal modifiable
  silent! 1,$ delete _
  silent! put =l:text
  silent! 1,1 delete _
  setlocal nomodifiable
endfunction


" @section Common functions


""
" Go into the VTD View buffer, making sure it is "valid".
"
" A buffer is "valid" if it has been set up.  If [view_type] is given, the
" buffer must also be of that type to be valid.
"
" There may be an already-existing view buffer.  If so, we clean it up if it's
" invalid, or simply enter it if it's valid.
"
" If [view_type] is not supplied and there is no existing view, the default view
" type is "Summary".
function! vtd#view#Enter(...)
  " Optional parameters.
  let l:specific_type_requested = (a:0 >= 1)
  let l:view_type = l:specific_type_requested ? a:1 : 'Summary'

  " Make sure we're getting the latest tasks, etc.
  call vtd#UpdateSystem()

  " Check whether a VTD View object already exists.
  if !empty(s:current_vtd_view)
    " If the existing view is valid, simply enter it directly, and we're done.
    if !l:specific_type_requested || l:view_type == s:CurrentViewType()
      call s:current_vtd_view.switchToViewBuffer()
      return
    endif
    " If the existing view is invalid, we need to clean it up before creating a
    " new one.
    call s:VtdViewTearDown()
  endif

  " At this point, no valid VTD View object should exist, so we have to make
  " one.
  " TODO(chiphogg): add an assertion to that effect.
  call s:VtdViewSetUp(l:view_type)
endfunction


""
" Leave and destroy the VTD View buffer.
"
" Note that this function must first enter the VTD View buffer if we're not
" already there.
function! vtd#view#Exit()
  if !empty(s:current_vtd_view)
    call vtd#view#Enter()
    call s:VtdViewTearDown()
    bwipeout
  endif
  " TODO(chiphogg): Add an assertion that the vtd view buffer number doesn't
  " exist.
  let s:vtd_view_buffer_number = -1
endfunction


""
" The type of the current VTD View buffer.
"
" Returns the empty string if there is none, or if it has no 'type' field.
function! s:CurrentViewType()
  let l:lacks_type = empty(s:current_vtd_view) ||
      \ !has_key(s:current_vtd_view, 'type')
  return l:lacks_type ? '' : s:current_vtd_view.type
endfunction


""
" Construct a new object for the current VTD View, and use it to set up the VTD
" View buffer.
"
" Leaves the editor inside the newly-created buffer.
function! s:VtdViewSetUp(view_type)
  " TODO(chiphogg): Assert that view_type is a valid VTD View class type.
  let s:current_vtd_view = s:VtdView.New()
  call s:current_vtd_view.enter()
  call s:current_vtd_view.setUp()
endfunction


""
" Go to the VTD View buffer, remove settings which are specific to the
" particular type of view, and set the current view object to empty.
"
" Does nothing if there isn't currently a VtdView object.
function! s:VtdViewTearDown()
  if !empty(s:current_vtd_view)
    call s:current_vtd_view.tearDown()
    let s:current_vtd_view = {}
  endif
endfunction
