" Maktaba boilerplate (which also prevents re-entry).
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter || !vtd#Compatible()
  finish
endif


""
" The .vtd files to load into the trusted system.  A list of strings, where each
" string is the fully qualified pathname for a .vtd file.
call s:plugin.Flag('files', [])

""
" Default contexts.  These contexts will be set by default when vim starts, and
" will be restored when the @command(VtdContextsDefault) command is called.
"
" If a context name begins with a '-', that context is excluded.  For example,
" setting contexts to ['-home'] will show all tasks except those in the 'home'
" context.  Specifying excluded contexts is often more useful in practice than
" specifying included contexts.
call s:plugin.Flag('contexts', [])
