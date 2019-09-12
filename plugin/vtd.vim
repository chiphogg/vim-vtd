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

" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" URL: https://github.com/chiphogg/vim-vtd


" Maktaba boilerplate (which also prevents re-entry).
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter || !vtd#Compatible()
  finish
endif


" Add python libraries to sys.path so python knows how to import them.
let s:python_path = maktaba#path#Join([expand('<sfile>:p:h:h'), 'python'])
let s:libvtd_path = maktaba#path#Join([s:python_path, 'libvtd'])
execute 'pyxfile' maktaba#path#Join([s:python_path, 'sysutil.py']) 
execute 'pythonx AddToSysPath(r"' . s:libvtd_path . '")'
