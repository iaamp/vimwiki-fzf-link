# vimwiki-fzf-link

[Vim](https://github.com/vim/vim) plugin to create [vimwiki](https://github.com/vimwiki/vimwiki) links with [fzf](https://github.com/junegunn/fzf.vim).

## What it does
This plugin is an extension to vimwiki which allows to create links with the help of fzf (and ripgrep). In vimwiki, links are created as `[[mynote]]` or `[mynote](mynote)` depending on the syntax. If however, you use a non-flat directory structure, this does not work, or more precisely, the created links are not correct.

A partial workaround already exists in typing part of the correct link, e.g. `[mynote](/notes/my` followed by `<C-x><C-f>` mapped to e.g.
`inoremap <expr> <c-x><c-f> fzf#vim#complete#path('rg --files') `. However, this still is cumbersome.

Instead, this plugin replaces the vimwiki function `VimwikiFollowLink` mapped to `<CR>` in the following way:
* if cursor on word but not a link: link selection with fzf
* elif cursor on word that is a link: call `vimwiki#base#follow_link` (same as `VimwikiFollowLink`
* else return

## Installation

#### Using [vim-plug](https://github.com/junegunn/vim-plug)
```
" load after vimwiki/vimwiki and junegunn/fzf.vim
Plug 'iaamp/vimwiki-fzf-link
```

#### Dependencies
* [vimwiki](https://github.com/vimwiki/vimwiki)
* [fzf.vim](https://github.com/junegunn/fzf.vim)
* [fzf](https://github.com/junegunn/fzf)
* [ripgrep](https://github.com/BurntSushi/ripgrep)

## Known Limitations & Future Work
* in non-vimwiki `markdown` files, the first use of `Enter` key is doing nothing (no default behaviour)
* only normal mode
* no setting to disable mapping yet
* no case-resolution for existing and conflicting mappings
* allow defining the source command for the search

#### known conflicts
* anything that maps `<CR>`, including
    * taskwiki

## License

Copyright (c) Alexander Moortgat-Pick.  Distributed under the same terms as Vim itself.
See `:help license`.
