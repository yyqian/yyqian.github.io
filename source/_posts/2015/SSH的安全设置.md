---
title: SSH 的安全设置
date: 2015-06-05 17:01:47
permalink: 1433494907104
tags: 网络安全
---

首先要注意的一点是，用户名密码登录的方式是不安全的。总体来说，对SSH登录要做以下几点防护：

1. 废除密码登录，改用key登录
2. 禁止root账户远程登录
3. 更改默认的22端口

要注意的是，第一点会导致你只能从事先注册过的电脑上登录服务器，无法从其他电脑登录。如果注册过的电脑都已经丢了密钥，则会导致你无法登录服务器，所以一旦禁止密码登录后，千万要保护好自己的私钥。

具体操作如下：

1. 在本地生成一个key：`ssh-keygen -t rsa`，该命令会生成2个key，一个公钥，一个私钥。公钥是存放在服务器端，可以公开的，私钥存放在本地要保护好。
2. 将本地的`~/.ssh/id_rsa.pub`用scp复制到服务器，并将该文件中的key添加到服务器端的`~/.ssh/authorized_keys`：
  `cat id_rsa.pub >> ~/.ssh/authorized_keys`
3. 最后我们要设置下权限，保证他人不能访问服务器端的`.ssh`文件夹：
  `chmod 700 ~/.ssh`
  `chmod 600 ~/.ssh/authorized_keys`
<!-- more -->
以上第一步完成后最好检查下本地端应有的权限，如果需要的话设置如下：

* `chmod 700 ~/.ssh`
* `chmod 600 ~/.ssh/id_rsa`
* `chmod 644 ~/.ssh/id_rsa.pub`

接下来，修改`/etc/ssh/sshd_config`：

1. `PermitRootLogin no //禁止root远程登录`
2. `Port 1234 //改成任意非22端口`
3. `PasswordAuthentication no //禁止使用基于口令认证的登录方式`
4. 确保`RSAAuthentication`和`PubkeyAuthentication`是`yes`
5. 重启服务`sudo service ssh restart`

下次登录就可以用新的端口啦：`ssh USER@xxx.xxx.xxx.xxx -p 1234`

详细介绍请阅读：https://help.ubuntu.com/community/SSH
