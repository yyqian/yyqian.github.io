---
title: Raspberry Pi 交叉编译配置
date: 2014-10-16 16:53:00
permalink: 1413449580000
tags: 树莓派
---

以下所用的配置环境：

* PC端: Ubuntu 14.04 LTS 64-bit
* Raspberry Pi(RPi)端: Raspbian

Raspbian的安装配置参照：[Raspbian安装配置记录](http://blog.yyqian.com/117.html)

[配置C/C++交叉编译环境](http://hertaville.com/2012/09/28/development-environment-raspberry-pi-cross-compiler/)

请仔细阅读以上链接内容，以下仅仅是个人操作记录。

PC端：

	sudo apt-get install build-essential git
	mkdir ~/rpi
	cd ~/rpi
	git clone git://github.com/raspberrypi/tools.git
	vi ~/.bashrc    #最后一行添加export PATH=$PATH:$HOME/Work/RPi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin
	source ~/.bashrc
	arm-linux-gnueabihf-gcc -v                    #检查是否安装成功
	arm-linux-gnueabihf-g++ test.cpp -o test.exe  #写一个test.cpp并尝试编译，生成的test.exe需要拷贝到RPi运行
<!-- more -->
Debian 7默认stable源的libc6版本有可能比较低，需要装testing源的高版本libc6：

	echo 'deb http://ftp.us.debian.org/debian/ testing main contrib non-free' >> /etc/apt/sources.list
	apt-get update
	apt-get install -t testing libc6

[配置Qt4交叉编译环境](http://hertaville.com/2014/04/12/cross-compiling-qt4-app/)

请仔细阅读以上链接内容，以下仅仅是个人操作记录,需要先按照上述步骤配置C/C++交叉编译。

RPi端：

	sudo apt-get install libqt4-dev   #安装Qt4 libraries

PC端：

	arm-linux-gnueabihf-gcc -v   #确认c/c++交叉编译已经成功配置
	sudo apt-get install sshfs   #这是为了远程mount RPi的文件系统，后面的Makefile中会"本地访问"RPi的文件系统
	sudo usermod -a -G fuse XXX  #把XXX改为自己PC端的用户名,为自己增加对mount分区的访问权限
	sudo apt-get install libqt4-dev-bin  #这个是为了安装moc-qt4，貌似是为了将qt相关的.h翻译成gcc可以认识的代码(archlinux下面的话安装qt4)
	mkdir $HOME/Work/RPi/mntrpi       #准备将RPi系统mount到该位置
	sudo sshfs pi@IPADDRESS:/ /home/XXX/Work/RPi/mntrpi/ -o transform_symlinks -o allow_other  #将IPADDRESS替换成RPi的ip地址,XXX替换为自己PC端的用户名
	sudo ln -s $HOME/Work/RPi/mntrpi/usr/lib/arm-linux-gnueabihf/ /usr/lib/arm-linux-gnueabihf
	sudo ln -s $HOME/Work/RPi/mntrpi/lib/arm-linux-gnueabihf/ /lib/arm-linux-gnueabihf
	cd ~/rpi
	wget http://hertaville.com/OTHERFILES/qttest.tar.gz  #下载测试文件
	tar xvzf qttest.tar.gz
	cd ~/rpi/qttest
	make                                     #为RPi编译可执行文件,make之前确保sshfs已经成功
	cp target_bin $HOME/Work/RPi/mntrpi/home/pi   #将可执行文件cp到RPi的~目录下，在桌面环境下运行测试(命令行环境运行会得到连接不上X server的错误)
	sudo umount $HOME/Work/RPi/mntrpi             #不需要编译的时候断开链接

Archlinux下这里有个问题：/lib被链接到了/usr/lib， 因此和debian下的文件系统对应不起来，下面语句无法创建两个链接

	sudo ln -s $HOME/Work/RPi/mntrpi/usr/lib/arm-linux-gnueabihf/ /usr/lib/arm-linux-gnueabihf
	sudo ln -s $HOME/Work/RPi/mntrpi/lib/arm-linux-gnueabihf/ /lib/arm-linux-gnueabihf

我的笨办法是把RPi系统中/usr/lib/arm-linux-gnueabihf/和/lib/arm-linux-gnueabihf/两个文件夹下的内容合并复制到本地系统的一个文件夹中，然后把/usr/lib/arm-linux-gnueabihf指向该文件夹，比如：

	sudo ln -s $HOME/Work/RPi/arm-lib/ /usr/lib/arm-linux-gnueabihf

请仔细读qttest这个测试程序，理解Makefile内容以及程序的结构。如果对Qt4和Makefile不熟，可以参考以下两个链接：
[Makefile](http://www.opensourceforu.com/2012/06/gnu-make-in-detail-for-beginners/),
[Qt4](http://www.zetcode.com/gui/qt4/)

######qcustomplot在交叉编译环境中的配置：
qcustomplot只有2个文件：qcustomplot.h, qcustomplot.cpp。
代码中只需要载入头文件：#include "qcustomplot.h"
编译的时候需要先用moc-qt4对qcustomplot.h进行处理,然后g++编译qcustomplot.cpp,最后链接所有的.o文件。

这是一个Makefile示例文件，根据之前的qttest示例修改的（在INC中添加qcustomplot.h，在SRC中添加qcustomplot.cpp）:

	CXX=arm-linux-gnueabihf-g++

	INCLUDEDIR = ./
	INCLUDEDIR += $(HOME)/rpi/mntrpi/usr/include/qt4/
	INCLUDEDIR += $(HOME)/rpi/mntrpi/usr/include/qt4/QtCore
	INCLUDEDIR += $(HOME)/rpi/mntrpi/usr/include/qt4/QtGui

	LIBRARYDIR = $(HOME)/rpi/mntrpi/usr/lib/arm-linux-gnueabihf/
	LIBRARY +=  QtCore QtGui
	XLINK_LIBDIR += $(HOME)/rpi/mntrpi/lib/arm-linux-gnueabihf
	XLINK_LIBDIR += $(HOME)/rpi/mntrpi/usr/lib/arm-linux-gnueabihf

	INCDIR  = $(patsubst %,-I%,$(INCLUDEDIR))
	LIBDIR  = $(patsubst %,-L%,$(LIBRARYDIR))
	LIB    = $(patsubst %,-l%,$(LIBRARY))
	XLINKDIR = $(patsubst %,-Xlinker -rpath-link=%,$(XLINK_LIBDIR))

	OPT = -O3
	DEBUG = -g
	WARN= -Wall
	PTHREAD= -pthread

	CXXFLAGS= $(OPT) $(DEBUG) $(WARN) $(INCDIR)
	LDFLAGS= $(LIBDIR) $(LIB) $(XLINKDIR) $(PTHREAD)

	INC = qcustomplot.h
	SRC = main.cpp qcustomplot.cpp dsp.cpp

	OBJ = $(SRC:.cpp=.o) $(INC:.h=.moc.o)

	all: $(OBJ)
		$(CXX) $(LDFLAGS) $(OBJ) -o tdlas

	%.moc.cpp: $(INC)
		moc-qt4  $<  -o $@

	%.o:%.cpp
		$(CXX) $(CXXFLAGS)  -c $<  

	clean:
		-rm *.o
		-rm target_bin
