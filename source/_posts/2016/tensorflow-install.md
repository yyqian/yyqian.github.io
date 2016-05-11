---
title: 配置 GPU 加速的 Tensorflow
date: 2016-05-11 13:38:07
permalink: 1462945087000
tags: [Tensorflow, CUDA, Centos, 机器学习]
---

最近想了解下热门的深度学习、神经网络，于是选择了 Tensorflow 作为工具。这里我们就先来安装下 Tensorflow。

Tensorflow 本身安装很容易，不过想要利用 GPU 多核的优势来加速计算，就要先安装显卡驱动和 CUDA，这两者的安装是有点麻烦的。

前提条件：

- 操作系统：Centos 7
- 硬件环境：Nvidia 的显卡（请自行查询是否支持 CUDA）

## 准备工作

yum 更新下，安装 Development Tools 软件包

```
sudo yum update
sudo yum group install 'Development Tools'
```

## 安装 Nvidia 驱动

Nvidia 官网上有显卡驱动的软件包下载，但安装前需要繁琐的配置，这里我们选择更简单的方式，通过软件源来安装：

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
<!-- more -->
下面的 CUDA 软件包中也包含了显卡驱动，但我没尝试过直接用这个包来安装驱动。

## 安装 CUDA

先去 Nvidia 上下载 CUDA 包，我下载的是 7.5 版本的，然后就可以进行安装：

```
sudo sh cuda_xxxx.run
```

这里会询问是否要安装驱动，因为前面我们已经安装好了驱动，所以这里别选

记住 CUDA 的根目录是在 /usr/local/cuda-7.5 和 /usr/local/cuda，后者是前者的一个链接

安装完后，配置环境变量，在 ~/.bash_profile 中添加：

```
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64"
export CUDA_HOME=/usr/local/cuda
# PATH 变量添加 /usr/local/cuda/bin
```

## 安装 cudnn

Tensorflow 还需要 cudnn 插件，这个可以从 Nvidia 官网下载，我下的版本是 v4，下载完后解压并复制到相应的文件夹。

```
tar xvzf cudnn-7.5-linux-x64-v4.tgz
sudo cp cudnn-7.5-linux-x64-v4/cudnn.h /usr/local/cuda/include
sudo cp cudnn-7.5-linux-x64-v4/libcudnn* /usr/local/cuda/lib64
sudo chmod a+r /usr/local/cuda/lib64/libcudnn*
```

## 安装 pip

我们将用 pip 来安装 Tensorflow，所以要先安装 pip。

```
sudo yum install python-pip python-devel
sudo pip install --upgrade pip
```

## 安装 Tensorflow

确保前面的显卡驱动、CUDA toolkit 7.5 和 CuDNN v4 安装好了，然后就可以用 pip 来安装了。

```
sudo pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.8.0-cp27-none-linux_x86_64.whl
```

## 安装 matplotlib

我们做数据相关的工作时，常常需要将数据可视化，matplotlib 可以进行一些简单的画图操作，所以最好安装一下。

如果直接用 pip 来安装，会提示缺少两个依赖的库，这是因为这两个依赖是 pip 解决不了的，需要 yum 来安装：

```
sudo yum install freetype-devel
sudo yum install libpng-devel
sudo pip install matplotlib
```

至此，CUDA、Tensorflow 以及一些相关的工具就都安装完毕了，我们在启动 Tensorflow 的程序时，会看到一系列 gpu 相关的输出，这就表明 Tensorflow 安装成功，并且已经启用了 GPU 来进行计算。
