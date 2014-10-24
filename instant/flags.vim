" Maktaba boilerplate (which also prevents re-entry).
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter || !vtd#Compatible()
  finish
endif

""
" VTD files to use. E.g., ['~/todo.vtd', '~/personal.vtd'].
call s:plugin.Flag('files', [])
""

""
" Contexts to display.
call s:plugin.Flag('contexts', [])
