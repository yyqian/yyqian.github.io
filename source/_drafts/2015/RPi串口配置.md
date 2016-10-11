---
title: RPi 串口配置
tags:
---

整理自[Link](http://www.hobbytronics.co.uk/raspberry-pi-serial-port)

RPi默认用Serial Port来作为console的I/O，所以我们要禁用它：
Disable Serial Port Login：
把/etc/inittab中的`T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100`注释掉

Disable Bootup Info： 
删掉/boot/cmdline.txt的其中一段，改成dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait

然后重启之后装minicom串口调试：

sudo apt-get install minicom
minicom -b 9600 -o -D /dev/ttyAMA0 #打开串口，用9600波特率

如果调试没问题，可以用C/C++来写程序控制，我这儿用了一个老外写的WiringPi库：
[WiringPi](https://projects.drogon.net/raspberry-pi/wiringpi/serial-library/)

安装见:[Link](https://projects.drogon.net/raspberry-pi/wiringpi/download-and-install/)
