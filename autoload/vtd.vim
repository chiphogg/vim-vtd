" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-08-06
" URL: https://github.com/chiphogg/vim-vtd

" Utility functions {{{1

" Taken from gundo.vim: this helps vim find the python script
let s:plugin_path = escape(expand('<sfile>:p:h'), '\')

" s:GotoClearPreview(): Goto-and-clear preview window (create if needed) {{{2
function! s:GotoClearPreview()
  " First, source the python scriptfile containing all the parsers.
  exe "pyfile" s:plugin_path."/parsers.py"
  " We don't want to close/reopen the preview window if we're in it!  That
  " could be distracting if, e.g., the user adjusted the height.
  if &previewwindow == 0
    pclose  " Closing: easier than looping through every open window!
    execute g:vtd_view_height "wincmd n"
    set previewwindow buftype=nofile filetype=vtdview winfixheight
    " Following line taken from fugitive: 'q' should close preview window
    nnoremap <buffer> <silent> q    :<C-U>bdelete<CR>
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

" th - vtd#VTD_Home(): Goto a "VTD Home" buffer for a system overview {{{2
function! vtd#VTD_Home()
  echom "Ain't no place like home!"
endfunction

" ti - vtd#VTD_Inboxes(): List all inboxes, and current status {{{2
function! vtd#VTD_Inboxes()
  call s:GotoClearPreview()
  call s:AppendToBufferNameBracketed("Inboxes")
  let l:inbox_content = vtd#VTD_Inbox_content()
  call append(line('$'), split(l:inbox_content, "\n"))
endfunction

function! vtd#VTD_Inbox_content()
  " Call python code which parses the Inboxes file for due (or overdue!)
  " inboxes, then fills a local variable with the resulting text.
  python parse_inboxes()
  return l:inbox_content
endfunction

" VTD actions {{{1

" td - vtd#VTD_Done(): Context-dependent checkoff {{{2

" tT - vtd#VTDTEST_KeywordCollector(): {{{2
function!vtd#VTDTEST_KeywordCollector(keyword)
  python "CheckLine(".a:keyword.")"
  echom l:linecheck_result
endfunction
