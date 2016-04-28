---
title: Nginx 笔记
date: 2015-03-27 17:30:31
permalink: 1427448631060
tags:
---

nginx在Ubuntu下安装很简单：`sudo apt-get install nginx`

首先配置：`/etc/nginx/nginx.conf`

#### main

[user](http://nginx.org/en/docs/ngx_core_module.html#user)   
nginx的worker进程所使用的用户名

[worker_processes](http://nginx.org/en/docs/ngx_core_module.html#worker_processes)   
进程数，取决于很多因素，可以先设置为CPU的核心数

**pid**   
存process ID of the main process

#### events

###### use    
`uname -r`显示linux内核，如果高于2.6，可以使用`use epoll;`

###### worker_connections    
Sets the maximum number of simultaneous connections that can be opened by a worker process.

###### accept_mutex
如果worker_processes>1，设置为on，否则为off

接下来配置：`/etc/nginx/sites-available/*`

`listen 80 default_server;`   
监听来自所有IP，端口为80的访问，如果没有找到匹配的server，就默认使用该server

`root /path/to/homepage`   
如果下面location中没有配置root，则使用该root位置

`index index.html index.htm`   
默认页面设置

`server_name domain.com *.domain.com`   
设置监听的域名以及子域名

## SSL配置

    server {
      listen              443 ssl;
      server_name         www.example.com;
      ssl_certificate     www.example.com.crt;
      ssl_certificate_key www.example.com.key;
    }

ssl_certificate是公钥，ssl_certificate_key是私钥

具体见http://nginx.org/en/docs/http/configuring_https_servers.html
