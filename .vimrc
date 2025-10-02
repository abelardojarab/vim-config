" =========================
" Clean, fast, compatible .vimrc
" =========================

" --- Windows behavior/mappings (yours) ---
source ~/.vim/autoload/win.vim
if !has('nvim')
  behave mswin
endif

" --- Core mappings you had at the top ---
smap <Del> <C-g>"_d
smap <C-c> <C-g>y
smap <C-x> <C-g>x
imap <C-v> <Esc>pi
smap <C-v> <C-g>p
smap <Tab> <C-g>1>
smap <S-Tab> <C-g>1<

" --- Plugin manager ---
source ~/.vim/autoload/plug.vim

" =========================
" General/editor settings
" =========================
set nocompatible
set encoding=utf-8
set nobomb

" GUI bits (ignored in most TUI sessions)
set t_Co=256
set showmode
set nowrap
set number
set mouse=a
if !has('nvim') | set ttymouse=xterm2 | endif

" Indentation
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
set smarttab smartindent shiftround
set autoindent copyindent

" Search
set ignorecase smartcase
set hlsearch incsearch gdefault magic

" Perf / buffers
set hidden lazyredraw ttyfast

" History / files
set history=10000 undolevels=999 autoread
set updatetime=250

" Leader
let mapleader=',' | let g:mapleader=','

" Key tweaks
inoremap <C-c> <Esc>
nnoremap Q <NOP>
cnoreabbrev help vert help

" Swap/backup off (your preference)
set nobackup nowritebackup noswapfile

" Spell
set spelllang=en_us

" Cursorline + subtle highlight
set cursorline
hi CursorLine term=bold cterm=bold

" Splits, UI
set splitbelow splitright
set showcmd showmatch
set scrolloff=5 sidescrolloff=7 sidescroll=1
set title
set wildmenu wildmode=list:longest
set wildignore+=*.DS_Store,.git,*.db,node_modules/**,*.jpg,*.png,*.gif,*.o,*.pyc

filetype plugin indent on
syntax enable

" Neovim: hide ~ tildes at end of buffer
if has('nvim')
lua << EOF
vim.opt.fillchars = {eob = " "}
EOF
endif

" --- Truecolor (safe) ---
if (empty($TMUX))
  if has('termguicolors')
    set termguicolors
  endif
endif

" =========================
" Quality-of-life mappings
" =========================
" jk on wrapped lines
nnoremap j gj
nnoremap k gk

" Easy escape
imap jj <Esc>

" sudo write
cmap w!! w !sudo tee % >/dev/null

" Ctrl-S/Ctrl-Q usable in terminals
silent! !stty -ixon
autocmd VimLeave * silent! !stty ixon

" Tmux cursor shape
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Toggle numbers
nnoremap <silent> <Leader>nn :set number!<CR>

" Clipboard (Vim only; Neovim uses system by default)
if !has('nvim')
  set clipboard=unnamed,unnamedplus
endif

" Copy filename / full path
nnoremap yY :let @" = expand("%")<CR>
nnoremap yZ :let @" = expand("%:p")<CR>

" Auto-cd and local dir per buffer
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>
autocmd BufEnter * silent! lcd %:p:h

" Terminal helpers
nnoremap <Leader>t :term ++close<CR>
tnoremap <Esc> <C-\><C-n>
if has('nvim')
  autocmd TermOpen * setlocal nonumber norelativenumber
endif

" Jenkinsfile filetype
autocmd BufNewFile,BufRead Jenkinsfile setf groovy

" =========================
" Plugins
" =========================
call plug#begin('~/.vim/plugged')

" --- Core UX / UI ---
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'ap/vim-buftabline'
Plug 'wellle/targets.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'editorconfig/editorconfig-vim'
Plug 'mbbill/undotree'
Plug 'ntpeters/vim-better-whitespace'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-commentary'     " (kept alongside NERDCommenter off by default)
Plug 'liuchengxu/vim-which-key'

" --- Files / fuzzy ---
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'jistr/vim-nerdtree-tabs'
Plug 'Nopik/vim-nerdtree-direnter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
if has('nvim-0.9')
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.*' }
  Plug 'nvim-telescope/telescope-project.nvim'
endif

" --- Git ---
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'
if has('nvim-0.5')
  Plug 'lewis6991/gitsigns.nvim'
endif

" --- LSP / completion ---
if has('nvim')
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
else
  Plug 'prabirshrestha/vim-lsp'
  Plug 'prabirshrestha/asyncomplete.vim'
  Plug 'prabirshrestha/asyncomplete-lsp.vim'

  " works with both vim and neovim; provides :lspinstallserver
  Plug 'mattn/vim-lsp-settings'

  " auto-install on first open of a filetype (optional)
  let g:lsp_settings_auto_install = 1

  " prefer these servers (optional)
  let g:lsp_settings_filetype_c   = ['clangd']
  let g:lsp_settings_filetype_cpp = ['clangd']
  let g:lsp_settings_filetype_python = ['pylsp']
  let g:lsp_settings_filetype_typescript = ['typescript-language-server']
  let g:lsp_settings_filetype_javascript = ['typescript-language-server']
endif

" --- Linting (single source of truth) ---
Plug 'dense-analysis/ale'

" --- Treesitter (Neovim) ---
if has('nvim-0.5')
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-treesitter/playground'
endif

" --- Languages / tools ---
Plug 'rhysd/vim-clang-format'
Plug 'Vimjas/vim-python-pep8-indent'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
" Plug 'bazelbuild/vim-bazel'
Plug 'ctrlpvim/ctrlp.vim'    " fallback if you prefer over :Files

" --- Colors ---
Plug 'rakr/vim-one'
Plug 'sickill/vim-monokai'
Plug 'gerardbm/vim-atomic'

call plug#end()

" =========================
" Post-plugin setup
" =========================

" Colors
colorscheme monokai
set background=dark

" Lightline
let g:lightline = {
  \ 'colorscheme': 'one',
  \ 'active': { 'left': [ [ 'mode', 'paste' ],
  \                        [ 'readonly', 'filename', 'modified' ] ] },
  \ 'tabline': { 'left': [ ['buffers'] ], 'right': [ ['close'] ] },
  \ 'component_expand': { 'buffers': 'lightline#bufferline#buffers' },
  \ 'component_type': { 'buffers': 'tabsel' }
  \ }
autocmd BufWritePost,TextChanged,TextChangedI * call lightline#update()
let g:lightline#bufferline#show_number = 1
let g:lightline#bufferline#shorten_path = 0
let g:lightline#bufferline#unnamed = '[No Name]'

" NERDTree
let g:NERDTreeIgnore=['\.pyc$', '\.pyo$', '__pycache__$']
let g:NERDTreeMinimalUI=1
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <leader>d :NERDTreeToggle<CR>
let NERDTreeMapOpenInTab = "\r"

" GitGutter
let g:gitgutter_max_signs = 5000
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '»'
let g:gitgutter_sign_removed = '_'
let g:gitgutter_sign_modified_removed = '»╌'
let g:gitgutter_map_keys = 0
let g:gitgutter_diff_args = '--ignore-space-at-eol'
nmap <Leader>j <Plug>(GitGutterNextHunk)zz
nmap <Leader>k <Plug>(GitGutterPrevHunk)zz
nnoremap <Leader>ga :GitGutterStageHunk<CR>
nnoremap <Leader>gu :GitGutterUndoHunk<CR>

" FZF / Telescope mappings
let $FZF_PREVIEW_COMMAND = 'cat {}'
nnoremap <C-f><C-f> :Files<CR>
nnoremap <C-f><C-g> :Commits<CR>
nnoremap <C-f><Space> :BLines<CR>
if has('nvim-0.5')
  nnoremap ;f :Telescope find_files<CR>
  nnoremap ;g :Telescope git_files<CR>
  nnoremap ;e :Telescope oldfiles<CR>
endif

" ALE (single linter)
let g:ale_virtualtext_cursor = 0
let g:ale_sign_column_always = 1
let g:ale_lint_on_save = 1
let g:ale_set_highlights = 0
let g:ale_linters = {
\ 'c':        ['clangd', 'clangtidy', 'clang'],
\ 'cpp':      ['clangd', 'clangtidy', 'clang'],
\ 'python':   ['pylint', 'flake8'],
\ 'javascript':['eslint'],
\ 'css':      ['csslint'],
\ 'tex':      ['chktex'],
\ }
if has('nvim-0.5')
  let g:ale_use_neovim_diagnostics_api = 1
endif

" Completion / LSP
if has('nvim')
  " coc basic UX
  inoremap <silent><expr> <C-Space> coc#refresh()
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)
else
  " vim-lsp + asyncomplete
  imap <c-space> <Plug>(asyncomplete_force_refresh)
  inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  inoremap <expr> <CR> pumvisible() ? "\<C-y>\<CR>" : "\<CR>"
  if executable('pyls')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'pyls',
          \ 'cmd': {server_info->['pyls']},
          \ 'allowlist': ['python'],
          \ })
  endif
endif

" Treesitter (Neovim)
if has('nvim-0.9')
lua << EOF
require('nvim-treesitter.configs').setup{
  ensure_installed = {},
  highlight = { enable = true, additional_vim_regex_highlighting = false },
  incremental_selection = { enable = true },
}
require('gitsigns').setup()
EOF
endif

" Undotree
nnoremap <Leader>u :UndotreeToggle<CR>

" Better whitespace
let g:better_whitespace_enabled = 1
let g:show_spaces_that_precede_tabs = 1
let g:strip_whitelines_at_eof = 1

" CtrlP sane defaults (if you prefer over :Files)
let g:ctrlp_user_command = executable('rg')
      \ ? 'rg %s --files --hidden --color=never --glob ""'
      \ : 'find %s -type f'
let g:ctrlp_show_hidden = 1
let g:ctrlp_follow_symlinks = 1

" Folding (simple, predictable)
set foldmethod=indent
set foldlevel=99
nnoremap <space> za

" Session dir
let g:session_directory = '~/.vim.cache/sessions'
let g:session_autosave  = 'yes'
let g:session_autoload  = 'yes'

" Statusline compatibility bits you had (kept minimal)
set laststatus=2

" Netrw (kept)
let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_browse_split = 1
let g:netrw_altv = 1
let g:netrw_winsize = 25

" Groovy for Jenkinsfile already set above

" vim: set ts=2 sw=2 et :

