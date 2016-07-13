---
title: Java 中的容器
date: 2016-07-11 11:00:55
permalink: 1468206055000
tags: Java
---

本文主要简单介绍下 Java 中有哪些容器接口以及它们的实现，并且给出选择它们的合适的场景。不建议使用的 Vector、Hashtable、Stack 等容器类在这里都不提了。

## Collection

我们先来看看整个 Collection 下面有哪些接口：

![](http://docs.oracle.com/javase/tutorial/figures/collections/colls-coreInterfaces.gif)

这几个接口对应了我们常用的一些抽象数据类型(Abstract Data Type)：链表、队列、栈、集合、映射表。

其中的 Deque 实际上是继承自 Queue 的，它可以代替 Stack 类来使用（以前的 Stack 类已经不建议使用了）。Set 可以看作是 Map 的一种特例（每个节点只有 key，没有 value），SortedSet 和 SortedMap 在你需要维持顺序的时候使用。

选择某个接口应该很简单，根据你需要的 ADT 进行选择就可以了。
<!-- more -->
## List

List 的常用实现有：

1. **ArrayList**，需要快速随机访问时使用
2. LinkedList，需要快速插入和删除时使用

并发的实现有：

1. CopyOnWriteArrayList，无需同步
2. SynchronizedList，需要同步

Arrays.asList() 方法可以返回一个 List View，它只能读不能改（add，remove 等方法都会抛出异常）

## Set

常用实现有：

1. **HashSet**，哈希表实现
2. TreeSet，红黑树实现
3. LinkedHashSet

特殊的实现：

1. EnumSet：Set 的元素都是 Enum 类型的
2. CopyOnWriteArraySet：并发实现

## Map

常用实现同 Set: **HashMap**, TreeMap, LinkedHashMap

特殊的实现：

1. EnumMap
2. ConcurrentHashMap：同时也是 ConcurrentMap 的实现

## SortedSet & SortedMap

它们的实现分别是：TreeSet, TreeMap

## Queue

Queue 的常用实现有：

1. **LinkedList**
2. PriorityQueue

并发的 Queue 有个接口 BlockingQueue，它的实现有：

1. LinkedBlockingQueue
2. ArrayBlockingQueue
3. PriorityBlockingQueue
4. DelayQueue
5. SynchronousQueue
6. ConcurrentLinkedQueue

## Deque

Queue 的常用实现有：

1. **ArrayDeque**
2. LinkedList

并发的实现有：

1. LinkedBlockingDeque
2. ConcurrentLinkedDeque

常用的实现类总结（蓝字是接口）：

![Screen Shot 2016-07-11 at 2.10.29 PM.png](http://cdn.yyqian.com/201607111412-Fihq5IyCVZ5Jmbh_YPp-9-UcIXmT?imageView2/2/w/800/h/600)

## 其他

这六个接口(除了 Queue 和 Deque)都有自己的加锁同步版本：Collection, List, Set, Map, SortedSet, SortedMap。它们通过调用 Collections 中的工厂方法 synchronizedXXXXX 来获得实例。

以上六个接口还有各自 immutable 的版本，通过调用 Collections 中的工厂方法 unmodifiableXXXXXX 来获得实例。

java.util.concurrent 还包含了多个线程安全的容器，并且它们都没有使用锁。常用的见下图（蓝字是接口）

![Screen Shot 2016-07-11 at 2.10.40 PM.png](http://cdn.yyqian.com/201607111412-Fn7Sp3v23nc0QGUP_rZxKtcXilMz?imageView2/2/w/800/h/600)

## 各个接口的常用方法（API）

Collection 作为最顶层的接口，它的常用方法有必要熟悉下：

```Java
public interface Collection<E> extends Iterable<E> {
    int size();
    boolean isEmpty();
    boolean contains(Object o);
    Iterator<E> iterator();
    Object[] toArray();
    <T> T[] toArray(T[] a);
    boolean add(E e);
    boolean remove(Object o);
    boolean containsAll(Collection<?> c);
    boolean addAll(Collection<? extends E> c);
    boolean removeAll(Collection<?> c);
    boolean retainAll(Collection<?> c);
    void clear();
    boolean equals(Object o);
    int hashCode();
    // 以下是 JDK 1.8 新增的
    default Stream<E> stream() {
        return StreamSupport.stream(spliterator(), false);
    }
    default Stream<E> parallelStream() {
        return StreamSupport.stream(spliterator(), true);
    }
}
```

List 特有的方法：

```
// 以下是根据 index 进行 CRUD 操作
E get(int index);
E set(int index, E element);
void add(int index, E element);
E remove(int index);
// 以下是查询
int indexOf(Object o);
int lastIndexOf(Object o);
// 视图
List<E> subList(int fromIndex, int toIndex);
```

Queue 作为 FIFO 特有的方法：

```
boolean offer(E e);
E poll();
E peek();
```

Deque 作为 LIFO 特有的方法：

```
void push(E e);
E pop();
E peek();
```

Set 没有任何特有的方法

Map 不继承自 Collection，因此是独立的：

```
public interface Map<K,V> {
    int size();
    boolean isEmpty();
    boolean containsKey(Object key);
    boolean containsValue(Object value);
    V get(Object key);
    V put(K key, V value);
    V remove(Object key);
    void putAll(Map<? extends K, ? extends V> m);
    void clear();
    Set<K> keySet();
    Collection<V> values();
}
```

## 实现类的源码解析

我们先不管并发包中的那几个实现，只关注 java.util 中的常用实现类。我个人觉得最值得研究的几个实现类是：

1. ArrayList：主要关注 add 和 remove 方法中涉及到的扩容和数组移动，看下可变数组是如何实现的
2. LinkedList：链表是多个抽象瘦据类型的实现，它结构简单，操作原理简单，应用广泛，是其他更复杂数据结构的蓝本
3. HashMap：个人觉得是很漂亮的一个实现，包含了可变数组 + 链表 + 红黑树，还有哈希值、索引值的计算，值得细细品味
4. LinkedHashMap：这个继承自 HashMap，相当于是 LinkedList 和 HashMap 的合体。它可以作为 LRUCache 来使用，所以可以通过读这个源码探究下 LRUCache 的原理

还有几个可以一读的类：

1. TreeMap：这个就是红黑树的实现，红黑树的操作比较繁杂，个人觉得弄清楚原理就行了（2-3树和红黑树的对应关系），也没必要死扣源码中的每一步操作。
2. PriorityQueue：这个是最小堆的实现，与红黑树类似，读这个类的源码实际就是在读堆的实现原理。
3. ArrayDeque：就是双向版本的 ArrayList，内部实现上与 ArrayList 大体相似，只是字段中的指针从一个变成了两个

Set 所有的实现类实际都是套了马甲的对应的 Map，所以只需要研究对应的 Map 就够了。
