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
execute 'pyfile' maktaba#path#Join([s:python_path, 'sysutil.py']) 
execute 'python AddToSysPath("' . s:libvtd_path . '")'
