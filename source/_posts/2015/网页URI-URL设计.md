---
title: 网页 URI/URL 设计
date: 2015-12-17 14:21:29
permalink: 1450333289904
tags: REST
---

最近自己在学习 Spring 框架，做了一个 Hacker News 的克隆版，见 [Github](https://github.com/yyqian/imagine) ，随手写的 URI 比较混乱，所以想起来要对 URI 重构一下。

之前介绍过 [RESTful API](http://yyqian.com/post/1432535189699) 的设计，这里主要思考下网站 URL/URI 的设计，只想知道结论的就直接看最后一句就行。

### URI 和 URL 的区分

首先，两者的全称分别是：

- Uniform Resource Identifier (URI)
- Uniform Resource Locator (URL)

URL 是 URI 的子集，除了要标识资源，还必须提供获取资源的方式，譬如说：

`yyqian.com/post/1432535189699` 标识了在 yyqian.com 这个网站上 id 为 1432535189699 的一个 post，这个是 URI，因为它标识了一个资源，但它不是 URL，因为获取这个资源的方式没有说明，可能是通过 http，https，也可能是通过 ftp, telnet 等。因此 `http://yyqian.com/post/1432535189699` 才是一个完整的 URL。

URL 的 sytax 必须符合 generic URI:
```
scheme:[//[user:password@]host[:port]][/]path[?query][#fragment]
```
- `scheme`：常见的有 `http`，`https`，`ftp`，`mailto`，`telnet`，`ssh`
- `//`：这个有的 scheme 是需要的，譬如 `http://`，有的是不需要的，譬如 `mailto`
- `user:password@`：譬如 `ssh://qian@yyqian.com:8080/home/git/swiftwind.git`，其中 `qian@` 是用来鉴权的，password 一般不会明文写出来
- `host`，`port`，`path`，`query`，`fragment` 以 http URL 为例应该很好理解，http的默认 port 是 80，所以一般都省略了`:80`

具体见：[RFC 3986](http://www.rfc-base.org/txt/rfc-3986.txt)

接下来为了讨论方便，我们限定下面提到的 URL 都特指 scheme 为 http，port 缺省，无需鉴权的 URI，例如：
```
http://yyqian.com/post?page=1&size=20#top
```
而 URI 特指在此基础上省略了 scheme, host, fragment 的特例，例如：
```
/post?page=1&size=20
```

### URI 设计

网页 URI 设计个人比较推崇 RESTful 风格，见 [RESTful API](http://yyqian.com/post/1432535189699) 的设计，也就是说要结合 HTTP Method 和 URI 的 path 这两点进行设计。

而网页 URI 的设计和 API 设计有一点不同的是：网页无法灵活使用所有的 HTTP Methods，浏览器默认是使用 GET，form 表单提交可以用 GET 或 POST（当然，为了防范 CSRF 攻击必须用 POST），而 PUT，DELETE 等其他方法只有在借助 Ajax 的情况下才能使用。

另外，如果采用 RESTful 风格，在网站安全方面必须结合路径和 HTTP 方法两者进行访问控制，不能单单依靠路径的字符串匹配。

对于第二点，一般技术上都可以实现，至少我接触过的 Node.js 和 Java EE 下面的框架都可以做到。对于第一点，个人觉得缺点就是如果网站有很多提供修改，删除操作的页面，就会比较繁琐，无法简单地通过表单来解决，但这类网站也不是多数。但优点也是明显的：

1. 多数增删改操作都需要处理返回的状态和出错信息，因此在这种使用场景下，用 JavaScript 来处理这些请求是必需的
2. 正因为浏览器无法发起 PUT，DELETE 这种“危险”操作，因此也可以利用这一点来提升安全性，加大 CSRF 攻击的难度

因此，结论就是还是按照 RESTful API 的风格来设计网页 URI。。。