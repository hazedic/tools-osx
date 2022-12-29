Plug 'dracula/vim', {'as': 'dracula'}

Plug 'vim-airline/vim-airline'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#quickfix#quickfix_text = 'Quickfix'
let g:airline#extensions#quickfix#location_text = 'Location'

Plug 'neoclide/coc.nvim', { 'branch': 'release' }
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

Plug 'vim-syntastic/syntastic'
let g:syntastic_error_symbol='✗'
let g:syntastic_warning_symbol='⚠'
let g:syntastic_style_error_symbol = '⚡ '
let g:syntastic_style_warning_symbol = '⚡ '
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_mode_map = {
            \ 'mode': 'active',
            \   'active_filetypes': ['python', 'javascript', 'coffee'],
            \   'passive_filetypes': ['html', 'css', 'scss', 'c', 'cpp'],
            \ }
let g:syntastic_python_pylint_post_args='--disable=E1101,W0613,C0111'
let g:syntastic_python_checkers = ['pylint2']
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_html_tidy_ignore_errors =
            \ ["proprietary attribute \"autofocus", "proprietary attribute \"ui-", "proprietary attribute \"ng-", "<form> proprietary attribute \"novalidate\"", "<form> lacks \"action\" attribute", "trimming empty <span>", "<input> proprietary attribute \"autofocus\"", "unescaped & which should be written as &amp;", "inserting implicit <span>", "<input> proprietary attribute \"required\"", "trimming empty <select>", "trimming empty <button>", "<img> lacks \"src\" attribute", "plain text isn't allowed in <head> elements", "<html> proprietary attribute \"app\"", "<link> escaping malformed URI reference", "</head> isn't allowed in <body> elements", "<script> escaping malformed URI reference", "discarding unexpected <body>", "'<' + '/' + letter not allowed here", "missing </script>", "proprietary attribute \"autocomplete\"", "trimming empty <i>", "proprietary attribute \"required\"", "proprietary attribute \"placeholder\"", "<ng-include> is not recognized!", "discarding unexpected <ng-include>", "missing </button>", "replacing unexpected button by </button>", "<ey-confirm> is not recognized!", "discarding unexpected <ey-confirm>", "discarding unexpected </ey-confirm>", "discarding unexpected </ng-include>"]

Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
let NERDTreeWinSize = 42
let NERDTreeMinimalUI = 1
let NERDTreeShowHidden = 1
let NERDTreeShowLineNumbers = 1
let NERDTreeHighlightCursorline = 1
let NERDTreeMouseMode = 2
let NERDTreeHijackNetrw = 1
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeIgnore = [
            \ '\~$', '\.pyc$', '\.pyo$', '\.class$', '\.aps',
            \ '\.git', '\.hg', '\.svn', '\.sass-cache',
            \ '\.tmp$', '\.gitkeep$', '\.idea', '\.vcxproj',
            \ '\.bundle', '\.DS_Store$', '\tags$']
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

nnoremap <silent> ` :NERDTreeToggle<CR>

Plug 'majutsushi/tagbar'
let g:tagbar_width = 40
let g:tagbar_autofocus = 1

nnoremap <F7> :TagbarToggle<CR>

Plug 'wesleyche/SrcExpl'
let g:SrcExpl_winHeight = 25
let g:SrcExpl_refreshTime = 100
let g:SrcExpl_jumpKey = "<ENTER>"
let g:SrcExpl_gobackKey = "<SPACE>"
let g:SrcExpl_pluginList = [
            \ "_NERD_tree_",
            \ "__Tagbar__",
            \ "Source_Explorer"
            \ ]
let g:SrcExpl_searchLocalDef = 1
let g:SrcExpl_isUpdateTags = 0
let g:SrcExpl_nestedAutoCmd = 1
let g:SrcExpl_updateTagsCmd = "ctags --sort=foldcase -R ."
let g:SrcExpl_updateTagsKey = "<C-F12>"
let g:SrcExpl_prevDefKey = "<C-F3>"
let g:SrcExpl_nextDefKey = "<C-F4>"

nnoremap <F8> :TagbarToggle<CR>:NERDTreeToggle<CR>:SrcExplToggle<CR><C-W><C-L>

autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

function! CheckLeftBuffers()
    if tabpagenr('$') == 1
        let i = 1
        while i <= winnr('$')
            " echom getbufvar(winbufnr(i), '&buftype')
            if getbufvar(winbufnr(i), '&buftype') == 'help' ||
                        \ getbufvar(winbufnr(i), '&buftype') == 'quickfix' ||
                        \ exists('t:NERDTreeBufName') &&
                        \   bufname(winbufnr(i)) == t:NERDTreeBufName ||
                        \ bufname(winbufnr(i)) == '__Tagbar__' ||
                        \ bufname(winbufnr(i)) == 'Source_Explorer' ||
                        \ getwinvar(i, 'SrcExpl') == 1
                let i += 1
            else
                break
            endif
        endwhile
        if i == winnr('$') + 1
            qall
        endif
        unlet i
    endif
endfunction
autocmd BufEnter * call CheckLeftBuffers()

Plug 'ludovicchabant/vim-gutentags'
" let g:gutentags_trace = 1
let g:gitroot = substitute(system('git rev-parse --show-toplevel 2>/dev/null'), '[\n\r]', '', 'g')
if g:gitroot !=# ''
    let g:gutentags_cache_dir = g:gitroot .'/.git/tags'
else
    let g:gutentags_cache_dir = $HOME .'/.cache/guten_tags'
endif
let g:gutentags_exclude_project_root = ['/usr/local', $HOME]
let g:guten_tags_file_list_command = {
            \ 'markers': {
            \ '.git': 'git ls-files',
            \ },
            \ }
let g:gutentags_resolve_symlinks = 1
let g:gutentags_generate_on_missing =1
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_write = 1

if exists(':terminal')
    if has('nvim-0.4.0') || has('patch-8.2.191')
        Plug 'chengzeyi/multiterm.vim'
        " Put the following lines in your configuration file to map <F12> to use Multiterm
        nmap <F12> <Plug>(Multiterm)
        " In terminal mode `count` is impossible to press, but you can still use <F12>
        " to close the current floating terminal window without specifying its tag
        tmap <F12> <Plug>(Multiterm)
        " If you want to toggle in insert mode and visual mode
        imap <F12> <Plug>(Multiterm)
        xmap <F12> <Plug>(Multiterm)
    endif
endif

Plug 'Yggdroot/indentLine'
let g:indentLine_setConceal = 0

Plug 'scrooloose/nerdcommenter'
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDDefaultAlign = 'left'
let g:NERDAltDelims_java = 1
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 1

Plug 'junegunn/vim-easy-align'
xmap ga <Plug>(EasyAlign)
nnoremap ga <Plug>(EasyAlign)

Plug 'alvan/vim-closetag'
let g:closetag_filenames = '*.html,*.js,*.jsx'

Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-endwise'

Plug 'othree/html5.vim', { 'for': ['html', 'djangohtml'] }
Plug 'hail2u/vim-css3-syntax', { 'for': ['html', 'css', 'sass', 'scss', 'less', 'djangohtml'] }
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'cakebaker/scss-syntax.vim', { 'for': ['scss', 'sass'] }
Plug 'lilydjwg/colorizer', { 'for': ['css', 'sass', 'scss', 'less', 'html', 'djangohtml'] }
Plug 'othree/javascript-libraries-syntax.vim', { 'for': ['javascript', 'html'] }
Plug 'othree/yajs.vim', { 'for': ['javascript', 'html'] }
Plug 'othree/es.next.syntax.vim', { 'for': ['javascript', 'html'] }
Plug 'othree/jspc.vim', { 'for': ['javascript', 'html'] }
Plug 'isRuslan/vim-es6', { 'for': ['javascript', 'html'] }
Plug 'Quramy/tsuquyomi', { 'for': 'typescript' }
Plug 'Quramy/vim-js-pretty-template', { 'for': 'typescript' }
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
Plug 'jason0x43/vim-js-indent', { 'for': ['javascript', 'typescript'] }
Plug 'neoclide/vim-jsx-improve', { 'for': ['jsx', 'javascript.jsx'] }

Plug 'Vimjas/vim-python-pep8-indent', { 'for': ['python', 'python3', 'djangohtml'] }
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

Plug 'hallison/vim-markdown', { 'for': 'markdown' }

Plug 'elzr/vim-json', { 'for': 'json' }
let g:vim_json_syntax_conceal = 0

Plug 'stephpy/vim-yaml'
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
