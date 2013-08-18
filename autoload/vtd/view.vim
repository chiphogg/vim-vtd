" This gives us access to all the python functions in vtd.py.
call vtd#EnsurePythonLoaded()

" The buffer number of the VTD View buffer.
let s:vtd_view_buffer_number = -1

" The current VTD View object.
let s:current_vtd_view = {}

" A list of keymapping objects which apply to every VTD View type.
let s:universal_keymaps = []

" @section Classes and objects

" TODO(chiphogg): Split classes into separate files under lib/vtd after I have a
" plugin-global variable.

" An option with several values, which can be cycled through.
let s:CyclableOption = {}


""
" Creates an option with the given {values}, in order.
"
" Can be given an index to the [initial_value] (defaults to the first option).
function! s:CyclableOption.New(values, ...)
  " Optional parameters.
  let l:initial_value = (a:0 >= 1) ? a:1 : 0

  let l:new = copy(s:CyclableOption)
  let l:new._values = a:values
  let l:new.value = l:initial_value

  " self.options lets us refer to the options by name rather than index.
  let l:new.options = {}
  for l:value in a:values
    let l:new.options[l:value] = index(a:values, l:value)
  endfor

  return l:new
endfunction


""
" Advance this option to the next permissible value.  (After the last, it loops
" around to the first.)
function! s:CyclableOption.Next()
  let self.value = (self.value + 1) % len(self._values)
endfunction


""
" Setting for a context: one of 'include', 'exclude', or 'clear'.
let s:ContextSetting = s:CyclableOption.New(['clear', 'include', 'exclude'])
function! s:ContextSetting.New()
  let l:new = copy(s:ContextSetting)
  return l:new
endfunction


" Registered VTD View classes.  These can be accessed by their "name"
" ("Contexts", "Next Actions", "Summary", etc.).
" 
" Populated by s:RegisterView().
let s:ViewObjects = {}


""
" Registers {object} as a VTD View object, which can be accessed by the given
" {name}.
"
" If [keymapping] is supplied, it will switch to the given type of VTD view from
" any other VTD view type.
function! s:RegisterView(object, name, ...)
  " Optional parameters.
  let l:keymapping = (a:0 >= 1) ? a:1 : ''

  let s:ViewObjects[a:name] = a:object
  let a:object.type = a:name

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
    setlocal conceallevel=3
    setlocal concealcursor=nc
    setlocal textwidth=0
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
" Save the current cursor position.
function! s:VtdView.saveCursor()
  let self._cursor = getpos('.')
endfunction


""
" Restore the saved cursor position, if any.
function! s:VtdView.restoreCursor()
  if has_key(self, '_cursor')
    call setpos('.', self._cursor)
  endif
endfunction


""
" Enter the VTD View buffer and display the contents.
function! s:VtdView.enter()
  call self.switchToViewBuffer()
  call self.display()
endfunction


""
" Perform setup tasks for a VTD view window.
"
" Tasks specific to a particular type may be performed in a .specialSetUp()
" function.
function! s:VtdView.setUp()
  call self.specialSetUp()
endfunction


""
" Teardown tasks common to all types of VTD view window.
"
" Tasks specific to a particular type may be performed in a .specialTearDown()
" function.
function! s:VtdView.tearDown()
  " Remove special keymaps from the buffer.
  call self.removeKeymaps()

  " Save the cursor position for the next time we enter this view.
  call self.saveCursor()

  " Any additional teardown tasks for this particular VTD View.
  call self.specialTearDown()
endfunction


""
" Setup tasks specific to a particular type of VTD View window.
"
" Intended to be overridden by specific instances.
function! s:VtdView.specialSetUp()
  return
endfunction


""
" Teardown tasks specific to a particular type of VTD View window.
"
" Intended to be overridden by specific instances.
function! s:VtdView.specialTearDown()
  return
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
  call self.restoreCursor()
endfunction


" @subsection Summary view


let s:VtdViewSummary = s:VtdView.New()
call s:RegisterView(s:VtdViewSummary, 'Summary', 'S')


function! s:VtdViewSummary.display()
  call self.fill(['Summary view (not yet implemented!)'])
endfunction


" @subsection Contexts view


let s:VtdViewContexts = s:VtdView.New()
call s:RegisterView(s:VtdViewContexts, 'Contexts', 'C')


""
" Display a {context} based on its current status.
"
" {context} is a list: the first element is the name of the context; the second
" is the number of current Next Actions having that context.
function! s:DisplayContextWithStatus(context)
  let l:name = a:context[0]
  let l:count = a:context[1]

  " Mark this context according to its status (visible, 
  let l:marker = ''
  if s:ContextSettingFor(l:name).value ==# s:ContextSetting.options.include
    let l:marker = '+'
  elseif s:ContextSettingFor(l:name).value ==# s:ContextSetting.options.exclude
    let l:marker = '-'
  endif

  return '[@' . l:marker . l:name . ' (' . l:count . ')]'
endfunction


function! s:VtdViewContexts.display()
  let l:contexts = []
  python vim.bindeval('l:contexts').extend(my_system.ContextList())
  call map(l:contexts, 's:DisplayContextWithStatus(v:val)')
  call self.fill(l:contexts)
endfunction


function! s:VtdViewContexts.specialSetUp()
  call add(self._keymaps, s:Keymap.New('+',
      \ ':call <SID>IncludeNearestContext()<CR>',
      \ 'Add the nearest context to the "included" list.'))
  call add(self._keymaps, s:Keymap.New('-',
      \ ':call <SID>ExcludeNearestContext()<CR>',
      \ 'Add the nearest context to the "excluded" list.'))
  call add(self._keymaps, s:Keymap.New('/',
      \ ':call <SID>ClearNearestContext()<CR>',
      \ 'Clear the nearest context from both "included" and "excluded" lists.'))
  call add(self._keymaps, s:Keymap.New('*',
      \ ':call <SID>ToggleNearestContext()<CR>',
      \ 'Cycle setting for nearest context among "included", "excluded",'
      \ . ' and neither.'))
  call self.setupKeymaps()
endfunction


function! s:IncludeNearestContext()
  let l:context = s:NearestContext()
  if !empty(l:context)
    call vtd#view#IncludeContexts([l:context])
  endif
  call vtd#view#Enter()
endfunction


function! s:ExcludeNearestContext()
  let l:context = s:NearestContext()
  if !empty(l:context)
    call vtd#view#ExcludeContexts([l:context])
  endif
  call vtd#view#Enter()
endfunction


function! s:ClearNearestContext()
  let l:context = s:NearestContext()
  if !empty(l:context)
    call vtd#view#ClearContexts([l:context])
  endif
  call vtd#view#Enter()
endfunction


function! s:ToggleNearestContext()
  let l:context = s:NearestContext()
  if !empty(l:context)
    let l:setting = s:ContextSettingFor(l:context)
    call l:setting.Next()
  endif
  call vtd#view#Enter()
endfunction


""
" Move to the context "nearest" to the current cursor position, and return its
" name.
"
" "Nearest" is intended to function similarly to the |*| search command: it
" chooses the context under the cursor, if any; if none, it searches to the end
" of the current line.
"
" If there is no nearest context, the cursor is unmoved.
function! s:NearestContext()
  " Search the current line for the next context.  We assume this looks like a
  " ']' at the end of something like '[@...]', where the '...' is anything
  " without any '[' or ']' characters.  This line also moves to the ']' if there
  " is one; otherwise we return (and the cursor will be unmoved).
  let l:context_opener = '\[\@'
  let l:no_square_brackets = '[^][]*'
  let l:line = search('\v(' . l:context_opener . l:no_square_brackets . ')@<='
        \ .'\]', 'ce', line('.'))
  if empty(l:line)
    return ''
  endif

  " Move back to the '@' (including a following non-word character, if any).
  " The next character is the first character of the context, so we move right
  " by 1 column.
  call search('\v\@\W?', 'be')
  normal! l
  " TODO(chiphogg): assert that this leaves us on the same line.
  return expand('<cword>')
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
      call s:current_vtd_view.enter()
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
" Add the given {contexts} to the "included" list.  This means that Next Actions
" having these contexts will be visible.  However, any such Next Actions which
" also have a context from the "excluded" list will *not* be visible; the
" "excluded" list takes priority.
function! vtd#view#IncludeContexts(contexts)
  for l:context in a:contexts
    let l:setting = s:ContextSettingFor(l:context)
    let l:setting.value = l:setting.options.include
  endfor
endfunction


""
" Add the given {contexts} to the "excluded" list.  This means that no Next
" Actions having these contexts will be visible.
function! vtd#view#ExcludeContexts(contexts)
  for l:context in a:contexts
    let l:setting = s:ContextSettingFor(l:context)
    let l:setting.value = l:setting.options.exclude
  endfor
endfunction


""
" Clear the settings for the given {contexts}, removing them from both the
" "included" and the "excluded" list.
function! vtd#view#ClearContexts(contexts)
  for l:context in a:contexts
    let l:setting = s:ContextSettingFor(l:context)
    let l:setting.value = l:setting.options.clear
  endfor
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
  let s:current_vtd_view = s:ViewObjects[a:view_type]
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


""
" The ContextSetting for the given {context}.
" 
" Creates it if it doesn't exist.
function! s:ContextSettingFor(context)
  " Define it here: we only ever access it through this function as an
  " interface.  Guarding it like this also makes the autoload script re-entrant
  " (won't clobber the context settings).
  if !exists('s:_context_settings')
    let s:_context_settings = {}
  endif

  " Create a setting for this context if it doesn't already have one.
  if !has_key(s:_context_settings, a:context)
    let s:_context_settings[a:context] = s:ContextSetting.New()
  endif

  return s:_context_settings[a:context]
endfunction
