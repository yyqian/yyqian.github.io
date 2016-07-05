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

## Java 平台的事务管理

Java 的局部事务管理中，事务管理的使用方式依赖于使用的数据访问技术（例如：JDBC, Hibernate, JMS），我们使用的是「特定于数据访问技术的」「基于 connection」的 API，这个「connection」 对于 JDBC 来说是 java.sql.Connection，对于 Hibernate 来说是 Session，也是依赖于数据访问技术的。

JDBC API 的事务管理代码片段：

```
// 以下省略了很多代码，只提炼出了关键的地方，不要用于现实环境中
Connection connection = null;
boolean rollback = false;
try {
    connection = dataSource.getConnection(); // 这个 Connection 特定于 JDBC
    connection.setAutoCommit(false); // 默认是自动提交事务，所以必须手动关闭
    // 使用 JDBC 进行数据访问
    connection.commit(); // 事务提交
} catch (SQLException e) {
    rollback = true;
} finally {
    if (rollback) {
        connection.rollback(); // 事务回滚
    } else {
        connection.close(); // 连接关闭
    }
}
```

Hibernate API 的事务管理代码片段：

```
Session session = null;
Transaction transaction = null;
try {
    session = sessionFactory.openSession();
    transaction = session.beginTransaction();
    // 使用 Hibernate 进行数据访问
    session.flush;
    transaction.commit();
} catch(HibernateException e) {
    transaction.rollback();
} finally {
    session.close();
}
```

对于分布式的事务管理，我们需要 JTA (Java Transaction API)和 JCA (Java Connector Architecture)的支援，这里就不继续探索了。

我们可以看到上面两段代码看上去行为有点类似，但它们操作的对象是不同的（前者是 Connection，后者是 Session 和 Transaction），抛出的错误类型也不同。除此之外，事务管理代码和数据访问代码是耦合在一起的。

因为这些不足之处，我们希望能整合不同的数据访问技术，在使用任意一种技术的时候，操作的封装的对象以及 API 是一致的，抛出的异常也是一致的，这就是 Spring 的事务管理框架要做的事。

## Spring 事务管理的架构

Spring 事务框架的设计理念是：让事务管理的关注点和数据访问的关注点分离。

Spring 事务抽象架构的核心接口是 PlatformTransactionManager，它有 getTransaction、commit、rollback 三个方法。

Spring 框架的事务管理示例：

```
TransactionDefinition definition = ...;
TransactionStatus txStatus = getTransactionManager().getTransaction(definition); // getTransactionManager() 会返回一个 PlatformTransactionManager 实例
try {
    // 数据访问，例如：userMapper.findOne();
} catch (DataAccessException e) {
    getTransactionManager().rollback(txStatus);
    throw e;
}
getTransactionManager().commit(txStatus);
```

我们可以看到，以上的代码不涉及具体的数据访问技术，大内总管变成了 PlatformTransactionManager 接口（各个数据访问技术有各自的实现类），抛出的异常被封装为 DataAccessException。

在 JDBC 的局部事务控制中，我们要保证多个 DAO 的数据访问方法处于同一个事务中，就要保证这些方法使用的是同一个 java.sql.Connection。做到这一点的办法就是在每个数据访问方法中都传入同一个 Connection 对象实例，这种称为 connection-passing。

把 Connection 实例传入数据访问方法这种做法，大体思路是可行的，但会带来数据访问方法和 Connection 对象的强耦合，不是一种良好的方式，所以我们要进行改进：我们在事务开始之前获取一个 Connection 实例，然后把这个实例绑定到当前的调用线程，之后数据访问方法需要 Connection 实例进行数据访问的时候，从当前线程上获取这个绑定的 Connection 实例就行了。最后完成事务提交或事务回滚，我们再把这个 Connection 与当前线程解除绑定。这里的思路就是把 Connection 实例放在一个地方，让大家都到这来取，而不是主动送过来，这个存放的地方就是当前线程。

上面的绑定、解绑、获取 Connection 三个操作被封装在 TransactionResourceManager 中，后面将简称 TRM。以下为原型定义示例：

```
public class TransactionResourceManager {
    private static ThreadLocal resources = new ThreadLocal();

    public static Object getResource() {
        return resources.get();
    }

    public static void bindResource(Object resource) {
        resources.set(resource);
    }

    public static Object unbindResource() {
        Object res = getResource();
        resources.set(null);
        return res;
    }
}
```

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
2. 事务的传播行为。假设 FoobarService 的方法中调用了 FooService 的方法和 BarService 的方法。我们可以给 FooService 和 BarService 设定不同的事务。这种行为有很多种，这里不展开了，需要自己去实践一下才能更好地掌握。
3. 事务的超时时间
4. 是否为只读事务

TransactionDefinition 的默认实现类是 DefaultTransactionDefinition，它已经设定好了各个事务属性的默认值。

**TransactionStatus**

TransactionStatus 用来表示事务状态，它可以查询事务状态，标记当前事务使其回滚。

它的实现有 DefaultTransactionStatus, SimpleTransactionStatus，一般我们都用前者。

**PlatformTransactionManager**

PlatformTransactionManager 是 Spring 事务抽象框架的核心组件。整个体系使用的是 Strategy 模式。它的实现类可以分为面向局部事务和面向全局事务两个分支。

面向局部事务可以针对数据访问技术进行选择，例如：

- DataSourceTransactionManager: JDBC/iBatis/MyBatis
- HibernateTransactionManager
- JpaTransactionManager

如果我们用的是 MyBatis，就可以使用 DataSourceTransactionManager

面向全局事务的实现类有：JtaTransactionManager。JTA 分布式的事务管理这里就不详述了。

下面我们用 DataSourceTransactionManager 来对 PlatformTransactionManager 进行分析：

DataSourceTransactionManager 的父类是 AbstractPlatformTransactionManager，它以模版方法的形式封装了固定的事务处理逻辑。我们这里只分析其中的三个模版方法：

1. getTransaction(TransactionDefinition)：这个方法目的是开启一个事务，但在此之前要判断下是否已经存在一个事务，如果存在，要依据 TransactionStatus 中的传播行为来决定如何操作。
2. rollback(TransactionStatus)：在事务处理过程中，我们可以通过 TransactionStatus 的 setRollbackOnly() 方法来标记事务回滚。commit(TransactionStatus) 会先检查 rollBackOnly 的状态，如果被设置，执行 rollback(TransactionStatus)。
3. commit(TransactionStatus)：这个方法与 rollback 类似，两者都要在最好做一些清理工作。

## Spring 事务管理的使用

Spring 中事务管理的使用有两种方式：

1. 编程式事务管理
2. 声明式事务管理

编程式事务管理说白了就是用 Java 代码来写事务的逻辑，又可以分为使用 PlatformTransactionManager 和 TransactionTemplate，前者更底层原始一点，后者用了模版模式，Spring 更推荐用后者。

声明式事务管理是建立在 AOP 之上的，本质就是对方法前后进行拦截，方法前创建或加入事务，方法后回滚或提交事务。优点么就是 AOP 本身的优点：非侵入式、业务逻辑和事务管理逻辑的关注点分离。

声明式事务也还可以分为两种方式：基于 xml 配置，基于 @Transactional 注解。显然，XML 配置已经过时了，让我们拥抱注解吧。因此，我们最终使用的应该是声明式事务管理下的注解方式，虽然这种方式的使用配置很简单，但注解背后的事情还是需要通过编程来解决的，所以如果想追根溯源，我们还是应该了解下编程式事务管理的运作方式。

### 编程式事务管理

直接使用 PlatformTransactionManager 的示例代码前面已经给出了，我们只要根据数据访问技术提供一个相应的 PlatformTransactionManager 实现。由于这种使用方式还是带来大量的重复代码，流程一般也是固定的，所以我们可以用模版方法来封装一下，于是就有了 TransactionTemplate。

TransactionTemplate 封装了大多数处理操作，开发人员只要关注于提供的 Callback 接口，我们有两个可以使用的 Callback 接口：TransactionCallBack 和 TransactionCallBackWithoutResult，示例代码如下：

```
TransactionTemplate txTemplate = ...;
txTemplate.execute(new TransactionCallBackWithoutResult() {
        public void doInTransactionWithoutResult(TransactionStatus txStatus) {
            // 各种事务操作。。。
        }
    });
//  TransactionCallBack 也是类似的。
```

我们可以看到，没有了定义 TransactionStatus、处理异常等操作，只要获取一个 TransactionTemplate 实例，然后把事务操作定义在 Callback 中。

我们可以通过抛出 unchecked exception 或调用 txStatus.setRollbackOnly() 来使得事务回滚。

与 PlatformTransactionManager 相比，TransactionTemplate 唯一的限制是无法抛出 checked exception，因为提供的两个 Callback 接口没有声明抛出任何 checked exception。

**基于 Savepoint 的嵌套事务**

TransactionStatus 除了通过 setRollbackOnly() 方法来使得事务回滚，它还有个功能，就是它继承自 SavepointManager，可以使用 Savepoint 机制来创建嵌套事务。

我们可以调用 TransactionStatus 的 createSavepoint() 来获得一个 savepoint，然后用 rollbackToSavepoint() 来回滚到之前的 savepoint。

### 声明式事务管理

前面我们用了 PlatformTransactionManager 和 TransactionTemplate 两种对象以编程的形式进行事务管理。为了达到终极的解耦目的，我们将使用声明式来进行事务管理。

有 Spring AOP 的支持，我们可以很容易地达到这一目的。我们只要建立一个拦截器，在业务方法开始之前开启一个事务，在方法执行完或异常退出的时候提交事务或回滚事务。这个拦截器可以用前面的编程式事务管理的两种方法之一来实现。

有了拦截器之后，我们要将这个拦截器织入需要事务处理的业务方法，织入可以通过基于 tx 和 aop 命名空间的xml配置文件进行配置，也可以通过 @Transactional 注解。这里我们只讨论注解的方式，因为这种方式最简洁明了。

我们用 @Transactional 来标注需要事务管理的方法，它的属性对应于 TransactionDefinition 中的内容。

只标注 @Transactional 显然是没用的，我们还需要让这些方法被发现，然后在前后织入事务管理的代码（也就是拦截器中的事务逻辑）。我们在这里只需要在容器的配置文件中加一行：

```
<tx:annotation-driven transaction-manager="transactionManager"/>
```

这样，IoC 容器将完成搜寻注解、读取内容、构建事务等工作。

上面的配置中，我们还需要为它提供一个 transactionManager 依赖。前面说了，各个数据访问技术有各自的 PlatformTransactionManager 的实现类，所以如果我们使用 JDBC 或 MyBatis，我们配置一个 DataSourceTransactionManager Bean 就大功告成了（当然，DataSourceTransactionManager 还依赖一个 DataSource）。

## MyBatis 和 Spring 的整合

MyBatis 在整合到 Spring 之后，事务就由 Spring 代管，而不是实现 MyBatis 自己的事务管理器，正如我们前面说的，MyBatis-Spring 用的是 DataSourceTransactionManager 管理器。

除此之外，整合之后各种异常也统一转换成 Spring 的 DataAccessError。

因此，我们需要以下 Bean：

1. DataSourceTransactionManage：这个就是我们的事务管理器
2. SqlSessionFactoryBean：在基本 MyBatis 中，session 工厂由 SqlSessionFactoryBuilder 创建，而 MyBatis-Spring 中用这个代替。我们用这个来获取 SqlSession（对应于 JDBC 中的 Connection，Hibernate 中的 Session）
3. MapperScannerConfigurer：除此之外，我们还需要一个映射器，映射 XML 和 Java class 之间的关系
