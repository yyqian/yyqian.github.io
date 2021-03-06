---
title: 深入理解 Java 虚拟机 - 自动内存管理机制
date: 2016-02-16 14:45:22
permalink: 1455605122895
tags: [Java, JVM]
---

本系列文章的内容来源于周志明的《深入理解 Java 虚拟机》一书，经过了自己的加工整理和精简，主要是为了梳理知识。

- [深入理解 Java 虚拟机 - 自动内存管理机制](http://yyqian.com/post/1455605122895)
- [深入理解 Java 虚拟机 - 虚拟机执行子系统](http://yyqian.com/post/1455864579129)
- [深入理解 Java 虚拟机 - 程序编译与代码优化](http://yyqian.com/post/1455872592672)
- [深入理解 Java 虚拟机 - 高效并发](http://yyqian.com/post/1455874363073)

## 1. 走近 Java

---

JDK（Java Development Kit）包含三部分：Java、JVM、Java API 类库

JRE（Java Runtime Enviroment）包含两部分：Java API 类库中的 Java SE API 子集、JVM

最常见的 Java 虚拟机有：

- HotSpot VM：最常用的 JVM，有热点代码探测和 OSR（栈上替换）功能，可以在运行时触发 JIT 编译器进行优化和产生本地机器代码。Oracle 公司在收购了 JRockit 之后，还移植了一些 JRockit 的特性到 HotSpot VM 中。
- JRockit VM：JRockit 专门用于服务器端，不包含解析器，全靠 JIT 编译器。
- J9 VM：IBM 的产品，与 HotSpot 的定位类似。

除此之外，还有特定硬件平台专有的「高性能」JVM：Azul VM、Liquid VM。

还有个特殊的 VM 是 Dalvik VM，用于 Android 平台。它不是一个 JVM，没有遵守 JVM 的规范，不能直接运行 Java 的 Class 文件，使用的是寄存器架构而不是 JVM 中常见的栈架构。

Java 技术未来的几个方向：

- 模块化：主要的技术有 OSGi 和 Java 9 中的 Jigsaw（拼图）
- 混合语言：JVM 上可以运行多种语言，譬如：Clojure、Scala、Groovy，因为它们都会被编译成统一的字节码
- 多核并行：JDK 1.5 中引入了 java.util.concurrent，JDK 1.7 中加入了 java.util.concurrent.forkjoin，Java 8 中的 Lambda
- 进一步丰富语法：譬如自动装箱、泛型、动态注解、可变长参数、遍历循环，还有 Coin 项目
- 64 位虚拟机：现在的 64 位 JVM 比 32 位的内存消耗更多，性能差大约 15%，还有改进空间
<!-- more -->
## 2. Java 内存区域与内存溢出异常

---

### 2.2 运行时数据区域

JVM 管理的内存会包括以下运行时数据区域：

![](http://cdn.yyqian.com/1455605122895_a.png)

#### 程序计数器（Program Counter Register）

这是一块较小的内存空间，可以看作是当前线程所执行的字节码的行号指示器。每条线程有独立的程序计数器，因此是「线程私有」的内存。这块区域是 JVM 规范中唯一没有规定 OutOfMemoryError 的内存区域。

#### Java 虚拟机栈（Java Virtual Machine Stacks）

这也是「线程私有」的，生命周期与线程相同。JVM Stack 描述的是 Java 方法执行的内存模型：每个方法在执行时都会创建一个 Stack Frame（栈帧），存储了局部变量表、操作数栈、动态链接、方法出口等。每个方法从调用到执行完成的过程，就对应一个 Stack Frame 入栈和出栈。

多数人把 Java 内存区分为 Heap 和 Stack，这个 Stack 就是这里的 JVM Stack。

局部变量表存了 primitive types、reference type和 returnAddress type。

- reference type 是对象的引用，这个不等同于引用的对象本身
- returnAddress type 指向一条字节码指令的地址

这个区域有两种异常：StackOverflowError 和 OutOfMemoryError，导致的原因可能是单个栈帧太大，也可能是栈帧太多。方法递归的深度太深、建立的线程太多，都有可能产生大量的栈帧（方法调用），然后就有可能导致 StackOverflowError。

#### 本地方法栈（Native Method Stack）

Native Method Stack 和 JVM Stack 类似，线程私有，能抛出的异常相同。HotSpot VM 不区分虚拟机栈和本地方法栈。

两者区别是 JVM Stack 为字节码服务、而 Native Method Stack 为 JVM 自身使用的 Native Method 服务。

#### Java 堆（Java Heap）

Java Heap 是 JVM 管理的内存中最大的一块，线程共享，唯一的目的就是存放对象实例。（JIT 编译器可能使用逃逸分析技术，将对象实例存放在 JVM Stack 中，随线程终结而销毁）

Java Heap 是 GC 管理的主要区域，因此也被称为 GC Heap。

现在的 GC 采用的是分代收集算法，因此 Java Heap 可以分为：

- 新生代：还能细分为 Eden 空间、From Survivor 空间、To Survivor 空间
- 老年代

Heap 大小可以通过参数控制（-Xmx 和 -Xms）

如果堆内存太小无法分配实例，并且堆也无法继续扩展，则抛出 OutOfMemoryError。如果创建了太多的实例对象，就有可能导致该异常。

#### 方法区（Method Area）

这个区域也被称为 Non-Heap，同样是线程共享的，存储的是 JVM 加载的类信息、常量、静态变量、JIT 编译后的代码等。

HotSpot JVM 中也把这个区域称为 Permanent Generation（永久代），因为 HotSpot 把 GC 的分代收集扩展到了方法区，JDK 1.7 中已经逐步放弃永久代了。而 JRockit 和 J9 是没有永久代的概念的，JVM 规范也没有要求对方法区进行 GC。

方法区还有一部分称为 Runtime Constant Pool（运行时常量池），其中加载的是 Class 文件中的常量池（Constant Pool Table），存放的是编译期生产的各种字面量和符号引用。如果常量过多，就有可能使常量池溢出，抛出 OutOfMemoryError。

方法区无法满足内存分配需求时，会抛出 OutOfMemoryError。Spring、Hibernate 这种框架在对类进行增强的时候，会使用 CGLib、ASM 等字节码技术，生产大量的动态类；还有大量的 JSP 文件，基于 OSGi 的应用等等，都有可能导致 OutOfMemoryError。

#### 直接内存（Direct Memory）

Direct Memory 不属于 JVM 管理的内存，NIO 类可以使用 Native 函数库直接分配堆外内存，这样可以避免在 Java Heap 和 Native Heap 来回复制数据，提高性能。

### 2.3 Java 堆中实例对象的创建、内存布局和访问

#### 对象的创建

1. 类加载：当 JVM 遇到 new 指令时，先检查能否在常量池中定位到类的符号引用，然后检查这个符号引用代表的类是否被加载、解析和初始化过，如果没有，则先进行类加载过程。

2. 分配内存：为新生对象分配内存的过程等同于从 Java 堆中划分一块大小确定的内存。如果 Java 堆内存是绝对规整的，则使用「指针碰撞（Bump the Pointer）」方式，即用一个指针划分空闲和占用的分界点，Serial、ParNew 这种带 Compact 过程的收集器使用这种方式。如果 Java 堆不是规整的，则使用「空闲列表（Free List）」方式，这个列表标记了哪些内存块是可用的，CMS 这种基于 Mark-Sweep 算法的收集器使用这种方式。为了处理并发的问题，有两种方案：同步处理（CAS方式）、TLAB（本地线程分配缓冲，每个线程会预先分配一块独立的小内存）

3. 初始化零值：分配到的内存空间都会初始化为零值（除了对象头），设置默认值等等不在这个阶段完成，因为这些都是在字节码中实现的。

4. 对实例对象进行必要的设置：主要是设置对象头（Object Header）中的数据

从 JVM 的角度来看，这个时候新的对象已经产生了。但从 Java 程序的角度来看，还需要执行 init 指令，对这个「零值」的对象按照 Java 代码中的方式进行初始化。

#### 对象的内存布局

HotSpot VM 的对象头（Object Header）包含两部分信息：

1. 对象自身的运行时数据（Mark Word）：HashCode、GC 分代年龄、锁状态标志、线程持有的锁、偏向线程ID、偏向时间戳等等。

2. 类型指针：类元数据的指针，也就是说通过这个指针来确定这个对象是哪个类的实例。

如果对象是个 Java 数组，还要在 Object Header 中记录数组长度。

Object Header 之后的数据是实例对象真正存储的有效信息，也就是各个字段内容。这些字段的存储顺序会受到分配策略和 Java 源码中定义的顺序的影响。

#### 对象的访问定位

一个实例对象包括两部分：

1. 对象实例的数据，存储在 Java Heap
2. 对象类型的数据，存储在 Method Area（Non-Heap）

而调用对象是通过 Stack 中的 reference 类型的数据，reference 定位的方式有两种：

1. 句柄访问：reference 存储的是一个句柄的地址，这个句柄同时包含了这个对象实例数据和类型数据各自的指针。
2. 直接指针访问：reference 存储的就是对象实例的地址，然后可以通过 Object Header 中的类型指针去 Method Area 访问对象类型数据。HotSpot 采用的是这种形式。

使用句柄的好处是移动对象的时候只需要改变句柄中的实例数据指针，不需要改变 reference 本身。而直接指针访问的好处就是访问速度快。


## 3. 垃圾收集器与内存分配策略

---

### 3.1 概述

Lisp 是第一门真正使用内存动态分配和垃圾收集技术的语言。

我们为什么要对自动的 GC 和 内存分配进行监控和调节：

1. 排查各种内存溢出、内存泄露问题
2. 当垃圾收集成为系统达到更高并发量的瓶颈

在 Java 内存运行时区域的各个部分中，程序计算器、虚拟机栈、本地方法栈这三个区域的生命周期是和线程一样的，内存分配和回收都具备确定性，因此不需要考虑回收的问题，方法结束或线程结束时，内存就跟随着回收了。

而 Java 堆和方法区只有在程序运行时才知道会创建哪些对象，这些内存的分配和回收都是动态的，并且是线程共享的。 GC 关注的就是这部分内存。

### 3.2 对象存活判定算法

一个方法是「引用计数法（Reference Counting）」，这个方法很难解决对象之间相互循环引用的问题。少数语言会使用过这个方法。

主流语言（Java、C#、Lisp）使用的都是「可达性分析算法（Reachability Analysis）」，它从「GC Roots」对象作为起始点，从这些节点开始往下搜索，走过的路径称为「引用链（Reference Chain）」，如果从 GC Roots 到某个对象「不可达」时，这个对象就是不可用的。

Java 中可作为 GC Roots 的对象有：

- JVM Stack（Stack Frame 的本地变量表）中引用的对象
- Native Method Stack 中 JNI（Native 方法）引用的对象
- Method Area 中类静态属性引用的对象
- Method Area 中常量引用的对象

Java 中 Reference 有四种：

- 强引用（Strong Reference）：普遍存在的引用，类似「Object obj = new Object()」，只要强引用存在，GC 就不会回收被引用的对象
- 软引用（Soft Reference）：在将要发生内存溢出之前，就会回收软引用的对象
- 弱引用（Weak Reference）：生存周期是当前到下一次 GC 时刻，也就是说在下次 GC 就会回收掉弱引用的对象
- Phantom Reference（虚引用或幽灵引用）

回收一个对象要经过两次标记过程，第一次标记的时候 JVM 会检查对象是否有必要执行 finalize() 方法（没有覆盖该方法或者已经被调用过都被视为没必要执行），如果对象在执行 finalize() 方法的过程中恢复了引用，拯救了自己，在第二次标记的过程中就不会被回收，否则就回收。但是，finalize() 方法非常不建议用。

Method Area（或者说 HotSpot VM 中的永久代）都是可以有 GC 的，该区域主要回收两部分内容：

- 废弃常量：譬如 String 对象
- 无用的类：判定无用的类条件比较苛刻，在大量使用反射、动态代理、CGLib 等字节码生产技术、OSGi 等场景下就需要回收无用的类，以保证永久代不会溢出

### 3.3 垃圾收集算法

垃圾收集就是对被判定「死亡」的对象进行内存回收，算法大概有以下几种：

#### Mark-Sweep（标记 - 清除）算法

算法分为「标记」和「清除」两个阶段，先标记需要回收的对象，再统一清除所有被标记的对象。这个算法的问题是：（1）效率不高（2）收集之后会产生大量不连续的内存碎片

#### Copying（复制）算法

算法将内存分为 A B 两个大小相等的区域，先使用 A 区，GC 的时候将 A 区存活的对象 Copy 到 B 区，然后清空 A 区，使用 B 区，再循环，这样不会产生内存碎片，但每次可用的空间只有 50%。

这个算法被普遍用来回收新生代，因为据研究表明，新生代 98% 的对象是「朝生暮死」的，所以存活的对象很少，复制的代价较小。A B 两个区实际也不用对等分，HotSpot 将内存分为一块 Eden 空间和两块 Survivor 空间，三者默认比例是 8:1:1，每次只使用 Eden 和一块 Survivor 空间，因此内存使用率是 90%，GC 时存活的对象被 Copy 到另外一块 Survivor 区域，如果存活的对象超过 10%，Survivor 空间不够用，可以用老年代进行分配担保，这些「溢出」的对象将直接进入老年代。

过程示例（E 表示 Eden，S0 和 S1 分别代表两块 Survivor，O 代表老年代）：

1. 使用 E 和 S0
2. 对 E 和 S0 进行 GC，存活的对象 Copy 到 S1 中（如果 S1 无法容纳，则存活的对象直接进入 O）
3. 清空 E 和 S0
4. 使用 E 和 S1
5. 继续循环 ...

Copying 算法一般不能用于老年代，一是因为老年代对象的存活率高，复制的代价大；二是因为如果不想浪费 50% 的空间，就得有额外空间进行分配担保，但没有额外空间给老年代进行担保。

#### Mark-Compact（标记 - 整理）算法

这个算法是根据老年代的特定设计的，标记过程和 Mark-Sweep 一样，只是没有清除过程，它将存活的对象向内存区域的一端移动，然后清理掉存活对象区域边界以外的内存。

#### Generational Collection（分代收集算法）

目前的商用 JVM 都使用这种算法，实际就是把 Java Heap 分为新生代和老年代，根据这两个区域不同的特定，选用前面几种算法中最合适的。因此，新生代使用 Copying 算法，老年代使用 Mark-Sweep 或 Mark-Compact 算法。

### 3.4 HotSpot 的算法实现

前面提到的对象存活判定算法和垃圾收集算法，在实现的时候必须要考量执行的效率，才能保证 VM 高效运行。

#### 枚举 GC Roots

在可达性分析过程中，必须要停顿所有 Java 执行线程（Stop The World），才能保证「一致性」，继而进行枚举 GC Roots，但 STW 会造成系统停顿。HotSpot 中用一个 OopMap 数据结构来存哪些地方存放着对象引用，因此 VM 可以快速完成 GC Roots 枚举。

#### Safepoint 和 Safe Region（安全点和安全区域）

（这一部分内容没仔细看，大致意思是程序只有在一些安全点或区域才能进行 GC，或生产 OopMap）

### 3.5 垃圾收集器

前面的垃圾收集算法是内存回收的方法论，这里的垃圾收集器就是具体实现，然而 JVM 规范没有限定垃圾收集器的具体实现，下面讨论的收集器是基于 HotSpot VM 的，包含了以下七种收集器：

![](http://cdn.yyqian.com/1455605122895_b.jpg)

#### Serial 收集器

Serial 是个单线程的收集器，它只使用一条线程去完成垃圾收集工作，并且在收集时，必须「Stop The World」，可能带来长时间的停顿，但它仍然是 VM 在 Client 模式下默认的新生代收集器。

#### ParNew 收集器

ParNew 是 Serial 的多线程版本，它是 Server 模式下默认的新生代收集器。

但是，ParNew 在单 CPU 的环境中不会比 Serial 有优势，因为线程交互是有开销的，只有在多 CPU 多线程的环境下有优势。

选择 Serial 或 ParNew 的其中一个重要原因是，目前只有这两个收集器才能与老年代的 CMS 收集器配合工作。

#### Parallel Scavenge 收集器

这个收集器的目的是让吞吐量（Throughput）可控，吞吐量 = 运行用户代码时间 /（运行用户代码时间 + 垃圾收集时间）。这个收集器有两个参数精确控制吞吐量：

- 最大垃圾收集停顿时间：缩短停顿时间是以牺牲吞吐量和新生代空间来换取的
- 吞吐量大小

用户需要在停顿时间和吞吐量之间进行权衡，这个时候也可以使用 UseAdaptiveSizePolicy 进行自适应调节，将两者都控制在一个合适的数值。

Parallel Scavenge 与 CMS 不兼容。

#### Serial Old 收集器

这个是 Serial 的老年代版本，使用「Mark - Compact」算法。主要是在 Client 模式下使用，在 Server 模式下有两个用途：

1. JDK 1.6 之前的版本与 Parallel Scavenge 配合使用
2. 作为 CMS 收集器的后备预案，在并发收集发生 Concurrent Model Failure 时使用

#### Parallel Old 收集器

这个是 Parallel Scavenge 的老年代版本，JDK 1.6 开始出现。出现的主要原因是，如果新生代选择了 Parallel Scavenge，老年代除了 Serial Old，没有优秀的收集器（Parallel Scavenge 与 CMS 不兼容）

因此，Parallel Scavenge 和 Parallel Old 组合可以运用在注重吞吐量以及 CPU 资源敏感的场合（Parallel Scavenge 是吞吐量优先的，CMS 比较费 CPU 资源）。

#### CMS 收集器（Concurrent Mark Sweep）

CMS 的目标是获取最短的回收停顿时间，适合在服务端用。基于「Mark - Sweep」算法实现。整个过程有四个步骤：

1. initial mark（初始标记）：需要 STW，标记 GC Roots 直接引用的对象，速度很快
2. concurrent mark（并发标记）：对 GC Roots 进行 Tracing，爬出所有的存活对象，耗时较长
3. remark（重新标记）：需要 STW，修正并发标记期间因为用户线程继续运作产生的变动，这个阶段比初始标记稍长，但远比并发标记短
4. concurrent sweep（并发清除）：这个阶段和并发标记阶段是整个过程耗时最长的，但这两个过程都不需要 STW，可以和用户线程一起工作。

CMS 的优点是并发收集、低停顿。缺点有三个：

1. 对 CPU 资源敏感。在并发阶段，它会因为占用一部分线程（CPU 资源）而导致应用程序变慢，总吞吐量降低。

2. 无法处理浮动垃圾（Floating Garbage），可能出现 Concurrent Model Failure，一旦这个异常出现，就需要用 Serial Old 进行一次 Full GC，停顿时间会很长。这个异常出现的原因是内存回收过程和用户线程是并发进行的，因此在 CMS 标记之后，会有新的垃圾产生，当次的 GC 不会回收这行新垃圾，也就成了「浮动垃圾」。因此 CMS 不能像其他收集器一样等到老年代几乎填满了再收集，需要多留些空间给程序运行时产生的浮动垃圾，如果留的空间不够，就会产生 Concurrent Model Failure。如果大量产生该异常，性能反而会降低。

3. CMS 是基于「Mark - Sweep」算法的，收集之后会产生大量内存碎片，如果大对象无法找到连续的内存空间，就需要提前进行一次 Full GC。为了解决这个问题，CMS 还有关于 Compact 的设置。

#### G1 收集器（Garbage - First）

G1 是一款面向服务端的垃圾收集器，跟 CMS 一样，立足于低停顿时间，但如果是追求吞吐量，G1 并没有更好的表现。G1 的特点如下：

1. 并行与并发：可以利用多核来缩短 STW 时间，部分 GC 过程可以与用户线程并发执行
2. 分代收集：G1 可以同时管理新生代和老年代
3. 空间整合：G1 从整体上来看是基于「Mark - Compact」算法的，不会产生内存碎片
4. 可预测的停顿：G1 可建立可预测的停顿时间模型，可以明确 M 毫秒的时间内，GC 的时间不能超过 N 毫秒

#### 总结

对于高性能服务器（多核多 CPU），适合的组合有：

1. 追求低停顿时间：ParNew + CMS（Serial Old 作为后备预案）
2. 追求吞吐量或者 CPU 资源敏感：Parallel Scavenge + Parallel Old
3. 未来的趋势：G1

Client 模式下，适合的组合是：

1. Serial + Serial Old

### 3.6 内存分配与回收策略

自动内存管理可以归结为两个问题：

1. 自动给对象分配内存
2. 自动回收分配给对象的内存

前面讲的都是关于如何自动回收内存，接下类就讲下如何给对象分配内存。

大体上来讲，对象的内存分配有以下原则：

从整个 JVM 管理的内存区域来看：

1. 正常是在 Heap 上分配
2. 如果 JIT 优化编译之后，有可能在 Stack 上分配。

从 Heap 区域来看：

1. 对象优先在新生代的 Eden 区分配，如果 Eden 区没有足够的空间进行分配，就会触发 Minor GC
2. 如果启用了 TLAB，则按线程优先在 TLAB 上分配
3. 大对象直接分配在老年代中，例如很长的字符串以及数组
4. 长期存活的对象将进入老年代：如果对象在 Eden 出生，经过 Minor GC，并且能被 Survivor 容纳，被移动到 Survivor 空间，年龄就增长一岁，当岁数达到阈值，就进入老年代。这个年龄判断也可以是动态的，譬如按一定比例来判定
5. 空间分配担保：Copying 收集算法中，如果 Survivor 空间无法容纳存活的对象，就会将存活的对象移动到老年代中，但这个时候也要保证老年代有足够的连续可用空间。因此，JVM 在 Minor GC 发生之前，会检查老年代最大可用的连续空间是否大于新生代所有对象的总空间，如果成立，则 Minor GC 确保是安全的，如果不成立，则 Minor GC 是有风险的，这个时候如果设置不允许冒险，则要进行 Full GC 来让老年代腾出更多空间；如果允许冒险，会根据以往数据再次检查，如果这次检查通过，则进行冒险的 Minor GC，如果没通过，则还是进行 Full GC。

Minor GC 和 Full GC 的区别：

- Minor GC：发生在新生代的 GC，Minor GC 非常频繁，回收速度也快
- Full GC / Major GC：发生在老年代的 GC，速度一般比 Minor GC 慢 10 倍以上。

## 4. 虚拟机性能监控与故障处理工具

---

JDK 的命令行工具都在 bin 目录中，常用的有：

1. jps
2. jstat
3. jinfo
4. jmap
5. jstack
6. HSDIS

可视化工具有：

1. JConsole：Java 监视与管理控制台
2. VisualVM：多合一故障处理工具

## 5. 调优案例分析

---

#### 高性能硬件上的程序部署策略

目标环境：4 个 CPU、16 GB 内存、64 位操作系统

在高性能硬件上部署程序，主要有两种方式：

1. 64 位 JDK 来使用大内存
2. 用若干 32 位 JVM ，搭配负载均衡器，建立逻辑集群来利用硬件资源

64 位 JDK 部署需要有把握把应用程序的 Full GC 频率控制得足够低，最好是一天一次，在深夜执行定时任务来触发 Full GC 或是自动重启应用服务器。控制 Full GC 频率的关键是控制老年代空间的增长，绝大多数对象要符合「朝生暮死」的特定，不能有成批、长生存时间的大对象产生，这样才能保障老年代空间的稳定。

使用 64 位 JDK 有可能面临以下问题:

1. Full GC 导致的长时间停顿
2. 64 位 JDK 性能普遍低于 32 位的
3. 相同程序在 64 位 JDK 中消耗的内存比 32 位的大

对于第二种方式，使用逻辑集群，要保证负载均衡器将一个固定的用户请求永远分配到固定的一个集群节点进行处理，适合使用无 Session 复制的亲合式集群。

使用逻辑集群也可能面临一些问题：

1. 节点竞争全区的资源，譬如磁盘竞争，容易导致 IO 异常
2. 很难高效利用某些资源池：譬如连接池，一般各个节点有自己独立的连接池
3. 受内存限制：32 位 Windows 平台每个进程最高只能 2GB 内存，堆一般最多到 1.5 GB
4. 大量使用本地缓存（譬如用 HashMap 作为 KV 缓存）的应用，会造成较大的内存浪费

最后的部署方案是：5 个 32 位 JDK 的逻辑集群，每个进程按 2GB 内存技术（其中堆固定为 1.5 GB），另外考虑到用户对响应速度比较关心，CPU 资源敏感度较低，用了 CMS 收集器进行垃圾回收。

#### 堆外内存导致的溢出错误

给 JVM 分配内存的时候，也要考虑留给系统和 Direct Memory 的空间。Direct Memory 不能像新生代、老年代那样，发现空间不足就通知 GC 进行回收，只能等老年代满了后进行 Full GC，「顺便」帮它清理下内存。

#### 外部命令导致系统缓慢

JVM 中调用外部 Shell 脚本是非常消耗资源的操作，要改为调用 Java 相关的 API 来完成相同的功能。

#### 服务器 JVM 进程崩溃

两台服务器间使用异步的方式远程调用对方的服务，如果两者服务速度不对等，譬如生产的速度远大于消费的速度，则可能随着时间变长就累积越来越多的等待线程和 Socket 连接。这种情况将异步调用改为生产者/消费者模式的消息队列即可。

#### 不恰当数据结构导致内存占用过大

目标环境：后台 RPC 服务器，64 位 JVM，-Xms4g -Xmx8g -Xmn1g，ParNew + CMS 收集器组合

问题：正常情况下 Minor GC 在 30 毫秒以内可以接受。但是，业务上每 10 分钟加载一个 80 MB 的数据文件，然后在内存中会产生超过 100 万个 `HashMap<Long, Long> Entry`，这个时候 Minor GC 会产生超过 500 毫秒的停顿。

原因：Minor GC 后，新生代大多数都是存活的，不符合「朝生暮死」的特点，导致 ParNew 这种基于 Copying 的算法复制的开销很大

治标不治本的办法：因为 Minor GC 对象的存活率很高，Survivor 空间也无法容纳存活的对象，因此可以去掉 Survivor 空间，让新生代存活的对象在第一次 Minor GC 后就进入老年代，等到老年代满的时候再 Full GC 清理掉。

---

注：

1. JVM 是 Java Virtual Machine（Java 虚拟机）的缩写
2. Primitive types 指各种基本数据类型（boolean、byte、char、short、int、float、long、double）
3. GC 是 Garbage Collect 或 Garbage Collection 的缩写
4. STW 是 HotSpot 中「Stop The World」的缩写
