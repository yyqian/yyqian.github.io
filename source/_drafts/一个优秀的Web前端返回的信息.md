---
title: 一个优秀的 Web 前端返回的信息
date: 2015-12-03 17:01:51
permalink: 1449133311077
tags:
---

- Waiting (TTFB, Time To First Byte) < 30 ms
- 启用了gzip
- 可以用 ETag 和 If-None-Match 来判断是否缓存

用Chrome的调试器应该能看到：

第一次访问的时候，content-encoding应该是gzip，response：

HTTP/1.1 200 OK
Server: nginx/1.4.6 (Ubuntu)
Date: Thu, 03 Dec 2015 08:50:20 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 2770
Connection: keep-alive
ETag: "1c3c-0vFHcijpEt2w8bp6DZ5LiA"
content-encoding: gzip

第二次访问的时候，Status Code应该是304，response：

HTTP/1.1 304 Not Modified
Server: nginx/1.4.6 (Ubuntu)
Date: Thu, 03 Dec 2015 08:49:04 GMT
Connection: keep-alive
ETag: "7f80-8KurRyHUiU+Q0Te5ajq7Bg"

发送的request，最优要处理的就是text/html这种格式：

GET /post/1409646660000 HTTP/1.1
Host: yyqian.com
Connection: keep-alive
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36
DNT: 1
Referer: http://yyqian.com/post
Accept-Encoding: gzip, deflate, sdch
Accept-Language: en-US,en;q=0.8
Cookie: koa:sess=eyJwYXNzcG9ydCI6eyJ1c2VyIjoieXlxaWFuIn0sIl9leHBpcmUiOjE0NDkxOTE5NjE3ODcsIl9tYXhBZ2UiOjg2NDAwMDAwfQ==; koa:sess.sig=hn4Dt5AH4588wNwE59bMjDcRHgM

第二次访问发送的request，唯一区别就是多了If-None-Match：

GET /post/1446792395444 HTTP/1.1
Host: yyqian.com
Connection: keep-alive
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36
DNT: 1
Referer: http://yyqian.com/post
Accept-Encoding: gzip, deflate, sdch
Accept-Language: en-US,en;q=0.8
Cookie: koa:sess=eyJwYXNzcG9ydCI6eyJ1c2VyIjoieXlxaWFuIn0sIl9leHBpcmUiOjE0NDkxOTE5NjE3ODcsIl9tYXhBZ2UiOjg2NDAwMDAwfQ==; koa:sess.sig=hn4Dt5AH4588wNwE59bMjDcRHgM
If-None-Match: "7f80-8KurRyHUiU+Q0Te5ajq7Bg"
