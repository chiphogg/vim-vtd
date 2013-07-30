" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" URL: https://github.com/chiphogg/vim-vtd

" Here's a list of reasons we might not want to load this script:
"   1) We already did
"   2) "compatible" mode (a.k.a. "crippled" mode) is set
"   3) Vim too old (autoload was introduced in Vim 7)
"   4) No python support
if exists("g:loaded_vtd") || &cp || v:version < 700 || !has('python')
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
endif

if s:flags.DoesMappings()
  let s:prefix = s:flags.MapPrefix('t')
  execute 'nnoremap <unique> <silent>' s:prefix ':VtdView<CR>'
endif
