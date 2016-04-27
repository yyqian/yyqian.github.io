---
title: 使用 Gitbook 和 Github 来写作
date: 2016-04-27 15:48:36
permalink: 1461744874666
tags:
- Gitbook
- Github
---

## Gitbook 常用命令

```
npm install gitbook-cli -g # 安装 gitbook
gitbook init # 初始化项目
gitbook serve # 本地预览，支持监视文件改动
gitbook build # 生成静态文件
```

## Gitbook 项目的文件结构

运行 `gitbook init` 命令之后，会得到 README.md 和 SUMMARY.md 两个文件。

**README.md**

这个相当于整本书的简介。例子：

```
# Netty in Action 学习笔记

主要是个人在阅读「Netty in Action」这本书时做的笔记，用于学习和分享。
```

**SUMMARY.md**

这个相当于是整本书的目录。例子：

```
# Summary

* Netty concepts and architecture
    * [Netty—asynchronous and event-driven](part1/chapter1.md)
    * [Your first Netty application](part1/chapter2.md)
* Codecs
    * [The codec framework](part2/chapter10.md)
```

**Markdown 文档**

Markdown 文档的存放应当是和你 SUMMARY.md 中设置的超链接一致的。

## 发布到 Gitbook

个人喜欢先发布到 Github，然后再让 Gitbook 关联 Github 的仓库，具体就是：

- Github 建一个 Gitbook 项目，发布内容到这个仓库
- Gitbook 关联 Github 中的该项目，这样你每次 push 到 Github 仓库， Gitbook 都会自动更新页面