" Standard ftplugin boilerplate; see ':help ftplugin'.
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setlocal foldmethod=syntax
setlocal textwidth=0

" A vtd file should be as insensitive as possible to having multiple instances
" open.  That means never keeping swapfiles, automatically reading updated
" versions without prompting, and frequent automatic writes.
setlocal autoread
setlocal noswapfile
augroup vtd_file
  autocmd!
  autocmd FocusLost,BufLeave,CursorHold <buffer> if &modified | write! | endif
augroup END
