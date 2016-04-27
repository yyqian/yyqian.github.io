---
title: Ubuntu 相关
date: 2015-02-06 01:25:00
permalink: 1423157100000
tags:
---

使用的版本：14.04.1 LTS

#####干净安装：
先装Ubuntu Server，再装桌面：`sudo apt-get install --no-install-recommends ubuntu-desktop`

如果显卡是独立显卡，安装完后可能无法顺利启动，因此在grub启动项按`e`进行编辑，在nomodeset前添加quiet splash，然后F10启动，顺利启动后先装桌面，再安装显卡的闭源驱动（预先下载好）。

#####中文输入法安装：
1. 安装语言包：选择`System Settings-->Language Support-->Install/Remove Languages`，添加`Chinese(Simplified)`
2. 安装IBus拼音：`sudo apt-get install ibus-pinyin`
3. 重启：`sudo reboot`
4. 添加输入法：`System Settings-->Text Entry`，添加`Chinese(Pinyin)`，更改快捷键`Super+Space`为`Ctrl+Space`

#####网络设置
如果需要wifi，先安装`wpasupplicant`，然后在`/etc/network/interfaces`中添加：

	#auto eth0
    allow-hotplug eth0
	iface eth0 inet dhcp
    
	#auto wlan0
	allow-hotplug wlan0
	iface wlan0 inet dhcp
	wpa-ssid 网络名称
	wpa-psk 密码

如果设置为静态IP(以eth0为例)：

	allow-hotplug eth0
	iface wlan0 inet static
    address 192.168.1.3
	netmask 255.255.255.0
	gateway 192.168.1.1
	dns-nameservers 8.8.8.8 8.8.4.4

然后可以手动启动：`sudo ifup eth0`或者`sudo ifup wlan0`

`auto`还是`allow-hotplug`可以看情况，如果同时设成auto和dhcp，而开机没有插网线或开wifi的话，系统则会等待dhcp响应超时。

详细配置可参考：https://www.debian.org/doc/manuals/debian-reference/ch05.en.html

#####常用软件tips
######byobu
* 横分屏：`ctrl-A |`
* 竖分屏：`ctrl-A %`
* 切换分屏：`ctrl-A 箭头` 或 `shift-箭头`
* 新建屏幕：`F2`
* 切换屏幕：`F3 F4`
* 关闭屏幕或分屏：`ctrl-d`

######gurb
更改启动配置：

1. `sudo vi /etc/default/grub`
2. `sudo update-grub`

#####Linux tips
* 切换文字终端：`ctrl-alt-F1~6`
* 切换图形终端：`ctrl-alt-F7`