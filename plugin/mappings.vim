" Maktaba boilerplate (which also prevents re-entry).
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter || !vtd#Compatible()
  finish
endif


let s:prefix = s:plugin.MapPrefix('t')
execute 'nnoremap <unique> <silent>' s:prefix ':VtdView<CR>'
