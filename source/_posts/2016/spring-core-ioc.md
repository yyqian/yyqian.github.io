---
title: Spring IoC 深入解析
date: 2016-06-30 12:59:47
permalink: 1467262787000
tags: Spring
---

IoC 的基本概念在这篇文章里先略过了，我们在这里主要探究一下实现的原理。

## IoC Service Provider

当我们写好了一个个 POJO，就需要有个对象来把这些相互之间有依赖关系的 Bean 组织在一起，这个对象就是 IoC Service Provider，提供 IoC 相关的服务。Spring IoC 容器就是一个提供依赖注入服务的 IoC Service Provider。

它有两个职责：

1. 业务对象的构建管理：当我们调用某个对象时，我们不需要去关心如何去构建它，IoC Service Provider 应当负责这件事
2. 业务对象之间的依赖绑定

IoC Service Provider 使用的注册对象管理信息的方式主要有以下几种：

1. 直接编码方式：也就是写在 Java 代码中，例如构建一个 Container 类，然后调用它的 register 方法来注册 Bean
2. 配置文件方式：最为常见的就是用 XML 文件
3. 元数据方式：最场景的就是使用注解，当然，注解最终也要通过代码处理来确定最终的注入关系，所以注解方式也可以算作编码方式的一种特殊情况。

以上三种方式在 Spring 提供的 IoC 容器中都是支持的，所以接下来我们主要来探究下 Spring 的 IoC 容器。
<!-- more -->
## BeanFactory 和 ApplicationContext

Spring 有两种容器类型：

- BeanFactory：默认 lazy-load，容器启动较快，对于资源有限的场景是合适的
- ApplicationContext：构建于 BeanFactory 之上，功能更多，默认是 eager-load，启动时间更长，初始的资源占用更多

两者的关系：

![Screen Shot 2016-06-24 at 10.03.43 AM.png](http://cdn.yyqian.com/201606241004-FqiUyxfP_kWIWmoqQbO6ShhD-_Pm?imageView2/2/w/800/h/600)

后面对 BeanFactory 适用的内容，也同样适用于 ApplicationContext。

BeanFactory 接口的定义大致有以下几类方法，基本都与查询有关：

1. getBean
2. getType
3. containsBean
4. isSingleton，isPrototype，isTypeMatch

### BeanFactory 对象注册与依赖绑定方式：

前面 IoC Service Provider 中提到的几种方式在 BeanFactory 中都是支持的。

**直接编码方式**

其实不管是用 XML 还是注解，最后都会被解析处理之后，通过编码的方式来实现。

BeanFactory的对象注册过程：

1. 构造一个实现类 DefaultListableBeanFactory，它同时实现了 BeanDefinitionRegistry 和 BeanFactory 两个接口（还记得 BeanFactory 只定义了查询相关的方法么，并不没有定义注册的方法）
2. 构建 BeanDefinition 来保存要注册对象的所有信息
3. 调用 BeanDefinitionRegistry 接口的 registerBeanDefinition 方法来注册 Bean
4. 指定 BeanDefinition 之间的依赖关系
5. 强制转换 DefaultListableBeanFactory 为 BeanFactory 然后返回（因为前面我们构造的 DefaultListableBeanFactory 实现了 BeanFactory接口）

**外部配置文件方式**

如果是通过外部文件进行 Bean 的配置（例如 XML），上述的过程之前，还需要进行：

1. 根据外部文件格式，构造相应的 BeanDefinitionReader
2. 用 BeanDefinitionReader 的 loadBeanDefinitions 方法来读取配置文件中的内容，并映射到多个 BeanDefinition
3. 前面直接编码方式的 2，3，4 步骤在这里可以省去，因为这里的 loadBeanDefinitions 已经自动完成了这些事情

最常用的外部文件配置通常是 XML，它也是功能最完整的。所以第一步我们可以用 XmlBeanDefinitionReader 来作为实现类。

**注解方式**

我们可以在 POJO 中使用 @Autowired 和 @Component 注解来对当前对象完成注入和注册。@Component 需要配合 `<context:component-scan/>` 的 classpath-scanning 功能使用，也就是说 Spring 会自动扫描指定包内的带有 @Component 标注的对象。

BeanFactory 详细的 XML 配置使用方式在这里先略过。

Spring 容器中有两种最基本的 bean 的类型：signleton 和 prototype。singleton 全局只会有一个，并且跟容器生命周期一样长。prototype 每次调用就新构造一个，并且容器不会去管理它的生命周期，调用者如果用完不需要了，就自然被 GC 了。

## 探索 BeanFactory

IOC 容器有两个阶段：

1. 容器启动阶段：除了直接编码方式，容器需要通过某些工具类（例如 BeanDefinitionReader）来读取和解析 XML 或注解中的内容，然后映射成 BeanDefinition，再把这些 BeanDefinition 注册到 BeanDefinitionRegistry 中，这样容器启动工作就完成了。
2. Bean 实例化阶段：当 Bean 被通过 BeanFactory 的 getBean 方法调用，会触发该 Bean 的实例化，这就是第二阶段的工作：先检查被请求的 Bean 是否已经实例化，如果有则返回该实例；如果没有，就通过第一阶段注册的 BeanDefinition 来实例化该对象。

我们可以把第一阶段比作用图纸来装配生产线，第二阶段比作用生产线来生成具体的产品。

### BeanFactoryPostProcessor

BeanFactoryPostProcessor 是对容器的一种扩展机制。它插手的地方在前面两个阶段之间，也就是已经注册了 BeanDefinition，但还为根据这个 BeanDefinition 来构造实例。它的工作是在这个时候对最终的 BeanDefinition 做一些修改，例如更改 BeanDefinition 的某些属性或者增加一些其他信息。

后面谈到的 ApplicationContext 只需要将 BeanFactoryPostProcessor 注册为 bean，就可以自动识别并使用它了。BeanFactory 使用起来要麻烦一些。

常用的几个 BeanFactoryPostProcessor 实现有：

**PropertyPlaceholderConfigurer**

这个用来替换占位符的实际内容。例如配置 DataSource 中的数据库连接属性，我们可以用`${xxx}`的格式来填写
 
 ```
<property name="url">
    <value>${jdbc.url}</value>
</property>
<property name="driverClassName">
    <value>${jdbc.driver}</value>
</property>
<property name="username">
    <value>${jdbc.username}</value>
</property>
<property name="password">
    <value>${jdbc.password}</value>
</property>
 ```

然后，我们把真正的属性值写在另外一个 properties 配置文件中，对于这种需要经常改动的属性，这么做更容易维护

```
jdbc.url=jdbc:mysql://xxxxx
jdbc.driver=com.mysql.jdbc.Driver
jdbc.username=your username
jdbc.password=your password
```

PropertyPlaceholderConfigurer 在实例化对象前，就会用 properties 配置文件中具体的数值替换掉 BeanDefinition 中的占位符

**PropertyOverrideConfigurer**

这个是用来覆盖默认的配置。它同样是从配置文件中进行获取配置信息，但不是去替换占位符，而是覆盖该 Bean 自身的某个属性的值，例如覆盖 Datasource 的 maxActive 属性：

```
dataSource.maxActive=200
```

配置的 key 必须符合 beanName.propertyName=value 的形式，否则 IOC 容器怎么知道你要覆盖哪个 bean 的哪个属性呢，我们这儿又没有占位符。

**CustomEditorConfigurer**

由于容器从 XML 中读到的数据都是 String 类型的，还需要进行类型转换，满足各种类型对象的需要。这个东西在这就是辅助完成这个转换过程的。大多数数据容器都能自动识别，但是有些像日期这种类型，格式多种多样，所以有的时候需要自己「造轮子」来完成我们期望的结果。

因此，当我们 XML 配置文件中的属性值的数据类型无法被正确识别的时候，我们需要自定义一个 PropertyEditor，再通过 CustomEditorConfigurer 告知容器。

### Bean 的一生

我们前面说过，BeanFactory 默认是 lazy-load，ApplicationContext 默认是 eager-load。所以对于 BeanFactory，只有当显式或隐式地被 getBean 调用的时候，才会实例化。

在 Bean 实例化后，Spring 容器将对它们的生命周期给予统一的管理，不会像正常的 Java 对象那样在脱离作用域之后就被 GC 回收。

Bean 的初始化有两种方式：反射和 CGLIB 动态字节码生成。容器内部采用策略模式来决定用哪种，默认用的是 CGLIB。初始化之后，框架还会对构造的对象用 BeanWrapper 进行包裹，所以实际返回的是 BeanWrapper 实例。

**BeanWrapper**

BeanWrapper 的主要作用是可以「设置对象属性」，前面我们说了可以用 BeanFactoryPostProcessor 对 BeanDefinition 进行修改，这里有个了 BeanWrapper 之后就可以方便地进行这些修改了，我们可以免去直接使用 Java 反射 API 的繁琐。

**Aware 接口**

作用是如果当前对象实例实现了某个 Aware 接口，容器就把这个 Aware 接口定义中规定的依赖注入给当前对象实例。

**BeanPostProcessor**

BeanPostProcessor 存在于对象实例化阶段，而 BeanFactoryPostProcessor 存在于容器启动阶段。BeanFactoryPostProcessor 处理对象是 BeanDefinition，而 BeanPostProcessor 的处理对象是实例化之后的对象实例。相当于一个是处理流水线上的生成设备，另一个是处理生产出来的产品。

它可以用来替换当前对象实例或字节码增强当前对象实例。Spring AOP 就用这个来为对象生成相应的代理对象。它是容器提供的对象实例化阶段的强有力的扩展点。

它的实际应用之一是：我们有个 User 类，它的其中一个属性是 password，在初始化的时候，传入的是加密的密码，我们可以用 BeanPostProcessor 进行拦截，获取该实例中加密的密码，然后解密之后设置回 password 属性。这样当程序拿到该实例的时候，这个 password 属性就是解密后的密码了。

**InitializingBean 和 init-method**

InitializingBean 接口定义如下：

```
public interface InitializingBean {
    void afterPropertiesSet() throws Exception;
}
```

它的作用在于，在实例化过程调用过「BeanPostProcessor 的前置处理」之后，会接着检查是否实现了 InitializingBean 接口，如果是，就调用 afterPropertiesSet 方法。例如某些对象实例化之后还不处于可用状态，可以在 afterPropertiesSet 方法中进行一些后续处理。

除此之外，还有另外一种方式来实现同样的功能。我们还可以在 XML 配置 Bean 的时候，指定 init-method 属性，该属性值是对象中的某个方法，这样就不用实现 InitializingBean 接口，方法名也不必是 afterPropertiesSet 了。

两者我们只要选其中一个就可以了。一般我们在集成第三方库，或者其他特殊情况下，才会使用该特性。

**DisposableBean 与 destroy-method**

这两个是针对 singleton 类型的bean实例的，容器在销毁 singleton 类型的bean实例之前，会检查是否实现了 DisposableBean 接口，如果是，就调用一个回调方法，执行销毁逻辑。

destroy-method 与前面的 init-method 类似，也是在 XML 配置中设置的另外一种方式。

这个功能的典型应用是 Spring 容器中注册的数据库连接池，当系统退出，连接池应当关闭，以释放资源，所以我们可以设置：

```
<bean id="dataSource" class="org.apache.commons.dbcp.BasicDataSource" ➥
destroy-method="close">
...
</bean>
```

其中的 close 是我们自己定义的方法。

这些销毁逻辑只有在该实例对象不再被使用的时候才会执行，这通常也是 Spring 容器关闭的时候，但是 Spring 容器在关闭之前，不会聪明的自动调用这些销毁方法。所以，我们还需要告知容器，在哪个时间点来执行对象的自定义销毁方法。这一点对于 BeanFactory 和 ApplicationContext 两个容器有所不同，这里不在深究了。

## ApplicationContext 的扩展

ApplicationContext 是在 BeanFactory 容器的基础上，提供的一个功能更强大的 IoC 容器。新增的特性包括：统一的资源加载策略、i18n、容器内部事件发布、多配置文件加载。

它有几个常用的实现：

- FileSystemXmlApplicationContext：从文件系统加载 XML
- ClassPathXmlApplicationContext：从 Classpath 加载 XML
- XmlWebApplicationContext

我们这里主要探究一下其中的两个新特性：统一的资源加载策略和多配置文件加载。

### Resource 和 ResourceLoader

Spring 中 Resource 和 ResourceLoader 的出现是因为 Java 自身的 URL 定义不明确。

**Resource**

Resource 是 Spring 中所有资源的抽象和访问接口。它的实现类有：

- ByteArrayResource
- ClassPathResource
- FileSystemResource
- UrlResource

它可以帮助我们查询资源状态、访问资源内容，接口定义为：

```
public interface Resource extends InputStreamSource {
  boolean exists();
  boolean isReadable();
  boolean isOpen();
  URL getURL() throws IOException;
  URI getURI() throws IOException;
  File getFile() throws IOException;
  long contentLength() throws IOException;
  long lastModified() throws IOException;
  Resource createRelative(String var1) throws IOException;
  String getFilename();
  String getDescription();
}
```

**ResourceLoader**

该接口主要的方法是：

```
Resource getResource(String location);
```

我们要用一个字符串来作为 key，来定位 Resource 对象。

它的实现类或扩展接口有：

**DefaultResourceLoader**

这是个默认的实现类，它的查找方式如下：

1. 检查是否以 `classpath:` 前缀打头，如果是，则尝试构造 ClassPathResource 类型并返回
2. 否则，尝试通过 URL，根据资源路径来定位。还是不行的话，委派 getResourceByPath 方法来查找

**FileSystemResourceLoader**

它继承自 DefaultResourceLoader，但覆盖了 getResourceByPath 方法，使得该方法返回的类型是 FileSystemResource

**ResourcePatternResolver**

这是 ResourceLoader 接口的扩展，它的接口定义如下：

```
public interface ResourcePatternResolver extends ResourceLoader {
    String CLASSPATH_ALL_URL_PREFIX = "classpath*:";
    Resource[] getResources(String locationPattern) throws IOException;
}
```

它有一种新的协议前缀`classpath*:`，功能支持由相应子类实现。

它的最常用的实现是 PathMatchingResourcePatternResolver，它支持 `**/*.suffix` 之类的格式，加载资源的行为和 DefaultResourceLoader 基本相同，只是多了个 getResources 方法，可以获取多个匹配的 Resource。

### ApplicationContext 与 ResourceLoader

通过 ApplicationContext 的继承关系，我们可以看到它继承了 ResourcePatternResolver，所以 ApplicationContext 本身就有加载资源的能力。

ApplicationContext 的实现类在作为 ResourceLoader 或者 ResourcePatternResolver 时候的行为，完全就是委派给了 PathMatchingResourcePatternResolver 和 DefaultResourceLoader。它可以有以下功能：

1. 扮演 ResourceLoader 的角色，加载 Resource
2. 被当做 ResourceLoader 类型的 Bean 注入到其他的 Bean
3. 还有其他的就不深究了。

一些细节：

classpath*:与classpath:的唯一区别在于，如果能够在classpath中找到多个指定的资源，则
返回多个。

当 ClassPathXmlApplicationContext 在实例化的时候，即使没有指明 classpath: 或者 classpath*: 等前缀，它会默认从 classpath 中加载 bean 定义配置文件。而 FileSystemXmlApplicationContex 则默认从文件系统中加载。不过如果在使用 FileSystemXmlApplicationContex 时加了 classpath: 前缀，它就会明确地从 classpath 中加载。简而言之，需要从 classpath 加载的时候，明确使用 classpath: 或者 classpath*: 前缀总是没错的。

### 多配置文件加载

使用 classpath* 我们可以完成加载多个配置文件，除此之外还有一种方式，就是在构造 ApplicationContext，传入配置文件参数的时候，我们传入一个 String[]，其中包含了多个配置文件所在路径，这样就能加载多个配置文件了，例如：

```
String[] locations = new String[]{ "conf/dao-tier.springxml", "conf/view-tier.springxml", "conf/business-tier.springxml"};
ApplicationContext container = new FileSystemXmlApplicationContext(locations);
// 或者
ApplicationContext container = new ClassPathXmlApplicationContext(locations);
// 甚至于使用通配符
ApplicationContext container = new FileSystemXmlApplicationContext("conf/**/*.springxml");
```

---

参考资料：《Spring 揭秘》
