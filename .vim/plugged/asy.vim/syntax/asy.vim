" Vim syntax file
" Language: Asymptote
" Last Change: 2012-03-07
" Author: Leo Mao

if exists("b:current_syntax")
  finish
endif
" A bunch of useful C keywords
syn keyword	asyTodo		contained TODO FIXME XXX

" asyCommentGroup allows adding matches for special things in comments
syn cluster	asyCommentGroup	contains=asyTodo

syn case ignore
syn match	asyNumbers	display transparent "\<\d\|\.\d" contains=asyNumber,asyFloat,asyOctal
" Same, but without octal error (for comments)
syn match	asyNumbersCom	display contained transparent "\<\d\|\.\d" contains=asyNumber,asyFloat,asyOctal
syn match	asyNumber		display contained "\d\+\(u\=l\{0,2}\|ll\=u\)\>"
"hex number
syn match	asyNumber		display contained "0x\x\+\(u\=l\{0,2}\|ll\=u\)\>"
" Flag the first zero of an octal number as something special
syn match	asyOctal		display contained "0\o\+\(u\=l\{0,2}\|ll\=u\)\>" contains=asyOctalZero
syn match	asyOctalZero	display contained "\<0"
syn match	asyFloat		display contained "\d\+f"
"floating point number, with dot, optional exponent
syn match	asyFloat		display contained "\d\+\.\d*\(e[-+]\=\d\+\)\=[fl]\="
"floating point number, starting with a dot, optional exponent
syn case match

syn keyword     asyStatement	  break return continue unravel
syn keyword     asyConditional	if else
syn keyword     asyRepeat	      while for do
syn keyword     asyStatement    draw write dot size drawline label
syn keyword     asyExternal     access from import include
syn keyword     asyOperator     new operator

syn keyword	    asyType         void bool int real string
syn keyword	    asyType         pair triple transform guide path pen frame
syn keyword     asyType         picture
syn keyword     asyType	        Label align marker margin circle line point

syn keyword	    asyStructure    struct typedef
syn keyword     asyStorageClass static public readable private explicit

syn keyword     asyPathSpec     and cycle controls tension atleast curl

syn keyword     asyConstant     true false
syn keyword     asyConstant     null nullframe nullpath
syn keyword     asyConstant     this

syn keyword asyFunction	    intersects intersect extension abs dir rotate intersectionpoint intersectionpoints
syn region asyString   start=+L\="+ skip=+\\\\\|\\"+ end=+"+
syn region asyImport   start="import\|include" end="$"
syn match asyOperator  display '[{}()\[\]]\|[-&|+<>=*/^%!?~;,.]'
syn region asyCommentL start="//" skip="\\$" end="$" contains=@asyCommentGroup
syn region asyComment  start="/\*" end="\*/" contains=@asyCommentGroup

hi def link asyConstant	    Constant
hi def link asyString	      String
hi def link asyFloat	      asyNumber
hi def link asyImport	      Include
hi def link asyExternel     Include
hi def link asyType	        Type
hi def link asyConditional	asyStatement
hi def link asyRepeat	      asyStatement
hi def link asyStatement    Statement
hi def link asyFunction	    Function
hi def link asyNumber	      Number
hi def link asyCommentL	    asyComment
hi def link asyComment	    Comment
hi def link asyOperator	    Operator

let b:current_syntax = "asy"
