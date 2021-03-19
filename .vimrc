"Vimmy vim and security stuff
set secure "make it secure so that no one can infect my machine with a malicious vimrc
set nocompatible "for compatibility with modern vim and not old vi
set backupdir=$HOME/.vim/backupdir "backup files (~ files)
set directory=$HOME/.vim/swapdir "Swap files
set mouse=""
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


" Notes
" Completion, turn on CoC
" :packadd coc.nvim
" read their docs:  https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim 

" CTRLP
" Press <F5> to purge the cache for the current directory to get new files, remove deleted files and apply new ignore options.
" Press <c-f> and <c-b> to cycle between modes.
" Press <c-d> to switch to filename only search instead of full path.
" Press <c-r> to switch to regexp mode.
" Use <c-j>, <c-k> or the arrow keys to navigate the result list.
" Use <c-t> or <c-v>, <c-x> to open the selected entry in a new tab or in a new split.
" Use <c-n>, <c-p> to select the next/previous string in the prompt's history.
" Use <c-y> to create a new file and its parent directories.
" Use <c-z> to mark/unmark multiple files and <c-o> to open them.
