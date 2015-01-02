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
" Open the VTD view buffer.
command -nargs=0 VtdView :call vtd#view#Enter()

""
" Add these {contexts} to the "included contexts" list: i.e., make actions
" from these {contexts} visible.
"
" Such an action can still be excluded if it has another context which is on
" the "excluded contexts" list.
command -nargs=+ VtdContextsInclude
    \ :call vtd#view#IncludeContexts([<f-args>])

""
" Add these {contexts} to the "excluded contexts" list: i.e., don't show any
" actions from these contexts.
" 
" Overrides the "included contexts" list.
command -nargs=+ VtdContextsExclude
    \ :call vtd#view#ExcludeContexts([<f-args>])

""
" Remove these {contexts} from both the "excluded contexts" and "included
" contexts" lists.  Clears all contexts if no argument is supplied.
command -nargs=* VtdContextsClear :call vtd#view#ClearContexts([<f-args>])


""
" Set the contexts to the defaults.
command -nargs=0 VtdContextsDefault :call vtd#view#DefaultContexts()
