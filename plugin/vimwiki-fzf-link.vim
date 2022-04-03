" Vim filetype plugin for creating vimwiki links with fzf
" Last Change: 2022 April 01
" Maintainer: Alexander Moortgat-Pick <moortgat.pick@gmail.com>
" License: Copyright (c) Alexander Moortgat-Pick.
"          Distributed under the same terms as Vim itself.
"          see :help license

if exists("g:loaded_vimwiki_fzf_link")
    finish
endif
let g:loaded_vimwiki_fzf_link = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:replaceCurrentWordWithString(str)
    " adapted from https://github.com/LucHermitte/lh-misc/blob/master/plugin/vim-tip-swap-word.vim
    let s = getline('.')
    let l = line('.')
    let c = col('.')-1
    let in  = '\w'
    let out = '\W'

    let crt_word_start = match(s[:c], in.'\+$')
    let crt_word_end  = match(s, in.out, crt_word_start)
    let s2 = (crt_word_start>0 ? s[:crt_word_start-1] : '')
                \ . a:str
                \ . (crt_word_end==-1 ? '' : s[crt_word_end+1:])
    call setline(l, s2)
endfunction

function! s:handleLinkPath(path)
    let word=expand("<cfile>")
    let link = '[' . word . '](/' . a:path . ')'
    call s:replaceCurrentWordWithString(link)
endfunction

function! s:cursorOnVimwikiLink()
    " extracted from vimwiki#base#follow_link
    " try WikiLink
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink')),
                \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'))
    " try WikiIncl
    if lnk ==? ''
        let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_global('rxWikiIncl')),
                    \ vimwiki#vars#get_global('rxWikiInclMatchUrl'))
    endif
    " try Weblink
    if lnk ==? ''
        let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWeblink')),
                    \ vimwiki#vars#get_syntaxlocal('rxWeblinkMatchUrl'))
    endif

    if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
        " markdown image ![]()
        if lnk ==# ''
            let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxImage')),
                        \ vimwiki#vars#get_syntaxlocal('rxWeblinkMatchUrl'))
            if lnk !=# ''
                if lnk !~# '\%(\%('.vimwiki#vars#get_global('web_schemes1').'\):\%(\/\/\)\?\)\S\{-1,}'
                    " prepend file: scheme so link is opened by sytem handler if it isn't a web url
                    let lnk = 'file:'.lnk
                endif
            endif
        endif
    endif
    return lnk
endfunction

function! s:vimwikiFzfLink()
    if vimwiki#vars#get_bufferlocal('wiki_nr') == -1
        nunmap <buffer> <CR>
        return
    endif
    let on_link = s:cursorOnVimwikiLink()
    if on_link !=? ''    " cursor is indeed on a link
        call vimwiki#base#follow_link('nosplit', 0, 1)
    else
        let word=expand("<cfile>")
        let wikipath=vimwiki#vars#get_wikilocal("path")

        " calls FZF and feeds resulting filename to the handlePath function
        call fzf#run(fzf#wrap({'source': 'rg --follow --files', 'sink': function('s:handleLinkPath'), 'dir': wikipath, 'options':  '-i --no-multi --query ' . '"' . word . '"' }))
    endif
endfunction

command! VimwikiFzfLink call s:vimwikiFzfLink()

augroup VimwikiFzfLink
    autocmd!
    " autocmd BufEnter * call CheckVimwikiFzfLink()

    " unbind <CR> from vimwiki
    autocmd FileType markdown nnoremap <buffer> łwf <Plug>VimwikiFollowLink
    autocmd Filetype markdown nnoremap <buffer> <silent> <CR> :VimwikiFzfLink<CR>
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
