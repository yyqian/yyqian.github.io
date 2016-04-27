---
title: 如何绑定动态 IP 的域名
date: 2015-06-05 14:11:41
permalink: 1433484701184
tags: 网络
---

最简单的方法就是注册花生壳，然后在路由器的DDNS里设置一下。

这儿的方法主要是针对路由器没有DDNS功能或DDNS无效的情况，实现的方法就是在内网的Linux服务器上定时运行脚本来更新当前的外网IP，步骤如下：

1. 去花生壳注册个账户
2. 申请个免费的“壳域名”，其实就是花生壳的一个二级域名
3. 如果路由器有DDNS设置，那么用上面申请到的信息填写就OK了，不需要以下操作。
4. 在要绑定动态IP的服务器上新建以下脚本：

  其中`USERNAME`, `PASSWORD`, `HOSTNAME`是自己填写的信息，`/PATH/TO/ip.log`是保存日志的文件

  `\#! /bin/bash
  curl -s -w " " http://USERNAME:PASSWORD@ddns.oray.com/ph/update?hostname=HOSTNAME >> /PATH/TO/ip.log
  date >> /PATH/TO/ip.log`

  这个脚本输出的格式是这样的：  
  `nochg XXX.XXX.XXX.XXX Fri Jun  5 12:30:01 CST 2015`

5. 然后`crontab -e`配置一个Crontab让该脚本每隔一段时间运行一下，更新服务器的外网IP:  
  `0,10,20,30,40,50 * * * * sh /PATH/TO/script.sh`  
  这个表示在任何day任何hour的0,10,20,30,40,50分钟运行该脚本，实际就是每隔10分钟更新一下。

6. cron的命令如下`sudo service cron status/stop/start/restart`

7. 如果需要一级域名，那么就把自己的一级域名CNAME到花生壳的二级域名。