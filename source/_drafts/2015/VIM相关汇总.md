---
title: VIM 相关汇总
date: 2015-03-06 15:19:45
permalink: 1425626385884
tags:
---

Cursor Movement:

	k	Up one line
	j	Down one line 
	h	Left one character
	l	Right one character (or use <Spacebar>)
	w	Right one word
	b	Left one word
    
	e		Move to end of current word
    $		Move to end of current line
    ^		Move to beginning of current line
    +	    Move to beginning of next line
    -		Move to beginning of previous line
    G		Go to last line of the file
    :n		Go to line with this number (:10 goes to line 10)
	<Ctrl>d	Scroll down one-half screen
    <Ctrl>u	Scroll up one-half screen
    <Ctrl>f	Scroll forward one full screen
    <Ctrl>b	Scroll backward one full screen
    )		Move to the next sentence
    (		Move to the previous sentence
    }		Move to the next paragraph
    {		Move to the previous paragraph
    H		Move to the top line of the screen
    M		Move to the middle line of the screen
    L		Move to the last line of the screen
    
Entering, Deleting, and Changing Text:

	i	Enter text entry mode
	x	Delete a character
	dd	Delete a line
	r	Replace a character
	R	Overwrite text, press <Esc> to end
    
    i    Insert text before current character
    a    Append text after current character
    I    Begin text insertion at the beginning of a line
    A    Append text at end of a line
    o    Open a new line below current line
    O    Open a new line above current line
    
Other:

	:set nu		Display line numbers
	:set nonu	Hide line numbers
    
	ZZ		Write (if there were changes), then quit
	:wq		Write, then quit
	:q		Quit (will only work if file has not been changed)
	:q!		Quit without saving changes to file
    
配置~/.vimrc：

	set encoding=utf-8

	set hlsearch        " Highlight search results
	set ignorecase      " Ignore case when searching

	syntax enable       " Enable syntax highlighting
	set shiftwidth=4    " Number of spaces that a <Tab> in the file counts for.
	set tabstop=4       " Number of spaces to use for each step of (auto)indent.
	set autoindent      " Copy indent from current line when starting a new line
	"set si             " Smart indent
	set wrap            " Wrap lines

	set number          " Show line numbers.
	set ruler           " Always show current position
	"set laststatus=2   " Always show the status line

	set history=100     " by default Vim saves your last 8 commands.

	" Return to last edit position when opening files (You want this!)
	autocmd BufReadPost *
    	\ if line("'\"") > 0 && line("'\"") <= line("$") |
    	\ exe "normal! g`\"" |
    	\ endif

`:w !sudo tee`当你用普通用户没有写权限时很好用。

在写Makefile时不要用expandtab，tab替换为空格后会出错。

设置光标返回到文件上次关闭时候的位置：
复制/etc/vim/vimrc中的这一段命令：

	if has("autocmd")
	au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
	\| exe "normal! g'\"" | endif
	endif