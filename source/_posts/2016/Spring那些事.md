---
title: Spring in Action 笔记
date: 2016-01-31 15:16:39
permalink: 1454224599679
tags: Spring
---

## Spring IoC

---

待注入的 class

```java
public class BraveKnight implements Knight {
  private Quest quest;
  // will inject Quest here
  public BraveKnight(Quest quest) {
    this.quest = quest;
  }
  public void embarkOnQuest() {
    quest.embark();
  }
}
```

将要注入的 class
<!-- more -->
```java
public class SlayDragonQuest implements Quest {
  private PrintStream stream;
  public SlayDragonQuest(PrintStream stream) {
    this.stream = stream;
  }
  public void embark() {
    stream.println("Embarking on quest to slay the dragon!");
  }
}
```

我们可以看到 BraveKnight 和 SlayDragonQuest 之间是通过 Quest 接口耦合的。下面将通过 JavaConfig 方法来执行注入。

```java
@Configuration
public class KnightConfig {
  @Bean
  public Knight knight() {
    return new BraveKnight(quest());
  }
  @Bean
  public Quest quest() {
    return new SlayDragonQuest(System.out);
  }
}
```

然后通过 application context 来调用这些 Beans，JavaConfig 要用 AnnotationConfigApplicationContext 来调用。

```java
public class KnightMain {
  public static void main(String[] args) throws Exception {
    ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("META-INF/spring/knight.xml");
    Knight knight = context.getBean(Knight.class);
    knight.embarkOnQuest();
    context.close();
  }
}
```

By default, all beans in Spring are singletons. 如果调用一个方法被注解了 @Bean，那么这个方法返回的是一个 Singleton 的 Bean，而不会再创建一个对象。

CD 机的例子：

```java
public interface CompactDisc {
  void play();
}

@Component
public class SgtPeppers implements CompactDisc {
  private String title = "Sgt. Pepper's Lonely Hearts Club Band";
  private String artist = "The Beatles";
  public void play() {
    System.out.println("Playing " + title + " by " + artist);
  }
}

@Component
public class CDPlayer implements MediaPlayer {
  private CompactDisc cd;
  public CDPlayer(CompactDisc cd) {
    this.cd = cd;
  }
  public void play() {
    cd.play();
  }
}
```

自动扫描设置

```java
@Configuration
@ComponentScan
public class CDPlayerConfig {}
```

手动 wiring

```java
@Bean
public CompactDisc sgtPeppers() {
  return new SgtPeppers();
}

@Bean
public CDPlayer cdPlayer() {
  return new CDPlayer(sgtPeppers());
}
```

上面的 wiring 也可以改成这样，这样 SgtPeppers 的 Config 就可以通过其他方式进行，譬如 XML 或 自动。

```java
@Bean
public CDPlayer cdPlayer(CompactDisc compactDisc) {
  return new CDPlayer(compactDisc);
}
```

## Spring Web

---

### @RequestMapping 方法的参数和返回值

参数可以是 Servlet API 中定义的一些 Objects：

* Request or response objects：例如 ServletRequest，HttpServletRequest
* Session object：具体见 [Supported method argument types](http://docs.spring.io/spring/docs/4.2.3.RELEASE/spring-framework-reference/htmlsingle/#mvc-ann-arguments)

要注意的是参数的位置是有先后的。

返回值在没有用 @ResponseBody 注解的情况下，常用的是 String，返回的是模版的名称，接下来将交给 View 来处理，

返回值在注解了 @ResponseBody 的情况下，可以用任何 Object，返回的时候会使用 Jackson2 来序列化，并直接返回给用户。

支持的返回值具体见：[Supported method return types](http://docs.spring.io/spring/docs/4.2.3.RELEASE/spring-framework-reference/htmlsingle/#mvc-ann-return-types)

### 几种 Component 的区别

`@Component` annotation marks a java class as a bean so the component-scanning mechanism of spring can pick it up and pull it into the application context.

`@Repository` annotation is a specialization of the `@Component` annotation with similar use and functionality. In addition to importing the DAOs into the DI container, it also makes the unchecked exceptions (thrown from DAO methods) eligible for translation into SpringDataAccessException.

`@Service` annotation is also a specialization of the component annotation. It doesn’t currently provide any additional behavior over the `@Component` annotation, but it’s a good idea to use `@Service` over `@Component` in service-layer classes because it specifies intent better. Additionally, tool support and additional behavior might rely on it in the future.

`@Controller` annotation marks a class as a Spring Web MVC controller. It too is a `@Component` specialization, so beans marked with it are automatically imported into the DI container.

In real life, you will face very rare situations where you will need to use `@Component` annotation. Most of the time, you will using `@Repository`, `@Service` and `@Controller` annotations. `@Component` should be used when your class does not fall into either of three categories i.e. controller, manager and dao.

Always use these annotations over concrete classes; not over interfaces.

If you want to define name of the bean with which they will be registered in DI container, you can pass the name in annotation itself e.g. @Service (“employeeManager”).

### Content-Type 相关

Spring Web 可以将提交的表格或者 ajax 提交的 json 直接转换为 Object 或是提取参数，调用的方式是在 @RequestMapping 方法的参数上注解 @RequestParam，@ModelAttribute，@RequestBody。以下是三者的用处以及支持的 Content-Type：

* @RequestParam：可以提取参数，支持 application/x-www-form-urlencoded
* @ModelAttribute：可以直接绑定到 Object，支持 application/x-www-form-urlencoded
* @RequestBody：可以直接绑定到 Object，支持 application/json

浏览器表单的提交是通过 application/x-www-form-urlencoded 这种格式上传的，jQuery 的 `$.ajax()` 也是将 json 转换成 application/x-www-form-urlencoded 格式再上传的。

@RequestBody 按理来说在配置了 FormHttpMessageConverter 之后也可以支持 application/x-www-form-urlencoded，但是我在 Spring Boot 配置的环境中无法实现，原因不确定。

### 处理异常

处理异常有几种方式，这里只介绍一种处理方式：

如果每个 @Controller 类单独处理自己的异常，可以在该类中定义 @ExceptionHandler 方法。

如果想集中处理所有 @Controller 类产生的异常，可以定义一个 @ControllerAdvice 类，这个类中的方法适用于所有 @Controller，因此在该类中定义 @ExceptionHandler 方法就可以处理所有控制器产生的异常。

一个例子：

```java
@ControllerAdvice
public class GlobalExceptionHandler extends DefaultHandlerExceptionResolver {
  @ExceptionHandler({
      BadRequestException.class,
      ForbiddenException.class,
      InternalServerErrorException.class,
      NotFoundException.class,
      UnauthorizedException.class
  })
  void restExceptionHandler(RuntimeException ex, HttpServletResponse response) throws IOException {
    int statusCode;
    if (ex instanceof BadRequestException) {
      statusCode = HttpServletResponse.SC_BAD_REQUEST;
    } else if (ex instanceof ForbiddenException) {
      statusCode = HttpServletResponse.SC_FORBIDDEN;
    } else if (ex instanceof NotFoundException) {
      statusCode = HttpServletResponse.SC_NOT_FOUND;
    } else if (ex instanceof UnauthorizedException) {
      statusCode = HttpServletResponse.SC_UNAUTHORIZED;
    } else {
      statusCode = HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
    }
    response.sendError(statusCode);
  }
}

public class BadRequestException extends RuntimeException {
  public BadRequestException() {
  }
  public BadRequestException(String message) {
    super(message);
  }
  public BadRequestException(String message, Throwable cause) {
    super(message, cause);
  }
  public BadRequestException(Throwable cause) {
    super(cause);
  }
  public BadRequestException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
    super(message, cause, enableSuppression, writableStackTrace);
  }
}
```

## Spring Boot

---

### 自动配置和注解配置

Spring Boot 最主要解决的问题就是省去了很多繁琐的配置。实现的原理可以从 @SpringBootApplication 这个注解看出，这个注解包含了 @Configuration，@EnableAutoConfiguration，@ComponentScan。因此，@SpringBootApplication 注解的 Class 会做以下几件事：

1. @Configuration：搜集当前 Class 中的配置
2. @EnableAutoConfiguration：Spring Boot的主要功能，根据依赖的 jar 包来判断是否自动注册相应的 Bean 以及进行默认的配置。
3. @ComponentScan：自动搜索当前包名下面的所有 Class，挑出所有 @Component 注解的 Class，并注册为 Bean。

@Controller，@RestController，@Repository，@Service，@Configuration 都是特殊的 @Component，都会被注册为 Bean。

以前的 XML 配置文件可以用 @Configuration 注解的 Class 来代替，要注册的 Bean 用 @Bean 来注解。auto-configuration 不会对自己注册过的 Bean 再进行注册或配置。

配置 Rabbitmq 的例子：

```java
@Configuration
public class RabbitmqConfig {
  @Bean
  public MessageConverter jackson2JsonMessageConverter() {
    return new Jackson2JsonMessageConverter();
  }
  @Bean
  public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
    RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
    rabbitTemplate.setMessageConverter(jackson2JsonMessageConverter());
    return rabbitTemplate;
  }
```

如果想手动禁止一些自动配置的话，有两种方法：

1. @EnableAutoConfiguration(exclude={DataSourceAutoConfiguration.class})
2. 配置 application.properties 文件中的 spring.autoconfigure.exclude

### 在 Ubuntu 中注册服务

Gradle 中加入：

```java
apply plugin: 'spring-boot'
springBoot {
    executable = true
}
```

编译得到的 jar 包 chmod 为 744，然后在 Ubuntu 中建立服务 `ln -s xxx.jar /etc/init.d/xxx`，就可以用 `service xxx start` 来启动应用了。

### 生成 war 包

如果想生成 war 包，放在容器中运行，可以通过以下步骤：

build.gradle 文件中添加：

```java
apply plugin: 'war'
war {
    baseName = 'app-name'
    version = '0.0.1'
}
```

@SpringBootApplication 注解的 Class 中添加：

```java
@SpringBootApplication
public class DolphinMsCoreApplication extends SpringBootServletInitializer {
  @Override
  protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
    return application.sources(DolphinMsCoreApplication.class);
  }
  public static void main(String[] args) {
    SpringApplication.run(DolphinMsCoreApplication.class, args);
  }
}
```

运行 `gradle build`

## Spring Testing

---

### 单元测试（Unit testing）

一般 Unit testing 速度很快，因为不需要设置或连接基础设施。

最普通的 POJO 可以直接 new 一个 object，然后用 JUnit 来测试，不需要 Spring 框架或任何容器。

service layer object 可以通过 stubbing or mocking DAO or Repository interfaces 来注入依赖，进而进行测试，这样就不需要连接数据库了。

Spring 提供了一些 mock objects 来辅助 unit testing：

1. Environment, PropertySource: `org.springframework.mock.env`, 包含了 MockEnvironment, MockPropertySource
2. JNDI: `org.springframework.mock.jndi`
3. Servlet API: `org.springframework.mock.web`, 代替了 EasyMock 和 MockObjects，主要用来测试 web contexts, controllers and filters

Spring 还提供了一些用来 testing 的工具，包含在 `org.springframework.test.util` package 中：

1. ReflectionTestUtils：可以用来访问 private 的属性或方法
2. AopTestUtils

Spring MVC 相关的测试包含在 `org.springframework.test.web` package 中，测试 controller 可以用 ModelAndViewAssert 结合 MockHttpServletRequest, MockHttpSession 等等来进行。

### 集成测试（Integration Testing）

集成测试与单元测试的主要不同是：需要导入 ApplicationContext，在这个上下文中进行测试

集成测试的一个例子：

```java
@RunWith(SpringJUnit4ClassRunner.class)
@SpringApplicationConfiguration(classes = EinsteinApplication.class)
@WebAppConfiguration
public class PostRestControllerTest {

  @Autowired
  private WebApplicationContext webApplicationContext;

  @Autowired
  private PostRepository postRepository;

  private MockMvc mockMvc;

  @Before
  public void setMockMvc () {
    mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
  }

  @Test
  public void testRead() throws Exception {
    String testId = postRepository.findAll().get(0).getId();
    mockMvc.perform(get("/api/post/" + testId))
        .andExpect(status().isOk());
  }
}
```

## Spring Security

---

authenticating user 有四种方式：

1. inMemoryAuthentication() 这个就是把 username，password 都写死在程序里
2. jdbcAuthentication() 适合 SQL DB，直接写 SQL 语句来查询；或者不写 SQL 语句，使用默认的 SQL 语句，构造符合要求的 TABLE
3. ldapAuthentication() 这个不了解
4. userDetailsService() 这个最灵活，自己实现 UserDetailsService 接口，override loadUserByUsername 方法，获取 domain 的 user，然后转换成 org.springframework.security.core.userdetails.User 返回。

Intercepting requests 主要用这几个方法：

1. authorizeRequests() 根据 URL 过滤
2. requiresChannel() 限定 HTTPS 请求
3. 如果用了 Thymeleaf，form 会自动添加 _csrf 项

HttpSecurity 在 authenticating 方面有以下常用方法：

1. formLogin() 这个用在 Web 界面登陆
2. httpBasic() 这个用在 RESTful API 等与 application 交互的地方
3. rememberMe() 可以用来实现 remember me 功能
4. logout()

Thymeleaf 还包含了一些自己的 security dialect，可以根据登录状态来判断显示默写模块。

## Integrating Spring

---

### SOA

Spring remoting 中讨论的主要是怎么使用 remote procedure call (RPC) 在一个 application 中调用另一个 app 的方法，Spring 可以使用的 remoting technologies 有：

1. Remote Method Invocation (RMI)
2. Hessian or Burlap
3. HTTP invoker
4. JAX-RPC and JAX-WS

这些技术都是用在 SOA (service oriented architecture) 架构中的，顾名思义，这种架构以 service 为中心，不同的模块以 methods 耦合在一起。这种架构有个缺陷就是 PRC 过程是 block 的，跟本地调用还是有差别的。

### RESTful API

RESTful API 也属于 Synchronous communication

### Messaging

Spring 中的 asynchronous messaging 主要有两种技术：Java Message Service (JMS)，Advanced Message Queuing Protocol (AMQP)。

#### JMS

messaging model有两种：point-to-point and publish/subscribe

架构主要针对几个对象：the message producer, the message consumer(s), and a channel (either a queue or a topic)

queues route using a point-to-point algorithm, and topics route in publish/subscribe fashion.

ActiveMQ 是 message broker 的实现之一，可以实现 asynchronous messaging with JMS

#### AMQP

AMQP 是最新的 messaging 技术，AMQP 可以实现跨语言、跨平台的沟通

RabbitMQ 是 AMQP 的实现之一

Kafka 是 Linkedin搞出来的，也可以考虑使用
