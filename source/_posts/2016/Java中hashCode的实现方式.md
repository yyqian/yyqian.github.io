---
title: Java 中 hashCode 的实现方式
date: 2016-04-22 16:37:34
permalink: 1461314254577
tags: Java
---

hash code 是在数据结构 hash table 中，将 hash function 作用于存储的对象，然后得到的一个值。其中，hash function 可以有多种实现，但实现的要求之一是得到的 hash code 尽可能的平均分布在一个取值空间内。hash code 的分布越是均匀，对 hash table 的性能就越好。这个 hash function 的实现是个研究的课题，最好留给数学和计算机领域的研究者来完成，我们自己不要去重新发明轮子，接下来我们就看看一种正确的实现方式。

「Effective Java」中有一篇专门讲了如何正确地实现 hashCode 方法，这里就不复制粘贴了。我研究了一下 Java 的源码之后，发现 Java 类库的实现方式和该书作者写的方法是几乎相同的（boolean 类型以及初始值的选择有差别）。因此，我们现在可以直接调用 Java 类库，而不用自己去按部就班地实现了。下面就讨论下如何针对不同类型的值来计算 hashCode。

## 单个基本类型的值

基本类型有八种：boolean, byte, char, short, int, long, float, double

它们的 wrapper class 都有一个静态的 hashCode 方法，例如 Long 类的源码：
<!-- more -->
```java
public static int hashCode(long value) {
        return (int)(value ^ (value >>> 32));
    }
```

因此，可以这样计算基本类型的 hash code：

```java
  int hashCode = Long.hashCode(1920L);
```

## 单个对象

Object 类有 hashCode 方法，因此所有对象都有 hashCode 方法, Object 类的源码是：

```java
public native int hashCode();
```

它是个 JNI(Java 本地接口)，由虚拟机实现。

除此之外，JDK 1.7 有了新的 Objects 类，其中也有个 hashCode 方法：

```java
    public static int hashCode(Object o) {
        return o != null ? o.hashCode() : 0;
    }
```

我们可以看到，这个方法的好处就是可以正确处理对象为 null 的情况。在非空的情况下，调用的还是 object 本身的 hashCode 方法。因此，计算对象的 hash code 推荐的方式是：

```java
  int hashCode = Objects.hashCode(obj);
```

## 数组

Arrays 类重载了八个基本类型数组以及 Object 数组的 hashCode 方法。因此，可以通过以下方式计算 hash code：

```java
  int hashCode = Arrays.hashCode(ary);
```

这里要注意的是，如果这个数组只有一个元素，得到的 hashCode 是不等于这个元素自身的 hashCode, 例如：

```java
  Integer.hashCode(3); // 3
  int[] a = {3};
  Arrays.hashCode(a); // 34
```

这里的原因可以通过阅读源码得知：

```java
    public static int hashCode(int a[]) {
        if (a == null)
            return 0;

        int result = 1;
        for (int element : a)
            result = 31 * result + element;

        return result;
    }
```

## 多个不同类型的值

Objects 类有个静态方法 hash：

```java
  public static int hash(Object... values) {
        return Arrays.hashCode(values);
    }
```

它接受 Object vararg，因此，任意多个不同类型的值都可以通过这种方式计算 hash code，例如：

```java
  int hashCode = Objects.hash(x, y, z);
```

个人觉得这个方法最大的缺陷就是对于基本类型的值，都会被 autoboxing 成为 wrapper class，效率相对来说低一点。

这里同样要注意的是，Object.hash(x) 不等于 x 自身的 hash code，原因同上面数组的情况，所以不要用 hash 方法来计算单个对象的 hash code。


## 总结

我们可以把 hash code 计算的方法总结如下：

```java
XXX.hashCode(primitive); // primitve 是基本类型，XXX 是 primitve 的 Wrapper Class
Objects.hashCode(obj); // obj 是对象
Arrays.hashCode(ary); // ary 是各种数组
Objects.hash(x, y, z); // 参数是 varargs，可以是多个各种类型，但不建议参数个数只有一个
```

## 额外的讨论

在 Java 的源码中，hash code 的计算并不都是统一使用了上面讨论的实现。例如在 HashMap 类中有个 sub-class：Node<K,V>，该类有个方法：

```java
public final int hashCode() {
    return Objects.hashCode(key) ^ Objects.hashCode(value);
}
```

这里的策略是先计算每个 field 自身的 hash code，然后将多个 hash code 使用 XOR 二进制运算进行合并，这样可行的原因是：

```
A B AND
0 0  0
0 1  0
1 0  0
1 1  1

A B OR
0 0  0
0 1  1
1 0  1
1 1  1

A B XOR
0 0  0
0 1  1
1 0  1
1 1  0
```

XOR 在合并两个 bits 的时候，得到的值的分布是均匀的，而 AND 和 OR 会偏向 0 或者 1。

但是，这个策略有自身的特点，有优点也有缺点：

1. 速度快，前面数组中使用的方法需要一次加法和乘法，而这里是一次位运算
2. 跟 fields 之间合并的先后顺序无关，符合交换律，这个特点在某些情况下是优点，有些情况下是缺点
3. 两个相同的值，XOR 之后的结果是 0，因此在某些情况下，hash code 可能会有一大部分集中在 0；并且 0 也不是一个有意义的值，一般 null 的 hash code 才会是 0.
