let s:plugin = maktaba#plugin#Get('vtd')
let s:action_keymaps = ['I', 'R', 'X', 'D']

function! s:SurroundBySpaceIfNonEmpty(string)
  return len(a:string) ? '  ' . a:string . ' ' : ''
endfunction


""
" The statusline text for Late actions.
function! vtd#statusline#Late()
  if vtd#Compatible()
    return s:SurroundBySpaceIfNonEmpty(s:StatuslineText('late'))
  endif
  return ''
endfunction


""
" The statusline text for Late actions.
function! vtd#statusline#Due()
  if vtd#Compatible()
    return s:SurroundBySpaceIfNonEmpty(s:StatuslineText('due'))
  endif
  return ''
endfunction


""
" Ensure the variable s:task_counts contains up-to-date task counts for each
" state ('Late', 'Due', etc.).
let s:task_counts = {}
let s:force_update_time = 15
function! s:EnsureTaskCountsUpdated()
  let l:changed = vtd#SystemModificationTime() >= get(
      \ s:, 'task_count_update_time', 0)
  let l:stale = localtime() > get(
      \ s:, 'last_updated_task_counts', 0) + s:force_update_time
  if l:changed || l:stale
    call s:UpdateTaskCounts()
    let s:task_count_update_time = localtime()
  endif
endfunction


""
" Update s:task_counts with the latest task counts per state.
function! s:UpdateTaskCounts()
  call vtd#EnsurePythonLoaded()
  " [A] is for 'All'; [D] is for 'Delegated'.
  let s:task_counts = {}
  call vtd#UpdateSystem()
  for l:keymap in s:action_keymaps
    let l:view_object = vtd#view#ObjectWhoseKeymapIs(l:keymap)
    call l:view_object.putActionsInPythonVariable()
    python CountCategories(
        \ actions, vim.eval('l:keymap'), vim.bindeval('s:task_counts'))
  endfor
  let s:last_updated_task_counts = localtime()
endfunction


""
" The statusline text for the requested {state}.
function! s:StatuslineText(state)
  call s:EnsureTaskCountsUpdated()
  if has_key(s:task_counts, a:state)
    return toupper(a:state) . ': ' . join(
        \ filter(map(copy(s:action_keymaps),
        \            's:StatuslineSnippetForKeymap("' . a:state . '", v:val)'),
        \        'len(v:val) > 0'),
        \ ', ')
  endif
  return ''
endfunction


function! s:StatuslineSnippetForKeymap(state, keymap)
  if has_key(s:task_counts[a:state], a:keymap)
    return printf('%d[%s]', s:task_counts[a:state][a:keymap], a:keymap)
  endif
  return ''
endfunction
