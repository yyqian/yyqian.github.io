---
title: Java 源码分析之 LinkedHashMap
date: 2016-07-13 09:02:07
permalink: 1468371727000
tags: Java
---

## 概览

LinkedHashMap 继承自 HashMap，它在功能上增加了双向链表的实现。它有两种顺序访问方式：插入序（insertion-order）或访问序（access-order）。插入序和普通的链表是一致的，类似 FIFO，而访问序实际就是 LRU(least-recently-used) 顺序，这点在后面的 LRUCache 会提到。

```
public class LinkedHashMap<K,V>
    extends HashMap<K,V>
    implements Map<K,V>
```

## 存储结构-字段

我们只关注扩展的部分，这里面值得注意的是 head 和 tail 字段，以及扩展后的内部节点类中的 before 和 after 字段。
<!-- more -->
```
// 类似 LinkedList，一头一尾两个引用
transient LinkedHashMap.Entry<K,V> head;
transient LinkedHashMap.Entry<K,V> tail;
// true 为 access-order，false 为 insertion-order
final boolean accessOrder;
```

```
// 内部的节点在 HashMap 的 Node 基础上进行了扩展，增加了 before 和 after 字段，这个字段要和 Node 自身的 next 区分开来，两者是不同层面的东西
// 桶内单向链表通过 next 链接
// 全局的双向链表通过 before 和 after 链接
static class Entry<K,V> extends HashMap.Node<K,V> {
    Entry<K,V> before, after;
    Entry(int hash, K key, V value, Node<K,V> next) {
        super(hash, key, value, next);
    }
}
```

## 功能实现-方法

### 插入序的实现

添加和替换操作

```
// link at the end of list
// 将新节点添加到双向链表的尾部
private void linkNodeLast(LinkedHashMap.Entry<K,V> p) {
    LinkedHashMap.Entry<K,V> last = tail;
    tail = p;
    if (last == null)
        // 如果 last 为空，说明之前的双向链表是空的，所以此时 head 也指向新的节点
        head = p;
    else {
        // 双向链接
        p.before = last;
        last.after = p;
    }
}

// apply src's links to dst
// 用 dst 节点替换双向链表中的 src 节点
private void transferLinks(LinkedHashMap.Entry<K,V> src,
                           LinkedHashMap.Entry<K,V> dst) {
    // 修改 dst 的前驱和后继链接
    LinkedHashMap.Entry<K,V> b = dst.before = src.before;
    LinkedHashMap.Entry<K,V> a = dst.after = src.after;
    // 让前驱和后继链接指向 dst，完成双向链接
    if (b == null)
        head = dst;
    else
        b.after = dst;
    if (a == null)
        tail = dst;
    else
        a.before = dst;
}
```

创建新节点之后，就调用 linkNodeLast 方法将之加入到双向链表的尾部

```
Node<K,V> newNode(int hash, K key, V value, Node<K,V> e) {
    LinkedHashMap.Entry<K,V> p =
        new LinkedHashMap.Entry<K,V>(hash, key, value, e);
    linkNodeLast(p);
    return p;
}
```

有了这几个方法之后，每次添加新节点，都是添加到双向链表的尾部，因此实现了类似 FIFO 的顺序，也就是插入序。

### 访问序的实现

前面说了插入序的实现，那访问序如何实现呢？实际上 HashMap 中已经为我们做好准备了，HashMap 的 remove、put、replace 等操作在完成之后，会调用以下几个方法之一，但是它们在 HashMap 中是空的，注释中写明了是为了方便 LinkedHashMap 实现的

```
// Callbacks to allow LinkedHashMap post-actions
void afterNodeAccess(Node<K,V> p) { }
void afterNodeInsertion(boolean evict) { }
void afterNodeRemoval(Node<K,V> p) { }
```

那么我们就来看看 LinkedHashMap 覆盖的这几个方法：

```
// 这个和访问序无关，由于双向链表的存在，我们在 remove 的时候需要一些额外的工作，除了把节点从哈希桶的单向链表中移除，也需要把它从双向链表中移除，为了不修改父类的逻辑，我们把这些额外的工作放在了这儿
void afterNodeRemoval(Node<K,V> e) { // unlink
    LinkedHashMap.Entry<K,V> p =
        (LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
    p.before = p.after = null;
    if (b == null)
        head = a;
    else
        b.after = a;
    if (a == null)
        tail = b;
    else
        a.before = b;
}

// 我们可以选择是否删除最老的节点
void afterNodeInsertion(boolean evict) { // possibly remove eldest
    // 如果是访问序，最老的节点在头部，最年轻的节点在尾部，所以这里 first 指向的是最老的节点
    LinkedHashMap.Entry<K,V> first;
    if (evict && (first = head) != null && removeEldestEntry(first)) {
        // 这里需要判断：
        // 不是在构造方法中
        // 头元素不为空
        // 要求删除最老元素
        K key = first.key;
        removeNode(hash(key), key, null, false, true);
    }
}

// 这个和访问序最息息相关，它会把被访问的节点，移动到双向链表尾部，也就是最年轻的位置
void afterNodeAccess(Node<K,V> e) { // move node to last
    // 指向最年轻的节点，也就是尾部节点
    LinkedHashMap.Entry<K,V> last;
    // 判断是否采用了 access-order 以及被访问节点是否已经在尾部了
    if (accessOrder && (last = tail) != e) {
        // 强制转换 Node 为 Entry
        // 获得被访问节点的前驱和后继
        LinkedHashMap.Entry<K,V> p =
            (LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
        // 被访问节点作为尾部，后继为 null
        p.after = null;
        // 让被访问节点的前驱和后继相互链接
        if (b == null)
            head = a;
        else
            b.after = a;
        if (a != null)
            a.before = b;
        else
            last = b;
        // 让被访问节点和之前的尾部节点双向链接
        if (last == null)
            head = p;
        else {
            p.before = last;
            last.after = p;
        }
        // 全局的 tail 字段指向被访问节点，也就是当前的尾部
        tail = p;
        ++modCount;
    }
}
```


LinkedHashMap 中的 afterNodeInsertion 方法实际不会发生作用，因为它调用的 removeEldestEntry 方法永远都返回 false。但我们注意到该方法被 protected 修饰，所以我们可以在需要该功能的情况下，继承 LinkedHashMap 类，override removeEldestEntry 方法，让它返回 true，这样就能激活 afterNodeInsertion 的功能了

```
protected boolean removeEldestEntry(Map.Entry<K,V> eldest) {
    return false;
}
```

前面说了，HashMap 的 remove、put、replace 等操作在完成之后会调用前面的几个回调方法，但唯独 get 方法没有调用。所以 LinkedHashMap 在这里复写 get 方法，在 accessOrder 为 true 的情况下，会调用 afterNodeAccess 来实现节点的移动。

```
public V get(Object key) {
    Node<K,V> e;
    if ((e = getNode(hash(key), key)) == null)
        return null;
    if (accessOrder)
        afterNodeAccess(e);
    return e.value;
}
```

### 遍历及迭代器

LinkeHashMap 有了全局的双向链表之后，实际有两种遍历方式：一种是和 HashMap 相同的遍历方式，依次遍历哈希桶中的单链表；另一种是利用这个双向链表。显然，双向链表才能满足我们对访问顺序的要求，并且遍历也更为简便。下面就看下迭代器源码中遍历的方式是否如此：

```
abstract class LinkedHashIterator {
    LinkedHashMap.Entry<K,V> next;
    LinkedHashMap.Entry<K,V> current;
    int expectedModCount;

    LinkedHashIterator() {
        next = head;
        expectedModCount = modCount;
        current = null;
    }

    public final boolean hasNext() {
        return next != null;
    }

    final LinkedHashMap.Entry<K,V> nextNode() {
        LinkedHashMap.Entry<K,V> e = next;
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
        if (e == null)
            throw new NoSuchElementException();
        current = e;
        // 从这一句我们就可以看到，它是在双向链表上遍历
        next = e.after;
        return e;
    }

    public final void remove() {
        Node<K,V> p = current;
        if (p == null)
            throw new IllegalStateException();
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
        current = null;
        K key = p.key;
        removeNode(hash(key), key, null, false, false);
        expectedModCount = modCount;
    }
}
```

除此之外，containsValue 方法也是用双向链表进行遍历的：

```
public boolean containsValue(Object value) {
    for (LinkedHashMap.Entry<K,V> e = head; e != null; e = e.after) {
        V v = e.value;
        if (v == value || (value != null && value.equals(v)))
            return true;
    }
    return false;
}
```

### LRU Cache 的实现

前面我们已经提到过，两种访问顺序的选择是通过 accessOrder 字段来确定的。这个字段唯一的设置方法是在构造方法中：

```
// 只有这个构造方法能传入 accessOrder 属性，并且必须给出 initialCapacity 和 loadFactor。我们通过传入 accessOrder = true 来设定 LRU 顺序
public LinkedHashMap(int initialCapacity,
                     float loadFactor,
                     boolean accessOrder) {
    super(initialCapacity, loadFactor);
    this.accessOrder = accessOrder;
}
// 默认的顺序是 FIFO
public LinkedHashMap() {
    super();
    accessOrder = false;
}
```

实际使用时，我们可能还需要设定最大容量，以及在溢出时清除最老的元素等操作，所以还需要进一步封装一下。

## 总结

LinkedHashMap 在 HashMap 基础上做出的扩展就在于双向链表的引入，它的引入带来了 FIFO 和 LRU 两种访问顺序的选择，以及更高效的遍历操作。其他方面还是和 HashMap 一样基于桶数组、桶内单链表和红黑树。它们也都支持 null 而键值。

