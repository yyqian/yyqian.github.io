---
title: Java 源码分析 - HashSet/TreeSet/LinkedHashSet
date: 2016-07-13 10:44:34
permalink: 1468377874000
tags: Java
---

这篇文章把各种 Set 放在一起讲的原因是：它们实际都是穿着马甲的各种 Map，它们用一个 dummy object 来填充 Map 中的 value，剩下的事全部由 Map 来代劳。眼见为实，耳听为虚，下面就通过源码来证明这一点。

首先从下面的两个字段和构造函数，我们就能看到：

- 内部数据存储是通过 HashMap<E,Object> 存储的
- 准备了一个没有实际内容的 Object
- 构造实例的时候在内部构造了一个 HashMap 实例
<!-- more -->
```
private transient HashMap<E,Object> map;

private static final Object PRESENT = new Object();

public HashSet() {
    map = new HashMap<>();
}
```

add 和 remove 操作，直接调用 HashMap 中相关的方法，值用 PRESENT 这个 dummy object 来填充

```
public boolean add(E e) {
    return map.put(e, PRESENT)==null;
}
public boolean remove(Object o) {
    return map.remove(o)==PRESENT;
}
```

其他操作也都是直接调用 HashMap 的对应方法

```
public int size() {
    return map.size();
}
public boolean isEmpty() {
    return map.isEmpty();
}
public boolean contains(Object o) {
    return map.containsKey(o);
}
```

TreeSet 和 LinkedHashSet 也是类似的，就不赘述了。

问题：HashSet 和 HashMap 之间的这种关系体现的是什么设计模式？

有点像个代理模式，但代理模式要求代理类和目标类实现同一个接口，HashSet 和 HashMap 不满足这一点，装饰器模式也是这样。最接近的模式应该是适配器（Adapter，又名 Wrapper）模式。不过非得归类到某种设计模式也感觉挺无聊的。
