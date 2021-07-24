" --- Start with Windows
source ~/.vim/autoload/win.vim
behave mswin
source ~/.vim/autoload/plug.vim

" --- general settings ---
set nocompatible   " Disable vi-compatibility
set guifont=menlo\ for\ powerline:h16
set guioptions-=T " Removes top toolbar
set guioptions-=r " Removes right hand scroll bar
set go-=L " Removes left hand scroll bar
set linespace=15
set t_Co=256

" --- editor settings ---
set showmode                    " always show what mode we're currently editing in
set nowrap                      " don't wrap lines
set tabstop=4                   " a tab is four spaces
set smarttab
set softtabstop=4               " when hitting <BS>, pretend like a tab is removed, even if spaces
set expandtab                   " expand tabs by default (overloadable per file type later)
set shiftwidth=4                " number of spaces to use for autoindenting
set shiftround                  " use multiple of shiftwidth when indenting with '<' and '>'
set backspace=indent,eol,start  " allow backspacing over everything in insert mode
set autoindent                  " always set autoindenting on
set copyindent                  " copy the previous indentation on autoindenting
set number                      " always show line numbers
set ignorecase                  " ignore case when searching
set smartcase                   " ignore case if search pattern is all lowercase,
set mouse=a                     "enable mouse automatically entering visual mode
set ttymouse=xterm2
filetype indent on
filetype plugin on

" --- spell checking ---
set spelllang=en_us         " spell checking
set encoding=utf-8 nobomb   " BOM often causes trouble, UTF-8 is awsum.

" --- performance / buffer ---
set hidden                  " can put buffer to the background without writing
                            "   to disk, will remember history/marks.
set lazyredraw              " don't update the display while executing macros
set ttyfast                 " Send more characters at a given time.

" --- history / file handling ---
set history=10000             " Increase history (default = 20)
set undolevels=999          " Moar undo (default=100)
set autoread                " reload files if changed externally

" --- Leader key to add extra key combinations ---
let mapleader = ','
let g:mapleader = ','

" --- Time delay on <Leader> key ---
set timeoutlen=3000 ttimeoutlen=100

" --- Update time ---
set updatetime=250

" --- Trigger InsertLeave autocmd ---
inoremap <C-c> <Esc>

" --- No need for Ex mode ---
nnoremap Q <NOP>

" --- Open help in a vertical window ---
cnoreabbrev help vert help

" --- backup and swap files ---
" I save all the time, those are annoying and unnecessary...
set nobackup
set nowritebackup
set noswapfile

" --- search / regexp ---
set gdefault                " RegExp global by default
set magic                   " Enable extended regexes.
set hlsearch                " highlight searches
set incsearch               " show the `best match so far' astyped
set ignorecase smartcase    " make searches case-insensitive, unless they
                            "   contain upper-case letters

" --- UI settings ---
if has('gui_running')
    "set guifont=Menlo:h13
    set gfn:Monaco:h14

    " toolbar and scrollbars
    set guioptions-=T       " remove toolbar
    set guioptions-=L       " left scroll bar
    set guioptions-=r       " right scroll bar
    set guioptions-=b       " bottom scroll bar
    set guioptions-=h      " only calculate bottom scroll size of current line
    set shortmess=atI       " Don't show the intro message at start and
                            "   truncate msgs (avoid press ENTER msgs).
endif

syntax enable
set cursorline
hi CursorLine term=bold cterm=bold guibg=Grey40

set report=0                " Show all changes.
set showcmd                 " show partial command on last line of screen.
set showmatch               " show matching parenthesis
set splitbelow splitright   " how to split new windows.
set title                   " Show the filename in the window title bar.
set scrolloff=5             " Start scrolling n lines before horizontal
                            "   border of window.
set sidescrolloff=7         " Start scrolling n chars before end of screen.
set sidescroll=1            " The minimal number of columns to scroll
                            "   horizontally.

" add useful stuff to title bar (file name, flags, cwd)
" based on @factorylabs
if has('title') && (has('gui_running') || &title)
    set titlestring=
    set titlestring+=%f
    set titlestring+=%h%m%r%w
    set titlestring+=\ -\ %{v:progname}
    set titlestring+=\ -\ %{substitute(getcwd(),\ $HOME,\ '~',\ '')}
endif

" --- command completion ---
set wildmenu                " Hitting TAB in command mode will
set wildchar=<TAB>          "   show possible completions.
set wildmode=list:longest
set wildignore+=*.DS_STORE,*.db,node_modules/**,*.jpg,*.png,*.gif

" --- diff ---
set diffopt=filler          " Add vertical spaces to keep right
                            "   and left aligned.
set diffopt+=iwhite         " Ignore whitespace changes.

" --- folding---
set foldmethod=manual       " manual fold
set foldnestmax=3           " deepest fold is 3 levels
set nofoldenable            " don't fold by default

" --- keys ---
set backspace=indent,eol,start  " allow backspacing over everything.
set esckeys                     " Allow cursor keys in insert mode.
set nostartofline               " Make j/k respect the columns

" Allow us to use Ctrl-s and Ctrl-q as keybinds
" Restore default behaviour when leaving Vim.
silent !stty -ixon
autocmd VimLeave * silent !stty ixon

" Use leader l to rapidly toggle `set list`
nmap <leader>l :set list!<CR>

" Use a bar-shaped cursor for insert mode, even through tmux.
if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Ensures that vim moves up/down linewise instead of by wrapped lines
nnoremap j gj
nnoremap k gk

" Easy escaping to normal model
imap jj <esc>

" Allow saving a sudo file if forgot to open as sudo
cmap w!! w !sudo tee % >/dev/null

" turns on nice popup menu for omni completion
:highlight Pmenu ctermbg=238 gui=bold

" --- key fixes ---
map  <Esc>[1;5A <C-Up>
map  <Esc>[1;5B <C-Down>
map  <Esc>[1;5D <C-Left>
map  <Esc>[1;5C <C-Right>
cmap <Esc>[1;5A <C-Up>
cmap <Esc>[1;5B <C-Down>
cmap <Esc>[1;5D <C-Left>
cmap <Esc>[1;5C <C-Right>

map  <Esc>[1;2D <S-Left>
map  <Esc>[1;2C <S-Right>
cmap <Esc>[1;2D <S-Left>
cmap <Esc>[1;2C <S-Right>

" ---  Clipboard  ---

" Allow Shift+Insert to paste
map <S-Insert> <MiddleMouse>
map! <S-Insert> <MiddleMouse>
set clipboard=unnamed,unnamedplus  "Use system clipboard by default
" set clipboard=unnamedplus

" Copy filename
:nmap yY :let @" = expand("%")<CR>

" Copy file path
:nmap yZ :let @" = expand("%:p")<CR>

" F2 = Paste Toggle (in insert mode, pasting indented text behavior changes)
set pastetoggle=<F2>

" Toggle paste mode
nmap <leader>o :set paste!<CR>

" --- Whitespace ---

" Remove trailing whitespace
nnoremap <leader>w :%s/\s\+$//<cr>:let @/=''<CR>

" Toggle whitespace visibility with ,s
nmap <Leader>s :set list!<CR>
set listchars=tab:>\ ,trail:·,extends:»,precedes:«,nbsp:×

" --- Leader based key bindings ---

" Auto change directory to match current file ,cd
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>
autocmd BufEnter * silent! lcd %:p:h

" Edit and Reload .vimrc files
nmap <silent> <Leader>ev :e $MYVIMRC<CR>
nmap <silent> <Leader>es :so $MYVIMRC<CR>

" --- Plugins ---
call plug#begin('~/.vim/plugged')
" Other plugins here.

" Sessions
" Plug 'conweller/findr.vim' " requires Lua
" Plug 'xolox/vim-session'
" Plug 'xolox/vim-misc'

" Status bar
Plug 'bling/vim-airline'  " Vim status bar
Plug 'vim-airline/vim-airline-themes'
Plug 'ton/vim-bufsurf'

" Git tools
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive' " Git integration
Plug 'junegunn/gv.vim'

" Perforce
Plug 'nfvs/vim-perforce'
Plug 'ngemily/vim-vp4'

" Tools
Plug 'ctrlpvim/ctrlp.vim'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'Nopik/vim-nerdtree-direnter'  " Fix issue with nerdtree
Plug 'jistr/vim-nerdtree-tabs'
Plug 'scrooloose/nerdcommenter'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
" Plug 'fholgado/minibufexpl.vim'  " Buffer explorer
Plug 'yegappan/mru' " MRU
Plug 'tmhedberg/SimpylFold'
Plug 'liuchengxu/vim-which-key'

" Copy paste
Plug 'svermeulen/vim-cutlass'
Plug 'svermeulen/vim-yoink'
Plug 'svermeulen/vim-subversive'

" Snippets
Plug 'Shougo/neosnippet.vim',
Plug 'Shougo/neosnippet-snippets'

" Search
Plug 'jremmen/vim-ripgrep'
Plug 'mileszs/ack.vim'

" Completion
Plug 'neoclide/coc.nvim', {'for':['zig','cmake','rust',
     \'java','json', 'haskell', 'ts','sh', 'cs',
     \'yaml', 'c', 'cpp', 'd', 'go',
     \'python', 'dart', 'javascript', 'vim'], 'branch': 'release'}

Plug 'Shougo/deoplete.nvim',
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'lighttiger2505/deoplete-vim-lsp'
Plug 'liuchengxu/vista.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'

" Syntax checker
Plug 'scrooloose/syntastic'  " Adds syntax checking
Plug 'tinyheero/vim-snippets'  " Fork of honza/vim-snippets
Plug 'dense-analysis/ale'

" Tabline
Plug 'ap/vim-buftabline'  " Vim tabs
Plug 'mengelbrecht/lightline-bufferline'
Plug 'itchyny/lightline.vim'
Plug 'mihaifm/bufstop'

" Python
Plug 'deoplete-plugins/deoplete-jedi',
Plug 'vim-scripts/indentpython.vim'
Plug 'Vimjas/vim-python-pep8-indent'

" C/C++
Plug 'rhysd/vim-clang-format' " Clang-format

" Go
Plug 'fatih/vim-go',
Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }
Plug 'deoplete-plugins/deoplete-go'

" Perl
Plug 'c9s/perlomni.vim'

" JavaScript
Plug 'ternjs/tern_for_vim', { 'do': 'npm install' }
Plug 'carlitux/deoplete-ternjs', { 'do': 'npm install -g tern' }
Plug 'othree/jspc.vim'
Plug 'maksimr/vim-jsbeautify'

" Rust
Plug 'racer-rust/vim-racer'

" Markdown
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'

" Additional syntax files
Plug 'othree/html5.vim'
Plug 'vim-language-dept/css-syntax.vim'
Plug 'hail2u/vim-css3-syntax'
Plug 'pangloss/vim-javascript'
Plug 'aklt/plantuml-syntax'
Plug 'gerardbm/asy.vim'
Plug 'gerardbm/eukleides.vim'

" tmux
Plug 'christoomey/vim-tmux-navigator'

" Net
Plug 'mattn/webapi-vim'
Plug 'diepm/vim-rest-console'

" Edition
Plug 'tpope/vim-surround'  " Quoting and parenthesizing made simple
Plug 'tomtom/tcomment_vim'  " Extensible & universal comment
Plug 'Shougo/context_filetype.vim'
Plug 'mbbill/undotree'
Plug 'junegunn/vim-easy-align'
Plug 'jiangmiao/auto-pairs'
Plug 'alvan/vim-closetag'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-capslock'
Plug 'wellle/targets.vim'
Plug 'christoomey/vim-sort-motion'
Plug 'terryma/vim-expand-region'
Plug 'FooSoft/vim-argwrap'
Plug 'gerardbm/vim-md-headings'
Plug 'matze/vim-move'

" Color schemes
Plug 'gerardbm/vim-atomic'
Plug 'rakr/vim-one'
Plug 'sickill/vim-monokai'

call plug#end()

" --- Colors ---
colorscheme monokai
set background=dark

" --- netrw settings ---
nmap <leader>f :Explore<CR>
nmap <leader><s-f> :edit.<CR>

let g:netrw_altv = 1
let g:netrw_dirhistmax = 0

" --- LSP support ---
imap <c-space> <Plug>(asyncomplete_force_refresh)
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>\<cr>" : "\<cr>"
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

if executable('pyls')
    " pip install python-language-server
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': {server_info->['pyls']},
        \ 'allowlist': ['python'],
        \ })
endif

let g:vista_executive_for = {
        \ 'cpp': 'vim_lsp',
        \ 'python': 'vim_lsp',
        \ }
let g:vista_ignore_kinds = ['Variable']

let g:coc_disable_startup_warning = 1

" --- Status line ---
set laststatus=2
set statusline=\ %{HasPaste()}%<%-15.25(%f%)%m%r%h\ %w\ \
set statusline+=\ \ \ %<%20.30(%{hostname()}:%{CurDir()}%)\
set statusline+=\ \ \ [%{&ff}/%Y]
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%=%-10.(%l,%c%V%)\ %p%%/%L
set statusline+=%*

function! CurDir()
    let curdir = substitute(getcwd(), $HOME, "~", "")
    return curdir
endfunction

function! HasPaste()
    if &paste
        return '[PASTE]'
    else
        return ''
    endif
endfunction

" --- Tabbar ---
try
set showtabline=2
set switchbuf=useopen,usetab,newtab
catch
endtry

tab sball

let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'tabline': {
      \   'left': [ ['buffers'] ],
      \   'right': [ ['close'] ]
      \ },
      \ 'component_expand': {
      \   'buffers': 'lightline#bufferline#buffers'
      \ },
      \ 'component_type': {
      \   'buffers': 'tabsel'
      \ }
      \ }

autocmd BufWritePost,TextChanged,TextChangedI * call lightline#update()

let g:lightline#bufferline#show_number  = 1
let g:lightline#bufferline#shorten_path = 0
let g:lightline#bufferline#unnamed      = '[No Name]'

let g:lightline                  = {}
let g:lightline.tabline          = {'left': [['buffers']], 'right': [['close']]}
let g:lightline.component_expand = {'buffers': 'lightline#bufferline#buffers'}
let g:lightline.component_type   = {'buffers': 'tabsel'}

" --- Nerd Tree ---
let NERDTreeIgnore=['\.pyc$', '\.pyo$', '__pycache__$']     " Ignore files in NERDTree
let NERDTreeMinimalUI=1

map <C-t> :NERDTreeToggle<CR>

" Open files in new tabs in Nerdtree
let NERDTreeMapOpenInTab='\r'

" Toggle NERDTree drawer
map <leader>d <plug>NERDTreeToggle<CR>

" Find files
nnoremap <C-f><C-l> :NERDTreeFind<CR>

" --- Move between buffers ---
map <C-Left> <Esc>:bprev<CR>
map <C-Right> <Esc>:bnext<CR>

map <C-PageUp> :bprevCR>
map <C-PageDown> :bnext<CR>

map <C-P> :bprevCR>
map <C-N> :bnext<CR>

" --- Statusbar ---
let g:airline_theme                       = 'one'
let g:airline_powerline_fonts             = 0
let g:airline#extensions#tabline#enabled  = 1
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#formatter='unique_tail'
let g:airline_section_z                   = airline#section#create([
            \ '%1p%% ',
            \ 'Ξ%l%',
            \ '\⍿%c'])
call airline#parts#define_accent('mode', 'black')

" --- Default vim file browser :Explore
let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_browse_split = 1
let g:netrw_altv = 1
let g:netrw_winsize = 25

" --- Git tools ---
let g:gitgutter_max_signs             = 5000
let g:gitgutter_sign_added            = '+'
let g:gitgutter_sign_modified         = '»'
let g:gitgutter_sign_removed          = '_'
let g:gitgutter_sign_modified_removed = '»╌'
let g:gitgutter_map_keys              = 0
let g:gitgutter_diff_args             = '--ignore-space-at-eol'

nmap <Leader>j <Plug>(GitGutterNextHunk)zz
nmap <Leader>k <Plug>(GitGutterPrevHunk)zz
nnoremap <silent> <C-g> :call <SID>ToggleGGPrev()<CR>zz
nnoremap <Leader>ga :GitGutterStageHunk<CR>
nnoremap <Leader>gu :GitGutterUndoHunk<CR>

" --- Buffer navigation ---
let g:BufstopSpeedKeys = ["<F1>", "<F2>", "<F3>", "<F4>", "<F5>", "<F6>"]
let g:BufstopLeader = ""
let g:BufstopAutoSpeedToggle = 1

nnoremap <leader>b :Bufstop<CR>

" --- Sessions ---
let g:session_autosave  = 'yes'
let g:session_autoload  = 'yes'
let g:session_directory = '~/.vim.cache/sessions'

" Restore cursor to file position in previous editing session
set viminfo='10,\"100,:20,%,n~/.viminfo
au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

" --- CtrlP settings ---
if executable('rg')
  let g:ctrlp_user_command = 'rg %s --files --hidden --color=never --glob ""'
endif

let g:ctrlp_map                 = '<C-p>'
let g:ctrlp_cmd                 = 'CtrlPBuffer'
let g:ctrlp_working_path_mode   = 'rc'
let g:ctrlp_match_window        = 'bottom,order:btt,min:1,max:10,results:85'
let g:ctrlp_show_hidden         = 1
let g:ctrlp_follow_symlinks     = 1
let g:ctrlp_open_multiple_files = '0i'
let g:ctrlp_prompt_mappings     = {
    \ 'PrtHistory(1)'        : [''],
    \ 'PrtHistory(-1)'       : [''],
    \ 'ToggleType(1)'        : ['<C-l>', '<C-up>'],
    \ 'ToggleType(-1)'       : ['<C-h>', '<C-down>'],
    \ 'PrtCurLeft()'         : ['<C-b>', '<Left>'],
    \ 'PrtCurRight()'        : ['<C-f>', '<Right>'],
    \ 'PrtBS()'              : ['<C-s>', '<BS>'],
    \ 'PrtDelete()'          : ['<C-d>', '<DEL>'],
    \ 'PrtDeleteWord()'      : ['<C-w>'],
    \ 'PrtClear()'           : ['<C-u>'],
    \ 'ToggleByFname()'      : ['<C-g>'],
    \ 'AcceptSelection("e")' : ['<C-m>', '<CR>'],
    \ 'AcceptSelection("h")' : ['<C-x>'],
    \ 'AcceptSelection("t")' : ['<C-t>'],
    \ 'AcceptSelection("v")' : ['<C-v>'],
    \ 'OpenMulti()'          : ['<C-o>'],
    \ 'MarkToOpen()'         : ['<c-z>'],
    \ 'PrtExit()'            : ['<esc>', '<c-c>', '<c-p>'],
    \ }

" Ignore some files when fuzzy searching
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.?(git|hg|svn|meteor|bundle|node_modules|bower_components)$',
  \ 'file': '\v\.(so|swp|zip)$'
  \ }

" --- Search with ack ---
if executable('ag')
    let g:ackprg = 'ag --vimgrep'
endif

" --- Undotree toggle ---
nnoremap <Leader>u :UndotreeToggle<CR>

" --- Multiple windows ---
" Remap wincmd
map <Leader>, <C-w>

" Settings
set winminheight=0
set winminwidth=0
set splitbelow
set splitright
set fillchars+=stlnc:\/,vert:│,fold:―,diff:―

" Split windows
map <C-w>- :split<CR>
map <C-w>. :vsplit<CR>
map <C-w>x :close<CR>
map <C-w>q :q!<CR>
map <C-w>, <C-w>=

" Resize windows
if bufwinnr(1)
    map + :resize +1<CR>
    map - :resize -1<CR>
    map < :vertical resize +1<CR>
    map > :vertical resize -1<CR>
endif

" Toggle resize window
nnoremap <silent> <C-w>f :call <SID>ToggleResize()<CR>

" Last, previous and next window; and only one window
nnoremap <silent> <C-w>l :wincmd p<CR>:echo "Last window."<CR>
nnoremap <silent> <C-w>p :wincmd w<CR>:echo "Previous window."<CR>
nnoremap <silent> <C-w>n :wincmd W<CR>:echo "Next window."<CR>
nnoremap <silent> <C-w>o :wincmd o<CR>:echo "Only one window."<CR>

" setting horizontal and vertical splits
set splitbelow
set splitright

" split navigations
nnoremap <Leader>h <C-w>h
nnoremap <Leader>l <C-w>l
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k

"  --- Folding ---
" Enable folding
set foldmethod=indent
set foldlevel=99

" Enable folding with the spacebar
nnoremap <space> za

" --- NERDCommenter settings ---
let g:NERDDefaultAlign          = 'left'
let g:NERDSpaceDelims           = 1
let g:NERDCompactSexyComs       = 1
let g:NERDCommentEmptyLines     = 0
let g:NERDCreateDefaultMappings = 0
let g:NERDCustomDelimiters      = {
    \ 'python': {'left': '#'},
    \ }

nnoremap cc :call NERDComment(0,'toggle')<CR>
vnoremap cc :call NERDComment(0,'toggle')<CR>

" --- FZF settings ---
let $FZF_PREVIEW_COMMAND = 'cat {}'
nnoremap <C-f><C-f> :Files<CR>
nnoremap <C-f><C-g> :Commits<CR>
nnoremap <C-f><Space> :BLines<CR>

" --- ALE settings ---
let g:ale_sign_column_always = 1
let g:ale_linters            = {
    \ 'c'          : ['clang'],
    \ 'python'     : ['pylint'],
    \ 'javascript' : ['jshint'],
    \ 'css'        : ['csslint'],
    \ 'tex'        : ['chktex'],
    \ }

" --- Syntastic settings ---
nmap <silent> <leader>q :SyntasticCheck # <CR> :bp <BAR> bd #<CR>

let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_enable_signs=1
let g:syntastic_aggregate_errors=1
let g:syntastic_loc_list_height=5
let g:syntastic_error_symbol='X'
let g:syntastic_style_error_symbol='X'
let g:syntastic_warning_symbol='x'
let g:syntastic_style_warning_symbol='x'
let g:syntastic_python_checkers=['flake8', 'pydocstyle', 'python3']

let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 1

" --- Setting up indendation ---
au BufNewFile, BufRead *.py
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    \ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix

au BufNewFile, BufRead *.js, *.html, *.css
    \ set tabstop=2 |
    \ set softtabstop=2 |
    \ set shiftwidth=2

" --- Better copy paste ---
let g:yoinkIncludeDeleteOperations   = 1

nnoremap x d
xnoremap x d

nnoremap xx dd
nnoremap X D

" --- Language settings ---
" Go sttings
let g:go_highlight_functions         = 1
let g:go_highlight_methods           = 1
let g:go_highlight_fields            = 1
let g:go_highlight_types             = 1
let g:go_highlight_operators         = 1
let g:go_highlight_build_constraints = 1

" Javascript settings
let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_ngdoc = 1
let g:javascript_plugin_flow  = 1

" Tern_for_vim settings
let g:tern#command   = ['tern']
let g:tern#arguments = ['--persistent']

" JS-Beautify
let g:config_Beautifier = {}
let g:config_Beautifier['js'] = {}
let g:config_Beautifier['js'].indent_style = 'tab'
let g:config_Beautifier['jsx'] = {}
let g:config_Beautifier['jsx'].indent_style = 'tab'
let g:config_Beautifier['json'] = {}
let g:config_Beautifier['json'].indent_style = 'tab'
let g:config_Beautifier['css'] = {}
let g:config_Beautifier['css'].indent_style = 'tab'
let g:config_Beautifier['html'] = {}
let g:config_Beautifier['html'].indent_style = 'tab'

augroup beautify
    autocmd!
    autocmd FileType javascript nnoremap <buffer> <Leader>bf :call JsBeautify()<cr>
    autocmd FileType javascript vnoremap <buffer> <Leader>bf :call RangeJsBeautify()<cr>
    autocmd FileType json nnoremap <buffer> <Leader>bf :call JsonBeautify()<cr>
    autocmd FileType json vnoremap <buffer> <Leader>bf :call RangeJsonBeautify()<cr>
    autocmd FileType jsx nnoremap <buffer> <Leader>bf :call JsxBeautify()<cr>
    autocmd FileType jsx vnoremap <buffer> <Leader>bf :call RangeJsxBeautify()<cr>
    autocmd FileType html nnoremap <buffer> <Leader>bf :call HtmlBeautify()<cr>
    autocmd FileType html vnoremap <buffer> <Leader>bf :call RangeHtmlBeautify()<cr>
    autocmd FileType css nnoremap <buffer> <Leader>bf :call CSSBeautify()<cr>
    autocmd FileType css vnoremap <buffer> <Leader>bf :call RangeCSSBeautify()<cr>
augroup end
