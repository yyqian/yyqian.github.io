---
title: Spring AOP 深入解析
date: 2016-06-30 14:36:36
permalink: 1467268596000
tags: Spring
---

## AOP 简介

AOP 可以看成是针对 OOP 的一个补充或增强。有些系统需求，例如：安全检查、事务管理，如果把这些功能的代码写到业务模块里，会产生很多业务无关的代码，给调试、重构带来很大的复杂度。AOP 在这里的作用就是关注点分离，将业务模块和基础设施模块进行解耦。

但 AOP 本身不能独立于 OOP 而存在，AOP 的实现一般都要「寄生」在 OOP 的领土之中，这个「寄生」的过程用 AOP 中的黑话来说就是「织入」：把 AOP 的组件集成到 OOP 的组件之中，获得一个新的、能力更强的 OOP 组件。

我们在这里约定没被增强的原始类称为 POJO，织入的 AOP 组件称为 Aspect，织入后的新的类称为增强类。

一个 POJO 被「织入」Aspect 之后，得到的增强类对于 POJO 的使用者来说应该是透明的，否则这种增强就是侵入式的了。对于不同的 AOP 的实现方式，如何对使用者透明，采取的方式也不一样。

AOP 从实现的方式来分可以分为：

1. 静态 AOP：典型代表是 AspectJ，它解析 Aspect 的语义之后，直接在 POJO 的字节码中植入 Aspect 相关的字节码，因此虽然 JVM 实际运行的字节码发生变化了，但增强类的类型没变，使用者关注的部分是没有变化的，所以是透明的。这种方式的 Aspect 一般也不是用 Java 语言来描述的，而是用领域特定语言 AOL，它的织入过程发生在编译阶段（这里把 Java 代码到字节码的过程称为编译）。

2. 动态 AOP：Spring AOP 就是其中之一，它在编译和系统启动之前，不会对 POJO 的 Java 代码或字节码做任何修改，也就是说「织入」过程不是发生在编译阶段的。实际上，动态方式的「织入」过程发生在类加载或者系统运行期间，这个期间我们无法再修改原始的 POJO 类，但我们还是有两种选择来实现对使用者透明：使用动态代理技术，代理类就是增强类，实现与之前相同的接口；使用动态字节码生成技术，生成一个继承了 POJO 类的增强类。不管是代理类还是字节码生成的子类，当我们用它来替换原来的 POJO 类的实现，对于 POJO 的调用者，它关心的部分没有变化，因此是透明的。

## AOP 的组成部分

这里我们采用 AspectJ 的描述方式：

1. Joinpoint（织入点）：例如在调用某个方法之前织入 Aspect 逻辑，这个方法调用的点就是一个织入点，除了方法调用，字段设置、读取、异常处理等都可以作为织入点，但不同的 AOP 实现支持的织入点是不同的。

2. Pointcut：Pointcut 是用来描述一组 Joinpoint 的，例如我们有多个 Controller 类，每个类都有若干方法，如果我们希望在所有这些方法调用之前织入日志记录的 Aspect 逻辑，就可以用「所有带 @Controller 注解的类的所有方法」来描述多个 Joinpoint，这个描述就称为 Pointcut。描述的方式多种多样，后面我们会专注于一种描述方式。

3. Advice：Pointcut 描述带着我们定位到需要进行「织入」的 Joinpoints，接下来要做的事就是描述我们要在这个 Joinpoint「做些什么」，这就是 Advice 要干的事情。Advice 又可以分为 Before Advice, After Advice, Around Advice, Introduction，大概意思就是在 Joinpoint 之前干点什么，之后干点什么，前后干点什么，根据你的需要而定。

4. Aspect：这个是把 Pointcut 和 Advice 封装在一起的实体，就好比 OOP 中把 field 和 method 封装成 Class。在 Spring AOP 的 @AspectJ 实现中，Aspect 可以用一个 POJO 类来描述实现，这点后面将会看到。

5. Weaver（织入器）：前面反复说了「织入」这个过程，这个过程不是由编译器完成的，而是由专门的织入器完成，各个实现有自己的织入器选择。

6. Target（目标对象）：这个就是被「织入」的对象，Pointcut 实际描述了两个部分：要被「织入」的对象和该对象中被「织入」的点。例如前面的「所有带 @Controller 注解的类」就是 Target。所以 Pointcut 同时描述了 Target 和 Joinpoint 两者。

把它们组织到一起，就有了下图：

![Screen Shot 2016-06-30 at 2.31.26 PM.png](http://cdn.yyqian.com/201606301431-Fowh5r_wL6mODDSR3IQ2egOAlDrd?imageView2/2/w/800/h/600)

其中我们要着手编写的是 Pointcut 和 Advice 两者（或者说是整个 Aspect），织入逻辑、织入对象以及织入点的描述都在其中。而 Weaver 由 AOP 框架来实现。

## Spring AOP 实现原理

前面说了，Spring AOP 的实现属于动态 AOP，它的目的是在运行时生成一个「代理对象 = 织入逻辑 + 目标对象」，在使用目标对象的地方都用这个「代理对象」来替代，这个代理对象的生成有「动态代理机制」和「字节码生成技术」两种方式。

### 动态代理机制

在讲解「动态代理机制」之前，我们先来看设计模式的其中一种：代理模式。

![Screen Shot 2016-06-30 at 3.06.05 PM.png](http://cdn.yyqian.com/201606301506-FsDPF4g32qoQ6FHEIt77a_oPcxlW?imageView2/2/w/800/h/600)

三者的使用方法如下：

```
ISubject target = new SubjectImpl(); // 为代理类的构造做准备
ISubject subject = new SubjectProxy(target); // 实际使用的代理对象，其中织入了 Aspect 逻辑
subject.doSomething(); // 这时调用方法就会触发织入的逻辑
```

由于 SubjectProxy 和 SubjectImpl 实现了相同的接口，并且 SubjectProxy 是 SubjectImpl 的拓展，所以我们可以把织入逻辑植入到 SubjectProxy 中，并且在使用中也可以直接替换掉 SubjectImpl。

Spring AOP 的动态代理机制也使用了类似的思路，但不同点在于「动态」两个字。虽然上面的代理模式能解决问题，但一般同一个织入逻辑（Advice）会被织入到多个目标对象中（Target），用上面的方式，就需要为每一个目标对象都生成一个静态的代理对象，这样的话代理对象的数量就会非常多。

因此，Spring AOP 实际上用的是 JDK 1.3 之后引入的动态代理（Dynamic Proxy）的机制，它是由 Proxy 类和 InvocationHandler 接口组合实现的。

这两者的使用方式就不详述了，需要知道的是这里的织入逻辑会被植入到 InvocationHandler 接口的实现类中，可以在该类 invoke 方法的前后添加逻辑。Proxy 类的静态方法 newProxyInstance 可以直接生成代理类的对象实例，而不用像前面那样事先定义代理类。

### 字节码生成技术

前面的「动态代理机制」有一个缺陷：如果目标对象（Target）没有实现任何接口，那我们使用的时候就无法用代理对象替换目标对象了，所以「动态代理机制」对这种没有遵守「面向接口编程」的对象是无效的。

以上情况下，我们可以用 CGLIB 等「字节码生成技术」，生成一个继承了目标对象的子类，然后在该子类上织入 Aspect 逻辑，由于`子类 instanceof 父类 == true`，所以我们可以用这个扩展的子类的对象实例来替换目标对象的实例。

「字节码生成技术」顾名思义，可以直接得到字节码，所以这个生成子类实例的过程就不需要为每个目标对象都定义扩展子类了。具体的该技术的使用这里也不做介绍了。

默认情况下，Spring AOP 如果发现目标对象实现了某个接口，就使用「动态代理机制」来生成代理对象的实例；如果没有，则使用 CGLIB。

## Spring AOP 的使用

这里只讨论一种使用方式：@AspectJ 注解形式的 Spring AOP。我们先来看一下一段示例，这段示例在所有 @Controller 类的方法上都添加了 Rate Limit 功能：

```Java
@Component
@Aspect
public class RateLimitAspect {
  private static final Logger logger =
      LoggerFactory.getLogger(RateLimitAspect.class);

  @Autowired
  private StringRedisTemplate redisTemplate;

  @Pointcut("@annotation(rateLimit)")
  private void annotatedWithRateLimit(RateLimit rateLimit) {}

  @Pointcut("@within(org.springframework.stereotype.Controller)"
      + " || @within(org.springframework.web.bind.annotation.RestController)")
  private void controllerMethods() {}

  /**
   * 处理 RateLimit 标注的 controller 包下面的方法.
   */
  @Before("controllerMethods() && annotatedWithRateLimit(rateLimit)")
  public void rateLimitProcess(final JoinPoint joinPoint,
                               RateLimit rateLimit) throws RateLimitException {
    logger.debug("触发 rateLimitProcess()");
    HttpServletRequest request = getRequest(joinPoint.getArgs());
    if (request == null) {
      logger.error(String.format("方法[%s]中缺失 HttpServletRequest 参数",
                                 joinPoint.getSignature().toShortString()));
      return;
    }
    String ip = request.getRemoteHost();
    String url = request.getRequestURI();
    String key = String.format("req:lim:%s:%s", url, ip);
    long count = redisTemplate.opsForValue().increment(key, 1);
    logger.debug(String.format("[Redis] %s = %s", key, count));
    if (count == 1) {
      redisTemplate.expire(key, rateLimit.duration(), rateLimit.unit());
    }
    if (count > rateLimit.limit()) {
      logger.warn(String.format("用户IP[%s]短时间内连续[%d]次访问地址[%s], 超过了限定的次数[%d]",
                                ip, count, url, rateLimit.limit()));
      throw new RateLimitException();
    }
  }

  private HttpServletRequest getRequest(Object[] args) {
    for (Object arg : args) {
      if (arg instanceof HttpServletRequest) {
        return (HttpServletRequest)arg;
      }
    }
    return null;
  }
}
```

其中跟 AOP 相关的是 @Aspect, @Pointcut, @Before 这几个注解。@Aspect 表明这个类是一个 Aspect；@Pointcut 用来描述一个 Pointcut，描述的领域特定语言可以查看文档，这里就不详述了；@Before 是 Advice 的一种，还有其他种类也请查看文档。基本上只要能玩转 @Pointcut 的描述和几种 Advice 就能实现很多功能了。

这里要注意的是我们需要 aspectjweaver 类库作为依赖，因为其中的 Pointcut 解析和匹配工作是由 AspectJ 类库完成的，Spring AOP 完成了其余的部分。

这里 Aspect 本身是个 POJO 类，也可以被当作 Bean 注入到 IoC 容器中。至于如何将这个定义好的 Aspect 织入目标类，我在 Spring Boot 框架下，只要把这个 bean 注入 IoC 容器就完成了，剩下的工作在框架内部是如何完成的我暂时也还不知道。

前面 RateLimiter 的完整实现见：[Github](https://github.com/yyqian/rate-limiter)

---

参考资料：《Spring 揭秘》
