" Test custom configuration
let g:test_tkeymap = 0
let g:test_keymap = 0

function! MySetTKeymaps()
  lua NvimGdb.i().keymaps:set_t()
  tnoremap <buffer> <silent> ~tkm <c-\><c-n>:let g:test_tkeymap = 1<cr>i
endfunction

function! MySetKeymaps()
  lua NvimGdb.i().keymaps:set()
  " One custom programmable keymap needed in some tests
  nnoremap <buffer> <silent> ~tn :let g:test_keymap = 1<cr>
endfunction

function! MyUnsetKeymaps()
  lua NvimGdb.i().keymaps:unset()
  " Unset the custom programmable keymap
  nunmap <buffer> ~tn
endfunction

let g:nvimgdb_config_override = {
  \ 'set_tkeymaps': 'MySetTKeymaps',
  \ 'set_keymaps': 'MySetKeymaps',
  \ 'unset_keymaps': 'MyUnsetKeymaps',
  \ }
