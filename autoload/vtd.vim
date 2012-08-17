" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-08-06
" URL: https://github.com/chiphogg/vim-vtd

" Utility functions {{{1

" Working directory for the script {{{2
let s:autoload_dir = expand('<sfile>:p:h')

" Write, but only if a file is modified {{{2
" This function helps autocommands for when we leave a buffer.  We check if
" it's modified to avoid updating the timestamp for no reason, which would
" cause the vtdview to think it's out of date and re-scan the files.
function! vtd#WriteIfModified()
  if &modified == 1
    write
  endif
endfunction


" Preserve cursor position, etc. {{{2
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

" Loading the scriptfiles {{{2

" Taken from gundo.vim: this helps vim find the python script
let s:plugin_path = escape(expand('<sfile>:p:h'), '\')

" s:ReadPython(): Ensure the python script has been read {{{3
function! s:ReadPython()
  exe "pyfile" s:plugin_path."/parsers.py"
  python FillMyPlate()
endfunction

function! s:JumpToWindowNumber(n)
  let l:cmd = "wincmd w"
  if a:n != 1
    let l:cmd = a:n.l:cmd
  endif
  execute l:cmd
endfunction

function! s:JumpToBaseWindow()
  if exists("g:vtd_base_window")
    call s:JumpToWindowNumber(g:vtd_base_window)
  endif
endfunction

" vtd#JumpToLine(): Goes to the line in the original file: {{{2
function! vtd#JumpToLine(...)
  if a:0 >=# 1
    if !match(a:1, '\v[ipsc]\d+')
      echom "Error: jump string '".a:1."'does not have a valid format."
      return 1
    endif
    let l:jump_to = a:1
  else
    let l:jump_to = matchstr(getline("."), '\v\<\<[ipsc]\d+\>\>')
  endif
  let l:file_id = matchstr(l:jump_to, '[ipsc]')
  let l:line_no = matchstr(l:jump_to, '\v\d+')
  " Go back to the old window
  call s:JumpToBaseWindow()
  " Jump to the file and line
  python <<EOF
abbrev = vim.eval("l:file_id")
vim.command("let l:file = '%s'" % vtd_fullpath(abbrev).replace("'", "''"))
EOF
  execute "edit +".l:line_no l:file
  execute "normal! zv"
endfunction

" s:GotoClearVTDView(): Goto-and-clear preview window (create if needed) {{{2
function! s:GotoClearVTDView(bufname)
  " First, source the python scriptfile containing all the parsers.
  call s:ReadPython()
  " If we're not already in the vtdview window, we need to go there
  if &filetype !=? 'vtdview'
    " Save the current window number (to jump back to later)
    let g:vtd_base_window = winnr()
    if exists("g:vtd_view_bufnr") && bufexists(g:vtd_view_bufnr)
      call s:JumpToWindowNumber(bufwinnr(g:vtd_view_bufnr))
    else
      execute g:vtd_view_height "wincmd n"
      setlocal buftype=nofile filetype=vtdview winfixheight noswapfile
      call vtd#ViewRemember()
      " Following line taken from fugitive: 'q' should close vtdview window
      nnoremap <buffer> <silent> q    :<C-U>bdelete<CR>
    endif
  endif
  " In any case: save position; clear buffer; rename to "VTD View":
  let b:cursor = getpos(".")
  setlocal modifiable
  normal! ggdG
  silent execute "file" substitute("VTD View (".a:bufname.")", ' ', '\\ ', 'g')
  setlocal statusline=%F
  setlocal nomodifiable
endfunction

" s:FillVTDView(): Fill a VTD-view buffer with content {{{2
" Assumes we are already inside the VTD-view buffer
function! s:FillVTDView(linenum, content)
  setlocal modifiable
  call append(a:linenum, split(a:content, "\n"))
  setlocal nomodifiable
  if exists("b:cursor")
    call setpos(".", b:cursor )
  endif
endfunction

" vtd#ViewForget(): Clear variables referencing the vtd view window/buffer {{{2
function! vtd#ViewForget()
  unlet g:vtd_view_bufnr
endfunction

" vtd#ViewRemember(): Clear variables referencing the vtd view window/buffer {{{2
function! vtd#ViewRemember()
  let g:vtd_view_bufnr = bufnr("%")
endfunction

" VTD views {{{1

" vtd#ReadAll(): Read/refresh the "list of everything that's on my plate" {{{2
function! vtd#ReadAll()
  call s:ReadPython()
endfunction

" vtd#ContextsPermanent(): Edit the "permanent contexts" file {{{2
function! vtd#ContextsPermanent()
  call s:GotoClearVTDView("Permanent contexts")
  setlocal modifiable
  setlocal filetype=vtdcontext
  setlocal statusline+=%=[hit\ 'q'\ to\ finish]
  call s:ReadContextsPermanent()
endfunction

function! s:ReadContextsPermanent()
  let l:cfile = expand(g:vtd_contexts_file)
  " If the user lacks a context file, create one from a template that gives
  " instructions:
  if !filereadable(l:cfile)
    let l:template = readfile(s:autoload_dir."/context_template.vtdc", "b")
    call writefile(l:template, l:cfile, "b")
  endif
  execute "read" l:cfile
  " It pastes *after* line 1, so delete line 1
  execute "normal! ggdd"
endfunction

function! vtd#WriteContextsPermanent()
  let l:content = getline(1, '$')
  call writefile(l:content, expand(g:vtd_contexts_file), "b")
  bdelete
endfunction

" th - vtd#Home(): Goto a "VTD Home" buffer for a system overview {{{2
function! vtd#Home()
  echom "Ain't no place like home!"
endfunction

" ti - vtd#Inboxes(): List all inboxes, and current status {{{2
function! vtd#Inboxes()
  call s:GotoClearVTDView("Inboxes")
  " Call python code which parses the Inboxes file for due (or overdue!)
  " inboxes, then fills a local variable with the resulting text.
  python <<EOF
inbox_text = my_plate.display_inboxes().replace("'", "''")
vim.command("let l:inbox = '%s'" % inbox_text)
EOF
  call s:FillVTDView(0, l:inbox)
endfunction

" tn - vtd#NextActions(): List all Next Actions for current context {{{2
function! vtd#NextActions()
  call s:GotoClearVTDView("Next Actions")
  python <<EOF
action_text = my_plate.display_NextActions().replace("'", "''")
vim.command("let l:actions = '%s'" % action_text)
EOF
  call append(line('1'), split(l:actions, "\n"))
endfunction

" VTD actions {{{1

" td - vtd#Done(): Context-dependent checkoff {{{2
function! vtd#Done()
  " First off: check whether we're in the vtdview buffer
  if &filetype == "vtdview"
    let l:view_win = winnr()
    call vtd#JumpToLine()
  endif

  " Now we're in the base file.
  " Determine what kind of line it is; checkoff accordingly.
  let l:line = getline(".")
  let l:type = 'None'
  " NextAction has an isolated '@' after a list-begin marker:
  if l:line =~# '\v^\s*\S\s+\@\s'
    let l:type = 'NextAction'
  " Anything else: if it has a date, it's recurring
  elseif l:line =~# '\v\d{4}-\d{2}-\d{2}(\s+\d{2}:\d{2})?'
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

  if l:type ==? 'NextAction' || l:type ==? 'Project'
    execute "normal! A(DONE \<C-R>=strftime('%F %R')\<CR>)\<esc>"
  elseif l:type ==? 'Recurring' || l:type ==? 'Inbox'
    let l:date_regex = '\v\d{4}-\d{2}-\d{2}'
    let l:cmd = "normal! 0/".l:date_regex."\<CR>c".l:size."l\<C-R>=strftime('"
    let l:cmd = l:cmd . l:timedate_fmt . "')\<CR>\<esc>"
    call s:Preserve(l:cmd)
  endif

  " If we started out in vtdview window, go back there
  if exists("l:view_win")
    call s:JumpToWindowNumber(l:view_win)
  endif
endfunction

" VTD-view buffer {{{1
