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

syntax region VtdSection start="\v^\z(\=+) .*\=$" end="\v(^\=\z1@!)@="
    \ fold
    \ contains=ALL
    \ keepend

syntax region doneItem start='^\z(\s*\)\S.*(DONE.*)' skip='^\z1\s' end='^'me=e-1
    \ contains=@NoSpell
highlight link doneItem Ignore
syntax region wontdo start='^\z(\s*\)\S.*(WONTDO.*)' skip='^\z1\s' end='^'me=e-1
    \ contains=@NoSpell
highlight link wontdo doneItem

syntax region recur start='^\z(\s*\)\S.*\<EVERY\>' skip='^\z1\s' end='^'me=e-1
    \ contains=lastDone,vtdComment
highlight link recur SpecialKey
syntax match lastDone '\v\(LASTDONE \d{4}-\d{2}-\d{2} \d{1,2}:\d{2}\)' contained
highlight link lastDone doneItem

syntax region vtdComment start='^\z(\s*\)\* ' skip='^\v(\z1\s|$)' end='^'me=e-1
highlight link vtdComment Comment
