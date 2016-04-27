---
title: Thinking in Java 笔记
date: 2015-11-06 14:46:35
permalink: 1446792395444
tags: Java
---

这段是草草看完一遍之后写的。Java确实在“安全性”上要比我之前学过的语言好一点，在大型项目、多人合作时优点应该会比较突出，可以降低普通程序员犯傻的几率，可扩展性也不错。但除次之外感觉优点不多，首先语法实在太繁琐，Everything is object也是把双刃剑，况且也不真的是“Everything”。另外，要说这语言简单，深究下去也并不简单，一些高级特性像inner class、反射机制这种使用起来很复杂，代码也很难读，只能说作为Class的使用者来说还是比较简单的，但作为Class的作者就比较有挑战了。功能上，Java应该是比较全面的，并且相信是有保障的；Node.js在这方面还是显得有些嫩，虽然node的核心小而美是件好事，npm上的模块也很多，但不少是个人维护的，稳定性以及将来持续维护的可能性都不确定，我个人就遇到过node版本更新导致模块安装错误或是依赖的模块安装错误，而且作者也没及时修复的意思，所以在真正大项目中使用node.js还是要谨慎。当然，这些也与Node本身快速变化有关，希望4.2版本作为LTS可以稳定下来。但如果做做小项目，个人还是很喜欢Node.js的，虽然Java也号称可以像搭积木一样堆模块，但前置的准备还是有点多，不如Node.js写起来畅快淋漓。《黑客与画家》的作者唱衰Java，觉得以后很有可能会消失在历史长流，但现有的替代者们要是真发展到Java这个规模，很难说还能保持优雅的特性。

## 1. Introduction to Objects

### The progress of abstraction

当我们用程序去解决一个问题的时候，我们要面对的一个问题就是抽象，怎么把现实的问题抽象到一定层面来跟计算机打交道。程序语言可以说是计算机和现实沟通的一个桥梁或翻译，但程序语言本身抽象的程度是不同的。
<!-- more -->
**Assembly language**是计算机底层的一个抽象。它跟机器很“近”，但离现实问题很“远”，所以一般我们不会直接用它来编程解决实际问题。

之后的**imperative language**(FORTRAN, BASIC, and C)是对Assembly language的一个抽象。这些语言在计算机发展的初期或者是我们学习编程的初期，已经可以解决很多实际问题，但这些语言抽象的程度不够，我们在写程序的时候还是要关注计算机的构造，书上的原话是：

> their primary abstraction still requires you to think in terms of the structure of the computer rather than the structure of the problem you are trying to solve.

这里我们就需要去解决solution space(structure of the computer)和problem space(structure of the problem)之间的一种mapping。面对一个复杂的问题，这种mapping也变得更加复杂，如果处理不好就会写出糟糕、可读性很差的代码。

其实，跟C语言同一个年代的还有另外一类语言：**LISP**，它的强大之处在于你可以直接"model the problem you’re trying to solve"，这类语言本身语法特性非常强大，抽象能力很强，但按书上原话：

> may be a good solution to the particular class of problem they’re designed to solve, but when you step outside of that domain they become awkward.

而程序语言发展到如今使用最广泛的就是**OOP**，它的流行在于比较通用，适用于“大部分”问题，可以让coder更关注于业务本身，写出来的代码也更容易理解，书上原话：

> OOP allows you to describe the problem in terms of the problem, rather than in terms of the computer where the solution will run

C++、Java都是OOP，而Java在这方面更“纯”一点。

不过，个人觉得最近这几年functional programming也有复苏的势头，因为在某些情景它特别擅长（譬如网络应用），而且它更抽象（函数是“一等公民”），因此现代的OOP语言也加入了FP的特性，所以个人觉得也不要把自己框在OOP这个圈子里，不时地也跳出来看看。

### OOP的一些特性

> one of the challenges of object-oriented programming is to create a one-to-one mapping between the elements in the problem space and objects in the solution space.

Object是对某种现实的一个抽象，它有type, interface。要把Object想象成一个service provider，要做到"each object does one thing well, but doesn’t try to do too much"，这样有助于设计high cohesion的架构，实际上就是模块化。

设计Object时要通过public, private, protected关键词来access control和hide implementation，这样有两个好处：

1. 让使用你模块（Object）的人只关注于他们所需要关心的地方。
2. 如果保证public的接口不变，你可以随意更改Object内部来改进该模块，而不会影响使用你模块的人。

Reusing：一个project由若干object组成，在设计好各个模块之后，你可以像搭积木一样把它们搭起来组成一个完整的系统。这些object可以直接从现有的class产生，也可以继承于现有的class，再进行修改。但书上也不建议一上来就做复杂的继承，还是要先关注于实现：

> Because inheritance is so important in object-oriented programming, it is often highly emphasized, and the new programmer can get the idea that inheritance should be used everywhere. This can result in awkward and overly complicated designs. Instead, you should first look to composition when creating new classes, since it is simpler and more flexible. If you take this approach, your designs will be cleaner. Once you’ve had some experience, it will be reasonably obvious when you need inheritance.

### Containers

There are two reasons that you need a choice of containers:

1. First, containers provide different types of interfaces and external behavior. A stack has a different interface and behavior than a queue, which is different from a set or a list. One of these might provide a more flexible solution to your problem than the other.   

2. Second, different containers have different efficiencies for certain operations.

### Client-side programming

书上讲了很多过时的东西：cgi, plug-ins, applet, ActiveX, Flash，现在唯一的赢家就是Javascript，而作者对JS的评价是：

> Dealing with errors and debugging JavaScript can only be described as a mess.

实际上现在JS有很多先进的工具，来帮助你写出优质的代码，但烂代码的下限也还是比其他语言更低，就看程序员水平了。

### Server-side programming

以往服务器端的语言主要是：Perl, Python, C++, or some other language to create CGI programs，Java算是后起之秀。但现在Java应该也已经是主流了，Ruby on rails，Node.js，GO什么的才算是新秀了。

### Summary

我觉得作者这一段讲得很好，不要盲目选择一种语言，要了解它的特性，根据自己的需求来做选择。

> OOP and Java may not be for everyone. It’s important to evaluate your own needs and decide whether Java will optimally satisfy those needs, or if you might be better off with another programming system (including the one you’re currently using). If you know that your needs will be very specialized for the foreseeable future and if you have specific constraints that may not be satisfied by Java, then you owe it to yourself to investigate the alternatives (in particular, I recommend looking at Python; see www.Python.org). If you still choose Java as your language, you’ll at least understand what the options were and have a clear vision of why you took that direction.

## 2. Everything is an Object

Java最大的特点就是“pure” object-oriented language。

这个pure主要是针对C/C++来说的，C++由于要兼容C，不是所有的东西都是Object，传参的时候需要考虑传的是值还是指针，因此比较混乱。

Java里所有东西都是Object，操作某个Object是通过操作它的reference，所有传递也都是传reference而不是Object本身，一致性很好，使用起来更优雅。

    String s; //s是一个String reference，没有指向任何Object  
    String s = "asdf"; //初始化之后，s就是指向"asdf"这个String Object的String reference了。

Object一般存放在heap里面，primitive types存放在stack里面，primitive types不是用new产生的，它们不是reference，这些变量直接存放这些值。Primitive type有：

* boolean, Boolean
* char, Character
* byte, Byte
* short, Short
* int, Integer
* long, Long
* float, Float
* double, Double
* void, Void

这些primitive types有对应的Wrapper type（以上列表右侧），用new产生后就是Object了，并且是存放在heap里

All numeric types are signed, so don’t look for unsigned types.

class的elements有两种：fields和methods

如果fields是primitive data type，即使不初始化也会自动有个默认值，但还是强烈建议手动初始化

Java中把调用object的method理解成： sending a message to an object。这里的message就是method

static描述的elements可以直接通过class name调用，并且建议是这样做

java.lang这个library会自动被import

以java.lang.System.out.println来分析如何查document：

1. 先找到java.lang.System这个class，它继承自java.lang.Object

2. java.lang.System这个class有个static field：out，因此java.lang.System.out是一个object，我们可以看到out这个object的class是PrintStream

3. 接着我们查PrintStream class有什么可以用的，然后查到java.io.PrintStream class有个public method是println

4. 因此，我们可以这样调用println：java.lang.System.out.println，由于java.lang已经默认import了，因此可以简化成System.out.println

因此，剖解开来就是：

1. java.lang是个library
2. java.lang.System是其中一个class
3. java.lang.System.out是System class的一个static field，这个field的class是java.io.PrintStream，它已经实例化了，因此是个object
4. java.lang.System.out.println是java.lang.System.out这个object调用它的public method：println

embedded documentation是可以用某种syntax来写comments，用javadoc命令生成html格式的说明文档

Java的coding style是camel-casing，同Javascript，class名首字母大写，其他的首字母小写（methods, fields, object reference）,不使用连字符

## 3. Operators

+的用法和JS一样，可以用来连接String，String + non-String也会尝试让non-String自动变为String。

assignment跟其他OOP一样。对于primitives是copy the contents，assign之后两者互不相干；对于object是copy a reference，assign之后指向的是同一个object。

Relational operators如果比较object，比较的是两者的reference，不是the contents of object。比如两个new Integer(47)是不等的，因为Integer是一对int的一个wrapper，是Object。

多数Java library class都引入了equals()，譬如Integer。如果自己定义的class要用equals()，需要override equals()。

Logical operators: &&, ||, !只能作用于boolean values，这一点和C＋＋不同。boolean value可以自动转换为String，如果需要的话。

Java也有short-circuiting现象，和JS相同，连续的&& / ||遇到false / true就停止继续evaluate右边的表达式。

Literals：trailing L代表long，trailing F代表float，trailing D代表double，leading 0x代表16进制，leading 0代表8进制，2进制没有literal representation，可以用静态方法Integer.toBinaryString()来输出2进制结果。指数用e，譬如1.39e-43F。

Bitwise和Shift operators没看，用的不多

ternary operator(conditional operator): boolean-exp ? value0 : value1，要注意的是value0和value1这两个表达式只有符合条件的那个会被执行。

+和+=可以被用作String，这是Java中的特例，Java本身不支持C++的operator overloading，因为这个特性被认为太复杂。


### Java中的类型转换

> Java allows you to cast any primitive type to any other primitive type, except for boolean, which doesn’t allow any casting at all. Class types do not allow casting.

可以用int b = (int)a;这种方式把变量a转换成int，有些转换还会是隐性的，但是boolean是不允许转换的。

narrowing conversions就是float到int这类转换，Java中是作truncation，譬如3.8转换成3，如果要四舍五入，要调用java.lang.Math.round()。

promotion是指int和long运算时，int会自动提升为long，结果也是long。double和float也是同样道理。还有char，byte，short在运算的时候不论什么情况都会提升为int，如果想让结果保持原来的type，要强制转换回来。

Java没有sizeof()，因为Java各种类型的data在不同架构上都是同样size的

书的84页（英文第四版）有所有operator的例子、摘录，可以参考。

## 3. Controlling Execution

Java中的控制流基本与C/C++相同，只多了个Foreach：

    for(float element : ary)
      System.out.println(element);
    }

这段代码中ary的type是float[]，element的type是float，这段代码遍历ary中所有的元素。

## 5. Initialization & Cleanup

constructor的特点：

1. 名字和类名相同，首字母大写。
2. 没有return type，因为它没有返回值。虽然new Foo()会返回一个object的reference，但Foo()本身不会返回任何值。
3. 如果没有argument，那么这个constructor就是default constructor

Java和C++一样，支持函数的重载（overloading），区分不同的重载函数的方法就是看参数列表，这包括参数的个数，类别，顺序。

如果重载的函数列表里有primitives，要注意隐性转换。

不能用return type来重载方法。

如果class定义没有constructor，Java会有个默认的无参数的constructor。但是如果自己写了constructor，需要调用default constructor，就必须自己写，否则会出错。

this可以指向当前的object，但不是必要不建议用。this在chaining style的代码中可以每次在结尾都return this;

this在constructor定义中不是指向object，而就是constructor本身，主要是用来调用其他constructor，实现重载，例子见书中118页。

static method中不能调用this，也不能调用non-static method，因为它不作用在任何实例上。static这个玩意其实不是很OOP，不能过多使用。

几种GC方式：

1. reference counting。计object的引用数，计数为0则GC。Every time a reference goes out of scope or is set to null, the reference count is decreased. 有个问题就是循环引用不易被GC。

2. tracing，从stack和static storage area出发找references指向的objects，一层一层找下去，没被找到的就是可以GC的。循环引用在这就没有问题。

3. JVM采用了一种adaptive的策略，没看明白具体是怎么操作的。。。

Class定义中field总是会初始化的，primitive field会初始化相应的值，object reference会初始化为null，但是local variable没初始化的话编译会报错。

Class定义时给field赋值可以初始化指定的默认值，但是在Constructor中初始化默认值更合适。

Class定义中，fields的初始化会在Constructor和methods之前，因此所有fields初始化都会被提到开头。

new Foo()的时候初始化顺序：1. static fields，2. non-static fields，3. Constructor。static fields只有在第一次new该类Class才会触发。

### Array initialization

    int[] a1 = { 1, 2, 3, 4, 5 };
    a.length; //intrinsic member, you can query—but not chang
    int[] a = new int[18];
    Integer[] a = new Integer[18];
    Integer[] a = {
      new Integer(1),
      new Integer(2),
      3, // Autoboxing
    };
    Integer[] a = new Integer[]{
      new Integer(1),
      new Integer(2),
      3, // Autoboxing
    };

### Variable argument lists (Java SE5)

这种syntax可以让输入的参数列表变长，省去call该method的时候要构建Array。

    //Java SE5之后的写法
    static void printArray(Object... args) {
      for (Object obj : args) System.out.print(obj + " ");
    }
    printArray(new Integer(47), new Float(3.14), new Double(11.11));

    //等价的没有使用varargs的写法
    static void printArray(Object[] args) {
      for(Object obj : args)
        System.out.print(obj + " ");
    }
    printArray(new Object[]{
      new Integer(47), new Float(3.14), new Double(11.11)
    });

### Enumerated types (Java SE5)

    public enum Spiciness {
      NOT, MILD, MEDIUM, HOT, FLAMING
    }
    Spiciness howHot = Spiciness.MEDIUM;
    System.out.println(howHot); // MEDIUM

static method有values( )，普通的method有ordinal( )，enum可以配合switch用。

## 6. Access Control

The levels of access control:

1. public
2. protected
3. package access (which has no keyword)
4. private

一个class的文件位置由两部分组成：CLASSPATH和package名字。譬如：

    package net.mindview.simple;
    public class List {
      public List() {
        System.out.println("net.mindview.simple.List");
      }
    }

如果CLASSPATH是C:\DOC\JavaT，那么这个List class文件所在位置应该是C:\DOC\JavaT\net\mindview\simple

这章的Summary讲得真好：

> When you set out to design a system, it’s important to realize that program development is an incremental process, just like human learning. It relies on experimentation; you can do as much analysis as you want, but you still won’t know all the answers when you set out on a project. You’ll have much more success-and more immediate feedback-if you start out to “grow” your project as an organic, evolutionary creature, rather than constructing it all at once like a glass-box skyscraper. Inheritance and composition are two of the most fundamental tools in object-oriented programming that allow you to perform such experiments.

这个方法标记某个Object的ID不错：

    public class Waveform {
      private static long counter;
      private final long id  = counter++;
      public String toString() {
        return "Waveform  " + id;
      }
    }

## 9. Interface

abstract class和Interface都可以避免被直调用接生成Object

只要class定义里有一个abstract method，那这个class就必须是abstract class，但不是所有method都必须是abstract，没有也行

interface的所有method都默认是abstract和public的，field也默认是static和final的，一般不写出来

一个class可以extends一个base class和implements多个interface

implements多个interface要避免这些interface之间有相同的method名

Interface的好处是可以衍生出很多base class，然后这些base class的sub-class也都可以upcast到这个interface

如果已有库里某个method的接口是interface，那么我们自己的任何class只要implements这个interface，就可以使用这个method。而如果这个method接收的是特点的class，则我们要对我们自己的class进行改造，成为这个特点的class，不如interface来得优雅。

现在的interface中很少有定义fields，过去这样使用是为了实现enum

Factory Method design pattern可以在这有所体现

## 10. Inner Classes

Inner class可以name hiding，调用的时候需要OuterClass.InnerClass

Inner class还可以随意调用Outer Class的private方法和属性

后面很多没看完，看得一知半解，以后还得重读，这章里也提到了用inner class实现闭包和callback。

## 11. Holding Your Objects

Java有以下一些“container”的实现：

- Array: type is known, size cannot be changed

- ArrayList: if you're doing a lot of random accesses
- LinkedList: if you will be doing a lot of insertions and removals in the middle of the list

- HashMap: designed for rapid access
- TreeMap: keeps its keys in sorted order
- LinkedHashMap: in insertion order

- HashSet: for fast lookups
- TreeSet: sorted order
- LinkedHashSet: in insertion order

Vector, Hashtable, Stack都已经过时，不要用了。要注意的是Queue本身是个interface，需要由LinkedList来实现。Queue有个实现叫PriorityQueue.

List与array类似，但是可以resize；Map用来实现映射；Set不接受重复的对象。

![](http://www.linuxtopia.org/online_books/programming_books/thinking_in_java/TIJ326.png)

黑框是最常用的：ArrayList, LinkedList, HashSet, HashMap。虚线的interface，实线的是 regular class (not abstract)。

不得不说这继承关系也真是复杂了。。。

## 12. Error Handling with Exceptions

Error 和 Exception 都继承自 Throwable，常用的 methods 有：

- String getMessage( )
- String getLocalizedMessage( )
- String toString( )
- void printStackTrace( )
- StackTraceElement[] getStackTrace( )

StackTraceElement 有个方法：getMethodName()

Error 一般不用处理，处理 Exception 最需要关心的就是 the name of the exception，一般这个 name 应该从字面上就是可以理解的。

RuntimeException 是特殊的一类 Exception，如果一个 method 有可能抛出 RuntimeException，可以不声明，一般这类 Exception 交由系统自己处理。如果 RuntimeException 一直没有被 catch，一般会回渗透到 main() 中，并调用 printStackTrace( )。

try - catch block 可以用来在同一个 method 中处理 Exception。一般是直接 throw new Exception()，然后在另外一端代码中进行统一处理。

try - catch - finally block 中的 finally 可以进行一些清理工作，但一般不需要进行内存回收。

match 一个 Exception 的时候，也符合 upcasting 的原则，父类的 Exception 可以接受子类的 Exception。

## 13. Strings

String object is immutable

Java不允许进行运算符重载，唯一的例外是Java对String对象重载了符号 + 和 +=，用于字符串连接。书上通过分析JVM机器码发现这是通过构造StringBuilder来重载的。以下两者等价：

    String s = "a" + "b" + "c";

    StringBuilder sb = new  StringBuilder();
    sb.append("a");
    sb.append("b");
    sb.append("c");
    String s = sb.toString();

后者在构造复杂的String时（比如多个+=语句），可以省去多余的StringBuilder产生和销毁，比用 + 效率更高。

toString()是Object的method，因此几乎所有class都有这个方法。

在重写toString()的时候，不要出现类似`return "This is the class: " + this;`其中的this会调用toString()，导致无限递归。

SE5中多了System.out.format()，这个和C的printf同用使用：`System.out.format("Row 1: [%d %f]\n", x, y);`

Formatter Class可以指定输出设备，例如：`Formatter f = new Formatter(System.out); f.format("x = %d\n", x);`

格式化：`%[flag][width][.precision]conversion`，例如%10.2f表示右对齐，至少宽度为10，小数点后2位，浮点数；%-15.15s表示左对齐，最小宽度15，最大宽度也是15，字符串。

SE5多了一个静态方法String.format()，输入参数和System.out.format()相同，返回一个String，基于Formatter Class实现，但更方便使用。

和Regular expressions有关的一些非静态method，接受的参数都是Regular expression（replace还有第二个参数）：

- matches()，返回boolean
- split()，返回String[]
- replaceFirst(), replaceAll()，返回String

RegEx草草看了下，用到的时候再看吧。

## 14. Type Information

这章讲了很多在runtime查class类型的东西，最主要的用处是反射机制，可以在运行时直接分析一个未知的class，得到它的方法、属性，即使是non-public的也行，可以用很强大的用处。

这章也是囫囵吞枣看了一遍，用到的时候再深究吧。

## 15. Generics

这个和C++的模板差不多

Generics是SE5引入的，之前是通过让任何class都upcast到Object来实现的，这种实现方式有个弊端是存入时可以自动upcast，但是取出时需要downcast，因此要强制类型转换的。

Class的泛型：`public class ClassName<T> {}`

Interface的泛型：`public interface InterfaceName<T> {}`

Methods的泛型：

    public <T> void f(T x) {}
    public static <K,V> Map<K,V> map() {}

method的泛型建议是能用就用，相当于是实现了无数次overload。

这章就看到了The mystery of erasure，后面还有很多细节方面的以后再看吧。

## 16. Arrays

Array取存：`array[index]`

List取存：`list.add(something); list.get(index);`

Arrays of objects hold references, but arrays of primitives hold the primitive values directly.

初始化方法：

    BerylliumSphere[] b = new BerylliumSphere[5];
    BerylliumSphere[] d = { new BerylliumSphere(), new BerylliumSphere(), new BerylliumSphere()};

    int[] f = new int[5];
    int[] h = { 11, 47, 93 };

Arrays.deepToString( )静态方法可以把多维数组转换成String

不要把array和generics一起用，array需要知道确切的type，而generics的erasure机制会把type信息都抹掉

Arrays.fill()静态方法可以填充某个数组的元素。书上还讲了用Generator来填充，这段没仔细看。

System.arraycopy() 这个静态方法可以shallow copy一个数组，shallow的意思是primitives会duplicate，但object只会duplicate the references，object本身不会duplicate。

Arrays还有一些sort、search方法，跟JavaScript SE5中的一些新方法类似，需要传入一个比较器，只不过在JS中是一个函数，而Java中需要将这个函数包装成Class，这个时候就体现出类Lisp语言的方便之处了。

这章结尾最后给出的建议是"prefer containers to arrays"，虽然arrays可能有一点性能的优势，但没那么大，Java貌似自己也觉得Array本身显得不那么OOP，跟倾向于让大家用更高级的containers。

## 17. Containers in Depth

跳过

## 18. I/O

这章除了讲读写流外，还讲了下持久化的问题，比较有用的是将一个Object serialization，然后在另一个程序中能deserialize，恢复成Object，其它一些方法还有XML等。JS的JSON与这些相比就方便多了。

## 19. Enumerated Types

跳过

## 20. Annotations

Annotation 是SE5引入的，SE5的时候只有三个general-purpose built-in annotations：

1. `@Override`，标记一个class中的某个method是override base class中的method，如果用户写错的话编译时就会报错
2. `@Deprecated`，标记这个element已经过时，如果使用编译器就会给warning
3. `@SuppressWarnings`，如果知道这个element编译会给warning，但不想看到，那就可以suppress这个warning

这章大多数都是在讲怎么自己写Annotation，然后自己写annotation processor来处理这些自定义的Annotation。

注意的是Annotation中的element必须有值，要么是default value，要么是使用这个Annotation的Class设定。

书中举了例子怎么通过在Model中添加Annotation来映射出一个Database Table，然后用自己写的processor来生产SQL语句来创建表格。这个和Spring Data JPA应该是同样的原理。

书中讲了怎么使用Java自带的apt工具来处理annotations，估计暂时还用不上，没仔细看。

最后着重讲了利用Annotation来实现Unit testing，里面的Unit工具貌似是作者自己写的，为了通用起见，还是研究JUnit比较划算。

unit testing遇到generic class怎么办？继承一个specified type的version，譬如public class StackLStringTest extends StackL<String> {}

虽然Java的built-in annotation不多，但很多框架会带很多可以用的Annotation，譬如Spring框架大量使用了annotation。

## 21. Concurrency

前面的熟悉了再往下看。
