let g:CSApprox_verbose_level = 0

set nocompatible

call pathogen#infect()

filetype plugin on
filetype plugin off

filetype plugin indent on
let g:indent_guides_guide_size=1

color kellybeans
syntax on

let mapleader = ','

""""""""""""""""" Set encoding
set encoding=utf-8

""""""""""""""""" Clipboard
set clipboard=autoselect

""""""""""""""""" Whitespace stuff
set shiftround
set tabstop=2 shiftwidth=2 softtabstop=2
set expandtab
set smarttab
set smartindent
" set list listchars=tab:»·,trail:·,precedes:<,extends:>
set list listchars=tab:\|·,trail:·,precedes:<,extends:>
set backspace=start,indent,eol

""""""""""""""""" Searching
set hlsearch
set incsearch
set ignorecase
set smartcase

""""""""""""""""" Status Bar
set laststatus=2
set report=0
set showcmd
set showmode

set statusline=   " clear the statusline for when vimrc is reloaded
set statusline+=%1*\ %-3.3n\                      " buffer number
set statusline+=%2*\ %t                           " file basename
set statusline+=%h%m%r%w\                         " flags
set statusline+=[%{strlen(&ft)?&ft:'none'},       " filetype
set statusline+=%{strlen(&fenc)?&fenc:&enc},      " encoding
set statusline+=%{&fileformat}]\                  " file format
set statusline+=%=                                " right align
set statusline+=%3*%{synIDattr(synID(line('.'),col('.'),1),'name')!=''?synIDattr(synID(line('.'),col('.'),1),'name'):'none'}  " highlight
set statusline+=%4*\ %3b,0x%-8B                   " current char
set statusline+=%-14.(%l/%L,%c%)\ %<%P            " offset

" hi User1 guifg=#ededed guibg=#3c5053 gui=bold,inverse
" hi User2 guifg=#ffffff guibg=#506063 gui=bold,inverse
" hi User3 guifg=#cccccc guibg=#506063 gui=NONE,inverse
" hi User4 guifg=#ededed guibg=#506063 gui=NONE,inverse

""""""""""""""""" Terminal Stuff
set ttyfast
set mouse=a
set ttymouse=xterm2
" set pastetoggle=<F12>
set paste

""""""""""""""""" Visual Junk
set ruler
set visualbell
set noerrorbells

""""""""""""""""" Tab Completion
set wildmenu
set wildmode=list:longest,full
set wildignore+=*.tmproj,*.o,*.obj,.git,*.rbc,*.class,*.gif,*.png,*.jpg,.svn,vendor/gems/*

""""""""""""""""" Folding
set foldmethod=syntax
set foldnestmax=3
set nofoldenable

""""""""""""""""" Line Numbering
set number
set relativenumber
autocmd VimEnter * nmap <silent> <leader>n :set nonumber! norelativenumber!<CR>

""""""""""""""""" Window Title
set title
if !has("gui_macvim")
  set t_ts=k
  set t_fs=\
  autocmd BufEnter * let &titlestring = 'Vim - ' . expand("%:t")
endif

" Tag List
" let Tlist_Inc_Winwidth = 0
" let Tlist_GainFocus_On_ToggleOpen = 1
" let Tlist_Ctags_Cmd = '/usr/local/bin/ctags'
" let g:tlist_javascript_settings = 'javascript;r:var;s:string;a:array;o:object;u:function'
map <leader>c :TlistToggle<CR>
map <leader>c :TagbarToggle<CR>
let g:tagbar_ctags_bin = '/opt/homebrew/bin/ctags'
let g:tagbar_left = 1
let g:tagbar_autofocus = 1
let g:tagbar_singleclick = 1
let g:tagbar_autoshowtag = 1
let g:tagbar_autoclose = 1

" viminfo and history
set history=1000
set viminfo='10,\"100,:20,%,n~/.viminfo
" if has("autocmd")
" Remember last location in file
" au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
" endif

" Ack
set grepprg=ack
set grepformat=%f:%l:%m

" CTags
map <leader>rt :!ctags --extra=+f -R *<CR><CR>
map <C-\> :tnext<CR>

function s:setupWrapping()
  set wrap
  set wrapmargin=2
  set textwidth=72
endfunction

function s:setupMarkup()
  call s:setupWrapping()
  map <buffer> <leader>p :Hammer<CR>
endfunction

" These files are Ruby
autocmd BufRead,BufNewFile {Gemfile,Guardfile,Rakefile,Thorfile,config.ru} set filetype=ruby

" md, markdown, and mk are markdown and define buffer-local preview
au BufRead,BufNewFile *.{md,markdown,mdown,mkd,mkdn} call s:setupMarkup()

" Add json syntax highlighting
au BufNewFile,BufRead *.json set ft=javascript

" Format text files
au BufRead,BufNewFile *.txt call s:setupWrapping()

" Unimpaired configuration
" Bubble single lines
nmap <C-Up> [e
nmap <C-Down> ]e
" Bubble multiple lines
vmap <C-Up> [egv
vmap <C-Down> ]egv

" Enable syntastic syntax checking
let g:syntastic_enable_signs=1
let g:syntastic_quiet_messages = {'level': 'warnings'}

" Use modeline overrides
set modeline
set modelines=10

" Directories for swp files
set backupdir=~/.vim/backup
set directory=~/.vim/backup

" Turn off jslint errors by default
"let g:JSLintHighlightErrorLine = 0

" quickfix window handling
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" use jslint as the default javascript makeprg
"autocmd FileType javascript setlocal makeprg=jslint\ %
"autocmd FileType javascript setlocal errorformat=%-P%f,
"                    \%A%>%\\s%\\?#%*\\d\ %m,%Z%.%#Line\ %l\\,\ Pos\ %c,
"                    \%-G%f\ is\ OK.,%-Q

" MacVIM shift+arrow-keys behavior (required in .vimrc)
let macvim_hig_shift_movement = 1

" % to bounce from do to end etc.
runtime! macros/matchit.vim

" Alignment
nmap <leader>ae :Tabularize/=<CR>
vmap <leader>ae :Tabularize/=<CR>
nmap <leader>ac :Tabularize/:\zs<CR>
vmap <leader>ac :Tabularize/:\zs<CR>
inoremap <silent> <Bar>   <Bar><Esc>:call <SID>align()<CR>a

function! s:align()
  let p = '^\s*|\s.*\s|\s*$'
  if exists(':Tabularize') && getline('.') =~# '^\s*|' && (getline(line('.')-1) =~# p || getline(line('.')+1) =~# p)
    let column = strlen(substitute(getline('.')[0:col('.')],'[^|]','','g'))
    let position = strlen(matchstr(getline('.')[0:col('.')],'.*|\s*\zs.*'))
    Tabularize/|/l1
    normal! 0
    call search(repeat('[^|]*|',column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
  endif
endfunction

" Make <c-l> clear the highlight as well as redraw
nnoremap <C-L> :nohls<CR><C-L>
inoremap <C-L> <C-O>:nohls<CR>

" Key mapping for vimgrep result navigation
map <A-o> :copen<CR>
map <A-q> :cclose<CR>
map <A-j> :cnext<CR>
map <A-k> :cprevious<CR>

" Visual search mappings
function! s:VSetSearch()

  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  let @@ = temp

endfunction

vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR>

"jump to last cursor position when opening a file
"dont do it when writing a commit log entry
autocmd BufReadPost * call SetCursorPosition()
function! SetCursorPosition()
  if &filetype !~ 'commit\c'
      if line("'\"") > 0 && line("'\"") <= line("$")
          exe "normal! g`\""
          normal! zz
      endif
  end
endfunction

" Key mapping for textmate-like indentation
nmap <D-[> <<
nmap <D-]> >>
imap <D-[> <<
imap <D-]> >>
vmap <D-[> <gv
vmap <D-]> >gv

" CoffeeMake
"   https://github.com/kchmck/vim-coffee-script

" YankRing
"   http://www.vim.org/scripts/script.php?script_id=1234
"   https://github.com/chrismetcalf/vim-yankring.git

let g:user_emmet_settings = {
\  'php' : {
\    'extends' : 'html',
\    'filters' : 'c',
\  },
\  'xml' : {
\    'extends' : 'html',
\  },
\  'haml' : {
\    'extends' : 'html',
\  },
\  'erb' : {
\    'extends' : 'html',
\  },
\}

" XML formatting
autocmd BufRead,BufNewFile *.bap,*.bpt,capture*.txt* set filetype=xml
autocmd BufRead,BufNewFile *.bap,*.bpt,*.xml,capture*.txt* exec(":silent 1,$!tidy --input-xml true --indent yes --wrap 0 --wrap-sections false --tab-size 2 2>/dev/null")
" autocmd BufRead,BufNewFile *.bap,*.bpt,*.xml,capture*.txt* exec(":silent 1,$!xml_pp -l 2>/dev/null")

" all file formatting
autocmd BufEnter all,all.* set filetype=bps

" Don't continue comments when pushing o/O
set formatoptions-=o

" formatting
" map  # {v}! par 72<CR>
" map  & {v}! par 72j<CR>

" SingleCompile key mappings
nmap <F5> :SCCompile<cr>
nmap <F6> :SCCompileRun<cr>

" make netRw re-use the same tab
let g:netrw_browse_split = 0

" disable annoying keys/commands that I accidentally type
map K <Nop>
map <D-p> <Nop>

" p4 stuff

" automatically 'p4 edit' files if it was RO and I try to change it
set autoread
autocmd FileChangedRO * echohl WarningMsg | echo 'File changed RO.' | echohl None
autocmd FileChangedShell * echohl WarningMsg | echo 'File changed shell.' | echohl None

let s:IgnoreChange=0
autocmd! FileChangedRO * nested
    \ let s:IgnoreChange=1 |
    \ call system('p4 edit ' . expand('%')) |
    \ set noreadonly
autocmd! FileChangedShell *
    \ if 1 == s:IgnoreChange |
    \   let v:fcs_choice="" |
    \   let s:IgnoreChange=0 |
    \ else |
    \   let v:fcs_choice="ask" |
    \ endif

" airline stuff

if has("gui_running")
  let g:airline_powerline_fonts=1
  let g:airline_section_c = airline#section#create(['%<', 'readonly'])
else
  let g:airline_section_c = airline#section#create(['%<', '%t', ' ', 'readonly'])
endif

call airline#init#bootstrap()

let g:airline_section_a = airline#section#create_left(['mode', 'iminsert'])
let g:airline_section_b = '%4b,0x%-6B'
let g:airline_section_x = '%{synIDattr(synID(line("."),col("."),1),"name")!=""?synIDattr(synID(line("."),col("."),1),"name"):""}'
let g:airline_section_y = '%{strlen(&ft)?&ft:"none"},%{&fileformat},%{strlen(&fenc)?&fenc:&enc}'
let g:airline_section_z = airline#section#create(['%-14.(%l/%L,%c%)', ' ', '%<%P'])

" enforce apps coding style standards
autocmd BufNewFile,BufRead $HOME/bps/ati-stable/*   set tabstop=4 shiftwidth=4 softtabstop=4
autocmd BufNewFile,BufRead $HOME/bps/ati-unstable/* set tabstop=4 shiftwidth=4 softtabstop=4

" seeing is believing + vim-ruby-xmpfilter plugin
let g:xmpfilter_cmd = "seeing_is_believing"

autocmd FileType ruby nmap <buffer> <leader>e <Plug>(seeing_is_believing-mark)
autocmd FileType ruby xmap <buffer> <leader>e <Plug>(seeing_is_believing-mark)
autocmd FileType ruby imap <buffer> <leader>e <Plug>(seeing_is_believing-mark)

autocmd FileType ruby nmap <buffer> <leader>u <Plug>(seeing_is_believing-clean)
autocmd FileType ruby xmap <buffer> <leader>u <Plug>(seeing_is_believing-clean)
autocmd FileType ruby imap <buffer> <leader>u <Plug>(seeing_is_believing-clean)

" xmpfilter compatible
autocmd FileType ruby nmap <buffer> <leader>r <Plug>(seeing_is_believing-run_-x)
autocmd FileType ruby xmap <buffer> <leader>r <Plug>(seeing_is_believing-run_-x)
autocmd FileType ruby imap <buffer> <leader>r <Plug>(seeing_is_believing-run_-x)

" auto insert mark at appropriate spot.
autocmd FileType ruby nmap <buffer> <F5> <Plug>(seeing_is_believing-run)
autocmd FileType ruby xmap <buffer> <F5> <Plug>(seeing_is_believing-run)
autocmd FileType ruby imap <buffer> <F5> <Plug>(seeing_is_believing-run)

