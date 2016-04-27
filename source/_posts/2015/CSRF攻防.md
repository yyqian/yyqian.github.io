---
title: CSRF 攻防
date: 2015-04-20 11:54:33
permalink: 1429502073486
tags: 网络安全
---

### CSRF攻击

CSRF攻击涉及到三者：WebA（正规网站/受害者），WebB（hack网站/发起攻击者），User（WebA的普通用户/受害者）。

流程大体是：

1. User登陆WebA，获取WebA给的cookie。
2. User在没有结束对话、cookie没有过期的情况下，访问了WebB，并执行了WebB中隐藏的攻击代码。
3. WebB中的攻击代码使用了User在WebA中的cookie，因此WebA以为是受信任的User执行了该代码，导致被攻击。

### CSRF防御

我所知道的比较好的方法有：

1. 给所有User发个共有token，提交请求时要发送hash(cookie + token)，然后服务器端验证该hash值。可以这样做的原因是：WebB一般是无法获取User在WebA的cookie的，因此也就没法计算出该hash值。
2. 给每个User的表单随机生成一个私有token，提交请求时要验证该token。可以这样做的原因是：WebB无法获取该token。
