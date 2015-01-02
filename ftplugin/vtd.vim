" Copyright 2015 Charles R. Hogg III. All rights reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.

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
