---
title: Centos 7
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

## 安装 Docker

[Docker](https://docs.docker.com/engine/installation/linux/centos/)

## 增加新用户

```
useradd xxx
passwd xxx
visudo 然后在文件尾部添加 XXX ALL=(ALL) NOPASSWD: ALL
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

## 安装 Nvidia 驱动

```
# 安装 elrepo 源
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
# 探测要安装的包
sudo yum install nvidia-detect
nvidia-detect
# 安装
sudo yum install kmod-nvidia
# 最后重启，然后检查是否安装成功
ls -la /dev | grep nvidia
```

## 安装 CUDA

```
sudo sh cuda_xxxx.run
```

前面已经安装好了驱动，这里别选安装驱动

记住 CUDA 的根目录是在 /usr/local/cuda-7.5 和 /usr/local/cuda，后者是一个链接

在 ~/.bash_profile 中添加：

```
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64"
export CUDA_HOME=/usr/local/cuda
```

PATH 变量添加 /usr/local/cuda/bin

## 安装 cudnn

```
tar xvzf cudnn-7.5-linux-x64-v4.tgz
sudo cp cudnn-7.5-linux-x64-v4/cudnn.h /usr/local/cuda/include
sudo cp cudnn-7.5-linux-x64-v4/libcudnn* /usr/local/cuda/lib64
sudo chmod a+r /usr/local/cuda/lib64/libcudnn*
```

## 安装 pip

```
sudo yum install python-pip python-devel
sudo pip install --upgrade pip
```

## 安装 Tensorflow

确保 CUDA toolkit 7.5 和 CuDNN v4 安装好了。

```
sudo pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.8.0-cp27-none-linux_x86_64.whl
```

## 安装 matplotlib

matplotlib 有两个依赖是 pip 解决不了的，需要 yum 来安装：

```
sudo yum install freetype-devel
sudo yum install libpng-devel
sudo pip install matplotlib
```

### 解决阿里云上的问题

```
-bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
```

在 /etc/environment 中添加：

```
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
```
