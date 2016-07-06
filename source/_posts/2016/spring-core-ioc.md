---
title: Spring IoC 深入解析
date: 2016-06-30 12:59:47
permalink: 1467262787000
tags: Spring
---

Spring 有两种容器类型：

- BeanFactory：默认 lazy-load
- ApplicationContext：构建于 BeanFactory 之上

![Screen Shot 2016-06-24 at 10.03.43 AM.png](http://cdn.yyqian.com/201606241004-FqiUyxfP_kWIWmoqQbO6ShhD-_Pm?imageView2/2/w/800/h/600)

对象注册大体分为三种方式：

**代码方式**

BeanFactory的对象注册过程：

1. 构造一个 DefaultListableBeanFactory，它同时实现了 BeanDefinitionRegistry 和 BeanFactory 两个接口
2. 用 BeanDefinition 来保存要注册对象的所有信息
3. 调用 BeanDefinitionRegistry 的 registerBeanDefinition 方法来进行注册
4. 指定 BeanDefinition 之间的依赖关系
5. 强制转换 DefaultListableBeanFactory 为 BeanFactory 然后返回（因为前面我们构造的 DefaultListableBeanFactory 实现了 BeanFactory接口）
<!-- more -->
**外部配置文件方式**

如果是通过外部文件进行 Bean 的配置（例如 XML），上述的过程之前，还需要进行：

1. 构造 BeanDefinitionReader
2. 用 BeanDefinitionReader 的 loadBeanDefinitions 方法来读取配置文件中的内容，并映射到 BeanDefinition
3. 前面的 2，3，4 在这里可以省去，因为这里的 loadBeanDefinitions 已经自动完成了这些事情

最常用的外部文件配置通常是 XML，所以第一步我们可以用 XmlBeanDefinitionReader 来作为实现。

**注解方式**

我们可以在 POJO 中使用 @Autowired 和 @Component 注解来对当前对象完成注入和注册。@Component 是配合 classpath-scanning 功能使用的，也就是说 Spring 会自动扫描指定包内的带有 @Component 标注的对象。

Spring 容器中有两种最基本的 bean 的类型：signleton 和 prototype。singleton 全局只会有一个，并且跟容器生命周期一样长。prototype 每次调用就新构造一个，并且容器不会去管理它的生命周期，调用者如果用完不需要了，就自然被 GC 了。

IOC 容器有两个阶段：

1. 容器启动阶段：加载配置，分析配置，映射成 BeanDefinition，其他「后处理」
2. Bean 实例化阶段：当 Bean 被通过 getBean 方法调用，会触发该 Bean 的实例化

BeanFactoryPostProcessor 是在 Bean 定义完成后，Bean 构造前进行的，也就是前面说的「后处理」，常见的有：

1. PropertyPlaceholderConfigurer 这个用来处理占位符，例如${jdbc.url}这种，可以把配置文件中具体的数值在这个时候进行替换
2. PropertyOverrideConfigurer 是用来覆盖默认的配置，同样是从配置文件中进行获取配置信息，但配置的 key 必须符合 beanName.propertyName=value 的形式，否则 IOC 容器怎么知道你要覆盖哪个 bean 的哪个属性呢
3. CustomEditorConfigurer，由于容器从 XML 中读到的数据都是 String 类型的，还需要进行类型转换，满足各种类型对象的需要。这个东西在这就是辅助完成这个转换过程的。大多数数据容器都能自动识别，但是有些像日期这种类型，格式多种多样，所以有的时候需要自己「造轮子」来完成我们期望的结果。

BeanFactory 对于对象实例化，默认采用延迟初始化；而 ApplicationContext 则会实例化所有的 Bean。

---

参考资料：《Spring 揭秘》