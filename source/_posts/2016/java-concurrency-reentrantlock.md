---
title: Java 并发 - ReentrantLock
date: 2016-07-22 09:30:20
permalink: 1469151020000
tags: Java
---

ReentrantLock 是 Java 5.0 中新增的，是对 synchronized 使用的内置锁的一种补充。

传统的加锁方式如下：

```
synchronized (lockObject) {   
  // 操作状态等
}  
```

它在进入代码块时获得锁，在离开代码块时释放锁，所以不可能在获取锁之后忘了释放锁，但同时这也带来一定局限性，获取和释放必须在同一代码块中。

而 ReentrantLock 的使用如下：

```
Lock lock = new ReentrantLock();  
lock.lock();  
try {   
  // update object state  
}  
finally {  
  lock.unlock();   
}  
```
<!-- more -->
它实现了 Lock 接口，在使用时，必须记住要在 finally block 中释放锁，否则程序抛出异常时会脱离正常执行流程，有可能导致锁没有被释放。

显式锁除了使用起来更加灵活，它还能提供内置锁没有的功能：

1. 轮询锁
2. 定时锁
3. 可中断的锁

除此之外，显式锁还能工作在「公平模式」，也就是说在多个线程争夺某个锁时，这些线程会排队，挨个获取，而不是无序的抢着用。但是，公平锁会把性能降低约两个数量级，所以只有真正需要公平机制的时候才启用显式锁的公平模式。

synchronized 和 ReentrantLock 两者如何选择？默认还是优先使用 synchronized，因为它相对来说更安全，不会忘了释放锁。只有当 synchronized 无法满足需求时，才使用 ReentrantLock，这些「需求」包括：可定时的、可轮询的、可中断的、公平锁和非块结构的锁（见 ConcurrentHashMap 的源码）。

除此之外，除了 ReentrantLock，还有一种「读写锁」：ReentrantReadWriteLock，它可以把读写两个操作用两个锁来保护，接口定义如下：

```
public interface ReadWriteLock {
    Lock readLock();
    Lock writeLock();
}
```

ReentrantReadWriteLock 的使用示例如下：

```
public class ReadWriteMap<K, V> {
  private final Map<K, V> map;
  private final ReadWriteLock lock = new ReentrantReadWriteLock();
  private final Lock readLock = lock.readLock();
  private final Lock writeLock = lock.writeLock();

  public ReadWriteMap(Map<K, V> map) {
    this.map = map;
  }

  public V put(K key, V value) {
    writeLock.lock();
    try {
      return map.put(key, value);
    } finally {
      writeLock.unlock();
    }
  }

  public V get(Object key) {
    readLock.lock();
    try {
      return map.get(key);
    } finally {
      readLock.unlock();
    }
  }
}
```

读锁和写锁实际是同一个锁的两个视图，我们可以多个线程持有读锁，但只能一个线程持有写锁，并且两者互斥：只要有一个读锁被持有，写锁就不能被持有，反之亦然。在读写频繁的情况下，读写锁能到来性能提升，在其他情况下，读写锁可能性能会略差，因为它的实现更复杂。

显式锁（ReentrantLock）作为内置锁的一种补充，提供了以上更高级的功能，当需要这些功能时，我们可以挑选使用合适的显示锁。

---

参考：
- [Java 并发编程实战](https://book.douban.com/subject/10484692/)