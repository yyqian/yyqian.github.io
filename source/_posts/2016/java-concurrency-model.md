---
title: Java 并发 - 基础构建模块
date: 2016-07-20 09:02:14
permalink: 1468976534000
tags: Java
---

Java 平台类库包含丰富的并发基础构建模块，这里将列举一些最有用的模块。

## 同步容器类

已经不建议使用的 Vector 和 Hashtable 这里就不说了。它们的替代者是 Collections.synchronizedXxxx 等工厂方法创建的容器。

我们以 synchronizedMap 方法为例，部分源码如下：

```
public static <K,V> Map<K,V> synchronizedMap(Map<K,V> m) {
    return new SynchronizedMap<>(m);
}

private static class SynchronizedMap<K,V>
    implements Map<K,V>, Serializable {

    // 装饰器模式，外部传入的 map
    private final Map<K,V> m;     // Backing Map

    // 私有锁
    final Object mutex;        // Object on which to synchronize

    // 两种构造方式，使用内置互斥锁或指定的互斥锁
    SynchronizedMap(Map<K,V> m) {
        this.m = Objects.requireNonNull(m);
        mutex = this;
    }
    SynchronizedMap(Map<K,V> m, Object mutex) {
        this.m = m;
        this.mutex = mutex;
    }

    // 在原有方法上用 synchronized (mutex) 来包裹，实现同步访问
    public V get(Object key) {
        synchronized (mutex) {return m.get(key);}
    }
    public V put(K key, V value) {
        synchronized (mutex) {return m.put(key, value);}
    }
}
```
<!-- more -->
从以上代码可以看出，这些同步容器实际是使用的装饰器模式，在原容器的各个方法上都用 `synchronized (mutex)` 来包裹，实现同步访问。

这个容器在复合操作下仍然需要额外的加锁机制，例如：

- 迭代：可能在迭代过程中元素的数量发生变化
- 跳转：通过 index 来获取元素
- 条件运算：若没有则添加，先检查后运算

以下复合操作都不是线程安全的：

```
public static Object getLast(Vector list) {
    int lastIndex = list.size() - 1;
    return list.get(lastIndex); // 这个时候 list 的大小有可能变化了
}

for (int i = 0; i < vector.size(); i++) {
    doSomething(vector.get());
}

List<String> strList = Collections.synchronizedList(new ArrayList<String>());
for (String str : strList) {
    doSomething(str);
}
```

我们需要额外的同步来修复这些操作：

```
public static Object getLast(Vector list) {
    synchronized (list) {
        int lastIndex = list.size() - 1;
        return list.get(lastIndex);
    }
}

synchronized (vector) {
    for (int i = 0; i < vector.size(); i++) {
        doSomething(vector.get());
    }
}

List<String> strList = Collections.synchronizedList(new ArrayList<String>());
synchronized (strList) {
    for (String str : strList) {
        doSomething(str);
    }
}
```

如果遍历容器耗时很长，对容器加锁会严重影响性能，替代的方法是克隆容器，在其副本上进行迭代操作。由于副本是封闭在线程内的，即使副本本身不是线程安全的，也不需要加锁。但克隆容器也是需要额外开销的，所以需要权衡考虑。

## 并发容器

前面的同步容器实际是把并发访问串行化来实现线程安全的。这种方法的代价是严重降低并发性、吞吐量。

Java 有一系列并发容器是针对多线程并发访问设计的，可以代替同步容器，极大地提高伸缩性并降低风险。以下是各个接口的并发实现：

- Map: ConcurrentHashMap
- List: CopyOnWriteArrayList
- Queue: ConcurrentLinkedQueue
- BlockingQueue: 有若干实现
- SortedMap, SortedSet: ConcurrentSkipListMap, ConcurrentSkipListSet

### ConcurrentHashMap

ConcurrentHashMap 用一种「分段锁」代替同步容器中的全局锁，实现粒度更细的加锁机制。在需要线程安全性的时候，应当首先考虑它，而不是 Hashtable 或 synchronizedMap。

### ConcurrentMap 接口

当我们需要进行复合操作的时候，ConcurrentHashMap 不能像同步容器那样被施加全局锁，为此，ConcurrentMap 该接口定义了一些常用的复合操作：

```
V putIfAbsent(K key, V value); // key 不存在是才插入
boolean remove(Object key, Object value); // key 被映射到 value 是才移除
boolean replace(K key, V oldValue, V newValue); // 当 key 被映射到 oldValue 时才用 newValue 代替
V replace(K key, V value); // 仅当 key 被映射到某个任意值时，才用 value 代替
```

### CopyOnWriteArrayList

前面说过，在使用同步容器的时候，如果需要遍历容器，就要对整个容器进行加锁来获取独占访问，或者是克隆容器，在其副本上进行遍历。CopyOnWriteArrayList 在这点上，两者都不需要就能实现线程安全。

它在遍历的过程中不会遇到容器被修改的情况，因为每次修改都会创建并重新发布一个新的容器副本，不会影响原来的容器。但是，每次修改都创建新的容器副本也存在一定的性能开销，因此，仅当迭代操作远远多于修改操作时，才应该使用 CopyOnWrite 容器。

## 阻塞队列

阻塞队列最主要是用来实现「生产者 - 消费者队列」。主要操作有可阻塞的 put 和 get 方法，以及支持定时的 offer 和 poll 方法。

最主要的实现是 LinkedBlockingQueue，ArrayBlockingQueue，PriorityBlockingQueue。前两者关系就和 LinkedList 与 ArrayList 类似，PriorityBlockingQueue 则是 PriorityQueue 的阻塞版本。

生产者 - 消费者模式可以用来解耦组件，也可以让组件并行执行，以文件索引器为例：

```
public static void startIndexing(File[] roots) {
    BlockingQueue<File> queue = new LinkedBlockingQueue<File>(BOUND);
    for (File root : roots) {
        new Thread(new FileCrawler(queue, root)).start;
    }
    for (int i = 0; i < N_CONSUMERS; i++) {
        new Thread(new Indexer(queue)).start;
    }
}
```

我们把这个索引器分为爬虫和索引两个独立的功能组件（FileCrawler, Indexer），然后用一个 BlockingQueue 将两者耦合在一起，爬虫作为生产者生成 File 对象，FileCrawler 作为消费者消费 File 对象；前者是 IO 密集型，后者是 CPU 密集型，它们搭配并发执行的吞吐量要远高于串行执行的吞吐量。

「生产者 - 消费者队列」促进了串行线程封闭，队列中的产品是我们关注的对象，它由生产者生成，然后放入队列，再由消费者获取，三者分别属于三个线程，但是它们对单个产品的访问是串行化的，产品的所有权一直在被转移，因此不管是生产者、队列还是消费者，对该产品都有独占的访问权，产品一直被封闭在单个线程中。

双端队列 Deque 或 BlockingDeque 适用于「工作密取（Work Stealing）」。在「生产者 - 消费者模式」中，所有消费中从同一个队列中获取任务；而在「工作密取模式」中，每个消费者都有各自的双端队列，如果一个消费者完成自己双端队列中的任务，可以从其他消费者双端队列末尾秘密地获取工作。

双端队列适合既是消费者也是生产者的问题：例如爬虫访问一个链接，在分析处理这个链接页面中的内容后，会产生更多的链接。

## 同步工具类

前面的阻塞队列是一种特殊的同步工具类，它既可以作为容器，也可以用来协助在生产者和消费者之间转移对象。接下来讨论另外三种同步工具类：闭锁（Latch）、栅栏（Barrier）以及信号量（Semaphore）。

### 闭锁

闭锁可以用来等待一组任务全部完成后，再执行下一个任务。它就像一扇门，只有当所有人都在门前准备好可以出发的时候，这个门才会打开，然后大伙就可以冲出去了。

它可以用来：

1. 等待游戏中多个玩家都已经准备好，然后游戏正式开始
2. 一系列依赖的资源或库都已经加载完成，然后主程序启动（例如编译之前要先连接依赖的库）
3. 一系列依赖的服务都已启动，然后本服务再启动（例如我们的 Web 应用一般都需要 MySql, Redis, RabbitMQ 等依赖的服务都启动之后，才能启动）

我们以 CountDownLatch 来举例闭锁的使用，CountDownLatch 在计数器非零的状态下，await 方法会会阻塞进程，当某个任务完成，我们就调用 countDown 方法递减计数器，当计数器递减为零的时候，await 方法就停止阻塞，进程继续运行。

下面的 TestHarness 展示了 CountDownLatch 的用法，startGate 用来等待所有任务准备好之后同时开始；endGate 等待所有任务完成之后进行下一步操作。

```
public class TestHarness {
  public static long timeTasks(int nThreads, final Runnable task) throws InterruptedException {
    final CountDownLatch startGate = new CountDownLatch(1);
    final CountDownLatch endGate = new CountDownLatch(nThreads);

    for (int i = 0; i < nThreads; i++) {
      Thread thread = new Thread() {
        @Override
        public void run() {
          try {
            // 所有线程都在这个门前等待
            startGate.await();
            try {
              // 执行（阻塞）
              task.run();
            } finally {
              // 任务完成, 计数器减一
              endGate.countDown();
            }
          } catch (InterruptedException ignored) {
            ignored.printStackTrace();
          }
        }
      };
      thread.start();
    }

    long start = System.currentTimeMillis();
    // 这个时候所有 Thread 都已经构造好了, startGate 递减为 0, 所有任务同时开始, 否则开始的时间会有先后差异
    startGate.countDown();
    // 在这个门前等待所有任务完成
    endGate.await();
    // 所有任务完成, 计算耗时
    long end = System.currentTimeMillis();
    return (end - start) / 1000;
  }

  public static void main(String[] args) throws InterruptedException {
    Random rnd = new Random(137);
    // 定义一个任务, 睡随机的秒数
    Runnable task = () -> {
      long sec = rnd.nextInt(10);
      try {
        Thread.sleep(sec * 1000);
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
      System.out.println(String.format("I slept %d seconds.", sec));
    };
    // 输出总耗时
    System.out.println(String.format("The total time costs is: %d seconds.", timeTasks(4, task)));
  }
}
```

### 栅栏

栅栏和闭锁有相似之处，它的作用是等待所有线程都到了某一个点之后，再同时进行下一步的计算。例如：如果我们要模拟一个盒子中的分子运动，我们可以让每个分子运动轨迹的计算并行执行，但在每个时间间隔点，我们都要等待所有的分子当前位置计算完毕，才能进行下一个时间点的计算，因为单个分子下一时刻的位置依赖于上一时刻其他分子的位置，所以在每个时间点，我们都需要一个栅栏。

栅栏可以用以下方式构造，我们告知需要等待的线程的数目，以及所有线程到达之后下一步的操作：

```
CyclicBarrier barrier = new CyclicBarrier(count,
    new Runnable() {
        public void run() {
            //xxxxx
        }});
```

在需要用栅栏进行同步的线程中，我们可以下面的方式调用栅栏，在当前阶段的任务处理完毕之后，调用 await 方法，表示已完成，等待其他线程也完成之后进行下一阶段的操作：

```
// 处理现阶段所有的任务
barrier.await();
```

### FutureTask

FutureTask 可以定义一个任务，该任务会有一个返回结果，我们可以用它的 get 方法来获取返回结果，如果我们调用 get 的时候任务还没完成，将阻塞线程；如果完成就返回结果。（这个和 Clojure 中的 future 在模式上是相同的）

```
public class PreLoader {
  private final FutureTask<Long> future = new FutureTask<Long>(() -> {
    long sleep = 3287;
    Thread.sleep(sleep);
    System.out.println(String.format("I slept %d milliseconds.", sleep));
    return sleep;
  });
  private final Thread thread = new Thread(future);

  public void start() {
    thread.start();
  }

  public Long get() throws ExecutionException, InterruptedException {
    return future.get();
  }

  public static void main(String[] args) throws ExecutionException, InterruptedException {
    PreLoader loader = new PreLoader();
    System.out.println("Started loading");
    loader.start();
    System.out.println("Started getting");
    System.out.println("Result: " + loader.get());
  }
}
```

### 信号量

一般也称为计数信号量（Counting Semaphore），它可以用来实现资源池，或者给容器加边界。

我们可以想象成某个资源有固定数量的许可证，我们可以通过 acquire 方法获取许可证，然后访问资源，访问完毕后调用 release 方法归还许可证。但是如果我们 acquire 的时候许可证已经都发光了，线程就会阻塞，等待其他线程归还许可证之后，我们再获取许可证进行访问。因此，我们可以控制同时访问一资源的线程数量，实现一个有固定大小的资源池。

我们在同步的时候用的互斥锁（mutex）就是信号量的一个特例，它是一个二值信号量，只保有一个许可证，一旦有线程 acquire 之后，其他线程就都得阻塞等待它 release。

以下是一个有边界的 HashSet，通过信号量来实现：

```
public class BoundedHashSet<T> {
  private final Set<T> set;
  private final Semaphore semaphore;

  public BoundedHashSet(int bound) {
    this.set = Collections.synchronizedSet(new HashSet<T>());
    this.semaphore = new Semaphore(bound);
  }

  public boolean add(T object) throws InterruptedException {
    semaphore.acquire();
    boolean wasAdded = false;
    try {
      wasAdded = set.add(object);
      return wasAdded;
    } finally {
      if (!wasAdded) semaphore.release();
    }
  }

  public boolean remove(Object object) {
    boolean wasRemoved = set.remove(object);
    if (wasRemoved) semaphore.release();
    return wasRemoved;
  }

  public static void main(String[] args) throws InterruptedException {
    BoundedHashSet<Integer> boundedHashSet = new BoundedHashSet<>(5);
    for (int i = 0; i < 6; i ++) {
      final int parm = i;
      new Thread(() -> {
        try {
          boundedHashSet.add(parm);
          System.out.println("add " + parm);
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }).start();
    }
    System.out.println("等待任务完成");
    Thread.sleep(1000);
    System.out.println("remove 3");
    boundedHashSet.remove(3);
  }
}
```

以上代码的输出为：

```
等待任务完成
add 0
add 2
add 4
add 3
add 1
remove 3
add 5
```

在这个类中，add 方法获取许可证，remove 方法归还许可证。

我们在 main 方法中构造了一个大小限定为 5 的 Set，然后我们启动 6 个线程，每个线程添加一个元素，那么前 5 个线程会添加成功并结束任务，第六个线程会被阻塞，直到我们从中移除一个元素，它才会成功地添加到容器中并返回。

## 应用：构造缓存

以下是一个缓存的示例。这里有几个注意点：

1. 使用 ConcurrentHashMap 可以避免同时读写某个 key 造成的并发问题
2. Future<V> 可以避免当两个线程同时发现某个 key 没有被缓存，然后同时开始计算该 key。用了 Future 之后，慢了一步的线程会在 Future.get() 方法上阻塞，等待另一个线程计算完毕返回结果。
3. putIfAbsent 避免「若没有则添加」这个复合操作带来的并发问题
4. cache.remove(key) 这一句是避免 Future 计算失败，导致缓存的是错误信息而不是真正的结果。

```
public class Memoizer<K, V> {
  // 两点优化: 使用 Future<V> 和 ConcurrentHashMap
  private final ConcurrentMap<K, Future<V>> cache
      = new ConcurrentHashMap<>();

  @SuppressWarnings("unchecked")
  public V compute(final K key) throws InterruptedException {
    while (true) {
      Future<V> future = cache.get(key);
      if (future == null) {
        FutureTask<V> futureTask = new FutureTask<>(() -> {
          // 实际的计算任务, 为了简化代码, 执行一个虚拟的任务
          Thread.sleep(5000);
          return (V)key;
        });
        future = cache.putIfAbsent(key, futureTask);
        if (future == null) {
          future = futureTask;
          futureTask.run();
        }
      }
      try {
        return future.get();
      } catch (CancellationException e) {
        cache.remove(key);
      } catch (ExecutionException e) {
        e.printStackTrace();
      }
    }
  }

  public static void main(String[] args) throws InterruptedException {
    Memoizer<Integer, Integer> memoizer = new Memoizer<>();
    for (int i = 0; i < 3; i++) {
      final int arg = i;
      new Thread(() -> {
        try {
          System.out.println("First run: " + memoizer.compute(arg));
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }).start();
    }
    System.out.println("Second run: " + memoizer.compute(2));
  }

}
```

## 总结

这篇文章主要概括介绍在并发情况下，我们可使用的基础构建模块，目的是为了构造线程安全的类：

1. 同步容器：最基础的线程安全的类，实现的方式是使用 synchronized 关键词来将并发访问串行化，缺陷就是串行化后吞吐量大大降低。
2. 并发容器：实现的方式根据容器类型各异，但至少不需要同步串行化，可以在满足线程安全的前提下大幅提高性能；对于复合操作，可以使用额外定义的 API 来操作，而不要自行通过客户端加锁来实现。
3. 阻塞队列：可以用来实现生产者 - 消费者模式，这个模式有利于促成解耦和线程封闭。
4. 同步工具类：闭锁、栅栏、FutureTask、信号量，它们的作用各异，但总体来说都是为了协同各个线程之间的交互。




