---
title: Archlinux安装记录和一些配置
tags:
---

安装环境：

硬件：Thinkpad X61s 
系统：Archlinux 2015.06.01

U盘制作见：https://wiki.archlinux.org/index.php/USB_flash_installation_media

详细的安装方法见：https://wiki.archlinux.org/index.php/Beginners'_guide

### 启动，开始连接网络

wifi-menu

### 分区

lsblk #确认安装的盘符 
parted /dev/sdX 
mklabel msdos 
mkpart primary ext3 1MiB 20GiB 
set 1 boot on 
mkpart primary ext3 20GiB 100% 
quit

### 格式化

lsblk /dev/sdX 
mkfs.ext4 /dev/sdX1
mkfs.ext4 /dev/sdX2

### mount盘符

mount /dev/sdX1 /mnt
mkdir -p /mnt/home 
mount /dev/sdX2 /mnt/home

### 开始安装

vi /etc/pacman.d/mirrorlist #选网易的
pacstrap -i /mnt base base-devel

genfstab -U -p /mnt >> /mnt/etc/fstab 
cat /mnt/etc/fstab

### 配置新系统

arch-chroot /mnt /bin/bash
vi /etc/locale.gen #选en_US和zh_CN
locale-gen 
echo LANG=en_US.UTF-8 > /etc/locale.conf 
export LANG=en_US.UTF-8 
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 
hwclock --systohc --utc 
echo myhostname > /etc/hostname 
nano /etc/hosts #把myhostname加在localhost后面

pacman -S iw wpa_supplicant dialog #安装wifi

passwd 
pacman -S grub os-prober 
grub-install --recheck /dev/sda 
grub-mkconfig -o /boot/grub/grub.cfg

exit 
umount -R /mnt 
reboot

### 安装之后的配置

useradd -m -G wheel -s /bin/bash username 
passwd username 
visudo #新建username ALL=(ALL) NOPASSWD: ALL
exit #relogin

ip link #查看无线网卡名称 
sudo wifi-menu wls3
sudo pacman -Syu
sudo pacman -S vim git openssh

vi ~/.bashrc #添加alias vi='vim'和alias ll='ls -all --color=auto'

sudo vi /etc/default/grub #GRUB_TIMEOUT设置为0
sudo grub-mkconfig -o /boot/grub/grub.cfg

### SSH安全配置

参照：http://yyqian.com/post/1433494907104

Arch下面重启服务使用：`sudo systemctl restart sshd`


### 其他一些软件

MongoDB

sudo pacman -S mongodb 
sudo systemctl start mongodb

Node

参照：http://fengmk2.com/blog/2014/03/node-env-and-faster-npm.html

 