---
title: AWS 管理
tags:
---

## EC2

我这里选择的是 Ubuntu 16.04 LTS，t2.micro 配置。

控制台中需要进行配置的是 Security Groups，也就是防火墙，新建一个 profile，然后把想开的端口都开出来。

然后 SSH 登录，先设置下 locale，在`/etc/environment` 文件中添加并重启：

```
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
```

配置时区：

```
sudo dpkg-reconfigure tzdata # 选择 Asia/Shanghai
```

装一些常用的软件(Java, Nginx)：

```
sudo apt-get update
sudo apt-get upgrade
sudo reboot
sudo apt-get install default-jdk nginx
```

装 nvm 和 nodejs：

```
sudo apt-get install build-essential libssl-dev
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash
exit
nvm install ****

```

配置 Nginx:

```
systemctl status nginx # 检查 Nginx 运行状态
# /etc/nginx/sites-available 文件夹中新建一个配置文件
# /etc/nginx/sites-enabled 文件夹中用 `ln -s` 链接过来
sudo systemctl reload nginx
```

## RDS

我这里选择的 MySQL 版本是 MySQL 5.6.27，db.t2.micro 配置。

启动完之后主要有两个地方要配置：防火墙和 MySQL 参数。按照以下步骤新建好 profile，然后让 Instance 调用这些配置并重启就可以了。

### 防火墙（Security Groups）

我这个配置的 RDS 估计就是在 EC2 上跑的 MySQL，所以 Security Groups 用的也是 EC2 的。因此防火墙设置在 EC2 中进行。

EC2 的 Security Groups 中新建一个 Security Group：

- Group Name: RDS
- Inboud: Type: MYSQL/Aurora, Port: 3306, Source: 0.0.0.0/0

以上实际就是允许所有人连接该 RDS，便于在开发阶段操作

### MySQL 参数

这个在 RDS 的 Parameter Groups 中进行操作：

- 新建一个 Parameter Group，命名自定
- 设置所有 character_set_* 为 utf8（除了 filesystem 为默认）
- 设置所有 collation_* 为 utf8_general_ci
- 设置 time_zone 为 Asia/Shanghai

以上设置编码为 UTF-8，时区为北京时间
