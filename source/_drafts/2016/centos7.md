---
title: centos7
tags:
---

## Dev tools

```
sudo yum group install 'Development Tools'
```

## Windows 双启动

```bash
sudo yum install epel-release
sudo yum install ntfs-3g
sudo vim /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

## 增加新用户

```
useradd xxx
passwd xxx
visudo 然后在文件尾部添加 XXX ALL=(ALL) NOPASSWD: ALL
```

### 解决：-bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory

```
sudo vim /etc/environment
```

添加：

```
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
```

## 更改 SSH 配置

用新账户登录

```
ssh-keygen -t rsa
```

~/.ssh/authorized_keys 中添加允许的 key

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
sudo vim /etc/ssh/sshd_config
PermitRootLogin no //禁止root远程登录
Port 1234 //改成任意非22端口
Protocol 2
PasswordAuthentication no //这个不要轻易设置，禁止使用基于口令认证的登录方式
```

确保 RSAAuthentication 和 PubkeyAuthentication 是 yes

重启服务 sudo service sshd restart

exit，然后用新端口登录：ssh USER@xxx.xxx.xxx.xxx -p 1234
