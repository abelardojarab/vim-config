" asy ftplugin file
"
" Author: LeoMao
"

setl cindent
let &l:makeprg='asy -V -noprc -render=0 -f pdf -o %:r %:r' 
