---
title: Raspbian 安装配置
tags:
---

######Raspbian:

Raspberry Pi(树莓派)以下简称RPi。Raspbian是RPi官网推荐的linux发行版本，基于Debian，对RPi做了很多优化，但预装了很多用于编程教学的软件和一些GUI界面，所以比较担心会拖累系统，本来打算换Archlinux的，但又看到有人benchmark得到的结果还不如Raspbian（可能是因为没有优化），所以最后决定重装Raspbian并精简系统。

######系统安装：

follow: http://www.raspberrypi.org/documentation/installation/installing-images/linux.md

PC端：

lsblk #查看microSD卡的位置，如果已经mount了，下一步要umount所有SD卡的分区
sudo umount /dev/sdb1 #假设SD卡位置是sdb，只有一个分区sdb1
sudo dd bs=4M if=raspbian.img of=/dev/sdb #复制镜像到SD卡，if=镜像位置，of=SD卡位置
sync #确认输出缓存都已经存到SD卡里了，拔掉SD卡

如果是Mac OS：

diskutil list
diskutil unmountDisk /dev/diskX
sudo dd bs=1m if=raspbian.img of=/dev/diskXX

######系统配置：

系统第一次启动会自动启动raspi-config，下面将对RPi进行初始设置。

1 Expand Filesystem, 建议
2 Change User Password, 建议
3 Enable Boot to Desktop/Scratch，可选，我选的是默认的text console
4 Internation...，建议，Local选en_US.UTF-8 UTF-8,Timezone选Asia->Shanghai,Keyboard选Generic 105-key->Other->English(US)
5,6,7,9可以不管
8 Advanced Options，可选，SSH建议打开，其他的不需要可以关了
到这儿系统安装配置就结束了，在命令行环境下输入startx便可以启动桌面环境。以下精简仅仅是个人需要，不建议照做。

###### 配置网络

如果需要wifi，确保已经安装`wpasupplicant`，然后修改`/etc/network/interfaces`:

#static IP:
allow-hotplug wlan0
iface wlan0 inet static
address 192.168.1.88
netmask 255.255.255.0
gateway 192.168.1.1
dns-nameservers 192.168.1.1
wpa-ssid XXXX
wpa-psk YYYY

#DHCP:
allow-hotplug eth0
iface eth0 inet dhcp

###### 改软件源

vi /etc/apt/sources.list

deb http://mirrors.ustc.edu.cn/raspbian/raspbian/ wheezy main contrib non-free rpi
deb-src http://mirrors.ustc.edu.cn/raspbian/raspbian/ wheezy main contrib non-free rpi
deb http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ wheezy main contrib non-free rpi
deb-src http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ wheezy main contrib non-free rpi
deb http://mirrors.neusoft.edu.cn/raspbian/raspbian/ wheezy main contrib non-free rpi
deb-src http://mirrors.neusoft.edu.cn/raspbian/raspbian/ wheezy main contrib non-free rpi

USTC的比较好

######系统精简：

在更新系统之前，先卸载掉一些不需要的软件，比如说wolfram-engine,scratch,sonic-pi，否则更新的时间会很长。

RPi端：

sudo apt-get remove --purge wolfram-engine scratch sonic-pi #这三个分别是mathmatica，儿童编程教学软件，声音编程软件
sudo apt-get remove --purge desktop-base lightdm lxappearance lxde-common lxde-icon-theme lxinput lxpanel lxpolkit lxrandr lxsession-edit lxshortcut lxtask lxterminal #一些lxde桌面相关的，如果不需要复杂的桌面环境的话
sudo apt-get autoremove #这个慎重，不保证不出问题
sudo apt-get update && sudo apt-get dist-upgrade #更新系统

其他的可以参考：http://shumeipai.nxez.com/2013/08/25/remove-software-for-wheezy-raspbian.html

######可选软件安装：

RPi端：`sudo apt-get install ttf-wqy-microhei #中文字体`

######SD卡备份/还原：

sdX为SD卡设备名，XXX.gz为备份文件名

sudo dd if=/dev/sdX | gzip>XXX.gz #压缩+备份
sudo gzip -dc XXX.gz | sudo dd of=/dev/sdX #解压+还原