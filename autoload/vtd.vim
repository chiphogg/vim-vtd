let s:plugin = maktaba#plugin#Get('vtd')

let s:plugin_root = expand('<sfile>:p:h:h')

let s:python_path = maktaba#path#Join([s:plugin_root, 'python'])


""
" Ensure that the VTD python utility scripts have been loaded.
function! vtd#EnsurePythonLoaded()
  if !exists('s:loaded_python_scripts')
    execute 'pyfile' s:python_path . '/vtd.py'
    let s:loaded_python_scripts = 1
  endif
endfunction


""
" The list of filenames which back the trusted system.
function! vtd#Files()
  let l:files = copy(maktaba#ensure#IsList(s:plugin.Flag('files')))
  call map(l:files, 'expand(v:val)')
  return l:files
endfunction


""
" Reread the vtd files and update the trusted system.
function! vtd#UpdateSystem()
  call vtd#EnsurePythonLoaded()
  execute 'python UpdateTrustedSystem(files=' . string(vtd#Files()) .')'
endfunction


" Here's a list of reasons we might not want to load this script:
"   1) "compatible" mode (a.k.a. "crippled" mode) is set
"   2) Vim too old (autoload was introduced in Vim 7)
"   3) No python support
function! vtd#Compatible()
  let l:incompatible = &cp || v:version < 700 || !has('python')
  return !l:incompatible
endfunction
