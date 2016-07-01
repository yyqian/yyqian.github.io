---
title: Spring 事务管理
date: 2016-07-01 11:07:33
permalink: 1467342453000
tags: Spring
---

## 什么是事务

事务指的是一组数据操作的集合。事务必须包含 ACID 四个属性：

- 原子性，Atomicity
- 一致性，Consistency
- 隔离性，Isolation
- 持久性，Durability

### 原子性

就是把事务包含的全部操作看作是一个不可分割的整体（就像一颗无法再继续分裂的原子），事务操作的结果只有整体成功和整体失败两种，不能是部分操作成功、部分操作失败（一旦有一个操作失败，事务就要中断并回滚之前的操作）。这样从外部来看，一个事务就像一个独立的操作一样。

### 一致性

一个事务执行完之后，要保持数据间的一致性状态。这是什么意思呢？例如账户 A 有 10 万元，账户 B 有 10 万元，我们要从账户 A 转账到账户 B 5 万元，这里的一致性要求是两者的总和要保持不变。如果一个事务只包含从 A 扣除 5 万元的一个操作，那么结果就是 A 有 5 万元，B 有 10 万元，这时候总和发生了变化，数据就不一致了，所以这个事务不满足一致性的要求。在这里，满足一致性要求的事务应当包含扣款和充值两个操作，并且数值相等。

### 隔离性

事务的隔离性指的是同一个数据资源在并发访问的状况下，多个事务之间以何种方式协作配合。例如对同一数据资源只有在当前事务完成之后，下一个事务才能执行，这时候事务之间就是完全隔离，相互之间不可能有影响。

根据不同的隔离级别，我们可能遇到几个问题：

1. 脏读（Dirty Read）。当 A 事务更改了某个数据但还没提交，B 事务就读取该数据。之后 A 事务失败了，事务回滚，这个时候 A 之前的更改结果就变得无效了，但已经被 B 事务读取了，B 读到的这种数据就是脏数据。
2. 不可重复读取（Non-Repeatable Read）。当一个事务在整个过程中包括了先后两次对同一个数据资源进行读取，但每次读到的数据都不同，这个导致的原因可能是：在两次读取的间隔中，另一个事务对该数据完成了一次修改并提交成功了。
3. 幻读（Phantom Read）。跟不可重复读有点类似，不同点是不可重复读针对的是同一个数据的值发生变化，而幻读针对的是数据集发生变化，两次读取得到的数据列表的数目发生了变化。例如事务 A 过程中先把数据库中所有数据都处理了一遍，然后又查询了一次，发现又有新的数据还没处理。导致的原因可能是：一个事务两次读取的间隔中，另一个事务插入了一条新的记录。

一般我们能把事务的隔离级别分为四种类型：

1. Read Uncommitted。事务 A 更新了某个数据，但还没提交，这个时候事务 B 就能读取该数据。这种情况下，以上三个问题都会发生。
2. Read Committed。事务 A 更新了某个数据，这个时候只有等事务 A 提交之后，事务 B 才能读取该数据。可以避免脏读，但无法避免另外两个问题。数据库一般默认采用这种隔离级别。
3. Repeatable Read。事务 A 读取了某个数据之后，就对该行的数据加锁直到事务 A 提交。在这期间内，事务 B 对该行数据只能读不能写。可以避免脏读和不可重复读，不能避免幻读。
4. Serializable。这个是最严格的隔离级别，所有事务都排队进行，所以不可能相互之间有影响，但性能当然也很差。前面三个问题都能避免。

隔离级别、并发性、一致性之间的关系：

![Screen Shot 2016-07-01 at 11.00.25 AM.png](http://cdn.yyqian.com/201607011100-FggPrMLSYAx7j71rMsiyC80KkMOW?imageView2/2/w/800/h/600)

### 持久性

持久性指的是：一旦某个事务提交成功，这个事务变更的结果就应当被持久化，像内存型的数据库的操作就不满足持久性。


### 事务中的成员

一个典型的事务处理场景，有四个成员：

1. RM（Resource Manager），例如数据库服务器
2. TM（Transaction Manager），在全局事务中，管理多个 RM 之间的协作，下面会提到。
3. TP Monitor（Transaction Processing Monitor），可以看作是 RM 和 TM 的容器。
4. Application，调用事务的应用程序

按涉及的 RM 的数量我们可以划分：

**局部事务**

例如，某个事务的所有操作都只对一个数据库进行操作，那么我们就只需要一个 RM 就可以了。

![Screen Shot 2016-07-01 at 11.22.09 AM.png](http://cdn.yyqian.com/201607011122-FpMKl2v7_aH9RSypOuC3V3djBPc0?imageView2/2/w/800/h/600)

**全局事务**

如果我们一个事务包含了对多个数据源的操作，这个时候每个数据源自身有个 RM 进行事务管理，我们还需要一个 TM 对这几个 RM 的操作结果进行监控管理，如果其中一个 RM 处理结果是失败，TM 就要通知其他 RM 也需要进行回滚。TM Monitor 在这中间起到协调作用。

这种全局事务的方式称为两阶段提交（Two-Phase Commit），这里 RM 的事务是多种操作的集合，TM 的事务是多个 RM 事务的集合。形象的例子是，西方婚礼的牧师是 TM，两对新人是两个 RM，TM 先问两个 RM 是否愿意结婚，只有当两个 RM 都反馈说 I do 之后，牧师才会宣布两者结为夫妇。否则只要有一方不同意，婚礼就失败了。

![Screen Shot 2016-07-01 at 1.12.52 PM.png](http://cdn.yyqian.com/201607011313-FkrUxSb9B1Zlpx3uxi_qvqlQTswx?imageView2/2/w/800/h/600)

这里要注意的是，即使我们用了多个数据库，但如果程序中每个事务都只涉及到其中一个数据库，没有跨数据库的事务，那么这些事务也都是局部事务，整个系统都可以没有 TM 和 TM Monitor 参与进来，毕竟有了 TM 之后就要用两阶段提交，增加了一次提交的运算开支。

## Spring 事务管理

Spring 事务框架的设计理念是：让事务管理的关注点和数据访问的关注点分离。

Spring 事务抽象架构的核心接口是 PlatformTransactionManager，它有 getTransaction、commit、rollback 三个方法。

在 JDBC 的局部事务控制中，我们要保证多个 DAO 的数据访问方法处于同一个事务中，就要保证这些方法使用的是同一个 java.sql.Connection。做到这一点的办法就是在每个数据访问方法中都传入同一个 Connection 对象实例，这种称为 connection-passing。

把 Connection 实例传入数据访问方法这种做法，大体思路是可行的，但会带来数据访问方法和 Connection 对象的强耦合，不是一种良好的方式，所以我们要进行改进：我们在事务开始之前获取一个 Connection 实例，然后把这个实例绑定到当前的调用线程，之后数据访问方法需要 Connection 实例进行数据访问的时候，从当前线程上获取这个绑定的 Connection 实例就行了。最后完成事务提交或事务回滚，我们再把这个 Connection 与当前线程解除绑定。这里的思路就是把 Connection 实例放在一个地方，让大家都到这来取，而不是主动送过来，这个存放的地方就是当前线程。

上面的绑定、解绑、获取 Connection 三个操作被封装在 TransactionResourceManager 中，后面将简称 TRM。

在 PlatformTransactionManager 类中，我们会在 getTransaction 方法中获取一个 Connection，然后调用 TRM 的 bindResource 方法把这个 Connection 绑定到当前线程；之后的数据访问方法中可以用 TRM 的 getResource 方法来获取这个 Connection 实例；最后在 commit 和 rollback 两个方法中，都使用了 TRM 的 unbindResource 方法来解除 Connection 与当前线程的绑定。以上只是个原型，实际会复杂很多。

Spring 中事务相关的操作中要获取一个 Connection 实例，必须通过 DataSourceUtils 工具来获取，而不是直接从 DataSource 实例中获取。因为这个工具会检查当前线程是否绑定了任何 Connection，然后选择是从 DataSource 获取一个新的 Connection，还是使用当前绑定了的。

### Spring 事务抽象

主要是三个接口：

1. PlatformTransactionManager
2. TransactionDefinition
3. TransactionStatus

三者之间关系：

![Screen Shot 2016-07-01 at 3.06.07 PM.png](http://cdn.yyqian.com/201607011506-FpALr3XZdg93MKoQF00mJ7UDo2m1?imageView2/2/w/800/h/600)

**TransactionDefinition**

这个用来定义事务属性：

1. 事务的隔离级别（就是前面讨论的四种类型，默认通常是 Read Committed）
2. 事务的传播行为。假设 FoobarService 的方法中调用了 FooService 的方法和 BarService 的方法。我们可以给 FooService 和 BarService 设定不同的事务。这种行为有很多种，这里不展开了。
3. 事务的超时时间
4. 是否为只读事务

TransactionDefinition 的默认实现类是 DefaultTransactionDefinition，它已经设定好了各个事务属性的默认值。

**TransactionStatus**

TransactionStatus 用来表示事务状态，它可以查询事务状态，标记当前事务使其回滚。

它的实现有 DefaultTransactionStatus, SimpleTransactionStatus，一般我们都用前者。

**PlatformTransactionManager**

PlatformTransactionManager 的实现类可以分为面向局部事务和面向全局事务两个分支。

面向局部事务可以针对数据访问技术进行选择，例如：

- DataSourceTransactionManager: JDBC/iBatis/MyBatis
- HibernateTransactionManager
- JpaTransactionManager

面向全局事务的实现类有：JtaTransactionManager。JTA 分布式的事务管理这里就不详述了。






