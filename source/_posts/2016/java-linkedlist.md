---
title: Java 源码分析 - LinkedList
date: 2016-07-13 09:01:53
permalink: 1468371713000
tags: Java
---

## 概览

LinkedList 也是一个很常用的容器类，从它实现的接口来看，它实现了 List 和 Deque，而 Deque 又继承了 Queue，因此，LinkedList 可以当做链表、队列、栈来使用，很全能。我们接下来就剖析下 JDK 1.8 中的 LinkedList 源码。

```
public class LinkedList<E>
    extends AbstractSequentialList<E>
    implements List<E>, Deque<E>, Cloneable, java.io.Serializable
```
<!-- more -->
## 存储结构

从字段来看，就是个很典型的双向链表（有些文章说这是个双向循环链表，但是从注释来看以及从源码实现来看，头尾是不连在一起的，或许是版本的差异？）。

```
transient int size = 0;

/**
 * Pointer to first node.
 * Invariant: (first == null && last == null) ||
 *            (first.prev == null && first.item != null)
 */
transient Node<E> first;

/**
 * Pointer to last node.
 * Invariant: (first == null && last == null) ||
 *            (last.next == null && last.item != null)
 */
transient Node<E> last;
```

节点的定义：

```
private static class Node<E> {
    E item;
    Node<E> next;
    Node<E> prev;

    Node(Node<E> prev, E element, Node<E> next) {
        this.item = element;
        this.next = next;
        this.prev = prev;
    }
}
```

## 链表操作

我们只探究一下基本的 CRUD 操作，以及相关的关键方法

### 关键方法

以下几个私有方法是各种 CRUD 操作的内部实现。

向头部添加元素

```
private void linkFirst(E e) {
    final Node<E> f = first;
    // 新节点 prev 为 null，next 为原来的头部
    final Node<E> newNode = new Node<>(null, e, f);
    // 头指向新节点
    first = newNode;
    if (f == null)
        // 如果原来的链表是空的话，那么现在头尾指向同一个节点
        last = newNode;
    else
        // 原来的头节点的 prev 指向新的头节点，完成双向链接
        f.prev = newNode;
    size++;
    modCount++;
}
```

向尾部添加元素

```
void linkLast(E e) {
    final Node<E> l = last;
    // 新节点 next 为 null，prev 为原来的尾部，后面的步骤跟 linkFirst 类似，不赘述了
    final Node<E> newNode = new Node<>(l, e, null);
    last = newNode;
    if (l == null)
        first = newNode;
    else
        l.next = newNode;
    size++;
    modCount++;
}
```

在任意一个非空节点前面插入元素

```
// 插入到 succ 节点的前面
void linkBefore(E e, Node<E> succ) {
    // assert succ != null;
    // 获取前驱
    final Node<E> pred = succ.prev;
    // 初始化的时候完成前驱和后继的单向链接
    final Node<E> newNode = new Node<>(pred, e, succ);
    // 完成后继的双向链接
    succ.prev = newNode;
    // 完成前驱的双向链接
    if (pred == null)
        first = newNode;
    else
        pred.next = newNode;
    size++;
    modCount++;
}
```

移除任意一个非空节点

```
E unlink(Node<E> x) {
    // assert x != null;
    // 我们后面需要返回被删除节点的值，所以要暂存
    final E element = x.item;
    // 获取该节点前驱和后继
    final Node<E> next = x.next;
    final Node<E> prev = x.prev;

    // 前驱指向后继
    if (prev == null) {
        first = next;
    } else {
        prev.next = next;
        // 把 x 前驱的引用清除，以便 GC
        x.prev = null;
    }

    // 后继指向前驱
    if (next == null) {
        last = prev;
    } else {
        next.prev = prev;
        // 把 x 后继的引用清除，以便 GC
        x.next = null;
    }

    // 把 x 值的引用清除，以便 GC
    x.item = null;
    size--;
    modCount++;
    return element;
}
```

根据索引获取元素，这个是耗时的 O(n) 时间复杂度

```
Node<E> node(int index) {
    // assert isElementIndex(index);

    // 根据 index 大小决定从头查找还是从尾部查找
    // int i 作为计数器，int index 作为目标数
    if (index < (size >> 1)) {
        Node<E> x = first;
        for (int i = 0; i < index; i++)
            x = x.next;
        return x;
    } else {
        Node<E> x = last;
        for (int i = size - 1; i > index; i--)
            x = x.prev;
        return x;
    }
}
```

### add

不指定添加位置的话，默认添加到尾部。实际工作由 linkLast 或 linkBefore 方法实现。

```
public boolean add(E e) {
    linkLast(e);
    return true;
}
// List 特有的方法
public void add(int index, E element) {
    checkPositionIndex(index);

    if (index == size)
        linkLast(element);
    else
        linkBefore(element, node(index));
}
```

### get

用 node 方法获取任意索引的元素

```
// List 特有的方法
public E get(int index) {
    checkElementIndex(index);
    return node(index).item;
}
```

### set

先用 node 方法定位获得目标对象，然后暂存原值，赋新值，返回原值。

```
// List 特有的方法
public E set(int index, E element) {
    checkElementIndex(index);
    Node<E> x = node(index);
    E oldVal = x.item;
    x.item = element;
    return oldVal;
}
```

### remove

如果不指定位置的话，默认从头部删除。remove(Object o) 比 remove(int index) 效率高，因为省去了 node(index) 这一步耗时的操作。

```
public E remove() {
    return removeFirst();
}
// List 特有的方法
public E remove(int index) {
    checkElementIndex(index);
    return unlink(node(index));
}
public boolean remove(Object o) {
    if (o == null) {
        for (Node<E> x = first; x != null; x = x.next) {
            if (x.item == null) {
                unlink(x);
                return true;
            }
        }
    } else {
        for (Node<E> x = first; x != null; x = x.next) {
            if (o.equals(x.item)) {
                unlink(x);
                return true;
            }
        }
    }
    return false;
}
```

### Queue: offer, poll, peek

从下面源码中可以看出，offer 添加到尾部，poll 从头部移除，peek 从头部查看，所以这个 FIFO 的 input 在尾部，output 在头部

```
public boolean offer(E e) {
    // add 默认添加到尾部
        return add(e);
    }

public E poll() {
    final Node<E> f = first;
    return (f == null) ? null : unlinkFirst(f);
}
public E peek() {
    final Node<E> f = first;
    return (f == null) ? null : f.item;
}
```

### Stack: push, pop, peek

push 方法将元素添加到头部，pop 从尾部移除，peek 方法同上，也是从头部查看。所以这个 LIFO 的 input 和 output 都是头部。

```
public void push(E e) {
        addFirst(e);
    }

public E pop() {
    return removeFirst();
}
```

## 总结

LinkedList 是很典型的链表结构，数据结构简单，操作实现也很简单，但能实现多种抽象数据类型。它在不指定索引情况下的 add()，remove() 组合，实际是 FIFO 的实现。但还是建议在使用 Queue 的情形下用 offer 和 poll，在使用 Stack 的情形下用 push 和 pop。

LinkedList 在不指定索引情况下的插入、删除操作一般都是 O(1) 复杂度的，但指定索引情况下的多数操作都是 O(n) 的，这点和 ArrayList 正好相反，两者形成了很好的互补。
