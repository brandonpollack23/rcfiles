"Local file sourcing
source ~/.vimrc.local

"Vimmy vim and security stuff
set secure "make it secure so that no one can infect my machine with a malicious vimrc
set nocompatible "for compatibility with modern vim and not old vi
set backupdir=$HOME/.vim/backupdir "backup files (~ files)
set directory=$HOME/.vim/swapdir "Swap files
set mouse="a"
let mapleader=","
set updatetime=250
set wildmenu "tab completion menu in commadn mode
set ignorecase "don't use case in search /
set encoding=utf-8
syntax enable

" Preferences
colorscheme monokai
"tab setup
set expandtab
set shiftwidth=4
set softtabstop=4
set backspace=indent,eol,start "be able to backspace indents, lines, and start
filetype indent on
filetype plugin on
set smartindent

" Utils
set autoindent "keep indents aligned when programming etc
set number "show line numbers
set ruler "bottom right ruler
set sidescroll=1 "Disable sidescrolling its thw worst

"Split buffers in these directions
set splitright
set splitbelow

"Mappings
imap jj <Esc>
map <Leader>f :NERDTreeToggle<CR>

"Plugin configurations
"markdown
"start with :MarkdownPreviewToggle
map <Leader>m :MarkdownPreviewToggle<CR>
let g:mkdp_auto_close = 1
let g:mkdp_echo_preview_url = 1
let g:mkdp_open_to_the_world = 1
let g:mkdp_preview_options = {
    \ 'mkit': {},
    \ 'katex': {},
    \ 'uml': {},
    \ 'maid': {},
    \ 'disable_sync_scroll': 0,
    \ 'sync_scroll_type': 'middle',
    \ 'hide_yaml_meta': 1,
    \ 'sequence_diagrams': {},
    \ 'flowchart_diagrams': {},
    \ 'content_editable': v:false,
    \ 'disable_filename': 0
    \ }
let g:mkdp_filetypes = ['md', 'markdown']

"coc
"let g:coc_global_extensions = ['coc-marketplace', 'coc-json', 'coc-git', 'coc-sh', 'coc-dot-complete', 'coc-rust-analyzer', 'coc-toml', 'coc-yaml', 'coc-vimlsp', 'coc-toml']

" Set internal encoding of vim, not needed on neovim, 
" since coc.nvim using some unicode characters in the file autoload/float.vim
set encoding=utf-8

" TextEdit might fail if hidden is not set.
 set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
    " Recently vim can merge signcolumn and number column into one
    set signcolumn=number
else
    set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

