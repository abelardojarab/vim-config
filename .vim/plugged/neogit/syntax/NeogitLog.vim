if exists("b:current_syntax")
  finish
endif

syn match Comment /^[a-z0-9]\{7}\ze/

let b:current_syntax = 1
