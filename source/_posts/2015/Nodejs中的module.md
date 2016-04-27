---
title: Node.js 中的 module.exports，exports，this
date: 2015-07-28 13:17:09
permalink: 1438060629760
tags: Node.js
---

Node.js和Core JS有一点重要的不同是，Node.js多了Module对象，Node会为每一个js文件创建一个Module对象，module之间无法直接访问各自的variable或function，需要通过module.exports来开放接口，然后通过require来引用这些接口，这样就可以实现模块化。

但这里有一点令人感到疑惑的是module.exports和exports的区别是什么？

首先，在默认情况下，这两者以及this都指向同一个引用，这个可以通过这两句来判断：

    console.log(module.exports === exports); //true
    console.log(module.exports === this); //true

然后要注意的另一点是，require()返回的是module.exports。

因此，如果要通过exports或this来暴露接口，要确保各自和module.exports是指向同一个引用的，但这样比较容易出错，因为既要保证exports或this在模块中没有指向新的对象，也要保证module.exports没有指向新的对象。个人比较喜欢的做法是

    module.exports = {
        x: 1,
        f: function () {}
    };

或者

    module.exports.x = 1;
    module.exports.f = function () {};

前者写起来比较简洁，sails框架用的都是这种风格；后者不会指向新的对象，通过this或者exports也能调用。

此外，top-level的this在core js中指向global，在浏览器中指向window，在node指向的是module.exports，个人感觉意义不大，用了容易引起误解。