---
title: 使用 Hexo 和 Github 搭建静态博客
date: 2016-04-27 15:22:29
permalink: 1461744842678
tags:
- Hexo
- Github
---

## 前提

- 本地安装好了 node，git 等工具
- 有 Github 账户，并且配置好了 ssh key
- 注册一个 [Github page](https://pages.github.com/)

## Hexo 基本命令

```bash
npm install hexo-cli -g # 安装 hexo
hexo init gitnote # 初始化一个项目 gitnote
hexo new "输入你文章的标题" # 初始化一篇文章
hexo server # 本地预览
hexo generate # 生成静态文件
hexo deploy # 部署到远程，需要先配置 Github 账户

hexo generate --watch # 监视文件改动，并重新生成静态文件
hexo deploy --generate # generate 之后紧接着 deploy
```

## Github 的部署配置

```bash
npm install hexo-deployer-git --save # 先安装 git 插件
```
配置 _config.yml：

```bash
deploy:
  type: git
  repo: git@github.com:yyqian/yyqian.github.io.git
  branch: master
  message:
```

## 实时预览

有时我们希望能实时地预览每次改动，但是 `hexo server` 命令并不支持监视文件改动，因此，我们需要运行两个进程来实时地预览改动后的样子：

```bash
# 命令行 1：
hexo generate --watch
# 命令行 2：
hexo server
```

## 同步项目文件夹

如果我们想在多台电脑上写作，同步项目文件夹是个问题，如果通过同步盘等方式，node_modules 这种文件夹会严重地拖慢同步速度。因此，我们还是用 Git 来完成：

- 先在 Github 上的 git page 仓库中建立一个新的分支，我这儿命名为 hexo
- 在 Github 中将这个分支设置为默认分支
- 在本地 clone 这个分支，然后清空这个分支的内容，把项目文件夹的内容都挪到这个分支中来

这样我们只要在每个电脑上克隆 Github Page 仓库的 hexo 分支，就能同步项目文件夹，而生成的静态文件内容，则发布到 master 分支中，而 Github Page 也是提取 master 分支内容来展示的，所以两者互不影响。