---
title: JavaScript 笔记
date: 2015-07-23 15:12:24
permalink: 1437635544279
tags: JavaScript
---

## 零碎的知识

---

不要比较两个浮点数是否相等，因为存在精度的问题，例如：`0.3 - 0.2 === 0.1`为`false`

定义变量一定要带var，如果要定义全局变量，定义在程序顶部

JS的Namespace采用的是Function Scope：{}中定义的变量为全局变量，function () {}中用var定义的变量对外隐藏，不用var定义的变量为全局变量

使用//注释

JS只有一个数字类型：64位的浮点数

JS所有字符都是16位的，可以用`\u[4 hex digits]`表示一个unicode字符

### 变量提升

```
console.log(x);
var x = 'Hello, world!';
```
以上代码会将var x;提升代码段开头，等价于：
```
var x;
console.log(x);
x = 'Hello, world!';
```
因此此时x是undefined。同上，下面的代码也会出错，会提示f不是function
```
f(1);
var f = function (x) { return x + 1; }
```
但是以下代码是ok的, Why?：
```
f(1);
function f(x) { return x + 1; }
```

## Object

---

JS里除了string, number, true, false, null, undefined其他都是Object，即使string, number, boolean也有对应的Wrapper Object：String, Number, Boolean。

注意几个名词：

* property attributes: 
    1. writable: 可否set value
    2. enumerable：for/in loop中可否枚举
    3. configurable：可否delete该属性
* object attributes: 
    1. prototype: 原型，其实就是父类
    2. class: type of an object，譬如：Date，Array，RegExp, Function
    3. extensible：可否增加新属性到该Object中
* Object的三种分类：
    1. native object: ECMAScript定义的Object，譬如：Date，Array，RegExp, Function
    2. host object: host environment，譬如浏览器、node.js中额外定义的Object
    3. user-defined object: 就是用户自己写的object
* Property的两种分类：
    1. own property: 该Object中定义的property，不是继承自prototype object的property
    2. inherited property: 继承自prototype object的property

避免Property Access Errors的小技巧：`var len = book && book.subtitle && book.subtitle.length;`

Creating Object的几种方法: 

1. `var x = {};`
2. `var x = new Object();`
3. `var x = Object.create(Object.prototype);`

Testing Properties的几种方法，以`var p={x: 1, y: 2};`为例：

1. in: `"x" in p`为true，`"toString" in p`为true
2. hasOwnProperty(): `p.hasOwnProperty("x")`为`true`， `p.hasOwnProperty("toString")`为`false`
3. propertyIsEnumerable(): `p.propertyIsEnumerable("x")`为`true`， `p.propertyIsEnumerable("toString")`为`false`
4. 直接访问: 如果不存在会返回`undefined`，`if (p.x)`可以简单地排除p.x为undefined, null, false, "", 0, NaN的情况

### Property Attributes

Attributes of a data property: value, writable, enumerable, and configurable

Attributes of an accessor property: get, set, enumerable, and configurable

获取object中某个property的属性：`Object.getOwnPropertyDescriptor(object, property)`

设置object中某个property的属性：`Object.defineProperty(object, property, {value:, writable:, enumerable:, configurable:})`

### Object Attributes

获取prototype: `Object.getPrototypeOf()`

判断是否为某个object的prototype: `isPrototypeOf()`

ES3和ES5都无法设置class属性，也只能间接读取class属性

不建议更改extensible属性，也不建议使用相关的函数

### Serializing Objects

Object serialization is the process of converting an object’s state to a string from which it can later be restored.

JSON.stringify() <-> JSON.parse()

例子：

    o = {x:1, y:{z:[false,null,""]}}; // Define a test object
    s = JSON.stringify(o); // s is '{"x":1,"y":{"z":[false,null,""]}}'
    p = JSON.parse(s); // p is a deep copy of o

> Objects, arrays, strings, finite numbers, true, false, and null are supported and can be serialized and restored. NaN, Infinity, and -Infinity are serialized to null. Date objects are serialized to ISO-formatted date strings (see the Date.toJSON() function), but JSON.parse() leaves these in string form and does not restore the original Date object. Function, RegExp, and Error objects and the undefined value cannot be serialized or restored. JSON.stringify() serializes only the enumerable own properties of an object. If a property value cannot be serialized, that property is simply omitted from the stringified output.

### Object Methods

These methods are intended to be overridden by other, more specialized classes: toString(), valueOf(), toLocaleString(), toJSON()

## Array

---

> JavaScript arrays are a specialized form of JavaScript object, and array indexes are really little more than property names that happen to be integers.

Array literal syntax allows an optional trailing comma, so [,,] has only two elements, not three.

### Sparse Arrays

Sparse arrays can be created with the Array() constructor or simply by assigning to an array index larger than the current array length.

    a = new Array(5); // No elements, but a.length is 5.
    a = []; // Create an array with no elements and length = 0.
    a[1000] = 0; // Assignment adds one element but sets length to 1001.
    var a1 = [,,,]; // This array is [undefined, undefined, undefined]
    var a2 = new Array(3); // This array has no values at all
    0 in a1 // => true: a1 has an element with index 0
    0 in a2 // => false: a2 has no element with index 0

DON'T use a for/in loop on array. Reason: it includes inherited properties (such as methods), iterates in any order

### Array Methods

Array.join() <-> String.split(): 将Array转换成String, not in place

Array.reverse(): It does the reverse in place. 所以不需要赋值给一个新的Array

Array.sort(): sorts the elements of an array in place and returns the sorted array. If no arguments, it sorts the array elements in alphabetical order (temporarily converting them to strings to perform the comparison, if necessary). 如果需要按其他方式sort，可以自定义一个function做为参数

Array.concat(): not in place

Array.slice(): not in place

Array.splice(): in place, 既可以删除指定位置的元素，也可以在指定位置插入元素

push(), pop(), unshift(), shift(): 一个在堆栈底操作，一个在堆栈顶操作

toString(): 输出和join()是一样的，没有方括号

### ES5 Array Methods

ES5中的新方法: forEach(), map(), filter(), every(), some(), reduce(), reduceRight(), indexOf(), lastIndexOf()

前面几个method都需要调用一个自定义的function，这个function的参数一般为element, index, array

对于Sparse Array，nonexistent elements不会被调用

这几个methods都相当于helper methods，效率应该不错，尽量使用

Array.isArray()可以判断是否type为Array

## Function

---

解释一些名词，以一下代码为例：

    var add = function (x, y) {
      var val = x + y;
      return val;
    }
    console.log(add(5,3));

* parameters: function定义时的输入变量x, y
* arguments: 调用function时提供的值5, 3
* return value: 返回的值val
* invocation context: this

function在不同语境下有不同名字：

* methods: if a function is assigned to the property of an object
* constructors: functions designed to initialize a newly created object
* closures: 

Method Chaining: when you write a method that does not have a return value of its own, consider having the method return `this`

> Unlike variables, the this keyword does not have a scope, and nested functions do not inherit the this value of their caller. If a nested function is invoked as a method, its this value is the object it was invoked on. If a nested function is invoked as a function then its this value will be either the global object (non-strict mode) or undefined (strict mode). It is a common mistake to assume that a nested function invoked as a function can use this to obtain the invocation context of the outer function.

Constructor Invocation: ???

Indirect Invocation: use call() and apply()

Optional Parameters: 可以考虑用`a = a || [];`来给可能缺省的parameter设置默认值

### Arguments Object

function中可以用arguments来引用所有的输入参数，可以在输入参数长度变化的时候使用。但一般不需要用到，JS一般的处理方式是missing arguments are undefined and extra arguments are simply ignored.

遇到输入参数长度不确定的情况，可以不写parameters，function中用arguments来引用

但arguments不是Array，是Arguments object，建议不要对arguments[]进行赋值操作，有可能有side effect

由于JS用的是Function Scope，可以通过定义函数再call的方式来实现私有的代码块

闭包和bind()需要仔细研究一下