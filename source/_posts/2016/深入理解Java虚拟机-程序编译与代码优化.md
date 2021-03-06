---
title: 深入理解 Java 虚拟机 - 程序编译与代码优化
date: 2016-02-19 17:03:12
permalink: 1455872592672
tags: [Java, JVM]
---

本系列文章的内容来源于周志明的《深入理解 Java 虚拟机》一书，经过了自己的加工整理和精简，主要是为了梳理知识。

- [深入理解 Java 虚拟机 - 自动内存管理机制](http://yyqian.com/post/1455605122895)
- [深入理解 Java 虚拟机 - 虚拟机执行子系统](http://yyqian.com/post/1455864579129)
- [深入理解 Java 虚拟机 - 程序编译与代码优化](http://yyqian.com/post/1455872592672)
- [深入理解 Java 虚拟机 - 高效并发](http://yyqian.com/post/1455874363073)

## 10. 早期（编译期）优化

---

Java 语言中「编译期」以及「编译器」有可能有两种含义：

1. 前端编译器：例如 Javac，这是个把 .java 文件转化成 .class 文件的过程
2. JIT 编译器（后端运行期编译器）：例如 HotSpot VM 的 C1、C2 编译器，把字节码转变成机器码的过程

还有可能是 AOT 编译器，直接把 Java 代码转变成机器码。

JVM 设计团队把对性能的优化都集中到了 JIT 编译器中，这样可以让所有产生 Class 文件的语言都能享受到性能的优化。

前段编译器的优化措施主要是改善开发人员的编码风格和提高编码效率。相当多新生的 Java 语法特性，都是靠编译器的「语法糖」来实现的，而不是依赖于 JVM 底层的改进支持。
<!-- more -->
### 10.2 Javac 编译器

Javac 编译器本身就是由 Java 语言编写的。Javac 的编译过程如下：

![](http://cdn.yyqian.com/1455872592672_a.jpg)

#### 解析与填充符号表

解析步骤包括了经典编译原理中的「词法分析」和「语法分析」两个过程。

「词法分析」是将源代码的字符流转变为 Token 集合。例如：`int a=b+2` 包含了六个 token：int、a、=、b、+、2.

「语法分析」是根据 Token 序列构造抽象语法树（Abstract Sytax Tree，AST）的过程。

「填充符号表」是将前面分析的结构填入符号表（Symbol Table）的过程

#### 注解处理器

JDK 1.5 之后，Java 提供了 Annotation 的支持。注解处理器可以看作是编译器的插件，它可以根据我们的注解，修改 AST 的任意元素，修改完之后会再回到前面的过程，反复直到没有再对 AST 的修改为止。

开发人员可以通过注解处理器完成很多原本需要在编码中完成的事情。

#### 语义分析和字节码生成

获得的 AST 只能保证结构正确，语义分析的主要任务就是对源程序上下文有关的性质进行审查。

语义分析中有个过程叫「常量折叠」，例如代码中定义的 `int a = 1 + 2;`，在前段编译之后，得到的是 `int a = 3;`。因此在代码里定义前者不会有任何运行时的性能损失，但有时能带来更好的阅读性。

还有个过程叫解语法糖（desugar），Java 中的泛型、变长参数、自动装箱/拆箱等语法糖，在 JVM 运行期都是不支持的，只有在前段编译器还原为基础的语法结构，才能正确运行。

在字节码生成阶段，前段编译器不仅仅把前面的获得的信息转化为字节码，还会添加少量的代码。譬如类构造器 `<clinit>()` 方法和实例构造器 `<init>()`。完成了所有的调整之后，最后可以用 com.sun.tools.javac.jvm.ClassWrite 类的 writeClass() 方法输出字节码，生成最终的 Class 文件。

### 10.3 Java 语法糖

语法糖不会提供实质性的功能改进，但是它们或能提高效率，或能提升语法的严谨性，或能减少编码出错的机会。

#### 泛型与类型擦除

没有泛型之前，程序员通过 Object 是所有类型的父类和类型强制转换两个特点来实现泛型。

Java 的泛型是伪泛型，是一种语法糖，因为它对泛型的支持不像 C# 是在运行期生成的一种真实的类型。Java 源代码在编译之后，类型会被擦除，例如 `ArrayList<int>` 和 `ArrayList<String>` 在前端编译之后，类型是同一个类 `ArrayList`，两者在运行期是没有差别的。所以泛型也不能用来重载，因为类型会被擦除。

#### 自动装箱、拆箱与遍历循环

一个包含泛型、自动装箱/拆箱、遍历循环、变长参数的例子，编译前：

```
public static void main(String[] args) {  
    List<Integer> list = Arrays.asList(1,2,3,4);  
    //如果是在 JDK 1.7 还有另外一颗语法糖  
    // List<Integer> list = [1,2,3,4];  
    int sum =0;  
    for(int i : list){  
        sum+=i;  
    }  
    System.out.print(sum);  
}  
```

解释后等效的源代码：

```
public static void main(String args[]) {  
    List list = Arrays.asList(new Integer[] {   
            Integer.valueOf(1),  
            Integer.valueOf(2),   
            Integer.valueOf(3),   
            Integer.valueOf(4) });  
    int sum = 0;  
    for (Iterator iterator = list.iterator(); iterator.hasNext();) {  
        int i = ((Integer) iterator.next()).intValue();  
        sum += i;  
    }  

    System.out.print(sum);  
}  
```

除此之外，还有条件编译、内部类、枚举类、断言语句等语法糖，可以通过反编译 Class 文件来了解它们的本质实现。

## 11. 晚期（运行期）优化

---

### 11.2 HotSpot VM 内的 JIT 编译器

HotSpot 中有两个 JIT 编译器：

- Client Compiler：C1 编译器
- Server Compiler：C2 编译器

可以使用 -client 或 -server 参数去强制 JVM 运行在 Client 模式或 Server 模式。

解释器与编译器搭配使用的方式称为「Mixed Mode」，可以用 -Xint 强制运行在「Interpreted Mode」，用 -Xcomp 强制运行在「Compiled Mode」。

HotSpot 采用分层编译的概念：

- 第 0 层：解释执行，可以触发第 1 层编译
- 第 1 层：C1 编译，将字节码编译为本地代码，进行简单、可靠的优化
- 第 2 层：C2 编译，将字节码编译为本地代码，启用耗时较长的优化，甚至激进的优化

会触发 JIT 编译器的「热点代码」有两类：

- 被多次调用的方法，这种是标准的 JIT 编译方式，可以通过计数器来进行热点探测，触发的阈值以及衰减是可以设置的
- 被多次执行的循环体，这种编译方式发生在代码执行过程中，被称为栈上替换（简称 OSR 编译）

### 11.3 编译优化技术

以一段代码为例子：

```
static class B{
    int value；
    final int get（）{
        return value；
    }
}
public void foo（）{
    y=b.get（）；
    //……do stuff……
    z=b.get（）；
    sum=y+z；
}
```

在「方法内联（Method Inlining）」之后，一是省去方法的调用成本，二是为其他优化建立良好基础：

```
public void foo（）{
    y=b.value；
    //……do stuff……
    z=b.value；
    sum=y+z；
}
```

在「冗余访问消除（Redundant Loads Elimination）」之后：

```
public void foo（）{
    y=b.value；
    //……do stuff……
    z=y；
    sum=y+z；
}
```

在「复写传播（Copy Propagation）」之后，用 y 来代替 z：

```
public void foo（）{
    y=b.value；
    //……do stuff……
    y=y；
    sum=y+y；
}
```

在「无用代码消除（Dead Code Elimination）」之后：

```
public void foo（）{
    y=b.value；
    //……do stuff……
    sum=y+y；
}
```

其他的经典优化技术还有：

#### 公共子表达式消除

譬如有源代码：

```
int d =（c * b）* 12 + a +（a + b * c）；
```

由于 `c * b` 和 `b * c` 是相同的，并且运算期是不变的，因此可以简化为：

```
int d= E * 12 + a +（a + E）；
```

然后还可能进行一种「代数化简」：

```
int d= E * 13 + a * 2；
```

#### 数据边界检查消除

由于 Java 访问数组时会自动进行边界检查，但频繁的数组元素访问，会导致频繁的边界检查，造成性能负担。因此 JIT 编译优化的时候，会在某些貌似安全的情况下取消这个检查。譬如说在循环之中，如果循环变量的取值范围在边界以内，就可以取消对访问的边界检查。

#### 逃逸分析（Escape Analysis）

逃逸分析（Escape Analysis）是目前 JVM 中比较前沿的优化技术。

逃逸分析的基本行为就是分析对象动态作用域：当一个对象在方法中被定义后，它可能被外部方法所引用，例如作为调用参数传递到其他方法中，称为方法逃逸。甚至还有可能被外部线程访问到，譬如赋值给类变量或可以在其他线程中访问的实例变量，称为线程逃逸。

如果能证明一个对象不会逃逸到方法或线程之外，也就是别的方法或线程无法通过任何途径访问到这个对象，则可能为这个变量进行一些高效的优化，譬如：

- 栈上分配（Stack Allocation）：JVM 中创建的对象一般是分配在 Heap 中的，GC 对这些对象的回收和整理都需要耗费时间。如果确定一个对象不会逃逸出方法之外，那让这个对象在 Stack 上分配内存空间，这样对象所占用的内存空间就可以随栈帧出栈而销毁。在一般应用中，不会逃逸的局部对象所占的比例很大，如果能使用栈上分配，那大量的对象就会随着方法的结束而自动销毁了，垃圾收集系统的压力将会小很多。

- 同步消除（Synchronization Elimination）：线程同步本身是一个相对耗时的过程，如果逃逸分析能够确定一个变量不会逃逸出线程，无法被其他线程访问，那这个变量的读写肯定就不会有竞争，对这个变量实施的同步措施也就可以消除掉。

- 标量替换（Scalar Replacement）：标量（Scalar）是指一个数据已经无法再分解成更小的数据来表示了，JVM 中的原始数据类型都不能再进一步分解，它们就可以称为标量。相对的，如果一个可以分解，则称作聚合量（Aggregate），对象就是最典型的聚合量。如果把一个对象拆散，根据程序访问的情况，将其使用到的成员变量恢复原始类型来访问就叫做标量替换。如果证明一个对象不会方法逃逸，并且这个对象可以被拆散的话，那程序真正执行的时候将可能不创建这个对象，而改为直接创建若干成员变量来代替。将对象拆分后，除了可以让对象的成员变量在栈上（栈上存储的数据，有很大的概率会被虚拟机分配至物理机器的高速寄存器中存储）分配和读写之外，还可以为后续进一步的优化手段创建条件。

目前逃逸分析技术还不是很成熟，有时分析的性能耗费大于优化得到的提升，因此需要这些选项需要手动开启。

### 11.4 Java 与 C/C++ 的编译器对比

Java 与 C/C++ 的编译器对比实际上是即时编译器与静态编译器的对比。

即时编译器在性能上有可能有以下劣势：

1. JIT 编译器运行时编译会占有资源，因此不敢随便引入大规模的优化技术
2. Java 有很多动态检查行为
3. Java 没有 virtual 关键字，但虚方法的使用频率远大于 C/C++
4. Java 动态可扩展，运行时加载的新类可能改变程序的继承关系，因此有些优化难以开展
5. Java 中对象的内存分配正常是在堆上进行的，只有方法的局部变量才能在栈上进行
