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

" @section Mappings


""
" Quit the VTD view window.
nnoremap <silent> <buffer> Q :call vtd#view#Exit()<CR>
nmap <silent> <buffer> q Q



" @section Autocmds


augroup vtd_view
  autocmd!
  autocmd FocusLost,BufLeave,FocusGained,BufEnter,CursorHold
      \ <buffer> call vtd#view#Enter()
augroup END
