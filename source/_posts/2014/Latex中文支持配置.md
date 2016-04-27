---
title: LaTeX 中文支持配置
date: 2014-07-22 11:07:00
permalink: 1405998420000
tags: LaTeX
---

**LaTeX安装**

运行环境：Ubuntu 14.04/Linux mint 17

    sudo apt-get install texlive-full

**字体安装**

    sudo mkdir /usr/share/fonts/win
    sudo cp *字体文件* /usr/share/fonts/win
    sudo chmod 644 /usr/share/fonts/win/*
    cd /usr/share/fonts/win/
    sudo mkfontscale
    sudo mkfontdir
    fc-cache
    sudo fc-cache -fv

用该命令可以列出系统所有的中文字体：`fc-list :lang=zh-cn`
<!-- more -->
**XeLaTeX中文环境设置**

    \usepackage{fontspec}%使可以设定字型
    \usepackage{xeCJK}%让中英文分开设置
    \setmainfont{Times New Roman}
    \setsansfont[Scale=MatchLowercase]{Arial}
    \setmonofont[Scale=MatchLowercase]{Consolas}
    \setCJKmainfont[BoldFont={Adobe Heiti Std},ItalicFont={Adobe Kaiti Std}]{Adobe Song Std}
    \setCJKsansfont{Adobe Song Std}
    \setCJKmonofont{Adobe Song Std}
    \XeTeXlinebreaklocale "zh" %这行和下行使中文能自动换行
	\XeTeXlinebreakskip = 0pt plus 1pt minus .1pt

**TeX文件编译**

	xelatex ***.tex
