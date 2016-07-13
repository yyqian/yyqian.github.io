---
title: Java 源码分析之 ArrayDeque
date: 2016-07-13 14:38:56
permalink: 1468391936000
tags: Java
---

## 概览

ArrayDeque 在实现上类似于 ArrayList，在功能上类似于 LinkedList，实现上比 ArrayList 稍复杂一点，功能上比 LinkedList 更强大一点。它实现了 Deque 接口，所以是个双端队列，可以被当做 FIFO 和 LIFO 两种队列来使用。

## 存储结构-字段

和 ArrayList 的区别就是从一个指针变成两个指针

```
transient Object[] elements; // non-private to simplify nested class access
// 头部元素的索引
transient int head;
// 尾部元素的下一个空位的索引，也就是说下一个被加入元素的位置
transient int tail;
```
<!-- more -->
## 容量相关操作

从下面的函数可以看出，数组大小必须是 2 次幂，这个要求和 HashMap 中的桶数组是相同的。

```
private void allocateElements(int numElements) {
    int initialCapacity = MIN_INITIAL_CAPACITY;
    // Find the best power of two to hold elements.
    // Tests "<=" because arrays aren't kept full.
    if (numElements >= initialCapacity) {
        initialCapacity = numElements;
        initialCapacity |= (initialCapacity >>>  1);
        initialCapacity |= (initialCapacity >>>  2);
        initialCapacity |= (initialCapacity >>>  4);
        initialCapacity |= (initialCapacity >>>  8);
        initialCapacity |= (initialCapacity >>> 16);
        initialCapacity++;

        if (initialCapacity < 0)   // Too many elements, must back off
            initialCapacity >>>= 1;// Good luck allocating 2 ^ 30 elements
    }
    elements = new Object[initialCapacity];
}
```

扩容，由于数组大小是 2 次幂，所以每次扩容实际就是容量翻倍。扩容只有当数组满的时候再扩，见下图。这个地方用的是 System.arraycopy 实现的数据移动，而 ArrayList 中的 grow 方法是用 Arrays.copyOf 在原地实现的。

```
private void doubleCapacity() {
    // 因为这个数组是环形的（尾巴连着头部），所以当数组满的时候，head == tail
    assert head == tail;
    int p = head;
    int n = elements.length;
    int r = n - p; // number of elements to the right of p
    // 容量翻倍
    int newCapacity = n << 1;
    // 小于零说明溢出
    if (newCapacity < 0)
        throw new IllegalStateException("Sorry, deque too big");
    // 分配新的空间
    Object[] a = new Object[newCapacity];
    // 这次 copy 对应于下图中的红线部分
    System.arraycopy(elements, p, a, 0, r);
    // 这次 copy 对应于下图中的绿线部分
    System.arraycopy(elements, 0, a, r, p);
    // elements 字段指向扩容后的数组
    elements = a;
    // head 和 tail 索引的位置也重置了
    head = 0;
    tail = n;
}
```

![56e97f8c98931.png](http://cdn.yyqian.com/201607131506-FpHXwz6zhztfrq8-fsrYJMu6WfTE?imageView2/2/w/800/h/600)

## 添加、移除操作

在哪个位置添加、删除都是差不多的，我们只以 push 和 pop 为例分析下源码：

```
public void push(E e) {
    addFirst(e);
}
public void addFirst(E e) {
    if (e == null)
        throw new NullPointerException();
    elements[head = (head - 1) & (elements.length - 1)] = e;
    if (head == tail)
        doubleCapacity();
}
```

```
public E pop() {
    return removeFirst();
}
public E removeFirst() {
    E x = pollFirst();
    if (x == null)
        throw new NoSuchElementException();
    return x;
}
public E pollFirst() {
    int h = head;
    @SuppressWarnings("unchecked")
    E result = (E) elements[h];
    // Element is null if deque empty
    if (result == null)
        return null;
    elements[h] = null;     // Must null out slot
    head = (h + 1) & (elements.length - 1);
    return result;
}
```

以上代码中值得注意的是这两个操作：

```
(head - 1) & (elements.length - 1)
(h + 1) & (elements.length - 1);
```

它的目的是让数组变成一个等效的环形数组，在数组大小为 2 次幂的情况下，上面两个操作等效为取模操作，这一点和 JDK 1.8 的 HashMap 相同，可以大幅提高取模的效率，具体解释见我的 HashMap 源码分析。

![56e97c2195747.png](http://cdn.yyqian.com/201607131523-FmjLWYxwkB9luBtJuOcZW3bSeZWA?imageView2/2/w/800/h/600)

## 总结

ArrayDeque 是基于环形数组实现的双向队列，通过两个指针标记头尾，并且由于环形的实现需求，我们需要进行频繁的取模操作，在这点上作者使用了 HashMap 中相同的优化：把数组大小限定为 2 次幂，用 AND 运算来代替取模操作，获得效率上的提升。

它的效率高于双向链表 LinkedList，但要注意 ArrayDeque 不支持为 null 的元素。

---

参考资料：

- [Java 容器源码分析之 Deque 与 ArrayDeque](http://blog.jrwang.me/2016/java-collections-deque-arraydeque/)