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

" Maktaba boilerplate (which also prevents re-entry).
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter || !vtd#Compatible()
  finish
endif


""
" The .vtd files to load into the trusted system.  A list of strings, where each
" string is the fully qualified pathname for a .vtd file.
call s:plugin.Flag('files', [])

""
" Default contexts.  These contexts will be set by default when vim starts, and
" will be restored when the @command(VtdContextsDefault) command is called.
"
" If a context name begins with a '-', that context is excluded.  For example,
" setting contexts to ['-home'] will show all tasks except those in the 'home'
" context.  Specifying excluded contexts is often more useful in practice than
" specifying included contexts.
call s:plugin.Flag('contexts', [])
