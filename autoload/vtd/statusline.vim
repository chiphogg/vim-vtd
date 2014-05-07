let s:plugin = maktaba#plugin#Get('vtd')

" This gives us access to all the python functions in vtd.py.
call vtd#EnsurePythonLoaded()


""
" The statusline text for Late actions.
function! vtd#statusline#Late()
  return s:StatuslineText('late')
endfunction


""
" The statusline text for Late actions.
function! vtd#statusline#Due()
  return s:StatuslineText('due')
endfunction


""
" Ensure the variable s:task_counts contains up-to-date task counts for each
" state ('Late', 'Due', etc.).
let s:task_counts = {}
function! s:EnsureTaskCountsUpdated()
  if vtd#SystemModificationTime() >= get(s:, 'task_count_update_time', 0)
    call s:UpdateTaskCounts()
    let s:task_count_update_time = localtime()
  endif
endfunction


""
" Update s:task_counts with the latest task counts per state.
function! s:UpdateTaskCounts()
  " [A] is for 'All'; [D] is for 'Delegated'.
  let s:task_counts = {}
  call vtd#UpdateSystem()
  for l:keymap in ['A', 'D']
    let l:view_object = vtd#view#ObjectWhoseKeymapIs(l:keymap)
    call l:view_object.putActionsInPythonVariable()
    python CountCategories(
        \ actions, vim.eval('l:keymap'), vim.bindeval('s:task_counts'))
  endfor
endfunction


""
" The statusline text for the requested {state}.
function! s:StatuslineText(state)
  call s:EnsureTaskCountsUpdated()
  if has_key(s:task_counts, a:state)
    return toupper(a:state) . ': ' . join(
        \ values(map(copy(s:task_counts[a:state]),
        \            'v:val . "[" . v:key . "]"')),
        \ ', ')
  endif
  return ''
endfunction
