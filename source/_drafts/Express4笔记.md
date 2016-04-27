---
title: Express 4.x 笔记
date: 2015-05-22 13:15:49
permalink: 1432271749265
tags:
---

## Request

下面主要记录下`req` object的一些属性和方法

**req.baseUrl**

这个是router的url path，不是实际的url path，见下例：

    var greet = express.Router();
    greet.get('/jp', function (req, res) {
      console.log(req.baseUrl); // /greet
      res.send('Konichiwa!');
    });
    app.use('/greet', greet); // load the router on '/greet'

实际的url是`/greet/jp`，而`baseUrl`是`/greet`

**req.body**

这个需要`body-parser`中间件，主要包含post/put/patch访问时提交的键值对，默认是`undefined `

**req.cookies**

这个需要`cookie-parser`中间件，看名字就知道是干嘛的，默认是`{}`

**req.hostname**

例子：

    // Host: "example.com:3000"
    req.hostname
    // => "example.com"

**req.ip**

对方的IP地址

**req.path**

不包含host和query的path

    // example.com/users?sort=desc
    req.path
    // => "/users"

**req.originalUrl**

包含了query的url，例子：

    // GET /search?q=something
    req.originalUrl
    // => "/search?q=something"

**req.params**

url里的参数，restful api经常用，例子：

    router /user/:name
    // GET /user/tj
    req.params.name
    // => "tj"

**req.query**

url中的query对象

**req.protocol**

`http or https`

**req.secure**

`true or false`，用来区分`http/https`， 等价于`'https' == req.protocol;`

**req.method**

`GET/POST/PUT/PATCH/DELETE`等http方法，express的api中没提到，不确定是否有这个属性，但sails中可以使用

**req.param()**

在Express 4.x中该方法已经deprecate，用以下三个方法替代：

* `req.params.id //适用于rest style的router` 
* `req.body //适用于表单内容`
* `req.query //适用于query style的router`

以下不熟悉或没用过：

**req.subdomains**
**req.xhr**
**req.signedCookies**
**req.stale**
**req.route**
**req.ips**  
**req.app**  
**req.fresh**  

## Respond

**res.send()**

注意不能传number，否则会当作是status code，可以是buffer, string, array。supertest中`res.send()`的内容会出现在`res.text`中，`Content-Type`会是`text/html`