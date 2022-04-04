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

    let word=expand("<cfile>")

    let crt_word_start = match(s[:c], in.'\+$')

    " let crt_word_end  = match(s, in.out, crt_word_start)
    " use below instead of above to acommodate for 'iskeyword' vim setting
    let crt_word_end  = strlen(word)+crt_word_start-1

    let s2 = (crt_word_start>0 ? s[:crt_word_start-1] : '')
                \ . a:str
                \ . (crt_word_end==-1 ? '' : s[crt_word_end+1:])
    call setline(l, s2)
endfunction

function! s:replaceVisualSelectionWithString(str)
    let selection=s:get_visual_selection()

    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    if line("'<") == line("'>")
        " only considered single line case
        let s = getline('.')
        let s2 = (column_start>0 ? s[:column_start-2] : '')
                    \ . a:str
                    \ . (column_end==-1 ? '' : s[column_end:])
        call setline(line_start, s2)
    else
        return
    endif
endfunction

function! s:handleLinkPath(path)
    echom ""
    let word=expand("<cfile>")
    let link = '[' . word . '](/' . a:path . ')'
    " echom link
    call s:replaceCurrentWordWithString(link)
endfunction

function! s:handleLinkPathVisual(path)
    let selection=s:get_visual_selection()
    let link = '[' . selection . '](/' . a:path . ')'
    call s:replaceVisualSelectionWithString(link)
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

function! s:get_visual_selection()
    " credit to xolox@stackoverflow
    " https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript

    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

function! s:vimwikiFzfLink(visual)
    if vimwiki#vars#get_bufferlocal('wiki_nr') == -1
        nunmap <buffer> <CR>
        return
    endif
    let on_link = s:cursorOnVimwikiLink()
    if on_link !=? ''    " cursor is indeed on a link
        if a:visual | return | else | call vimwiki#base#follow_link('nosplit', 0, 1) | endif
    else
        let wikipath=vimwiki#vars#get_wikilocal("path")
        if a:visual
            if line("'<") == line("'>")
                " action undefined for multi-line visual mode selections
                let search=s:get_visual_selection()
                let sink='s:handleLinkPathVisual'
            endif
        else
            let search=expand("<cfile>")
            let sink='s:handleLinkPath'
        endif

        " calls FZF and feeds resulting filename to the handlePath function
        call fzf#run(fzf#wrap({'source': 'rg --follow --files', 'sink': function(sink), 'dir': wikipath, 'options':  '-i --no-multi --query ' . '"' . search . '"' }))
    endif
endfunction

command! VimwikiFzfLink  call s:vimwikiFzfLink(0)
command! VimwikiFzfLinkV call s:vimwikiFzfLink(1)

if !exists("no_plugin_maps") && !exists("vimwiki_fzf_link_no_maps")
    augroup VimwikiFzfLink
        autocmd!
        " autocmd BufEnter * call CheckVimwikiFzfLink()

        " unbind <CR> from vimwiki
        autocmd FileType markdown nnoremap <buffer> łwf <Plug>VimwikiFollowLink
        autocmd FileType markdown vnoremap <buffer> łwf <Plug>VimwikiNormalizeLinkVisualCR

        autocmd Filetype markdown nnoremap <buffer> <silent> <CR> :VimwikiFzfLink<CR>
        autocmd Filetype markdown vnoremap <buffer> <silent> <CR> :<C-U>VimwikiFzfLinkV<CR>
    augroup END
endif

let &cpo = s:save_cpo
unlet s:save_cpo
