---
title: Node.js 代码规范
date: 2015-07-23 17:46:50
permalink: 1437644810029
tags:
---

摘录自：https://github.com/dead-horse/node-style-guide

使用2个空格而不是 tab 来进行代码缩进， sublime设置：

    "tab_size": 2,
    "translate_tabs_to_spaces": true

使用 UNIX 风格的换行符 (\n):

    "default_line_ending": "unix"

去除行末尾的多余空格:

    "trim_trailing_white_space_on_save": true

每行80个字符:

    "rulers": [80]

用单引号包裹字符串

大括号位置:

    if (true) {
      console.log('winning');
    }

每个变量声明都带一个 var

变量、属性和函数名都采用小驼峰，类名采用大驼峰

用大写来标识常量

对象、数组的创建 ：使用尾随逗号，尽量用一行来声明，只有在编译器不接受的情况下才把对象的 key 用单引号包裹。 使用字面表达式，用 {}, [] 代替 new Array, new Object。例如：

    var a = ['hello', 'world'];
    var b = {
      good: 'code',
      'is generally': 'pretty',
    };

使用 === 比较符

三元操作符分多行: 

    var foo = (a === b)
      ? 1
      : 2;

不要扩展内建类型，WRONG:

    Array.prototype.empty = function() {
      return !this.length;
    }

所有复杂的条件判断都需要赋予一个有意义的名字或者方法：

    var isValidPassword = password.length >= 4 && /^(?=.*\d).{4,}$/.test(password);
    if (isValidPassword) {
      console.log('winning');
    }

为了避免深入嵌套的 if 语句，尽早的从函数中return。

尽量给闭包、匿名函数命名：

    req.on('end', function onEnd() {
      console.log('winning');
    });

不要嵌套闭包

不要使用以下东西：Object.freeze, Object.preventExtensions, Object.seal, with, eval

不要使用 setters，当没有副作用的时候，可以使用 getters

Node 的异步回调函数的第一个参数应该是error：

    function cb(err, data , ...) {...}

推荐的Node 的继承写法：

    function Socket(options) {
      // ...
      stream.Stream.call(this);
      // ...
    }
    util.inherits(Socket, stream.Stream);

文件命名单词之间使用 _ underscore 来分割

在所有的操作符前后都添加空格，function 关键字后面添加空格：

    var add = function (a, b) {
      return a + b;
    };