---
title: Java 源码分析之 ArrayList
date: 2016-07-12 14:51:11
permalink: 1468306271000
tags: Java
---

## 概览

ArrayList 是最常用的集合类，它可以当做一种可变长度的数组来使用，最大的区别就是元素不能是 primitive type，只能是 Object。

ArrayList 实现了以下四个接口，后三个都是标记接口，不需要实现任何方法，其中 RandomAccess 接口表明 ArrayList 支持随机访问（因为它基于数组）

```
public class ArrayList<E> extends AbstractList<E>
        implements List<E>, RandomAccess, Cloneable, java.io.Serializable
```

接下来，我们从存储结构和功能实现两部分来对 ArrayList 进行剖析。
<!-- more -->
## 存储结构-字段

```
transient Object[] elementData;
private int size;
```

elementData 引用的 Object 数组用来存放数据，是该类核心的属性，这个字段被标记 transient，所以序列化不会包含内部存储的实际的数据（其他容器类也不会）。

size 既可以用来记录当前容器中的实际元素数量，也可以被当作一个指针来标记数据的尾部。

## 功能实现-方法

这里主要解读下最基本的 CRUD 操作，以及比较关键的扩容操作

### 容量相关方法

扩容方法 grow 中的关键函数是 `Arrays.copyOf`，它可以直接返回一个新的长度的数组，并且已完成了内容的复制。每次扩容之后大小会变成之前的 1.5 倍。

```
private static final int DEFAULT_CAPACITY = 10;
private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};

public void ensureCapacity(int minCapacity) {
    int minExpand = (elementData != DEFAULTCAPACITY_EMPTY_ELEMENTDATA)
        // any size if not default element table
        ? 0
        // larger than default for default empty table. It's already
        // supposed to be at default size.
        : DEFAULT_CAPACITY;

    if (minCapacity > minExpand) {
        ensureExplicitCapacity(minCapacity);
    }
}

private void ensureCapacityInternal(int minCapacity) {
    // 在第一次调用 add 之前，我们的数组实际大小为零，可以是看作延迟初始化的目的
    if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
        minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
    }
    // 进行实际的容量检查
    ensureExplicitCapacity(minCapacity);
}
private void ensureExplicitCapacity(int minCapacity) {
    // modCount 继承自父类，由于 add 和 addAll 方法都会调用 ensureExplicitCapacity 这个函数，所以可以放在这里。
    modCount++;
    // 如果容量不够就进行扩容
    // overflow-conscious code
    if (minCapacity - elementData.length > 0)
        grow(minCapacity);
}
private void grow(int minCapacity) {
    // overflow-conscious code
    // 扩充为原来的 1.5 倍
    int oldCapacity = elementData.length;
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // 进行实际的扩容操作
    // minCapacity is usually close to size, so this is a win:
    elementData = Arrays.copyOf(elementData, newCapacity);
}
```

### add 方法

add 方法相关的源代码如下，实际的增加操作就只有一步 `elementData[size++] = e;`，但在这之前首先要判断容量是否足够。

```
public boolean add(E e) {
    // 确保容量足够
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    // 新的元素添加到数组的尾部
    elementData[size++] = e;
    // 如果成功返回 true
    return true;
}
```

### get 和 set 方法

这两个方法很显而易见

```
public E get(int index) {
    rangeCheck(index);
    return elementData(index);
}
public E set(int index, E element) {
    rangeCheck(index);
    E oldValue = elementData(index);
    elementData[index] = element;
    return oldValue;
}
E elementData(int index) {
    // 进行强制转换
    return (E) elementData[index];
}
private void rangeCheck(int index) {
    if (index >= size)
        throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}
```

### remove 方法

这个方法的功能实际是通过 System.arraycopy 函数实现的，在 remove 之后，要注意可能导致的内存泄露

```
public E remove(int index) {
    // 边界检查
    rangeCheck(index);

    modCount++;
    E oldValue = elementData(index);
    // 如果我们从数组中部移除一个元素，我们要把它之后的元素整体左移一位，所以我们要计算移动元素的个数（下面的 System.arraycopy 函数需要该参数）
    int numMoved = size - index - 1;
    // 调用 System.arraycopy 方法整体移动一段元素
    if (numMoved > 0)
        System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
    // 移动之后，要注意尾部可能引入内存泄露，所以这个地方必须手动设置为 null，以便被 GC 
    elementData[--size] = null; // clear to let GC do its work
    return oldValue;
}
```

## 总结

ArrayList 内部通过数组实现，可以看作加强版的数组，封装了若干操作。它有高效的随机访问特性，但每次删除元素都需要用 System.arraycopy 方法移动数组，增加元素的时候也可能需要用 Arrays.copyOf 方法进行扩容，因此在需要频繁插入、删除操作的情况下应当使用 LinkedList。
