" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-08-06
" URL: https://github.com/chiphogg/vim-vtd

" Utility functions {{{1

" Preserve cursor position, etc. {{{2
" Adapted from:
" https://gist.github.com/2973488/222649d4e7f547e16c96e1b9ba56a16c22afd8c7

function! PreserveStart()
  let b:PRESERVE_search = @/
  let b:PRESERVE_cursor = getpos(".")
  normal! H
  let b:PRESERVE_window = getpos(".")
  call setpos(".", b:PRESERVE_cursor)
endfunction

function! PreserveFinish()
  let @/ = b:PRESERVE_search
  call setpos(".", b:PRESERVE_window)
  normal! zt
  call setpos(".", b:PRESERVE_cursor)
endfunction

function! Preserve(command)
  call PreserveStart()
  execute a:command
  call PreserveFinish()
endfunction

" Loading the scriptfiles {{{2

" Taken from gundo.vim: this helps vim find the python script
let s:plugin_path = escape(expand('<sfile>:p:h'), '\')

" s:ReadPython(): Ensure the python script has been read {{{3
function! s:ReadPython()
  exe "pyfile" s:plugin_path."/parsers.py"
  python FillMyPlate()
endfunction

function! s:JumpToBaseWindow()
  if exists("g:vtd_base_window")
    let l:cmd = "wincmd w"
    if g:vtd_base_window != 1
      let l:cmd = g:vtd_base_window.l:cmd
    endif
    exe l:cmd
  endif
endfunction

" vtd#VTD_JumpToLine(): Goes to the line in the original file: {{{2
function! vtd#VTD_JumpToLine(...)
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

" s:GotoClearPreview(): Goto-and-clear preview window (create if needed) {{{2
function! s:GotoClearPreview()
  " First, source the python scriptfile containing all the parsers.
  call s:ReadPython()
  " We don't want to close/reopen the preview window if we're in it!  That
  " could be distracting if, e.g., the user adjusted the height.
  if &previewwindow == 0
    pclose  " Closing: easier than looping through every open window!
    execute g:vtd_view_height "wincmd n"
    setlocal previewwindow buftype=nofile filetype=vtdview winfixheight
          \ noswapfile
    " Following line taken from fugitive: 'q' should close preview window
    nnoremap <buffer> <silent> q    :<C-U>bdelete<CR>
    " Save the current window number
    let g:vtd_base_window = winnr()
  endif
  " In any case: clear the buffer, then rename it to "VTD View":
  normal! ggdG
  silent file VTD\ View
endfunction

" Append a string to the current buffer name
function! s:AppendToBufferName(string)
  silent execute "file" substitute(bufname("%").a:string, ' ', '\\ ', 'g')
endfunction

function! s:AppendToBufferNameBracketed(string)
  call s:AppendToBufferName(" (".a:string.")")
endfunction

" VTD views {{{1

" vtd#VTD_ReadAll(): Read/refresh the "list of everything that's on my plate" {{{2
function! vtd#VTD_ReadAll()
  call s:ReadPython()
endfunction

" th - vtd#VTD_Home(): Goto a "VTD Home" buffer for a system overview {{{2
function! vtd#VTD_Home()
  echom "Ain't no place like home!"
endfunction

" ti - vtd#VTD_Inboxes(): List all inboxes, and current status {{{2
function! vtd#VTD_Inboxes()
  call s:GotoClearPreview()
  call s:AppendToBufferNameBracketed("Inboxes")
  " Call python code which parses the Inboxes file for due (or overdue!)
  " inboxes, then fills a local variable with the resulting text.
  python <<EOF
vim.command("let l:inbox = '%s'" % my_plate.display_inboxes().replace("'", "''"))
EOF
  call append(0, split(l:inbox, "\n"))
  normal! gg
endfunction

" tn - vtd#VTD_NextActions(): List all Next Actions for current context {{{2
function! vtd#VTD_NextActions()
  call s:GotoClearPreview()
  call s:AppendToBufferNameBracketed("Next Actions")
  python parse_next_actions()
  call append(line('1'), split(l:actions, "\n"))
endfunction

" VTD actions {{{1

" td - vtd#VTD_Done(): Context-dependent checkoff {{{2

" VTD-view buffer {{{1
