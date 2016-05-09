---
title: Let's Encrypt 在 Centos 和 Nginx 中的部署
date: 2016-05-06 15:28:29
permalink:
tags:
---

## 前提

- 把你的域名解析到主机的 IP 上，因为 Let's Encrypt 服务器在给你发证书的时候，会检查这个域名是不是你持有
- 已经安装好 Nginx


## 安装 Let's Encrypt 客户端

首先安装 git 和 bc，然后克隆 Let's Encrypt 的代码到 /opt/letsencrypt 文件夹

```
sudo yum -y install git bc
sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
```

你可能需要安装所有的依赖

```
sudo /opt/letsencrypt/letsencrypt-auto --help
```

## 获取证书

我们将使用 standalone 的方式来获取证书。在这之前我们需要先把 Nginx 服务停掉，让 standalone 服务器直接占用 80 端口来等待 Let's Encrypt 服务端的验证.

这里我们假设你的域名是 example.com，你需要在这把子域名也写上

```
sudo systemctl stop nginx
sudo /opt/letsencrypt/letsencrypt-auto certonly --standalone -d example.com -d www.example.com -d blog.example.com
sudo systemctl start nginx
```

获取成功的证书会存放在 /etc/letsencrypt/live/example.com 文件夹中

## 生成 Strong Diffie-Hellman Group

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

新建 example-redirect.conf 文件，用来重定向 http 连接

```
server {
        listen 80;
        server_name example.com www.example.com;
        return 301 https://$server_name$request_uri;
}
```

然后重启 Nginx 服务

```
systemctl restart nginx
exit
```

## 参考

https://www.nginx.com/blog/free-certificates-lets-encrypt-and-nginx/

https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-centos-7

https://letsencrypt.org/getting-started/
