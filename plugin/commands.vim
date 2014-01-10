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
