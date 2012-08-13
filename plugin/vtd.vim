" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-08-08
" URL: https://github.com/chiphogg/vim-vtd

" Load guard {{{1

" Here's a list of reasons we might not want to load this script:
"   1) We already did
"   2) "compatible" mode (a.k.a. "crippled" mode) is set
"   3) Vim too old (autoload was introduced in Vim 7)
"   4) No python support
if exists("g:loaded_vtd") || &cp || v:version < 700 || !has('python')
  finish
endif
let g:loaded_vtd = 1

" Settings variables {{{1

" Wrapper function to set options, but only if the user didn't already.
" Results in something like the following:
" let g:vtd_<name> = <value>
function! s:SetIfNew(name, value)
  let l:full_name = "g:vtd_".a:name
  if !exists(l:full_name)
    execute "let" l:full_name "= '".a:value."'"
  endif
endfunction

" 'View window' settings {{{2
call s:SetIfNew("view_height", 10)

" Filenames {{{2

" Path names
" g:vtd_wiki_path -- Path to the wiki (relative to ~)
call s:SetIfNew("wiki_path", "~/productivity/viki")

" Individual filenames
" g:vtd_file_inboxes -- filename which tracks our Inboxes
call s:SetIfNew("file_inboxes", "Inboxes.wiki")
" g:vtd_file_projects -- Project info and support material
call s:SetIfNew("file_projects", "Projects.wiki")
" g:vtd_file_somedaymaybe -- Stuff to do someday... maybe.
call s:SetIfNew("file_somedaymaybe", "SomedayMaybe.wiki")
" g:vtd_file_checklists -- Checklist templates
call s:SetIfNew("file_checklists", "Checklists.wiki")

" Section header settings {{{2

" Regex identifying Inboxes section
call s:SetIfNew("section_inbox", '^= Inboxes =\s*$')
" Regex identifying Thoughts section
call s:SetIfNew("section_thoughts", '^= Thoughts =\s*$')

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

" VTD "Views" (Next Actions, Waiting, etc.) {{{2
" VTD (h)ome: "command central" for VTD {{{3
" This will provide an overview for your system: How many Next Actions, what
" are you Waiting for, which Inboxes need to be emptied, what are your Big
" Rocks for the day, etc.
call s:VTD_map('Home', ':call vtd#VTD_Home()<CR>', 'h')

" VTD (i)nboxes {{{3
call s:VTD_map('Inboxes', ':call vtd#VTD_Inboxes()<CR>', 'i')

" VTD (n)ext actions {{{3
call s:VTD_map('NextActions', ':call vtd#VTD_NextActions()<CR>', 'n')

" VTD "Actions" (Done, Send, etc.) {{{2

" VTD (d)one: "smart" (context-dependent) checkoff {{{3
" Q) What does it mean to "check off" an item?  
" A) It depends entirely on the *nature* of that item.
" For a "regular item", we mark it as done.
" For a RECUR item or INBOX, we simply adjust the timestamp.
call s:VTD_map('Done', ':call vtd#VTD_Done()<CR>', 'd')

