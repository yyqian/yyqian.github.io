---
title: Java 源码分析：HashMap
date: 2016-07-12 10:48:14
permalink: 1468291694000
tags: Java
---

本文将深入分析 Java 8 的 HashMap 类，主要解读它的存储结构以及四个关键的方法：hash, put, get, resize。

## 存储结构-字段

Java 中的 HashMap 在碰撞处理方面主要采用的是[Separate chaining with list head cells](https://en.wikipedia.org/wiki/Hash_table#Separate_chaining_with_list_head_cells)方式，JDK 1.8 中加入红黑树部分。也就是说，JDK 1.8 实现主体采用的是数组 + 链表，当某个链表长度大于 8 的时候，该链表就被替换成红黑树。如下图所示：

![](http://tech.meituan.com/img/java-hashmap/hashMap%E5%86%85%E5%AD%98%E7%BB%93%E6%9E%84%E5%9B%BE.png)

上图中的哈希桶数组，在源码中是用 table 字段来表示的。这里要注意的一点是，JDK 1.8 的实现中，table 数组的大小是 2 的幂，默认是 16。这一点对后面的索引计算很重要。

```
transient Node<K,V>[] table;
```

它的元素 Node 定义如下，上图中每个黑色点都是一个 Node 实例（KV 对）：

```
static class Node<K,V> implements Map.Entry<K,V> {
        final int hash;
        final K key;
        V value;
        Node<K,V> next; // 下一个节点

        Node(int hash, K key, V value, Node<K,V> next) {...}
        public final K getKey()        { return key; }
        public final V getValue()      { return value; }
        public final String toString() { return key + "=" + value; }
        public final int hashCode() {...}
        public final V setValue(V newValue) {...}
        public final boolean equals(Object o) {...}
```

除此之外，还有几个重要的字段：

```
    transient int size; // 实际存储节点的数量
    int threshold; // 所能存储节点的极限，当 size > thresold 时，我们就需要 resize 进行扩容
    final float loadFactor; // 负载因子，threshold = length * Load factor（length 是字段 table 数组的长度）
```

LoadFactor 默认取 0.75，如果没有特殊需求不建议更改。在 table 数组定下来之后，LoadFactor 越大，所能容纳的节点数目就越多，但发生 hash collision 的概率也就越大，需要在链表上进行频繁的操作，因此性能越差，适合内存有限并且对性能不敏感的情况。

## 功能实现-方法

这里主要挖掘 hash, put, resize, get 这四个方法

### hash 方法

不管是 CRUD 中哪一种操作，我们要做的第一步都是计算 key 的哈希值，来定位到哈希桶数组中的位置。这里主要由三步组成：

1. 调用 key 自身的 hashCode 方法得到一个值
2. 将该值的高位与低位进行 XOR 异或操作
3. 用数组大小进行**等价的**取模运算

以下方法包含了第一、第二步：

```
    static final int hash(Object key) {
        int h;
        return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
    }
```

我们为什么需要第二步？这点等讲解完第三步之后再说。

第三步的等效的取模运算没有定义单独的方法，散落在其他各个方法中，它的代码是：

```
(table.length - 1) & hash
```

为什么这里用的是 & 操作？原因是我们的 table 数组大小永远是 2 的幂，在这种情况下，上面的操作就等效于取模，并且性能更好，原理见下图：

![](http://tech.meituan.com/img/java-hashmap/hashMap%E5%93%88%E5%B8%8C%E7%AE%97%E6%B3%95%E4%BE%8B%E5%9B%BE.png)

现在我们来回答第二步存在的原因：第三步中影响索引取值的只有 hash 值的低位（上图中是低四位），作者认为在某些特殊情况下，如果没有第二步会发生大量的 hash collision，因此在用了一个较小的代价（把高 16bit 与低 16bit 取 XOR 操作）将高位传播到低位，进一步优化哈希值的计算。

不过，即使上面的 hash 值计算没能给出一个分布均匀的哈希表，JDK 1.8 增加的红黑树在这就发挥作用了。当大量碰撞的情况下，如果我们用的是链表，查找操作的时间复杂度是 O(1) + O(N)，因此 O(N) 是会影响速度的。但是，如果我们将链表用平衡搜索树（红黑树）来代替，复杂度就变成了 O(1) + O(lgN)，效率大大提高。

### put 方法

put 方法大致流程如下：

![](http://tech.meituan.com/img/java-hashmap/hashMap%20put%E6%96%B9%E6%B3%95%E6%89%A7%E8%A1%8C%E6%B5%81%E7%A8%8B%E5%9B%BE.png)

下面我们把步骤分析直接写在源码注释中：

```
    public V put(K key, V value) {
        // 这里的 hash 就是前面分析的 hash 方法
        return putVal(hash(key), key, value, false, true);
    }

    final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        // 如果字段 table 为空，则执行 resize 方法进行扩容
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length;
        // 根据 hash code 计算在 table 中的 index，并定位到该位置，如果该位置为 null，说明还没有节点占据该位置，于是我们直接把该节点赋值为我们新建的节点
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
        else {
            Node<K,V> e; K k;
            // 如果检查发现 table 中该节点位置的 key 与我们当前的 key 相同，说明这是个更新操作，我们把该节点缓存到变量 e，等待后面对该节点进行更新操作。
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
            // 如果该节点是红黑树的节点，说明后面连接的是一棵树，我们按照树的逻辑去处理
            else if (p instanceof TreeNode)
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            // 当前节点连接的是一个链表，接下来就处理这个链表
            else {
                for (int binCount = 0; ; ++binCount) {
                    // 退出条件：如果我们搜索了整个列表，到结尾还没找到该 key，说明这是个新增操作，我们把新的节点连接到该链表的结尾。如果这时链表长度超过阈值，就把它变成一棵红黑树。
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null);
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                            treeifyBin(tab, hash);
                        break;
                    }
                    // 如果我们在遍历链表的过程中，发现 key 已经存在，把该节点缓存到变量 e
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            // 如果该变量非空，说明这是个更新操作，我们更新该变量所缓存的节点的值。
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ++modCount;
        // 增加当前 table 的实际大小，如果超过阈值就扩容
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);
        return null;
    }
```

### resize 方法

如果当前实际存储的节点数目大于设定的阈值，就需要进行扩容。该方法可以初始化 table 数组，或者将 table 数组大小翻倍。由于 JDK 1.8 之后加入了红黑树，该 resize 方法变得较为复杂，我们这里以 JDK 1.7 的源码进行分析：

```
void resize(int newCapacity) {   //传入新的容量
     Entry[] oldTable = table;    //引用扩容前的Entry数组
     int oldCapacity = oldTable.length;         
     if (oldCapacity == MAXIMUM_CAPACITY) {  //扩容前的数组大小如果已经达到最大(2^30)了
         threshold = Integer.MAX_VALUE; //修改阈值为int的最大值(2^31-1)，这样以后就不会扩容了
         return;
     }
  
     Entry[] newTable = new Entry[newCapacity];  // 初始化一个新的Entry数组
     transfer(newTable);                         // 将数据转移到新的Entry数组里
     table = newTable;                           // table 字段引用新的Entry数组
     threshold = (int)(newCapacity * loadFactor);//修改阈值
}

void transfer(Entry[] newTable) {
    Entry[] src = table;                   //src引用了旧的Entry数组
    int newCapacity = newTable.length;
    for (int j = 0; j < src.length; j++) { //遍历旧的Entry数组
        Entry<K,V> e = src[j];             //取得旧Entry数组的每个元素
        if (e != null) {
            src[j] = null;//释放旧Entry数组的对象引用（for循环后，旧的Entry数组不再引用任何对象）
            do {
                Entry<K,V> next = e.next;
                int i = indexFor(e.hash, newCapacity); //重新计算每个元素在数组中的位置
                // 插入到索引为 i 的槽中，注意这里是添加到链表的头部
                e.next = newTable[i]; // 把当前的链表头作为 e 的下一个节点
                newTable[i] = e;      // 将该节点放在数组上，作为链表的头部
                e = next;             // 接着遍历下一个 Entry 链上的元素
            } while (e != null);
        }
    }
}
```

以上操作的图示如下：

![](http://tech.meituan.com/img/java-hashmap/jdk1.7%E6%89%A9%E5%AE%B9%E4%BE%8B%E5%9B%BE.png)

JDK 1.8 中对扩容过程做了优化，利用了 table 数组大小永远是 2 次幂的特性。在扩容之后，如果我们重新计算索引值，我们会发现它的位置只有两种可能性：1. 没变；2. 原位置再移动 2 次幂的位置。原因见下图，扩容后我们的 mask 多了 1 位，所以新的索引值在原有基础上新增了一个最高位：

![](http://tech.meituan.com/img/java-hashmap/hashMap%201.8%20%E5%93%88%E5%B8%8C%E7%AE%97%E6%B3%95%E4%BE%8B%E5%9B%BE1.png)

这个时候我们不需要重新计算 hash 值，它已经存在了节点中，我们只需要用以下方法重新计算索引值就可以了

```
(table.length - 1) & hash
```

新的索引值结果示例如下：

![](https://cloud.githubusercontent.com/assets/1736354/6958301/519be432-d93c-11e4-85bb-dff0a03af9d3.png)

由于新增的 1bit 是 0 还是 1 可以认为是随机的，所以 resize 过程均匀的把当前的节点分散到了 table 中新的空槽中。大致的图示如下：

![](http://tech.meituan.com/img/java-hashmap/jdk1.8%20hashMap%E6%89%A9%E5%AE%B9%E4%BE%8B%E5%9B%BE.png)

另外一点与 JDK 1.7 不同的是：在扩容过程中，JDK 1.7 的每次移动节点都是添加到链表头部，因此得到的链表与扩容前是倒序的；但在 JDK 1.8 中，该顺序是不变的。

### get 方法

我们将结合源码来解析 get 方法，在理解 HashMap 存储结构的情况下应该很好理解：

```
    public V get(Object key) {
        Node<K,V> e;
        // 获取目标节点，处理 null，取该节点的值
        return (e = getNode(hash(key), key)) == null ? null : e.value;
    }

    final Node<K,V> getNode(int hash, Object key) {
        Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
        // 处理一些特殊情况，如果参数不合法或者该 hash 所对应索引位置为空，就返回 null
        if ((tab = table) != null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) != null) {
            // 如果 table 中的链表头命中，就直接返回
            if (first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k))))
                return first;
            // 如果链表头未命中，就进行遍历
            if ((e = first.next) != null) {
                // 判断是平衡搜索树还是链表，如果是红黑树，按照树的操作去查找
                if (first instanceof TreeNode)
                    return ((TreeNode<K,V>)first).getTreeNode(hash, key);
                // 如果是链表，一个个节点进行比较判断
                do {
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        return e;
                } while ((e = e.next) != null);
            }
        }
        return null;
    }
```

## 总结

1. HashMap 不是线程安全的，在多线程情况下应当使用 ConcurrentHashMap 代替。

2. 扩容是个耗时的操作，如果能预估需要的 Map 的大小，我们可以在初始化的时候给出 initialCapacity 参数（table 实际的大小会是二次幂，内部的 tableSizeFor 方法会进行计算）

3. JDK 1.8 中红黑树的引入和哈希函数的改进，明显地提高了 HashMap 的性能

---

参考：

- 美团的[Java8系列之重新认识HashMap](http://tech.meituan.com/java-hashmap.html)
- [Java HashMap工作原理及实现](http://yikun.github.io/2015/04/01/Java-HashMap%E5%B7%A5%E4%BD%9C%E5%8E%9F%E7%90%86%E5%8F%8A%E5%AE%9E%E7%8E%B0/)