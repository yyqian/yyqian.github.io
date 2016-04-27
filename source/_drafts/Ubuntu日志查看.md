---
title: Ubuntu 日志查看
date: 2015-06-12 09:37:08
permalink: 1434073028903
tags:
---

## 介绍

昨天查看了下公司服务器的日志文件，才发现对外开了22端口之后一直在被攻击，估计是有人在用工具扫描全网段的弱口令。于是改了ssh默认的22端口，登录方式改为密钥登录，果然世界就清净了...

以下是auth.log的部分信息，持续了整整1个月，我的失误...：

    8 May 10 08:18:36 cheerapp sshd[27977]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=180.150.230.214  user=root
    9 May 10 08:18:38 XXX sshd[27977]: Failed password for root from 180.150.230.214 port 2756 ssh2
    10 May 10 08:18:56 XXX sshd[27977]: message repeated 5 times: [ Failed password for root from 180.150.230.214 port 2756 ssh2]
    11 May 10 08:18:56 XXX sshd[27977]: Disconnecting: Too many authentication failures for root [preauth]
    12 May 10 08:18:56 XXX sshd[27977]: PAM 5 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=180.150.230.214  user=root
    13 May 10 08:18:56 XXX sshd[27977]: PAM service(sshd) ignoring max retries; 6 > 3
    14 May 10 08:19:00 XXX sshd[27979]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=180.150.230.214  user=root
    15 May 10 08:19:01 XXX sshd[27979]: Failed password for root from 180.150.230.214 port 3421 ssh2
    16 May 10 08:19:11 XXX sshd[27979]: message repeated 5 times: [ Failed password for root from 180.150.230.214 port 3421 ssh2]
    17 May 10 08:19:11 XXX sshd[27979]: Disconnecting: Too many authentication failures for root [preauth]
    18 May 10 08:19:11 XXX sshd[27979]: PAM 5 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=180.150.230.214  user=root
    19 May 10 08:19:11 XXX sshd[27979]: PAM service(sshd) ignoring max retries; 6 > 3

    265523 Jun 11 19:57:23 XXX sshd[2329]: PAM 2 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=218.87.111.117  user=root
    265524 Jun 11 19:57:23 XXX sshd[2346]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=218.87.111.117  user=root
    265525 Jun 11 19:57:25 XXX sshd[2346]: Failed password for root from 218.87.111.117 port 53632 ssh2
    265526 Jun 11 19:57:29 XXX sshd[2346]: message repeated 2 times: [ Failed password for root from 218.87.111.117 port 53632 ssh2]
    265527 Jun 11 19:57:29 XXX sshd[2346]: Received disconnect from 218.87.111.117: 11:  [preauth]
    265528 Jun 11 19:57:29 XXX sshd[2346]: PAM 2 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=218.87.111.117  user=root
    265529 Jun 11 19:57:30 XXX sshd[2349]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=218.87.111.117  user=root
    265530 Jun 11 19:57:32 XXX sshd[2349]: Failed password for root from 218.87.111.117 port 40134 ssh2
    265531 Jun 11 19:57:36 XXX sshd[2349]: message repeated 2 times: [ Failed password for root from 218.87.111.117 port 40134 ssh2]
    265532 Jun 11 19:57:36 XXX sshd[2349]: Received disconnect from 218.87.111.117: 11:  [preauth]

## 查看日志文件

下面我们来查看一下有哪些常用的日志文件。我用的是Ubuntu 14.04，日志位于`/var/log`，我们将主要查看以下几个文件

### wtmp和utmp

这两个文件记录了登录过的用户，但不能直接查看这两个文件，我们需要用下面的命令：

* `who     #查看当前登录的用户`
* `last      #查看最近登录的用户`
* `lastlog #查看所有用户最近一次登录的时间和IP`

### auth.log

这个可以直接查看用户登录的情况