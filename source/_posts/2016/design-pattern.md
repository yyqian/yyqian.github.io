---
title: Spring 和 Java 中的设计模式
date: 2016-07-11 10:06:33
permalink: 1468202793000
tags: 设计模式
---

这篇文章将搜集本人在 Spring 和 Java 核心库中遇到过的设计模式，尽量只包含很典型的例子，生搬硬套往上凑的就不计入了。

## 工厂模式

Spring IoC 容器 BeanFactory(ApplicationContext 继承了它) 就是一个 Bean 工厂，只需要调用它的 getBean 方法就可以得到实例对象，不需要我们自己 new 一个实例。

Java 的 Collections 工具类有很多工厂方法（factory method），例如：

``` Java
public static <K,V> Map<K,V> synchronizedMap(Map<K,V> m); // 用于生成同步的 Map
public static <K,V> Map<K, V> unmodifiableMap(Map<? extends K, ? extends V> m); // 用于生成不可变的 Map
```
<!-- more -->
## 代理模式

Spring AOP 是非常典型的代理模式，在其中大量使用。代理类和目标类继承同一个接口，类型用接口定义，赋的值用代理类代替。例子：

```Java
ISubject target = new SubjectImpl(); // 为代理类的构造做准备
ISubject subject = new SubjectProxy(target); // 实际使用的代理对象，其中织入了 Aspect 逻辑
subject.doSomething(); // 这时调用方法就会触发织入的逻辑
```

## 模版模式

Spring 中 XXXXTemplate 的一般都是，主要工作是封装 boilerplate repeated code

Spring 数据访问中的 JdbcTemplate 接口封装了 Java 原生的 JDBC API，把繁琐、重复、易出错的步骤封装到 JdbcTemplate 的方法中，开发者只要在这一套模版之上，填入自己的数据访问逻辑。

Spring 事务管理中的 TransactionTemplate 封装了 PlatformTransactionManager 中的大量操作，我们在此基础上只需要关注于一个 Callback 接口。

## 单例模式

Spring IoC 中大量使用，其中的 Bean 大多数是 singleton 类型的 Bean，虽然它们的 Java 定义不是实际的单例模式（一般只是个 POJO），但有了 IoC 容器的管理，可以保证只实例化和提供一个实例对象。

## 策略模式（Strategy）

该模式封装的一般都是具体的算法。

Spring 中 Bean 的初始化有两种方式：反射和动态字节码生成。Spring 采用策略模式来决定使用哪种。

Spring AOP 的实现也有 JDK 动态代理和 CGLIB 字节码生成两种方式，也使用策略模式进行选择。

## 装饰器模式（Decorator）

Java Collections 类中的 synchronizedXXX 方法可以构造同步容器类，包装器在构造的时候接受一个容器参数，然后在这个容器参数的每个方法上都包裹 `synchronized (mutex) {}` 来实现为同步类。unmodifiableXXX 方法构造的 Immutable 容器也类似。

