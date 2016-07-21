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

- newFixedThreadPool
- newCachedThreadPool
- newSingleThreadPool
- newScheduledThreadPool：这个类可以代替 Timer 类来管理延迟任务和周期任务

用基于线程池的策略代替「每个任务分配一个线程」，有几点好处：

- 不会在高负载情况下失败
- 不会创建数千条线程来争夺有限的 CPU 和内存资源
- 通过 Executor 可以实现额外的调优、管理、监视等功能

## ExecutorService

ExecutorService 接口是 Executor 接口的扩展，它主扩展了一些生命周期管理的方法和任务提交的方法

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

它有返回值，也能抛出受检异常。ExecutorService 的 submit 方法可以接受 Callable<T> 作为参数，并且会返回一个 Future<T> 对象（Future 对象这里就不介绍了）。因此在之后的代码中就可以调用 Future 的 get 方法来阻塞地等待计算结果。这一个功能是 Executor 无法实现的。

