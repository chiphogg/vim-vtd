" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-08-22
" URL: https://github.com/chiphogg/vim-vtd

" Initialization {{{1
"
" Working directory for the script {{{2
let s:autoload_dir = expand('<sfile>:p:h')

" Loading the scriptfiles {{{2

" Taken from gundo.vim: this helps vim find the python script
let s:plugin_path = escape(expand('<sfile>:p:h'), '\')

" FUNCTION: s:UpdatePython() {{{3
" Ensure the python script has been read and that the my_plate variable is
" up-to-date
function! s:UpdatePython()
  exe "pyfile" s:plugin_path."/parsers.py"
  python FillMyPlate()
endfunction

" End Initialization }}}1

" Utility functions {{{1
" SECTION: Bitwise 'and' {{{2
function! s:BitwiseAnd(a, b)
  return s:BitwiseAnd_recurse(a:a, a:b, 1)
endfunction

function! s:BitwiseAnd_recurse(a, b, weight)
  if a:a < 1 || a:b < 1
    return 0
  endif
  let l:a_2 = a:a / 2
  let l:b_2 = a:b / 2
  let l:higher_digits = s:BitwiseAnd_recurse(l:a_2, l:b_2, a:weight * 2)
  let l:this_digit = ((a:a % 2) + (a:b % 2) == 2)
  return (a:weight * l:this_digit) + l:higher_digits
endfunction

" SECTION: Preserve cursor position, etc. {{{2

" Adapted from:
" https://gist.github.com/2973488/222649d4e7f547e16c96e1b9ba56a16c22afd8c7

function! s:PreserveStart()
  let b:PRESERVE_search = @/
  let b:PRESERVE_cursor = getpos(".")
  normal! H
  let b:PRESERVE_window = getpos(".")
  call setpos(".", b:PRESERVE_cursor)
endfunction

function! s:PreserveFinish()
  let @/ = b:PRESERVE_search
  call setpos(".", b:PRESERVE_window)
  normal! zt
  call setpos(".", b:PRESERVE_cursor)
endfunction

function! s:Preserve(command)
  call s:PreserveStart()
  execute a:command
  call s:PreserveFinish()
endfunction

" FUNCTION: s:GotoUsableWindow() {{{2
" Go to a "usable" (i.e., not special in any way) window, creating one if none
" exists.  Defaults to most-recently-used window.
"
" (HEAVILY influenced by NERDtree's `s:Opener._previousWindow()` and related.)
function! s:GotoUsableWindow()
  let l:win_num = winnr("#")
  if !s:WindowUsable(l:win_num)
    let l:win_num = 1
    while l:win_num <= winnr("$")
      if l:win_num !=# winnr("#") && s:WindowUsable(l:win_num)
        break
      endif
      let l:win_num += 1
    endwhile
  endif
  
  " At this point, l:win_num either holds a usable window, or an invalid window
  " number.  If it's usable, go there; else, make a new split.
  if l:win_num <= winnr("$")
    execute l:win_num."wincmd w"
  else
    botright new
  endif
endfunction

" FUNCTION: s:LineContainsValidJump() {{{2
" Check whether the current line contains a valid jump marker.
"
" Return:
" 1 if this line has a valid jump marker; 0 otherwise
function! s:LineContainsValidJump()
  return match(getline("."), '\v\<\<[ipsc]\d+\>\>') > -1
endfunction

" FUNCTION: s:WindowUsable() {{{2
" Check whether the given window is "usable": i.e., an ordinary, regular
" window (rather than a help window, preview window, NERDtree, VOoM, VTDview,
" VTD context picker, etc.)
"
" Args:
" win_num: The window number to check.
"
" Return:
" 1 if the window is usable; 0 otherwise
function! s:WindowUsable(win_num)
  let l:buf_num = winbufnr(a:win_num)

  " If the window doesn't exist, it's obviously not usable
  if l:buf_num == -1
    return 0
  endif

  " Run through the checklist for what makes a buffer "usable"
  let l:U = 1 " Start with 1 (True); break up lines for readability
  " A 'USABLE BUFFER'...
  " ...must be a 'normal buffer':
  let l:U = l:U && getbufvar(l:buf_num, '&buftype') ==# ''
  " ...can't be preview window:
  let l:U = l:U && !getwinvar(l:buf_num, '&previewwindow')
  " ...can't be modified (unless 'hidden' is set!):
  let l:U = l:U && (!getbufvar(l:buf_num, '&modified') || &hidden)
  " ...can't be the vtdcontext window:
  let l:U = l:U && getbufvar(l:buf_num, '&filetype') !=? 'vtdcontext'

  return l:U
endfunction

" FUNCTION: vtd#JumpToLine() {{{2
" Goes to the named line in the original file.  If no line/file is given, look
" for a marker in the current line of the current buffer.
"
" Args:
" a:1: A string starting with the one-letter abbreviation of a VTD wiki file
"    (i=inboxes, p=projects, etc.) followed by one or more digits representing
"    the line number within that file.
function! vtd#JumpToLine(...)
  if a:0 >=# 1
    if match(a:1, '\v[ipsc]\d+') < 0
      echom "Error: jump string '".a:1."'does not have a valid format."
      return 1
    endif
    let l:jump_to = a:1
  else
    let l:jump_to = matchstr(getline("."), '\v\<\<[ipsc]\d+\>\>')
  endif
  let l:file_id = matchstr(l:jump_to, '[ipsc]')
  let l:line_no = matchstr(l:jump_to, '\v\d+')
  " Jump to the file and line
  python <<EOF
abbrev = vim.eval("l:file_id")
vim.command("let l:file = '%s'" % vtd_fullpath(abbrev).replace("'", "''"))
EOF
  call s:GotoUsableWindow()
  execute "edit +".l:line_no l:file
  execute "normal! zv"
endfunction

" FUNCTION: vtd#WriteIfModified() {{{2
" Write, but only if a file is modified.
"
" This function helps autocommands for when we leave a buffer.  We check if
" it's modified to avoid updating the timestamp for no reason, which would
" cause the vtdview to think it's out of date and re-scan the files.
function! vtd#WriteIfModified()
  if &modified == 1
    write
  endif
endfunction

" End Utility functions }}}1

" The following are the two "special buffers" for VTD.
"   The "VTD View" window shows your pruned, filtered lists: Next Actions,
"   Inboxes, etc.:
" VTD View buffer {{{1

" Notes about the VTD View buffer:
" 1) There will be only one buffer for the VTD View, identifiable by its name:
"    "__VTD_VIEW_BUFFER__"
" 2) This buffer is read-only, has no swap file, and has filetype "vtdview"

" VTD view: Variables and settings {{{2
" Buffer name {{{3
" Don't be stupid and give another buffer this name; I don't know
" what would happen.
let s:vtdview_name = "__VTD_VIEW_BUFFER__"

" Content state variables, i.e., "what gets displayed" {{{3

" Constants determining whether to show a given section in the VTD view.
" Used as bitwise logical operators.
let s:INBOX = 1
let s:RECUR = 2
let s:NEXTACT = 4
let s:REMIND = 8
" Show 'em all by default (corresponds to 'Home view'):
let s:vtdview_show = s:INBOX + s:RECUR + s:NEXTACT + s:REMIND

" Summary variables: show all content for this category, or just a summary?
" Default to 1 ("Summarize").
let s:vtdview_summarize_inbox = 1
let s:vtdview_summarize_nextActions = 1
let s:vtdview_summarize_recur = 1
let s:vtdview_summarize_remind = 1
let s:vtdview_summarize_contexts = 1

let s:vtdview_show_help = 0

" End Variables and settings }}}2
" VTD view: Utility functions {{{2
" FUNCTION: s:ConfidentViewBufNumber() {{{3
" Return the buffer number of the VTD view buffer.  Creates it if it doesn't
" already exist (this is the 'Confident' part).
"
" Return: 
" The buffer number of the VTD view buffer.
function! s:ConfidentViewBufNumber()
  " If it doesn't already exist, create it:
  if !s:View_Exists()
    silent! execute "badd" s:vtdview_name
  endif
  return bufnr(s:vtdview_name)
endfunction

" FUNCTION: s:CreateOrSwitchtoViewWin() {{{3
" End up in the vtdview window: switch to it if it exists; create it if not.
function! s:CreateOrSwitchtoViewWin()
  " Ensure the python code has been read.  This also checks timestamps and
  " updates the my_plate variable if needed.
  call s:UpdatePython()

  " If already *in* the view window, updating my_plate is all we need to do!
  if s:InVTDViewWindow()
    return
  endif

  " Save current buffer name and position
  call s:UpdatePreviousBufInfo()

  " This should always succeed, since it creates the buffer if it doesn't
  " already exist:
  let l:view_bufnr = s:ConfidentViewBufNumber()

  let l:winnr = bufwinnr(l:view_bufnr) 
  if l:winnr == -1
    " Create a window for the buffer if it doesn't already have one
    silent execute "topleft" g:vtd_view_height "new"
    setlocal winfixheight
    call s:SetViewBufOptions()
  else
    " If the vtdview buffer already has a window, go ahead and assume that
    " window has its options setup properly.  (In fact, this should have been
    " done by the exact code in the other branch of this if-block.)  So just go
    " to that window and be done with it!
    silent execute l:winnr "wincmd w"
  endif
endfunction

" FUNCTION: s:DisplayHelp() {{{3
" Writes help message to the current buffer.  *Heavily* influenced -- almost to
" the point of copy-pasting -- by scrooloose's NERDtree plugin.
function! s:DisplayHelp()
  let l:old_h = @h
  let @h = ''

  if s:vtdview_show_help == 1
    let @h=@h."# Nope: no help yet.\n"
  else
    let @h=@h."# Someday, pressing '?' will print a help message!\n"
  endif
  silent! put h

  let @h = l:old_h
endfunction

" FUNCTION: s:DisplayViewContent() {{{3
" Display the "meat" of the VTD view: inboxes, next actions, etc.
function! s:DisplayViewContent()
  call s:View_AppendSection('contexts', s:View_ContentContexts())
  call s:View_AppendSection('inbox', s:View_ContentInboxes())
  call s:View_AppendSection('remind', s:View_ContentReminders())
  call s:View_AppendSection('recur', s:View_ContentRecurs())
  call s:View_AppendSection('nextActions', s:View_ContentNextActions())
endfunction

" FUNCTION: s:FillViewBuffer() {{{3
function! s:FillViewBuffer()
  " Not very elegant; then again, I don't expect this should ever happen.
  if bufname("%") !=# s:vtdview_name
    throw "ERROR: Trying to put VTDview contents in non-VTDview buffer!"
  endif

  " Save current position and make buffer writable
  let l:old_position = getpos(".")
  let l:top_line = line("w0")
  setlocal modifiable

  " Delete buffer contents without clobbering register
  " (thanks scrooloose for the elegant, expressive syntax)
  silent 1,$ delete _
  let s:vtdview_sections = []

  " Add the actual content
  call s:DisplayHelp()
  call s:DisplayViewContent()
  call s:View_SetStatusline()

  " Delete the blank line at the top
  silent 1,1 delete _

  " Make buffer nonwritable and restore old position
  setlocal nomodifiable
  call cursor(l:top_line, 1)
  normal! zt
  call setpos(".", l:old_position)
endfunction

" FUNCTION: s:InVTDViewWindow() {{{3
" (bool): Are we currently in the vtd view window?
"
" Return:
" 1 if yes, 0 if no.
function! s:InVTDViewWindow()
  return bufname("%") ==# s:vtdview_name
endfunction

" FUNCTION: s:RestorePreviousBufCurrentWin() {{{3
" Recall that s:CreateOrSwitchtoViewWin() saved the info about the buffer we
" were editing when we *last* jumped to the view window.  This function
" restores that buffer state in the CURRENT window (i.e., it assumes the caller
" has already gone to the desired window).
function! s:RestorePreviousBufCurrentWin()
  " It would be surprising for the buffer to no longer exist, but if it
  " happens I'd want to know about it:
  if !bufexists(s:vtdview_previous_bufnr)
    let l:msg = "Cannot restore previous buffer #"
    let l:msg=l:msg.s:vtdview_previous_bufnr
    let l:msg=l:msg."; it no longer exists!"
    throw l:msg
  endif

  " Open the buffer and restore the position
  silent execute "buffer" s:vtdview_previous_bufnr
  silent call cursor(s:vtdview_previous_topline, 1)
  silent normal! zt
  silent call setpos(".", s:vtdview_previous_position)

  " Forget these variables
  unlet s:vtdview_previous_bufnr
  unlet s:vtdview_previous_topline
  unlet s:vtdview_previous_position
endfunction

" FUNCTION: s:Section_FirstLine() {{{3
" Linenumber of the first line of the current section in the VTD view window.
function! s:Section_FirstLine()
  let l:last = -1
  for [l:num, l:name] in s:vtdview_sections
    if l:num == line(".")
      return l:num
    elseif l:num > line(".")
      return l:last
    else
      let l:last = l:num
    endif
  endfor
  return l:last
endfunction

" FUNCTION: s:Section_Name() {{{3
" Name of the current section in the VTD view window.
function! s:Section_Name()
  let l:target = s:Section_FirstLine()
  for [l:line, l:name] in s:vtdview_sections
    if l:line == l:target
      return l:name
    endif
  endfor
  return "LOLwut?"
endfunction

" FUNCTION: s:SetViewBufOptions() {{{3
" Set the common options for the vtdview buffer
function! s:SetViewBufOptions()
  " Buffer options: this buffer should be very lightweight, just a "view"
  " (no swapfile, no file on disk, no spell-check, etc.)
  setlocal noswapfile
  setlocal buftype=nofile 
  setlocal bufhidden=delete
  setlocal nofoldenable
  setlocal nobuflisted
  setlocal nospell
  setlocal nowrap
  silent! exec "file" s:vtdview_name

  setfiletype vtdview
endfunction


" FUNCTION: s:ShouldDisplay(category) {{{3
" Should we display a given category?
function! s:ShouldDisplay(category)
  return s:BitwiseAnd(a:category, s:vtdview_show)
endfunction


" FUNCTION: s:ToggleSummary(name) {{{3
" Toggle the summary status for the named section
"
" Args:
" name: A string telling which section to summarize.  There must be a
"    corresponding variable s:vtdview_summarize_<name>.
function! s:ToggleSummary(name)
  let l:varname = "s:vtdview_summarize_".a:name
  if !exists(l:varname)
    let l:msg = "Section named '".a:name."' requires variable called '"
    let l:msg=l:msg.l:varname."'; but none exists"
    throw l:msg
  endif

  " Change 1 to 0 and 0 to 1:
  silent! exec "let" l:varname "= 1 -" l:varname
endfunction

" FUNCTION: s:UpdatePreviousBufInfo() {{{3
" When we enter the VTD view buffer, we want to be able to jump back where we
" came from.  So, this function saves the buffer name and position... *unless*
" we're already *in* the VTD view buffer, in which case it does nothing.
function! s:UpdatePreviousBufInfo()
  if !s:InVTDViewWindow()
    let s:vtdview_previous_bufnr = bufnr("%")
    let s:vtdview_previous_position = getpos(".")
    let s:vtdview_previous_topline = line("w0")
  endif
endfunction

" FUNCTION: s:View_AppendSection(name, content) {{{3
" Append a string to the buffer, and keep track of which line this section
" starts at.
"
" Args:
" name: A meaningful name for the section
" content: The section's content
function! s:View_AppendSection(name, content)
  " Blank sections don't get added
  if !strlen(a:content)
    return
  endif

  let l:old_c = @c
  let @c = a:content
  let s:vtdview_sections += [[line(".") + 1, a:name]]
  silent! put c
  let @c = l:old_c
endfunction

" FUNCTION: s:View_ContentContexts() {{{3
" Display the current contexts.
function! s:View_ContentContexts()
  let l:str = ''
  python <<EOF
content = my_plate.display_contexts()
vim.command("let l:str=l:str.'%s'" % content.replace("'", "''"))
EOF
  return l:str
endfunction

" FUNCTION: s:View_ContentInboxes() {{{3
" The current content about inboxes.
"
" Return: A string (possibly empty) describing inboxes currently visible to the
" user.  Information shown depends on value of s:vtdview_summarize_inbox.
function! s:View_ContentInboxes()
  let l:str=''
  if s:ShouldDisplay(s:INBOX)
    python <<EOF
content = my_plate.display_inboxes()
vim.command("let l:str=l:str.'\n%s'" % content.replace("'", "''"))
EOF
  endif
  return l:str
endfunction

" FUNCTION: s:View_ContentNextActions() {{{3
" The current content about Next Actions.
"
" Return: A string (possibly empty) describing Next Actions currently visible
" to the user.  Information shown depends on value of
" s:vtdview_summarize_nextActions.
function! s:View_ContentNextActions()
  let l:str=''
  if s:ShouldDisplay(s:NEXTACT)
    python <<EOF
content = my_plate.display_NextActions()
vim.command("let l:str=l:str.'\n%s'" % content.replace("'", "''"))
EOF
  endif
  return l:str
endfunction

" FUNCTION: s:View_ContentRecurs() {{{3
" The current content about recurring actions.
"
" Return: A string (possibly empty) describing recurring actions currently
" visible to the user.  Information shown depends on value of
" s:vtdview_summarize_recur.
function! s:View_ContentRecurs()
  let l:str=''
  if s:ShouldDisplay(s:RECUR)
    python <<EOF
content = my_plate.display_recurs()
vim.command("let l:str=l:str.'\n%s'" % content.replace("'", "''"))
EOF
  endif
  return l:str
endfunction

" FUNCTION: s:View_ContentReminders() {{{3
" The current content about reminders.
"
" Return: A string (possibly empty) describing reminders currently visible to
" the user.  Information shown depends on value of s:vtdview_summarize_recur.
function! s:View_ContentReminders()
  let l:str=''
  if s:ShouldDisplay(s:REMIND)
    python <<EOF
content = my_plate.display_reminders()
vim.command("let l:str=l:str.'\n%s'" % content.replace("'", "''"))
EOF
  endif
  return l:str
endfunction

" FUNCTION: s:View_Exists() {{{3
" Is there a currently-existing VTD view window?
"
" Return:
" 1 if a VTD view window exists, otherwise 0
function! s:View_Exists()
  return bufexists(s:vtdview_name)
endfunction

" FUNCTION: s:View_SetStatusline() {{{3
" Set the statusline for the view window depending on what's on our plate
function! s:View_SetStatusline()
  setlocal statusline=VTD\ View\ (
  setlocal statusline+=%{vtd#View_Type()}
  setlocal statusline+=)
endfunction

" End Utility functions }}}2
" VTD view: Public functions {{{2
" FUNCTION: vtd#View_ActOnLine() {{{3
" Perform the action appropriate for the given line.  If it's a section header,
" toggle summary-mode.  If it's a line-number, jump to that line.  Otherwise,
" do nothing.
function! vtd#View_ActOnLine()
  let l:linenum = line(".")
  let l:line = getline(".")
  let l:section_start = s:Section_FirstLine()
  if l:section_start ==# l:linenum
    " If we're on a section header, toggle its summary status
    call s:ToggleSummary(s:Section_Name())
  elseif s:LineContainsValidJump()
    " If we have a valid linejump, do that jump
    call vtd#JumpToLine()
  endif
  " Otherwise, silently do nothing

  " Refresh display
  call vtd#View_Refresh()
endfunction

" FUNCTION: vtd#View_Close() {{{3
" Close the VTD view window and delete the buffer.
function! vtd#View_Close()
  if s:View_Exists()
    silent! exec "bdelete" s:ConfidentViewBufNumber()
  endif
endfunction

" FUNCTION: vtd#View_EnterAndRefresh() {{{3
" Enter the VTD view window and refresh its contents.
function! vtd#View_EnterAndRefresh()
  call s:CreateOrSwitchtoViewWin()
  call s:FillViewBuffer()
endfunction

" FUNCTION: vtd#View_Home() {{{3
" Goto a 'VTD Home' buffer for a system overview.
function! vtd#View_Home()
  let s:vtdview_show = s:INBOX + s:RECUR + s:NEXTACT + s:REMIND
  let s:vtdview_type_name = "Home"
  call vtd#View_EnterAndRefresh()
endfunction

" FUNCTION: vtd#View_Inboxes() {{{3
" List all visible inboxes and their current status.
function! vtd#View_Inboxes()
  let s:vtdview_show = s:INBOX
  let s:vtdview_type_name = "Inboxes"
  call vtd#View_EnterAndRefresh()
endfunction

" FUNCTION: vtd#View_NextActions() {{{3
" List all Next Actions for current context.
function! vtd#View_NextActions()
  let s:vtdview_show = s:NEXTACT
  let s:vtdview_type_name = "Next Actions"
  call vtd#View_EnterAndRefresh()
endfunction

" FUNCTION: vtd#View_Refresh() {{{3
" Refresh VTD view window's contents.
" Based on the function names, you might think this would be called by
" vtd#View_EnterAndRefresh, but it's the other way around!  The reason is that
" we refresh a buffer by entering it, deleting its contents, and writing in the
" new contents.  So the other function is actually the more basic one.
function! vtd#View_Refresh()
  let l:already_there = s:InVTDViewWindow()
  call vtd#View_EnterAndRefresh()
  if !l:already_there
    wincmd p
    call s:RestorePreviousBufCurrentWin()
  endif
endfunction

" FUNCTION: vtd#View_Type() {{{3
" Which type of VTD view buffer is it? (Home, Inboxes, NextActions, etc.)
function! vtd#View_Type()
  return s:vtdview_type_name
endfunction

" End Public functions }}}2

" End VTD View buffer }}}1

"   The "VTD Contexts" window lets you edit the contexts file.
" VTD Contexts buffer {{{1

" VTD contexts: Utility Functions {{{2
" FUNCTION: s:ConfidentContextBufNumber() {{{3
" Return the buffer number of the VTD contexts buffer.  Creates it if it
" doesn't already exist (this is the 'Confident' part).
"
" Return: 
" The buffer number of the VTD contexts buffer.
function! s:ConfidentContextBufNumber()
  " If it doesn't already exist, create it:
  if !s:Contexts_Exists()
    silent! execute "badd" g:vtd_contexts_file
  endif
  return bufnr(g:vtd_contexts_file)
endfunction

" FUNCTION: s:Contexts_Exists() {{{3
" Is there a currently-existing VTD contexts window?
"
" Return:
" 1 if a VTD contexts window exists, otherwise 0
function! s:Contexts_Exists()
  return bufexists(g:vtd_contexts_file)
endfunction

" FUNCTION: s:CreateOrSwitchtoContextsWin() {{{3
" End up in the contexts window: switch to it if it exists; create it if not.
function! s:CreateOrSwitchtoContextsWin()
  " If already *in* the contexts window, we're done!
  if s:InVTDContextsWin()
    return
  endif

  " This should always succeed, since it creates the buffer if it doesn't
  " already exist:
  let l:context_bufnr = s:ConfidentContextBufNumber()

  let l:winnr = bufwinnr(l:context_bufnr) 
  if l:winnr == -1
    " Create a window for the buffer if it doesn't already have one
    silent execute "topleft" g:vtd_context_width "vnew"
    setlocal winfixwidth
    call s:SetContextBufOptions()
  else
    " If the contexts buffer already has a window, go ahead and assume that
    " window has its options setup properly.  (In fact, this should have been
    " done by the exact code in the other branch of this if-block.)  So just go
    " to that window and be done with it!
    silent execute l:winnr "wincmd w"
  endif
endfunction

" FUNCTION: s:InVTDContextsWin() {{{3
" (bool): Are we currently in the vtd contexts window?
"
" Return:
" 1 if yes, 0 if no.
function! s:InVTDContextsWin()
  return bufname("%") ==# g:vtd_contexts_file
endfunction

" FUNCTION: s:SetContextBufOptions() {{{3
" Set the common options for the vtdview buffer
function! s:SetContextBufOptions()
  setlocal noswapfile
  setlocal bufhidden=delete
  setlocal nofoldenable
  setlocal autoread
  setlocal nobuflisted
  setlocal nospell
  setlocal nowrap
  silent! exec "edit" g:vtd_contexts_file

  setfiletype vtdcontext
endfunction


" End Utility Functions }}}2
" VTD contexts: Public functions {{{2
" FUNCTION: vtd#Contexts_Enter() {{{3
" Enter the VTD Contexts window, creating it if necessary.
function! vtd#Contexts_Enter()
  call s:CreateOrSwitchtoContextsWin()
endfunction

" End Public functions }}}2

" End VTD Contexts buffer }}}1

" VTD actions {{{1

" td - vtd#Done(): Context-dependent checkoff {{{2
function! vtd#Done()
  " First off: check whether we're in the vtdview buffer
  if s:InVTDViewWindow()
    let l:view_win = winnr()
    call vtd#JumpToLine()
  endif

  " Now we're in the base file.
  " Determine what kind of line it is; checkoff accordingly.
  let l:old_cursor = getpos(".")
  let l:line = getline(".")
  let l:type = 'None'
  let l:datetime = '\d{4}-\d{2}-\d{2}(\s+\d{2}:\d{2})?'
  if l:line =~# '\v^\s*\S\s+\@\s'
    " NextAction has an isolated '@' after a list-begin marker:
    let l:type = 'NextAction'
  elseif l:line =~# '\vREMIND\s*'.l:datetime
    " Reminder has the REMIND pattern, followed by a datetime:
    let l:type = 'Reminder'
  elseif l:line =~# '\v\s@<='.l:datetime && l:line !~# '\v\(DONE.*\)'
    " A whitespace-preceded date means this item recurs; "checking it off"
    " means setting the timestamp to now.
    let l:size = 10
    let l:timedate_fmt = '%F'
    " If this item has time as well as date, we'll need to update timestamp
    if l:line =~# '\v(\s+\d{2}:\d{2})'
      let l:size = 16
      let l:timedate_fmt = l:timedate_fmt.' %R'
    endif
    if l:line =~# 'RECUR'
      let l:type = 'Recurring'
    else
      let l:type = 'Inbox'
    endif
  " Any nonblank characters make this a "Project"
  elseif l:line =~# '\v\S'
    let l:type = 'Project'
  endif
  let l:done = (l:line =~# '\v\(DONE.*\)')

  if l:type ==? 'NextAction' || l:type ==? 'Project' || l:type ==? 'Reminder'
    if l:done
      let l:done_regex = '\v\s*\(DONE.*\)'
      let l:cmd = "normal! 0/".l:done_regex."\<CR>d%"
      call s:Preserve(l:cmd)
    else
      execute "normal! A (DONE \<C-R>=strftime('%F %R')\<CR>)\<esc>"
    endif
  elseif l:type ==? 'Recurring' || l:type ==? 'Inbox'
    let l:date_regex = '\v\d{4}-\d{2}-\d{2}'
    let l:cmd = "normal! 0/".l:date_regex."\<CR>c".l:size."l\<C-R>=strftime('"
    let l:cmd = l:cmd . l:timedate_fmt . "')\<CR>\<esc>"
    call s:Preserve(l:cmd)
  endif
  call setpos(".", l:old_cursor)

  " If we started out in vtdview window, go back there
  if exists("l:view_win")
    call s:JumpToWindowNumber(l:view_win)
  endif
endfunction

" End VTD actions }}}1

