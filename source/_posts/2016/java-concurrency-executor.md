---
title: Java 并发 - Executor
date: 2016-07-21 15:56:00
permalink: 1469087760000
tags: Java
---

大多数并发程序都是围绕「任务执行」来构造的，例如 Web 应用，我们的服务端需要响应用户的访问请求，这些请求就是我们要处理的任务。

围绕「任务执行」来设计应用程序架构的时候，第一步就是找出清晰的任务边界。在理想情况下，各个任务之间应当是相互独立的：一个任务并不依赖其他任务的状态、结果或边界效应。例如在 Web 应用中，用户的每个访问请求，都是相互独立的，因此，我们可以将独立的请求作为任务边界，这样既可以实现任务的独立性，又可以控制合理的任务规模。

在介绍这篇文章的主角之前，我们先看下常见的两种多任务执行模式。

## 在线程中执行任务

### 串行执行所有任务

最直接的方式是将所有任务挨个执行，也就是下面的串行执行。
<!-- more -->
```
public class SingleThreadWebServer {
  public static void main(String[] args) throws IOException {
    ServerSocket socket = new ServerSocket(80);
    while (true) {
      Socket connection = socket.accept();
      handleRequest(connection);
    }
  }

  private static void handleRequest(Socket connection) {
    try {
      Thread.sleep(10000L); // 模拟一个耗时的操作
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}
```

SingleThreadWebServer 接受一个请求之后，就用 handleRequest 处理该请求，处理完毕之后再接受一下个请求。

这样一来，所有任务都在单个线程中执行，如果 handleRequest 耗时较长，就会阻塞线程，后面的请求将会等待很长时间才能得到响应。

### 显式地为每个任务创建线程

由于每个任务都是相互独立的，所以实际上我们可以把每个任务放到单独的线程中去执行，由于它们之间不存在依赖关系，那么执行的线程之间也就不需要通信或交互，因此实现起来也很简单：

```
public class ThreadPerTaskWebServer {
  public static void main(String[] args) throws IOException {
    ServerSocket socket = new ServerSocket(80);
    while (true) {
      final Socket connection = socket.accept();
      new Thread(() -> handleRequest(connection)).start();
    }
  }

  private static void handleRequest(Socket connection) {
    try {
      Thread.sleep(10000L); // 模拟一个耗时的操作
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}
```

上面作为构造参数的 Lambda 函数，实际是个自定义的 Runnable 实现类，它在 Java 中是一个任务的抽象（该接口只有一个方法 run）。

以上模式在服务器负载轻的时候是可行的，并且效率很高。但在负载较重，创建的线程数量很大的情况下，会出现以下问题：

1. 线程生命周期开销很高。如果请求处理是个开销小的操作，那么整个任务大多是时间都花在了线程的创建和销毁上
2. 资源消耗严重。活跃的线程对于内存的消耗最为严重
3. 稳定性。如果线程数超过 JVM 或者系统的限制，可能导致 OOM 异常

以上问题的根源都来自同一个问题：没有限制可创建线程的数量以及没有重复利用线程。

## Executor 框架

上面两种直接在 Thread 中执行任务的问题在于：前者的响应行和吞吐量太低，后者无法对资源进行有效的管理。于是，我们就有了 Executor 来作为 Runnable 的执行框架。它的接口定义如下：

```
public interface Executor {
    void execute(Runnable command);
}
```

Runnable 是任务的抽象。前面我们用 Thread 来执行 Runnable，但实际上 Runnable 的主要执行抽象并不是 Thread，而是 Executor。

Executor 基于生产者-消费者模式，任务是产品，提交任务的操作相当于生产者，执行任务的**线程**相当于是消费者。

在使用了 Executor 之后的代码如下：

```
public class TaskExecutionWebServer {
  private static final int NTHREADS = 100;
  private static final Executor executor
      = Executors.newFixedThreadPool(NTHREADS);

  public static void main(String[] args) throws IOException {
    ServerSocket socket = new ServerSocket(80);
    while (true) {
      final Socket connection = socket.accept();
      executor.execute(() -> handleRequest(connection));
    }
  }

  private static void handleRequest(Socket connection) {
    try {
      Thread.sleep(10000L); // 模拟一个耗时的操作
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}
```

我们在这里用了 ThreadPoolExecutor 实现，在构造的时候指定最大线程数，线程池中的线程会被反复重用，这样就不会遇到之前的资源耗尽的问题了。

并且如果我们不想用线程池，还想用原来的串行或每个任务一个线程的模式，可以自己实现一个 Executor 类，重载 execute 方法，把相应的执行逻辑写入其中就可以了。

每当看到 `new Thread(runnable).start();` 这样的代码时，我们都应当考虑用 Executor 来代替 Thread 执行。

### 线程池

「在线程池中执行任务」比「为每个任务分配一个线程」有更多的优势，通过重用已创建的线程，可以节省开销，并且当任务执行请求到达时，一般线程已经准备好了，因此节省了创建线程的耗时，响应速度更快。

我们有若干个静态方法来创建带线程池的 Executor：

- newFixedThreadPool：有界的，可以实现对资源使用的限制，使用 LinkedBlockingQueue 来实现等待线程的排队策略
- newCachedThreadPool：无界的，使用 SynchronousQueue 来管理队列任务（不是真正的任务队列，只是移交任务），性能最好
- newSingleThreadPool：这种线程池可以用来实现对非线程安全对象的线程封闭访问，以此来满足线程安全
- newScheduledThreadPool：这个类可以代替 Timer 类来管理延迟任务和周期任务

用基于线程池的策略代替「每个任务分配一个线程」，有几点好处：

- 不会在高负载情况下失败
- 不会创建数千条线程来争夺有限的 CPU 和内存资源
- 通过 Executor 可以实现额外的调优、管理、监视等功能

线程池使用的注意事项：

- 当任务都是同类型，并且相互独立的时候，线程池的性能达到最佳
- 如果线程池中各个任务之间存在依赖（例如调用子方法），最好使用无界的线程池（例如 newCachedThreadPool），否则容易造成线程饥饿死锁
- 将长时间运行的任务和短时间运行的任务放入同一个线程池的话，容易发生「拥塞」，这个时候可以用多个线程池来分配执行

线程池有大量可调节的选项：

- 线程池大小：一般设置为 N_cpu + 1
- 创建线程和关闭线程的策略
- 队列任务的策略：也就是线程池满载，任务在队列中排队等待时的策略
- 饱和策略：任务队列也被填满时的策略
- 用钩子方法来扩展 ThreadPoolExecutor

## ExecutorService

ExecutorService 接口是 Executor 接口的扩展，它主要扩展了一些生命周期管理的方法和任务提交的方法

```
public interface ExecutorService extends Executor {
    void shutdown();
    List<Runnable> shutdownNow();
    boolean isShutdown();
    boolean isTerminated();
    boolean awaitTermination(long timeout, TimeUnit unit)
        throws InterruptedException;
    <T> Future<T> submit(Callable<T> task);
    <T> Future<T> submit(Runnable task, T result);
    Future<?> submit(Runnable task);
    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks)
        throws InterruptedException;
}
```

我们可以用以上的 isShutdown、awaitTermination 等方法来优雅地退出程序。

### 返回结果的任务 Callable<T> 和 Future<T>

前面的 Executor 接口接受的是 Runnable 对象，但 Runnable 存在很大局限性：它不能返回一个值或抛出受检查的异常（见接口的方法定义：`void execute(Runnable command);`）

因此，Callable 是一个更强大的抽象的计算任务。它的接口定义如下：

```
@FunctionalInterface
public interface Callable<V> {
    V call() throws Exception;
}
```

它有返回值，也能抛出受检异常。ExecutorService 的 submit 方法可以接受 Callable<T> 作为参数，并且会返回一个 Future<T> 对象（Future 对象这里就不介绍了）。因此在之后的代码中就可以调用 Future 的 get 方法来阻塞地等待计算结果。这一功能在 Executor 中是无法实现的。

### CompletionService

以上我们用 ExecutorService 提交 Callable 任务，然后从返回的 Future 对象中阻塞地等待返回结果。如果我们的 Callable 任务可以进一步并行化，我们可以将它分割成多个独立的 Callable 来执行。

例如我们的任务是下载一组图片，如果用单个 Callable 任务，那么这些下载任务是在单个进程中挨个完成的，然后再把所有的图片一并通过 Future 对象返回。虽然我们已经把下载任务从主线程 delegate 给了 ExecutorService 中的线程，但这样做性能依然不是很好，因为串行下载所有图片的时间也很长。

因此，我们可以考虑把每个图片下载作为单独的任务，并且每下完一个图片，就对该图片做进一步处理。z这里我们可以考虑用一个 BlockingQueue，把单个图片下载任务的执行结果放到队列中，然后我们从队列中获取结果（被封装为 Future 对象）。

CompletionService 就是 Executor 和 BlockingQueue 的融合，接口定义如下，它有一个实现类：ExecutorCompletionService。

```
public interface CompletionService<V> {
    Future<V> submit(Callable<V> task);
    Future<V> submit(Runnable task, V result);
    Future<V> take() throws InterruptedException;
    Future<V> poll();
    Future<V> poll(long timeout, TimeUnit unit) throws InterruptedException;
}
```

我们可以遍历所有的图片下载链接，通过 submit 方法反复提交下载任务（抛弃立即返回的 Future）；然后在这之后反复调用 take 方法阻塞地等待每个返回的图片，然后处理图片。

### 任务限时

有时，我们需要实现当任务超过某个限定时间，就不再需要它的结果，该任务也就可以取消了。我们有以下实现措施：

#### 使用 Future 的 get 和 cancel 方法

示例代码如下：

```
Future<Ad> f = executor.submit(new FetchAdTask());
try {
  ad = f.get(timeInNanoseconds, NANOSECONDS);
} catch (ExecutionException e) {
  ad = DEFAULT_ad;
} catch (TimeoutException e) {
  ad = DEFAULT_ad;
  f.cancel(true);
}
```

这里执行的逻辑是，尝试阻塞地等待 timeInNanoseconds 纳秒，如果任务超时，就抛出 TimeoutException，将结果设置为默认值，并取消任务（这点一定要注意）；如果任务执行出现其他 ExecutionException 异常，也将结果设置为默认值。

### 使用 ExecutorService 的 invokeAll 方法

在处理一组有限时要求的任务时，ExecutorService 的 invokeAll 方法更简便，它的逻辑是：我们提交一组任务，这组任务有相同的时限，当以下三种情况发生时 invokeAll 将返回：

1. 所有任务都执行完毕
2. 调用线程被中断
3. 超过指定时限

在超过时限的情况下，未完成的任务都会被取消，因此省去了我们自己 catch TimeoutException 然后 cancel 任务的烦恼。

当 invokeAll 返回后，我们可以通过调用 get 或 isCancelled 来判断任务是正常完成还是被取消了。

## 总结

在 Java 中，我们用 Runnable 或 Callable 来作为任务的封装，用 Future 来作为异步任务返回结果的封装。

相比为每个异步任务创建一个 Thread 来执行，Executor 框架提供了更好的线程管理机制，我们可以利用线程池来获得更好的伸缩性。

除此之外，ExecutorService 扩展了 Executor 接口，提供了：

1. 生命周期管理功能
2. 获取异步任务返回结果功能（返回结果由 Future 来封装）
3. 通过 CompletionService 实现一个基于 Future 的生产者 - 消费者队列
4. 任务限时

因此，当我们遇到 `new Thread(runnable).start();` 这样的代码的时候，可以考虑用 Executor 来代替。

---

参考：
- [Java 并发编程实战](https://book.douban.com/subject/10484692/)