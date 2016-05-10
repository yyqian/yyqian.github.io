---
title: Let's Encrypt 在 Centos 和 Nginx 中的部署
date: 2016-05-06 15:28:29
permalink: 1462519709000
tags: [Let's Encrypt, Nginx, Centos]
---

Let’s Encrypt项目旨在让每个网站都能使用HTTPS加密，现在主流浏览器都已经把这个项目的证书添加到了信任列表。

## 前提

- 把你想要加到证书中的域名和子域名都解析到主机的 IP 上
- 已经安装好 Nginx

## 安装 Let's Encrypt 客户端

首先安装 git 和 bc，然后克隆 Let's Encrypt 的代码到 /opt/letsencrypt 文件夹

```
sudo yum -y install git bc
sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
```

安装所有的依赖

```
sudo /opt/letsencrypt/letsencrypt-auto --help
```

## 获取证书

Let's Encrypt 在给你颁发证书的时候，首先会检查你想要加到证书中的域名是否都是你持有的，因此它会挨个访问这些域名，并做一些操作来进行检验。

这里我们将使用 standalone 的方式来获取证书。这种方式需要我们先把 Nginx 服务停掉，让 standalone 服务器直接占用 80 端口来等待 Let's Encrypt 服务端的验证。

我们假设你的域名是 example.com，你需要在这把子域名也写上

```
sudo systemctl stop nginx
sudo /opt/letsencrypt/letsencrypt-auto certonly --standalone -d example.com -d www.example.com -d foo.example.com
sudo systemctl start nginx
```

获取成功的证书会存放在 /etc/letsencrypt/live/example.com 文件夹中
<!-- more -->
## 生成 Strong Diffie-Hellman Group

这个在后面的 Nginx 配置文件中会用到

```
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```

输出会存放在 /etc/ssl/certs/dhparam.pem

## Nginx 中配置 TLS/SSL

进入 Nginx 的配置文件夹

```
cd /etc/nginx/conf.d
sudo su
```

新建 example-ssl.conf 文件，用来配置 SSL

```
server {
        listen 443 ssl;

        server_name example.com www.example.com;

        ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /etc/ssl/certs/dhparam.pem;
        ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security max-age=15768000;

        # The rest of your server block
        root /path/to/root;
        index index.html index.htm;

        location / {
                try_files $uri $uri/ =404;
        }
}
```

新建 ssl-redirect.conf 文件，用来将 http 重定向到 https，这样我们就能强制 https 连接了

```
server {
        listen 80;
        server_name example.com www.example.com;
        return 301 https://$server_name$request_uri;
}
```

然后重载 Nginx 服务

```
systemctl reload nginx
exit
```

## 测试 SSL

可以用以下网址测试 SSL 的安全等级，把 example.com 改成你的域名：

https://www.ssllabs.com/ssltest/analyze.html?d=example.com

![Screen Shot 2016-05-09 at 5.54.40 PM.png](http://cdn.yyqian.com/201605091755-Ft4WzoSKT2HE3Dmx-TpKvrQLwKhj?imageView2/2/w/800/h/600)


## 自动更新证书

这个证书有效期是 3 个月。接下来，我们可以设定一个 crontab 任务，在每个月的 10 号 4:00 更新证书。

新建一个 `/root/le-renew.sh` 脚本

```
#!/usr/bin/env bash
systemctl stop nginx
/opt/letsencrypt/letsencrypt-auto renew --non-interactive >> /var/log/le-renew.log
systemctl start nginx
```

用 `sudo crontab -e` 来新建 root 级别的 cron 任务

```
0 4 10 * * /root/le-renew.sh
```

## 增加或删除子域名

增加子域名：在原有的域名列表后边添加新的子域名就行

```
sudo /opt/letsencrypt/letsencrypt-auto certonly --standalone -d example.com -d www.example.com -d blog.example.com
```

Let’s Encrypt 貌似还不能删除子域名，如果在原有列表上删除子域名，它会新建一套新的证书，不会覆盖原有的证书，我暂时的做法是把 `/etc/letsencrypt` 文件夹清除，然后重新生成所有的证书。

## 参考链接

https://www.nginx.com/blog/free-certificates-lets-encrypt-and-nginx/

https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-centos-7

https://letsencrypt.org/getting-started/
