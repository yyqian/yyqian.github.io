---
title: Java 并发 - JMM
date: 2016-07-22 09:31:36
permalink: 1469151096000
tags: Java
---

这一篇文章主要围绕「可见性」来展开，讲述如何正确发布对象。对于 Java 内存模型，在这里只是简单介绍一下，详细的请见之前的文章 [深入理解 Java 虚拟机 - 高效并发](https://yyqian.com/post/1455874363073/)。

## 内存模型

JMM 中有两点会给我们带来很多困扰：

源代码中的指令顺序和实际运行时的指令顺序可能是不同的，编译器出于优化的目的，会对指令进行「重排序」，会采用乱序或并行等方式来执行指令，它只要满足一个条件即可：「程序的最终结果与在严格串行环境中执行的结果相同」。在这种情形下，如果另一个线程坐在那观察某个执行过程中的线程，会发现该线程的执行过程是不可预测的，在这个时候得到的状态也是无效的，这就是安全发布的必要性。

除此之外，JMM 中每个线程有自己的本地的缓存（也就是下图中的工作内存），如果某个线程更新变量之后没有及时同步到主内存，其他线程是看不到更新后的值的，这就带来可见性的问题，但这在缓存一致性的要求上是满足最小保证的：允许不同的处理器再任意时刻从同一个存储位置上看到不同的值。
<!-- more -->
![](http://cdn.yyqian.com/1455874363073_b.jpg?imageView2/2/w/500)

我们可以通过使用特殊的指令（称为内存栅栏或栅栏）来协助实现数据共享。但串行一致性在任何现代的多处理器架构中都不会提供，JMM 也是如此（串行一致性：在每次读取变量时，都能获得在执行序列中最近一次写入该变量的值）。

如果我们要保证执行操作 B 的线程看到操作 A 的结果，那么在 A 和 B 之间必须满足先行发生原则（happens-before），这里只列举其中三个：

- 程序次序规则（Program Order Rule）：在一个线程内，按照代码顺序，前面的操作先行发生于后面的操作。这里要注意是在同一个线程内。

- 管程锁定规则（Monitor Lock Rule）：同一个锁的 unlock 操作先行发生于后面（时间上先后）的 lock 操作。

- volatile 变量规则（Volatile Variable Rule）：对一个 volatile 变量的写操作先行发生于后面（时间上先后）对这个变量的读操作。

第一个是显而易见的（但一定要注意是在同一线程中自己观察自己），第二个和第三个表明分别使用了同步策略和 volatile。前面我们说过了，这个两个策略都是能保证「可见性」的，因此，它们的「可见性」保障也就是来自于这个先行发生原则的。

## 发布

发布安全性的保证，来自于 JMM 提供的先行发生原则（happens-before）保证。不正确发布的根本原因，都是由于 Happens-Before 的排序的缺失。

下面我们用单例模式的实现来说明安全和安全的发布。

### 不安全的发布

当缺少 Happens-Before 关系，有可能导致在没有充分同步的情况下发布一个对象会导致另一个线程看到一个只被部分构造的对象。

以下代码就是这种情况：

```
public class UnsafeLazyInitialization {
  private static Resource resource;

  public static Resource getInstance() {
    if (resource == null) {
      resource = new Resource();
    }
    return resource;
  }
}
```

线程 A 调用发现 `resource == null`，因此开始构造一个新的 Resource 对象，这个时候字段 resource 被指向这个正在构建中的对象，然后碰巧线程 B 调用，并发现 `resouce != null`，因此就取用了这个正在构建中的对象，也就是一个只被部分构造的对象，

### 安全的发布

**Eager 模式**：这个模式实现很简单。它的安全保障来自于类初始化过程中，静态域的额外的线程安全性保证。

```
public class SafeEagerInitialization {
  private static Resource resource = new Resource();

  public static Resource getInstance() {
    return resource;
  }
}
```

**Lazy 模式，使用 synchronized 同步**：这个的安全保证来自于前面 happens-before 第二条规则，在 lock, unlock 之间是有先后保证的。

```
public class SafeLazyInitialization {
  private static Resource resource;

  public synchronized static Resource getInstance() {
    if (resource == null) {
      resource = new Resource();
    }
    return resource;
  }
}
```

**Lazy 模式，使用占位类模式**：这个模式结合了以上两个模式的优点：

1. 它是延迟加载的
2. 它的安全保证来源跟 Eager 模式相同，利用的是类初始化过程中静态域的线程安全保证。这个 ResourceHolder 私有类只有当第一次使用时才被加载初始化，因此是延迟加载的。

```
public class ResourceFactory {
    public static Resource getResource() {
        return ResourceHolder.resource;
    }

    private static class ResourceHolder {
        static final Resource resource = new Resource();
    }
}
```

---

参考：
- [Java 并发编程实战](https://book.douban.com/subject/10484692/)