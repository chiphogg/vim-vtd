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

