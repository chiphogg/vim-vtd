" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" URL: https://github.com/chiphogg/vim-vtd

" Make sure we should load this plugin.
if exists("g:loaded_vtd") || !vtd#Compatible()
  finish
endif
let g:loaded_vtd = 1

" Waiting for a better vim library...
function! s:DoesMappings() dict abort
  return 1
endfunction
function! s:DoesCommands() dict abort
  return 1
endfunction
function! s:MapPrefix(letter) dict abort
  return '<Leader>' . a:letter
endfunction
let s:flags = {
    \ 'DoesCommands': function('s:DoesCommands'),
    \ 'DoesMappings': function('s:DoesMappings'),
    \ 'MapPrefix' : function('s:MapPrefix'),
    \ '_name': 'vim-vtd'}

if s:flags.DoesCommands()
  ""
  " Open the VTD view buffer.
  command! -nargs=0 VtdView :call vtd#view#Enter()

  ""
  " Add these {contexts} to the "included contexts" list: i.e., make actions
  " from these {contexts} visible.
  "
  " Such an action can still be excluded if it has another context which is on
  " the "excluded contexts" list.
  command! -nargs=+ VtdContextsInclude
      \ :call vtd#view#IncludeContexts([<f-args>])

  ""
  " Add these {contexts} to the "excluded contexts" list: i.e., don't show any
  " actions from these contexts.
  " 
  " Overrides the "included contexts" list.
  command! -nargs=+ VtdContextsExclude
      \ :call vtd#view#ExcludeContexts([<f-args>])

  ""
  " Remove these {contexts} from both the "excluded contexts" and "included
  " contexts" lists.
  command! -nargs=+ VtdContextsClear :call vtd#view#ClearContexts([<f-args>])
endif

if s:flags.DoesMappings()
  let s:prefix = s:flags.MapPrefix('t')
  execute 'nnoremap <unique> <silent>' s:prefix ':VtdView<CR>'
endif


" Add python libraries to sys.path so python knows how to import them.
let s:python_path = expand('<sfile>:p:h:h') . '/python'
let s:libvtd_path = s:python_path . '/libvtd'
execute 'pyfile' join([s:python_path, 'sysutil.py'], '/') 
execute 'python AddToSysPath("' . s:libvtd_path . '")'
