" This gives us access to all the python functions in vtd.py.
call vtd#EnsurePythonLoaded()

" The buffer number of the VTD View buffer.
let s:vtd_view_buffer_number = -1

" The current VTD View object.
let s:current_vtd_view = {}

" A list of keymapping objects which apply to every VTD View type.
let s:universal_keymaps = []

" @section Classes and objects


" Registered VTD View classes.  These can be accessed by their "name"
" ("Contexts", "Next Actions", "Summary", etc.).
" 
" Populated by s:RegisterView().
let s:ViewClasses = {}


""
" Registers {prototype} as a VTD View class, which can be accessed by the given
" {name}.
"
" If [keymapping] is supplied, it will switch to the given type of VTD view from
" any other VTD view type.
function! s:RegisterView(prototype, name, ...)
  " Optional parameters.
  let l:keymapping = (a:0 >= 1) ? a:1 : ''

  let s:ViewClasses[a:name] = a:prototype
  let a:prototype.type = a:name

  if !empty(l:keymapping)
    call add(s:universal_keymaps, s:Keymap.New(l:keymapping,
        \ ':call vtd#view#Enter("' . a:name . '")<CR>',
        \ 'Jump to ' . a:name))
  endif
endfunction


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
  let l:new._action = a:action
  let l:new._modes = l:modes
  let l:new._description = l:description
  return l:new
endfunction


""
" Set up this keymapping in the current buffer.
"
" Should be idempotent, unless <unique> is in self._modes.
function! s:Keymap.map()
  execute 'nnoremap' self._modes self._key self._action
endfunction


""
" Remove this keymapping from the current buffer.
function! s:Keymap.unmap()
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
    call s:SetUniversalVtdViewMappings()
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
" Setup all view-type-specific keymaps from this buffer.
function! s:VtdView.setupKeymaps()
  for l:map in self._keymaps
    call l:map.map()
  endfor
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
    call l:map.unmap()
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


" @subsection Summary view


" Inherits from s:VtdView in the constructor rather than here, so that
" s:VtdView's constructor code will be executed for each new object.
let s:VtdViewSummary = {}
call s:RegisterView(s:VtdViewSummary, 'Summary', 'S')


function! s:VtdViewSummary.New()
  " Call the parent constructor.
  let l:new = s:VtdView.New()

  call extend(l:new, copy(s:VtdViewSummary))
  return l:new
endfunction


function! s:VtdViewSummary.display()
  call self.fill(['Summary view (not yet implemented!)'])
endfunction


function! s:VtdViewSummary.setUp()
  call add(self._keymaps, s:Keymap.New('j', ':echomsg "FOO!"<CR>'))
  call self.setupKeymaps()
endfunction


" @subsection Contexts view


let s:VtdViewContexts = {}
call s:RegisterView(s:VtdViewContexts, 'Contexts', 'C')


function! s:VtdViewContexts.New()
  " Call the parent constructor.
  let l:new = s:VtdView.New()

  call extend(l:new, copy(s:VtdViewContexts))
  return l:new
endfunction


function! s:VtdViewContexts.display()
  call self.fill(['Contexts view (not yet implemented!)'])
endfunction


" @section Common functions


" @subsection API functions


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


" @subsection Helper functions


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
  let s:current_vtd_view = s:ViewClasses[a:view_type].New()
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


""
" Set up mappings which should be valid in *every* VTD view window.
"
" Mainly, these are navigational mappings.
function! s:SetUniversalVtdViewMappings()
  for l:map in s:universal_keymaps
    call l:map.map()
  endfor
endfunction
