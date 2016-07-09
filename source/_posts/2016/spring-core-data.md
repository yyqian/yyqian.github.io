---
title: Spring Data 深入解析
date: 2016-06-30 14:48:28
permalink: 1467269308000
tags: Spring
---

Spring 数据访问层可以分成三个部分：

1. 统一的数据访问异常层次体系：Spring 框架会把所有特定于数据访问技术的异常（Exception）都进行转译，然后封装为一套标准的异常层次体系。这样我们只要处理这一套封装之后的异常体系就可以了。

2. JDBC API 的最佳实践：说白了就是对 JDBC API 的封装。

3. 以统一的方式对各种 ORM 方案的集成：这一部分内容以后会用 MyBatis 作为例子单独进行阐述。

这三个部分本质上都是一种封装，第一部分是对各种异常的封装，第二部分是对 JDBC API 的封装，第三部分是都多种 ORM 技术的封装。
<!-- more -->
## 统一的数据访问异常层次体系

对于数据访问，我们一般使用 DAO 模式，它的组成成员有：

1. DAO，即数据访问对象，有时也称作 Domain。不管是文本文件、csv 文件、数据库还是 LDAP，统一抽象为 DAO
2. 数据访问接口，一般称作 Repositiory 或 Mapper，用于让服务层访问数据，这时服务层不需要关心以何种技术去连接数据层，以及特定于技术的错误的处理。
3. 数据访问接口的实现，服务层不需要直接与它打交道。这个实现依赖于使用的数据源，我们这里关心的是数据库，所以使用 JDBC 来实现，当然我们也可以切换至 LDAP，这个修改对于服务层来说可以是透明的。

但是以上模式有个缺陷，我们以使用 JDBC 技术为例：JDBC API 会抛出 checked exception（SQLException），这个 checked exception 如果在接口的实现中内部消化的话，上层建筑就不知道出了什么差错，所以需要抛出；但如果抛出的话，这些 exception 特定于各种数据访问技术，如果更换数据源的话，就需要更换数据访问技术，这时候抛出的异常就会有变化，导致接口的定义发生变化，而接口的变化是我们不希望发生的，这会导致上层建筑需要处理新的异常类型。

我们既不可以内部处理 checked exception，又不可以把它直接抛出，那么合适的做法就是把它封装之后再抛出。接下来的问题就是是抛出 checked exception 还是 unchecked exception？Spring 认为大部分甚至所有的数据访问抛出的异常，客户端都是无法处理的，所以最有效的处理就是不做处理。因此 Spring 在这里选择抛出 unchecked exception。

但是，如果我们只抛出一种 RuntimeException 类型的 unchecked exception，我们无法用它来区分不同的错误类型。因此 Spring 在这里的工作就是进行转义（或者说翻译，不管你们说哪国语言，在这个关卡中统统翻译成 Spring 王国的语言），实际就是用一张映射表，将特定于技术的 ErrorCode 映射成 Spring 封装/统一之后的异常。

总的来说，Spring 在这里采取的措施是：统一各种数据源/技术的异常类型，对它们进行封装，使得它们对外表现出一致性。这样即使更换数据源，数据访问接口也不会有变化，上层建筑也不需要处理新的异常类型。

Spring DAO 异常层级体系的根部是 DataAccessException

![Screen Shot 2016-06-30 at 9.49.53 AM.png](http://cdn.yyqian.com/201606300950-FtiwFLy1238zxntxyGgYR-CTpxoQ?imageView2/2/w/800/h/600)

各种特定于数据源以及访问技术的异常，都可以映射到以上的这一系列异常，即使无法映射到其中之一，也可以映射到 UncategorizedDataAccessException。每种类型的异常的含义，请自行查阅。

## JDBC API 的最佳实践

Spring 提供了两种最佳实践：

1. 以 JdbcTemplate 为核心的基于 Template 的 JDBC 使用方式
2. 在 JdbcTemplate 基础上构建的基于操作对象的 JDBC 使用方式

这里只讨论第一种。

### JdbcTemplate

JdbcTemplate 的目的、方式和设计模式中的模板方法是一致的：它把繁琐、重复、易出错的步骤封装到 JdbcTemplate 的方法中，用户只需要关系与数据访问逻辑相关的东西，对于 JDBC 底层相关的细节不用过多地考虑。

JdbcTemplate 是 Spring JDBC API 最佳实践的核心，其他更方便的更高层次的抽象都是以此为基础的。它主要关注两件事情：

1. 封装所有基于 JDBC 的数据访问代码，例如取得或关闭数据库连接、创建或关闭 Statement 等
2. 对 SQLException 中的异常信息进行转译，返回前面讨论的统一的数据访问异常，提供给客户端

理解 JdbcTemplate 只需要理解设计模式的 Template Method Pattern 就可以了，内在的逻辑就是正常 JDBC 使用的一套流程。它的实现原理和使用方式这里先略过了。

### DataSource

Spring 的数据访问框架在数据库资源的管理上全部采用 javax.sql.DataSource 接口作为标准，不管是 JdbcTemplate 还是各种 ORM。

DataSource 的基本角色是 ConnectionFactory，它的实现有三类：

1. 简单的 DataSource 实现：DriverManagerDataSource，SingleConnectionDataSource，前者每次都返回一个新的数据库连接，后者只维护一个 singleton 的 Connection，客户端需要排队使用。

2. 拥有连接缓冲池的 DataSource 实现：我们在生产环境中最普遍使用的就是这种，它在启动的时候就初始化了一定的数据库连接以备用，当客户端的 Connection 对象调用 close() 方法，实际是把这个连接返还给缓冲池，并没有真正的关闭。

3. 支持分布式事务的 DataSource 实现类，这里就不讨论这种重量级的选手了

### 多数据源

如果我们有多个数据源，我们有两种处理方式：

![Screen Shot 2016-07-09 at 3.29.04 PM.png](http://cdn.yyqian.com/201607091529-FkoyBqRXkOyDjU_JRSxuprwkGtHI?imageView2/2/w/800/h/600)

这种方式就是定义多个 DataSource，然后每个 DataSource 都有单独的 JdbcTemplate。这样，客户端通过调用不同的 JdbcTemplate 来使用不同的数据库。

![Screen Shot 2016-07-09 at 3.30.59 PM.png](http://cdn.yyqian.com/201607091531-FiEChuJCWPC7Xm1z1cMgPIBnRt_W?imageView2/2/w/800/h/600)

这种方式是每个数据源有各自的 DataSource 对象，然后额外再使用一个 DataSource 来统一管理这些 DataSource，我们可以继承 AbstractRoutingDataSource 来自定义这个「盟主」，实现 determineCurrentLookupKey() 方法就可以了。

两者结合起来还能得到以下方式：

![Screen Shot 2016-07-09 at 3.35.44 PM.png](http://cdn.yyqian.com/201607091535-FqL2E-OmLRx9L4fo8aTXS7432iHw?imageView2/2/w/800/h/600)

---

参考资料：《Spring 揭秘》