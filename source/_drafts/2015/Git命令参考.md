---
title: Git 命令参考
date: 2015-02-13 01:25:00
permalink: 1423761900000
tags:
---

基础
```
git init
git log
```

状态修改
```
git add [file]
git rm [file] (--cached)
git commit -m "[message]" (-a) # -a 可以跳过暂存区，立即 commit 所有跟踪的文件
git diff (--cached)
git mv [file_from] [file_to]
```

推送/接收
```
git fetch [remote-name] [branch-name] # 抓取
git pull [remote-name] [branch-name] # 抓取并合并
git push [remote-name] [branch-name] # 推送
git remote show [remote-name] # 查看远程库
git clone git@path/to/base.git
git remote add [remote-name] [url]
git remote rm [remote-name]
```

标签
```
git tag # 列出标签
git tag -a v1.4 # 给当前打标签
git tag -a v1.2 9fceb02 # 给之前的提交补标签
git push origin --tags # 默认 push 不会把标签提交上去
```


分支
```
git branch # 查看分支
git branch [branch-name] # 创建分支
git branch -d [branch-name] # 删除分支
git checkout [branch-name] # 切换分支
git checkout -b [branch-name] # 新建并切换到分支
git merge [branch-name] # 合并XX分支到当前分支
```

rebase
```
git checkout experiment
git rebase master
```


sudo git init --bare dolphin-server.git
sudo chown -R git:git dolphin-server.git
sudo chmod 770 -R dolphin-server.git

### hotfix 分支

在需要 hotfix 的时候，从 master 分支新建 hotfix 分支，然后在该分支上工作，修补完成，测试通过，然后切换到 master 分支，并合并推送到服务器，然后将该 hotfix 分支删除

### 处理冲突

git merge 如果出现问题，需要先修改文件，然后再 commit

### 新项目
```
git init
git add .
git commit -m 'initial commit'
git remote add origin [url]
git push origin master
```