---
title: 生产者 - 消费者模式的多种实现
date: 2016-11-29 14:08:53
permalink: 1480399733000
tags: Java
---

这篇文章将借助生产者 - 消费者模式的几种实现，来探究 wait/notify、显式锁、Condition 的使用。

## 使用现成的 BlockingQueue 实现

我们先给出一个使用了 `java.util.concurrent.BlockingQueue` 的实现。

这个版本在逻辑上最清晰，我们有两个线程：Producer 和 Consumer，它们共享一个阻塞队列，在这个队列上完成两个线程的交互。这个队列的特点是如果队列为空，take() 方法会阻塞，如果队列满了，put() 方法会阻塞。

```
public class Producer<T> implements Runnable {

  private final BlockingQueue<T> queue;

  public Producer(BlockingQueue<T> queue) {
    this.queue = queue;
  }

  @Override
  public void run() {
    try {
      while (true) {
        T item = (T)new Object(); // produce item here
        queue.put(item);
        System.out.println("I produced an item: " + item.toString());
      }
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}

public class Consumer<T> implements Runnable {

  private final BlockingQueue<T> queue;

  public Consumer(BlockingQueue<T> queue) {
    this.queue = queue;
  }

  @Override
  public void run() {
    try {
      while (true) {
        T item = queue.take();
        System.out.println("I consumed an item: " + item.toString()); // process item here
      }
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}

public class ProducerConsumerExample {
  public static void main(String[] args) {
    BlockingQueue<Object> queue = new LinkedBlockingDeque<>(10);
    new Thread(new Producer<>(queue)).start();
    new Thread(new Consumer<>(queue)).start();
  }
}
```
<!-- more -->
## 使用 wait/notify

上面的实现很简单，是因为我们用了现成的 BlockingQueue，阻塞等待这个逻辑被封装在了队列的操作里。下面我们就尝试脱离这些高级工具，使用 Java 比较原始的工具来实现。

这里我们尝试实现一个 BlockingStack，逻辑上和 Queue 类似，只是出列的顺序不同，不过实现起来能简单点。

这个 Stack 我们用一个数组来存元素，用一个指针来指示当前栈顶和元素数量。

```
public class MyBlockingStackImpl0<T> implements MyBlockingStack<T> {

  private final int capacity;
  private final Object[] items;
  private int count;

  public MyBlockingStackImpl0(int capacity) {
    this.capacity = capacity;
    this.items = new Object[capacity];
  }

  @Override
  public T take() {
    while (count == 0) {
    }
    T item = (T)items[--count];
    items[count] = null;
    return item;
  }

  @Override
  public void put(T item) {
    while (count == capacity) {
    }
    items[count++] = item;
  }
}
```

上面的实现在 take 和 put 方法的入口处，用一个 while 循环来判断当前数组是否空/满。如果空/满，当前线程就进入忙等待状态，直到数组状态改变。这个实现有两个问题：

1. 由于 count 变量缺少同步机制以及内存可见性的问题，这个实现实际上不会正常工作
2. 即使第一个问题解决了，利用忙等待来实现阻塞是非常浪费计算资源的。

所以这里我们可以用 Object.wait/Object.notify 这两个方法来更正以上实现，它们的使用如下：

```
public class MyBlockingStackImpl1<T> implements MyBlockingStack<T> {

  private final int capacity;
  private final Object[] items;
  private int count;

  public MyBlockingStackImpl1(int capacity) {
    this.capacity = capacity;
    this.items = new Object[capacity];
  }

  @Override
  public synchronized T take() throws InterruptedException {
    while (count == 0) {
      wait();
    }
    T item = (T)items[--count];
    items[count] = null;
    notifyAll();
    return item;
  }

  @Override
  public synchronized void put(T item) throws InterruptedException {
    while (count == capacity) {
      wait();
    }
    items[count++] = item;
    notifyAll();
  }
}
```

以上 wait() 方法实际是 this.wait()，也就是某个线程调用 MyBlockingStackImpl1 实例的 wait() 方法。在调用该方法前，该线程必须将该对象作为锁来持有（否则会抛出 IllegalMonitorStateException 异常），因此我们的 take, put 方法加了 synchronized 修饰。调用 wait 方法后，该线程会进入等待状态，并且释放持有的锁。当其他线程调用了 notify 或者 notifyAll 方法，之前等待该对象的线程又会被唤醒，继续执行。

obj.notify() 和 obj.notifyAll() 两个方法的区别是前者只唤醒一个等待 obj 的线程，后者会唤醒所有等待 obj 的线程。但即使有多个线程在等待 obj，然后同时被唤醒，仍然要受到同步机制的制约而逐个运行。

## 使用 Lock 和 Condition

以上 wait/notify/notifyAll 这几个方法是 Java 比较低级的操作，用的时候要特别小心，Effective Java 中并不建议直接使用这几个方法，而是应该使用更高级的工具。当然，我们可以像文章一开始那样直接用现成的 BlockingQueue 实现，除此之外，我们通过查看 LinkedBlockingDeque 和 ArrayBlockingQueue 的源码，我们发现还可以用 ReentrantLock 来代替原始的 wait/notify/notifyAll 方法。

以下我们用 Lock 来代替了 synchronized 隐式锁，用 Condition 的 await/signal/signalAll 方法来代替 Object 的 wait/notify/notifyAll 方法，其他逻辑和之前的实现是相同的。

```
public class MyBlockingStackImpl2<T> implements MyBlockingStack<T> {

  private final int capacity;
  private final Object[] items;
  private int count;
  private final Lock lock;
  private final Condition condition;

  public MyBlockingStackImpl2(int capacity) {
    this.capacity = capacity;
    this.items = new Object[capacity];
    this.lock = new ReentrantLock();
    this.condition = lock.newCondition();
  }

  @Override
  public T take() throws InterruptedException {
    lock.lock();
    try {
      while (count == 0) {
        condition.await();
      }
      T item = (T)items[--count];
      items[count] = null;
      condition.signal();
      return item;
    } finally {
      lock.unlock();
    }
  }

  @Override
  public void put(T item) throws InterruptedException {
    lock.lock();
    try {
      while (count == capacity) {
        condition.await();
      }
      items[count++] = item;
      condition.signal();
    } finally {
      lock.unlock();
    }
  }
}
```

这里还有个可以改进的地方，我们的线程在遇到堆栈空/满时需要等待，这里等待的实际是某个条件的发生，这里有两种条件：非空或非满。所以为了语义更加明确，我们可以用两个 Condition: notEmpty, notFull 来改进以上实现：

```
public class MyBlockingStackImpl3<T> implements MyBlockingStack<T> {

  private final int capacity;
  private final Object[] items;
  private int count;
  private final Lock lock;
  private final Condition notEmpty;
  private final Condition notFull;

  public MyBlockingStackImpl3(int capacity) {
    this.capacity = capacity;
    this.items = new Object[capacity];
    this.lock = new ReentrantLock();
    this.notEmpty = lock.newCondition();
    this.notFull = lock.newCondition();
  }

  @Override
  public T take() throws InterruptedException {
    lock.lock();
    try {
      while (count == 0) {
        notEmpty.await();
      }
      T item = (T)items[--count];
      items[count] = null;
      notFull.signal();
      return item;
    } finally {
      lock.unlock();
    }
  }

  @Override
  public void put(T item) throws InterruptedException {
    lock.lock();
    try {
      while (count == capacity) {
        notFull.await();
      }
      items[count++] = item;
      notEmpty.signal();
    } finally {
      lock.unlock();
    }
  }
}
```

## 结语

这篇文章主要借助生产者 - 消费者的多种实现来探索 wait/notify, Lock, Condition 的使用，这里给出了三种不同封装级别的阻塞容器的实现：

1. 现成的 concurrent 包中的容器
2. 使用低级的 wait/notify 的实现
3. 使用 Lock 和 Condition 的实现

我们日常应该尽可能使用现成的并发容器，只有无法满足需求时才自己用 Lock 等并发工具来造轮子，而 wait/notify 方法在维护古老的代码时，也可能会用到。
