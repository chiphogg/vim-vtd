" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-08-08
" URL: https://github.com/chiphogg/vim-vtd

" Load guard {{{1

" Here's a list of reasons we might not want to load this script:
"   1) We already did
"   2) "compatible" mode (a.k.a. "crippled" mode) is set
"   3) Vim too old (autoload starts in Vim 7)
"   4) No python support
if exists("g:loaded_vtd") || &cp || v:version < 700 || !has('python')
  finish
endif
let g:loaded_vtd = 1

" Key mappings {{{1

" All VTD mappings start with a common prefix.  It defaults to
" '<LocalLeader>t', which is usually ',t' or '\t'.
" The user can set this manually by placing a line such as
"   let g:vtd_map_prefix = '\foo'
" in their '.vimrc' file.
if !exists('g:vtd_map_prefix')
  let g:vtd_map_prefix = '<LocalLeader>t'
endif

" A word about key mappings... {{{2
" I want to give the user as much power as possible for setting keymappings.
" Thus, I provide two main options:
"
"   1) HIGH-LEVEL CONTROL:
"      Set the prefix ('g:vtd_map_prefix') to whatever is desired
"      The rest of each mapping is still the same
"
"   2) FINE-GRAINED CONTROL:
"      Set mapping for individual commands
"
" To handle (1), the user simply sets 'g:vtd_map_prefix' in their .vimrc file.
"
" To handle (2), we use the <Plug> approach:
"   - Keystrokes get mapped to <Plug>VTD_Action
"   - <Plug>VTD_Action gets unequivocally mapped to an actual function call
" The value of this approach is *abstraction*: we can change the way we
" actually perform VTD_Action (different parameters, different function, etc.)
" and the mappings will all Just Work.
"
" I believe these approaches will "play nice" with each other, i.e., you can
" change them all by choosing the prefix, then remap individual ones to suit
" your taste.

" HELPER FUNCTION VTD_map(): setup a map in a courteous way {{{2
" a:action  -- a meaningful name for the action to perform
" a:code    -- the code (function call, etc.) which performs the action
" a:key     -- The shortcut key
function! s:VTD_map(action, code, key)
  let l:action_deco = '<Plug>VTD_'.a:action 
  execute 'nnoremap' l:action_deco a:code
  if !hasmapto(l:action_deco, 'n')
    execute "nmap" g:vtd_map_prefix.a:key l:action_deco
  endif
endfunction

" VTD (h)ome: "command central" for VTD {{{2
" This will provide an overview for your system: How many Next Actions, what
" are you Waiting for, which Inboxes need to be emptied, what are your Big
" Rocks for the day, etc.
call s:VTD_map('Home', ':call vtd#VTD_Home()<CR>', 'h')
