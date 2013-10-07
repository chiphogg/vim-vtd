" This gives us access to all the python functions in vtd.py.
call vtd#EnsurePythonLoaded()

" The buffer number of the VTD View buffer.
let s:vtd_view_buffer_number = -1

" The current VTD View object.
let s:current_vtd_view = {}

" A list of keymapping objects which apply to every VTD View type.
let s:universal_keymaps = []

" If set to a context, we show only that context.
let s:exclusive_context = ''

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
" The name of the option given by [index] (defaults to current).
function! s:CyclableOption.Setting(...)
  " Optional parameters.
  let l:index = (a:0 >= 1) ? a:1 : self.value
  return self._values[l:index % len(self._values)]
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


""
" Whether or not to show the interactive help.
let s:show_help = s:CyclableOption.New(['Hide', 'Show'])


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
    let a:object.key = l:keymapping
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


""
" A human-readable description of the keymap and what it does.
function! s:Keymap.display()
  let l:key = '[' . self._key . ']'
  return printf('%12s: %s', l:key, self._description)
endfunction


" @subsection History functions
" For now, just make a single global history object.  If I ever decide I want
" more than one, I can turn it into a class.
let s:history = {}
let s:history._index = 0
let s:history._changes = []


""
" Apply {patch} to {file}, and save it in the undo history (along with optional
" [description]).
function! s:history.apply(patch, file, ...)
  " Optional parameters.
  let l:description = (a:0 >= 1) ? a:1 : ''
  " Add the patch to the end of the undo history, and "redo" it.  (This way the
  " index will be updated correctly.)
  call self.forgetRedo()
  call add(self._changes, {'patch': a:patch, 'file': a:file,
        \ 'description': l:description })
  call self.redo()
endfunction


""
" Forget any undone changes.
function! s:history.forgetRedo()
  if len(self._changes) > self._index
    call remove(self._changes, self._index, -1)
  endif
endfunction


""
" Redo the last change in the stack.
function! s:history.redo()
  if self._index >= len(self._changes)
    call s:Warn('Nothing to redo!')
    return
  endif

  let l:patch = self._changes[self._index]
  if s:Patch(l:patch.patch, l:patch.file)
    let self._index += 1
  endif
endfunction


""
" Undo the last change in the stack.
function! s:history.undo()
  if self._index < 1
    call s:Warn('Nothing to undo!')
    return
  endif

  let l:patch = self._changes[self._index - 1]
  if s:Patch(l:patch.patch, l:patch.file, '-R')
    let self._index -= 1
  endif
endfunction


" @subsection VTD View functions
let s:VtdView = {}


" All VtdView objects should have a '?' keymap to show help.
call add(s:universal_keymaps, s:Keymap.New('?',
      \ ':call <SID>ToggleHelpDisplay()<CR>',
      \ 'Toggle the "help" display'))
function! s:ToggleHelpDisplay()
  call s:show_help.Next()
  call vtd#view#Enter()
endfunction


""
" Construct a VTD view window.
function! s:VtdView.New()
  let l:new = copy(s:VtdView)
  let l:new._keymaps = []
  let l:new.key = ''
  let l:new.active = 0
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
" Print an interactive help menu for the current View.
function! s:VtdView.help()
  let l:next_setting = s:show_help.Setting(s:show_help.value + 1)
  let l:lines = ['? [?] ' . l:next_setting . ' interactive help']
  if s:show_help.value ==# s:show_help.options.Show
    call extend(l:lines, ['?', '? Global Keymaps'])
    for l:keymap in s:universal_keymaps
      call add(l:lines, '? ' . l:keymap.display())
    endfor

    if len(self._keymaps) > 0
      call extend(l:lines, ['?', '? Special Keymaps'])
      for l:keymap in self._keymaps
        call add(l:lines, '? ' . l:keymap.display())
      endfor
    endif

    call add(l:lines, '')
  endif
  return l:lines
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
" Perform setup tasks for a VTD view window.
"
" Tasks specific to a particular type may be performed in a .specialSetUp()
" function.
function! s:VtdView.setUp()
  let self.active = 1
  call self.specialSetUp()
  call self.setupKeymaps()
endfunction


""
" Teardown tasks common to all types of VTD view window.
"
" Tasks specific to a particular type may be performed in a .specialTearDown()
" function.
function! s:VtdView.tearDown()
  let self.active = 0

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
  if self.active
    call self.saveCursor()
  endif
  let l:lines = []

  " Basic content, common to all views.
  call extend(l:lines, self.help())
  call extend(l:lines, self.title())

  " Additional lines specific to this particular view.
  let self._first_content_line = len(l:lines) + 1
  call extend(l:lines, a:lines)

  let l:text = join(l:lines, "\n")

  setlocal modifiable
  silent! 1,$ delete _
  silent! put =l:text
  silent! 1,1 delete _
  setlocal nomodifiable
  call self.restoreCursor()
endfunction


function s:VtdView.title()
  return !has_key(self, 'type') ? [] :
      \ ['= ' . s:DecorateWithKeymapping(self.type, self.key) . ' =', '']
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
  let l:marker = ' '
  if empty(s:exclusive_context)
    let l:setting = s:ContextSettingFor(l:name)
    if l:setting.value ==# s:ContextSetting.options.include
      let l:marker = '+'
    elseif l:setting.value ==# s:ContextSetting.options.exclude
      let l:marker = '-'
    endif
  else
    let l:marker = (l:name == s:exclusive_context) ? '!' : '#'
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
  call add(self._keymaps, s:Keymap.New('!',
      \ ':call <SID>ToggleNearestContextExclusive()<CR>',
      \ 'Include *only* the nearest context (press twice to cancel).'))
endfunction


function! s:IncludeNearestContext()
  let s:exclusive_context = ''
  let l:context = s:NearestContext()
  if !empty(l:context)
    call vtd#view#IncludeContexts([l:context])
  endif
  call vtd#view#Enter()
endfunction


function! s:ExcludeNearestContext()
  let s:exclusive_context = ''
  let l:context = s:NearestContext()
  if !empty(l:context)
    call vtd#view#ExcludeContexts([l:context])
  endif
  call vtd#view#Enter()
endfunction


function! s:ClearNearestContext()
  let s:exclusive_context = ''
  let l:context = s:NearestContext()
  if !empty(l:context)
    call vtd#view#ClearContexts([l:context])
  endif
  call vtd#view#Enter()
endfunction


function! s:ToggleNearestContext()
  let s:exclusive_context = ''
  let l:context = s:NearestContext()
  if !empty(l:context)
    let l:setting = s:ContextSettingFor(l:context)
    call l:setting.Next()
  endif
  call vtd#view#Enter()
endfunction


function! s:ToggleNearestContextExclusive()
  let l:context = s:NearestContext()
  if !empty(l:context)
    let s:exclusive_context = (s:exclusive_context ==# l:context) ?
        \ '' : l:context
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
  call search('\v\@\W?', 'be')
  " TODO(chiphogg): assert that this leaves us on the same line.
  return expand('<cword>')
endfunction


" @subsection Next Actions view


let s:VtdViewNextActions = s:VtdView.New()
call s:RegisterView(s:VtdViewNextActions, 'Next Actions', 'N')


function! s:VtdViewNextActions.display()
  let l:actions = []

  " Make python variable 'actions' hold the list of actions to display.
  call self.putActionsInPythonVariable()
  " Populate the global python variable 'next_action_sections'.
  python MakeSectionedActions(actions)

  python na = next_action_sections.Lines(NextActionDisplayText)
  python vim.bindeval('l:actions').extend(na)
  call self.fill(l:actions)
endfunction


""
" Put list of actions in 'actions' variable.
function! s:VtdViewNextActions.putActionsInPythonVariable()
  python actions = my_system.NextActions()
endfunction


""
" Set python variable 'na' to the Node on the current line, if any.  Returns
" 1 if successful, 0 otherwise.
function! s:VtdViewNextActions.CurrentNodeTo_na()
  let l:index = line(".") - self._first_content_line
  python na = next_action_sections.NodeAt(int(vim.eval('l:index')))
  python vim.command('let l:success = {}'.format(1 if na else 0))
  return l:success
endfunction


""
" Check off the NextAction on the current line.
function! s:VtdViewNextActions.checkoff()
  " Check that the current line holds a valid NextAction.
  let l:found_node = self.CurrentNodeTo_na()
  if !l:found_node
    call s:Warn('No Next Action on line ' . line(".") . '.')
    return
  endif

  " Find the NextAction object and retrieve the info we need: its patch, its
  " text, and its file name.
  let l:vars = []
  python patch = na.Patch(libvtd.node.Actions.DefaultCheckoff)
  python vim.bindeval('l:vars').extend([patch, na.text, na.file_name])
  let l:patch = l:vars[0]
  let l:text = printf(self.CheckoffPatchFormat(), l:vars[1])
  let l:file = l:vars[2]

  " Patch the file
  call s:history.apply(l:patch, l:file, l:text)
endfunction


""
" Jump to the line in the original file which corresponds to the Node on the
" current line.
function! s:VtdViewNextActions.jump()
  let l:found_node = self.CurrentNodeTo_na()
  if !l:found_node
    call s:Warn('No Next Action on line ' . line(".") . '.')
    return
  endif

  " Find the NextAction object and retrieve the info we need: its file name and
  " line number.
  let l:vars = []
  python (file, line) = na.Source()
  python vim.bindeval('l:vars').extend([file, line])

  " Go to the file.
  execute 'edit' . escape(l:vars[0], ' ')

  " Go to the line number and ensure the fold is open.
  execute "normal!" l:vars[1] . 'G'
  normal! zv
endfunction


""
" A format string for the checkoff() patch.
function! s:VtdViewNextActions.CheckoffPatchFormat()
  return 'Mark as "DONE": "%s"'
endfunction


function! s:CheckoffNextAction()
  call s:current_vtd_view.checkoff()
endfunction
function! s:JumpToFile()
  call s:current_vtd_view.jump()
endfunction
function! s:HistoryUndo()
  call s:history.undo()
endfunction
function! s:HistoryRedo()
  call s:history.redo()
endfunction


function! s:VtdViewNextActions.specialSetUp()
  call add(self._keymaps, s:Keymap.New('<Space>',
      \ ':call <SID>CheckoffNextAction()<CR>',
      \ 'Check off the NextAction on the current line as "DONE"'))
  call add(self._keymaps, s:Keymap.New('gf',
      \ ':call <SID>JumpToFile()<CR>',
      \ 'Open the underlying VTD file at the corresponding line'))
  call add(self._keymaps, s:Keymap.New('u',
      \ ':call <SID>HistoryUndo()<CR>',
      \ 'Undo the previous change to the Trusted System'))
  call add(self._keymaps, s:Keymap.New('<C-R>',
      \ ':call <SID>HistoryRedo()<CR>',
      \ 'Undo the previous change to the Trusted System'))
endfunction


" @subsection Recurring Actions view


let s:VtdViewRecurs = copy(s:VtdViewNextActions)
call s:RegisterView(s:VtdViewRecurs, 'Recurring Actions', 'R')


""
" Put list of recurring actions in 'actions' variable.
function! s:VtdViewRecurs.putActionsInPythonVariable()
  python actions = my_system.RecurringActions()
endfunction


""
" A format string for the checkoff() patch.
function! s:VtdViewRecurs.CheckoffPatchFormat()
  return 'Update "LASTDONE": "%s"'
endfunction


" @subsection Inboxes view


let s:VtdViewInboxes = copy(s:VtdViewRecurs)
call s:RegisterView(s:VtdViewInboxes, 'Inboxes', 'I')


""
" Put list of inboxes in 'actions' variable.
function! s:VtdViewInboxes.putActionsInPythonVariable()
  python actions = my_system.Inboxes()
endfunction


" @subsection 'All' view (NextActions, RecurringActions, Inboxes)


let s:VtdViewInboxes = copy(s:VtdViewRecurs)
call s:RegisterView(s:VtdViewInboxes,
    \ 'All (Next Actions; Recurring Actions; Inboxes)', 'A')


""
" Put list of doable actions in 'actions' variable.
function! s:VtdViewInboxes.putActionsInPythonVariable()
  python actions = []
  python actions.extend(my_system.Inboxes())
  python actions.extend(my_system.RecurringActions())
  python actions.extend(my_system.NextActions())
endfunction


" @subsection Waiting view


let s:VtdViewWaiting = copy(s:VtdViewNextActions)
call s:RegisterView(s:VtdViewWaiting, 'Waiting', 'W')


""
" Put list of 'waiting-for' actions in 'actions' variable.
function! s:VtdViewWaiting.putActionsInPythonVariable()
  python actions = my_system.Waiting()
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
  call s:UpdateSystemContexts()

  " Check whether a VTD View object already exists.
  if !empty(s:current_vtd_view)
    " If the existing view is valid, simply enter it directly, and we're done.
    if !l:specific_type_requested || l:view_type == s:CurrentViewType()
      call s:current_vtd_view.switchToViewBuffer()
      call s:current_vtd_view.display()
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
" Update the trusted system to use the contexts we've included.
function! s:UpdateSystemContexts()
  python ci = vim.eval('s:ContextsToInclude()')
  python ce = vim.eval('s:ContextsToExclude()')
  python my_system.SetContexts(include=ci, exclude=ce)
endfunction


""
" If {text} contains the given {key}, surround {key} in {text} with square
" brackets to indicate that it is a mapping.
"
" Does nothing if {key} is empty.
function! s:DecorateWithKeymapping(text, key)
  if empty(a:key)
    return a:text
  endif
  let l:key = '[' . a:key . ']'
  let l:index = stridx(a:text, a:key)
  if l:index == -1
    " If the key doesn't appear in the text, tack it on to the end.
    return a:text . ' (' . l:key . ')'
  elseif l:index == 0
    " Special case if the text begins with the key (otherwise we'll hit negative
    " indices and it won't do what we expect).
    return l:key . a:text[1:]
  else
    " If the key appears after the first character, replace it with the wrapped
    " version.
    return a:text[0:(l:index - 1)] . l:key . a:text[(l:index + 1):]
  endif
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
  let s:current_vtd_view = s:ViewObjects[a:view_type]
  call s:current_vtd_view.switchToViewBuffer()
  call s:current_vtd_view.setUp()
  call s:current_vtd_view.display()
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


""
" The list of contexts (having at least one visible NextAction) to include.
function! s:ContextsToInclude()
  let l:contexts = []
  if empty(s:exclusive_context)
    python vim.bindeval('l:contexts').extend(my_system.ContextList())
    call filter(map(l:contexts, 'v:val[0]'),
          \ 's:ContextSettingFor(v:val).value ==# '
          \ . 's:ContextSetting.options.include')
  else
    call add(l:contexts, s:exclusive_context)
  endif
  return l:contexts
endfunction


""
" The list of contexts (having at least one visible NextAction) to exclude.
function! s:ContextsToExclude()
  let l:contexts = []
  if empty(s:exclusive_context)
    python vim.bindeval('l:contexts').extend(my_system.ContextList())
    call filter(map(l:contexts, 'v:val[0]'),
          \ 's:ContextSettingFor(v:val).value ==# '
          \ . 's:ContextSetting.options.exclude')
  endif
  return l:contexts
endfunction


""
" Echo a warning message.
function! s:Warn(message)
  echohl WarningMsg
  echomsg a:message
  echohl none
endfunction


""
" Apply {patch} to {file}, with [options].  Returns the success status of the
" patch operation.
function! s:Patch(patch, file, ...)
  let l:options = (a:0 >= 1) ? a:1 : ''
  let l:command = join(['patch', l:options, shellescape(a:file)])
  let l:result = system(l:command, a:patch)
  call vtd#view#Enter()
  return empty(v:shell_error)
endfunction
