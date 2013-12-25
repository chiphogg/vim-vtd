let s:plugin_root = expand('<sfile>:p:h:h')

let s:python_path = maktaba#path#Join([s:plugin_root, 'python'])


function! vtd#EnsurePythonLoaded()
  if !exists('s:loaded_python_scripts')
    execute 'pyfile' s:python_path . '/vtd.py'
    let s:loaded_python_scripts = 1
  endif
endfunction


function! vtd#UpdateSystem()
  call vtd#EnsurePythonLoaded()
  execute 'python UpdateTrustedSystem(file_name="' . g:vtd_file .'")'
endfunction


" Here's a list of reasons we might not want to load this script:
"   1) "compatible" mode (a.k.a. "crippled" mode) is set
"   2) Vim too old (autoload was introduced in Vim 7)
"   3) No python support
function! vtd#Compatible()
  let l:incompatible = &cp || v:version < 700 || !has('python')
  return !l:incompatible
endfunction
