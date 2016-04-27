---
title: koa 框架以及 ES6 的分析
date: 2015-09-11 13:49:39
permalink: 1441950579342
tags: [Node.js, koa]
---

随着今年ECMAScript 6的发布和最近Node.js v4.0.0的发布，node.js又得到了一次加强。以往node.js在性能上有着优越的表现，但是JavaScript的语法却常常遭人诟病，譬如回调地狱、无块级作用域等等。这些一部分确实是设计上的问题，另一部分也源于JS其实是“披着C外衣的LISP”，虽然JS很容易使用，但大家并不真的了解它，在这种情况下，很容易写出糟糕的代码。

ES6的推进一定程度上解决了部分问题，譬如用Generator函数和Promise对象改善异步的处理，用let和const来缓解大家对JS词法作用域的不适应，还有Class类来适应面向对象设计。这些改动都让JS语言变得更强大。Node.js 4.0支持了部分ES6的新特性并在逐步覆盖所有特性，并使用了最新的Chrome V8引擎，由于不像浏览器端存在兼容性的问题，也不用去操作糟糕的DOM树，所以Node应该是拥抱ES6带来的改变的最佳试炼场。

接下来主要是分析Node.js的下一代web框架：koa，同时看下ES6的新特性是如何在实际环境中运用的。

### 中间件（middleware）

koa延用了express的中间件（middleware），但两者中间件的形式是不一样的：

express中：
```
function (req, res, next) {
  if (req.isAuthenticated()) {return next();}
  return res.redirect('/');
}
```
koa中：
```
function () {
  return function*(next) {
    if (this.isAuthenticated()) {
      yield next;
    } else {
      this.redirect('/');
    }
  };
}
```
一个是传递req, res的function，一个是返回Generator function的function

以下是一些常用中间件的介绍：

无需验证用户身份的中间件流程：

`gzip --> fresh --> etag --> favicon --> logger --> static --> route <--|回溯`

koa-gzip用于压缩任何传输的数据，所以应当放在出入口。  
koa-fresh根据etag来判断待传输的数据有没有更新，如果没有更新则返回304 Not Modified，不传输数据。  
koa-etag用于给传输的数据打tag。  
koa-favicon用于处理favicon.ico的请求，这个请求会非常频繁，所以单独处理。  
koa-logger记录所有访问记录，可以放在static后面，或者省略掉。  
koa-static用于处理静态文件访问，譬如js，css文件。  
route就是路由表，可以用koa-route或koa-router。  

用于验证登录的中间件流程：

`gzip --> fresh --> etag --> favicon --> logger --> static --> bodyparser --> session --> passport --> authenticate --> private-route <--|回溯`

koa-bodyparser用于解析请求的body部分，但是解析请求在koa中不推荐用中间件来处理，因为多数访问都是http get访问，无需解析，可以用co-body，在必要的地方用一个函数来解析。这里使用中间件这种方式主要是配合passport使用。
session用于处理session，有多种选择选择，passport中间件必需的
koa-passport用于用户验证，需要先配置passport实例，然后调用：`app.use(passport.initialize()); app.use(passport.session());`
authenticate用于处理passport验证的结果，一般验证失败则返回，验证通过进入下一步，这一步可以自己写  
private-route由于必须要通过authenticate才能访问到，所以是受保护的  

以上两者结合起来的流程如下：

`gzip --> fresh --> etag --> favicon --> logger --> static --> public-route --> bodyparser --> session --> passport --> login-route --> authenticate --> private-route <--|回溯`
