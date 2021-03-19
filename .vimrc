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
