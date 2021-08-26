" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_compe#VS#LSP#TextEdit#import() abort', printf("return map({'_vital_depends': '', 'apply': '', '_vital_loaded': ''}, \"vital#_compe#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
"
" _vital_loaded
"
function! s:_vital_loaded(V) abort
  let s:Text = a:V.import('VS.LSP.Text')
  let s:Position = a:V.import('VS.LSP.Position')
  let s:Buffer = a:V.import('VS.Vim.Buffer')
  let s:Option = a:V.import('VS.Vim.Option')
endfunction

"
" _vital_depends
"
function! s:_vital_depends() abort
  return ['VS.LSP.Text', 'VS.LSP.Position', 'VS.Vim.Buffer', 'VS.Vim.Option']
endfunction

"
" apply
"
function! s:apply(path, text_edits) abort
  let l:current_bufname = bufname('%')
  let l:current_position = s:Position.cursor()

  let l:target_bufnr = s:_switch(a:path)
  call s:_substitute(l:target_bufnr, a:text_edits, l:current_position)
  let l:current_bufnr = s:_switch(l:current_bufname)

  if l:current_bufnr == l:target_bufnr
    call cursor(s:Position.lsp_to_vim('%', l:current_position))
  endif
endfunction

"
" _substitute
"
function! s:_substitute(bufnr, text_edits, current_position) abort
  try
    " Save state.
    let l:Restore = s:Option.define({
    \   'foldenable': '0',
    \ })
    let l:view = winsaveview()

    " Apply substitute.
    let [l:fixeol, l:text_edits] = s:_normalize(a:bufnr, a:text_edits)
    for l:text_edit in l:text_edits
      let l:start = s:Position.lsp_to_vim(a:bufnr, l:text_edit.range.start)
      let l:end = s:Position.lsp_to_vim(a:bufnr, l:text_edit.range.end)
      let l:text = s:Text.normalize_eol(l:text_edit.newText)
      execute printf('noautocmd keeppatterns keepjumps silent %ssubstitute/\%%%sl\%%%sc\_.\{-}\%%%sl\%%%sc/\=l:text/%se',
      \   l:start[0],
      \   l:start[0],
      \   l:start[1],
      \   l:end[0],
      \   l:end[1],
      \   &gdefault ? 'g' : ''
      \ )
      call s:_fix_cursor_position(a:current_position, l:text_edit, s:Text.split_by_eol(l:text))
    endfor

    " Remove last empty line if fixeol enabled.
    if l:fixeol && getline('$') ==# ''
      noautocmd keeppatterns keepjumps silent $delete _
    endif
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  finally
    " Restore state.
    call l:Restore()
    call winrestview(l:view)
  endtry
endfunction

"
" _fix_cursor_position
"
function! s:_fix_cursor_position(position, text_edit, lines) abort
  let l:lines_len = len(a:lines)
  let l:range_len = (a:text_edit.range.end.line - a:text_edit.range.start.line) + 1

  if a:text_edit.range.end.line < a:position.line
    let a:position.line += l:lines_len - l:range_len
  elseif a:text_edit.range.end.line == a:position.line && a:text_edit.range.end.character <= a:position.character
    let a:position.line += l:lines_len - l:range_len
    let a:position.character = strchars(a:lines[-1]) + (a:position.character - a:text_edit.range.end.character)
    if l:lines_len == 1
      let a:position.character += a:text_edit.range.start.character
    endif
  endif
endfunction

"
" _normalize
"
function! s:_normalize(bufnr, text_edits) abort
  let l:text_edits = type(a:text_edits) == type([]) ? a:text_edits : [a:text_edits]
  let l:text_edits = s:_range(l:text_edits)
  let l:text_edits = sort(l:text_edits, function('s:_compare'))
  let l:text_edits = reverse(l:text_edits)
  return s:_fix_text_edits(a:bufnr, l:text_edits)
endfunction

"
" _range
"
function! s:_range(text_edits) abort
  let l:text_edits = []
  for l:text_edit in a:text_edits
    if type(l:text_edit) != type({})
      continue
    endif
    if l:text_edit.range.start.line > l:text_edit.range.end.line || (
    \   l:text_edit.range.start.line == l:text_edit.range.end.line &&
    \   l:text_edit.range.start.character > l:text_edit.range.end.character
    \ )
      let l:text_edit.range = { 'start': l:text_edit.range.end, 'end': l:text_edit.range.start }
    endif
    let l:text_edits += [l:text_edit]
  endfor
  return l:text_edits
endfunction

"
" _compare
"
function! s:_compare(text_edit1, text_edit2) abort
  let l:diff = a:text_edit1.range.start.line - a:text_edit2.range.start.line
  if l:diff == 0
    return a:text_edit1.range.start.character - a:text_edit2.range.start.character
  endif
  return l:diff
endfunction

"
" _fix_text_edits
"
function! s:_fix_text_edits(bufnr, text_edits) abort
  let l:max = s:Buffer.get_line_count(a:bufnr)

  let l:fixeol = v:false
  let l:text_edits = []
  for l:text_edit in a:text_edits
    if l:max <= l:text_edit.range.start.line
      let l:text_edit.range.start.line = l:max - 1
      let l:text_edit.range.start.character = strchars(get(getbufline(a:bufnr, '$'), 0, ''))
      let l:text_edit.newText = "\n" . l:text_edit.newText
      let l:fixeol = &fixendofline && !&binary
    endif
    if l:max <= l:text_edit.range.end.line
      let l:text_edit.range.end.line = l:max - 1
      let l:text_edit.range.end.character = strchars(get(getbufline(a:bufnr, '$'), 0, ''))
      let l:fixeol = &fixendofline && !&binary
    endif
    call add(l:text_edits, l:text_edit)
  endfor

  return [l:fixeol, l:text_edits]
endfunction

"
" _switch
"
function! s:_switch(path) abort
  let l:curr = bufnr('%')
  let l:next = bufnr(a:path)
  if l:next >= 0
    if l:curr != l:next
      execute printf('noautocmd keepalt keepjumps %sbuffer!', bufnr(a:path))
    endif
  else
    execute printf('noautocmd keepalt keepjumps edit! %s', fnameescape(a:path))
  endif
  return bufnr('%')
endfunction

