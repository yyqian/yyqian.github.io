---
title: Spring MVC 深入解析
date: 2016-07-06 08:57:35
permalink: 1467766655000
tags: Spring
---

## Spring MVC 史前时代

这里我们主要回顾一下 Java 平台上的 Web 开发历程。

最早的时候，我们用的是 Servlet，它运行于 Web 容器之内，提供了 Session 和对象生命周期管理等功能。它本身是 Java 类，所以可以调用 Java 平台各种 API。

如果单单依靠这一种技术，我们就会把所有代码全部写在 Servlet 中，包括视图渲染的代码，例如 `out.println("<td>" + rs.getString(2) + "</td>")` 。但这样不满足我们关注点分离的要求，会导致系统难以重构、需求更改和维护。

除此之外，我们还一般使用「一个 Servlet 对应处理一个 Web 请求」，所以会有大量的散乱的 Servlet。

为了能将 Servlet 中视图渲染的逻辑提取出来，让业务逻辑和视图渲染逻辑分离，我们就有了 JSP。JSP 可以看作是现在 Java 平台各种模版引擎的鼻祖，它看上去和 HTML 代码差不多，只是有一些自己独特的命名空间和变量。但它与现在的模版技术有一个主要区别：它最终是编译为 Servlet 来运行的。由于这一点，JSP 中还可以写 Java 代码，可以写复杂的逻辑处理，它的能力更强大。

在使用 Servlet 的时候，我们要在 web.xml 中配置请求 URL 和 Servlet 的映射关系。有些开发人员为了省去这些繁琐的配置，就把所有的逻辑都写入了 JSP，完全抛弃了 Servlet，这个时候 JSP 已经不只是一个视图模版了。前面我们使用单一 Servlet 带来的困扰，在 JSP 中又重现了，唯一改善的只是配置变得比以前容易了。
<!-- more -->
这个时候 SUN 公司祭出了 JavaBean，把业务逻辑剥离到其中，完成了初步的关注点分离，这个时候我们称为 JSP Model 1：

![Screen Shot 2016-07-06 at 9.36.40 AM.png](http://cdn.yyqian.com/201607060936-Fs7QfdEyF_B75nyUBu2n4wymhDUe?imageView2/2/w/800/h/600)

但这个时候，我们现在所谓的控制器部分，还混杂在 JSP 中。于是，我们又让尘封已久的 Servlet 重现光辉，让它担任控制器角色，进行了进一步的关注点分离，这个时候我们称之为 JSP Model 2：

![Screen Shot 2016-07-06 at 9.40.06 AM.png](http://cdn.yyqian.com/201607060940-Ft68LqBDwod3FN3JcDjIUbOTBPVF?imageView2/2/w/800/h/600)

这个模型其实就是我们现在 MVC 的鼻祖。对于这一个模型，它的问题在于 Servlet 作为控制器常常会遇到 web.xml 文件膨胀或者硬编码带来的维护和重复利用的问题。所以我们在这个基础上，需要一套更容易复用的基础设施。

这时候就迎来了两种类型的 Web 开发框架：

1. 请求驱动的 Web 框架（request-driven framework），基于 request/response 处理模型构建，Struts，Spring MVC 都属于这一种。
2. 事件驱动的 Web 框架（event-driven framework），Netty 框架应该可以算是一个例子。

对于请求驱动的 Web 开发框架，它们在 JSP Model 2 的基础上，进一步改进了控制器，把它变成了两级。原来单一 Servlet 作为 Front Controller，接收到请求之后根据映射规则，再转发给后面的 sub-controller，关系如下：

![Screen Shot 2016-07-06 at 9.54.33 AM.png](http://cdn.yyqian.com/201607060954-FnJiC3hMZHrQKWIqZXxoFBNqIYyC?imageView2/2/w/800/h/600)

我们从后面的分析中可以看到，其实现在我们直接开发的都是这些 sub-controller，这个单一的 Front Controller 在 Spring MVC 中的名字叫 DispatcherServlet。接下我们就踏入 Spring MVC 时代。

## Spring MVC 概览

前面我们引入 Front Controller 和 Page Controller 的目的是分离流程控制逻辑和具体的 Web 请求处理逻辑。在 Spring MVC 中，DispatcherServlet 就是这个 Front Controller，关系如下：

![Screen Shot 2016-07-06 at 10.42.19 AM.png](http://cdn.yyqian.com/201607061042-FjeBQV1tSZpG5mwuxJAwxgqmbs_h?imageView2/2/w/800/h/600)

DispatcherServlet 的作用可以从它的名字「Dispatcher」看出来，就是任务的分发，它自己本身不处理实际的业务。它主要与以下对象打交道：

**HandlerMapping**

DispatcherServlet 在接收到一个 Request，它要知道这个 Request 应该交给谁去处理，这个时候，它就先去问 HandlerMapping，然后再把这个 Request 转交给负责处理该请求的 Controller。所以 HandlerMapping 在这里是 Request 与 Controller 之间的映射关系。

后面我们会看到的 @RequestMapping 中的内容，实际就是在为 HandlerMapping 提供信息。

**Controller**

这个就是 DispatcherServlet 的次级控制器，它实现了对应于某个具体的 Request 的处理逻辑。在处理完毕之后，它可以返回一个 ModelAndView 实例，这个对象包含两部分信息：

- 视图的名称或对象实例：它决定了用哪个视图模版
- 模型数据：视图模版 + 模型数据，经过视图渲染就得到最终的输出

**ViewResolver 和 View**

由于现在视图技术有很多种：JSP, Velocity, Thymeleaf 等。所以在这里我们需要封装一下，就像我们封装各种数据访问技术一样。这里我们封装得到的两个对象是 ViewResolver 和 View。View 对应于一个视图模版，ViewResolver 可以看作是名字和 View 实例的一个映射，用来根据名字来查找对应的模版。

它们之间的交互大致如下：

![Screen Shot 2016-07-06 at 11.04.41 AM.png](http://cdn.yyqian.com/201607061104-Filt8DvCJYQbaviBMWglG1yEA3N-?imageView2/2/w/800/h/600)

## Spring MVC 中的主角

这里我们来详细介绍下 Spring MVC 中的几个主角，也就是前面提到的。

### HandlerMapping

这里我们称为 HandlerMapping 而不是 ControllerMapping 的原因是：Controller 是 Handler 的一种，还有其他类型的 handler。它的接口定义很简单，只有一个方法：

```
HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception;
```

它返回的实际是一个 HandlerExecutionChain，我们这里为了简化概念，说返回的是 Handler，但 handler 实际是包含在 HandlerExecutionChain 中的。

它有多个实现类：

- BeanNameUrlHandlerMapping
- SimpleUrlHandlerMapping
- ControllerClassNameHandlerMapping
- DefaultAnnotationHandlerMapping（Deprecated）

从名字我们大致也能猜到它的特定用处。对于不同的实现类，我们要针对这个类写它所能「理解」的映射规则。

我们也可以使用多个 HandlerMapping 的实例，让它们组成一个 chain，按照优先级处理，如果当前 HandlerMapping 不知道怎么映射当前的 Request，就交给下一个 HandlerMapping 去做。

### Controller

它是我们在 Spring MVC 中接触最多的角色，我们着手开发的一般都是 Controller 类；而 HandlerMapping 的实现是现成的，我们一般也不用选择用哪个实现类，默认都已经替你选好配置好了。

Controller 接口也只有一个方法：

```
ModelAndView handleRequest(HttpServletRequest request, HttpServletResponse response) throws Exception;
```

注意，我们自己开发的 Controller 类不会去继承 Controller 接口，我们的一般只是个注解了 @Controller 的 POJO，这个在后面会提到。

Contoller 类也有多个实现，它们的差别在于扩展了不同程度的规范操作，例如：数据绑定，数据验证，异常处理。由于我们最终采用的会是基于注解的 Controller，不会直接用到这些实现类，这里就不一一展开讲了。

### ModelAndView

ModelAndView 实例包含两部分内容：视图信息（可以是名称，也可以是 View 实例），模型数据。这一点从它的构造函数我们就可以看出：

```
public ModelAndView(String viewName)
public ModelAndView(String viewName, Map<String, ?> model)
public ModelAndView(String viewName, String modelName, Object modelObject)
public ModelAndView(View view)
public ModelAndView(View view, Map<String, ?> model)
public ModelAndView(View view, String modelName, Object modelObject)
```

构造完毕后，我们可以用 addObject 或者 addAllObject 方法来添加模型数据。

如果 ModelAndView 中的视图信息是 View 实例，那么 DispatcherServlet 就会直接从中获取 View 实例，然后调用 View 的 render 方法进行视图渲染；否则，DispatcherServlet 会先通过 ViewResolver 来根据 viewName 获得一个 View 实例，然后再 render。

实际中，我们一般都使用 viewName，因为直接返回 View 实例会导致一定的耦合。

在 ModelAndView 内部，有个 ModelMap field，用来保存我们添加进来的模型数据（它是个 LinkedHashMap<String, Object>）这个对象将在视图渲染阶段，被 View 实例来获取和使用。

### ViewResolver

ViewResolver 接口也很简单，只有一个方法：

```
View resolveViewName(String viewName, Locale locale) throws Exception;
```

参数 viewName 我们已经明白了，Locale 参数的作用是支持国际化，我们可以根据 Locale 来选择合适语言的模版。

大部分的 ViewResolver 实现类，都继承自 AbstractCachingViewResolver，它关键是可以缓存 View 实例，这样就不用每次 DispatcherServlet 调用就创建新的实例，一般默认缓存是启用的。在开发环境中我们也可以考虑把它关掉来即刻反映修改结果。这些实现类又大致可以分为两类：面向单一视图和面向多视图。

- 我们在用 JSP，Velocity，FreeMaker 的时候，都用的是单一视图的实现类，我们只要注册一个对应的实现类的 Bean 就可以了。
- 面向多视图的 ViewResolver 实现类可以根据你的规则，把某些名称映射到 JSP 的 View 实现类，把另外一些名称映射到 Velocity 的 View 实现类。

跟 HandlerMapping 类似，DispatcherServlet 也可以接受多个 ViewResolver，形成一个 Chain Of ViewResolver，我们要注意的是安排它们之间的优先级关系。

### View

View 接口有两个方法：

```
String getContentType();
void render(Map<String, ?> model, HttpServletRequest request, HttpServletResponse response) throws Exception;
```

View 实现类的主要职责就是用 render 方法完成视图渲染工作。整个渲染过程大致如下：

![Screen Shot 2016-07-06 at 2.04.56 PM.png](http://cdn.yyqian.com/201607061405-Fi1oJ41ILAPXtYvz3yn8DA4SkEoO?imageView2/2/w/800/h/600)

以 Velocity 的实现类 VelocityView 为例，它内部有个 field：VelocityEngine 模版引擎。render 方法先把 ModelMap 中的模型数据 copy 到一个 VelocityContext 中，然后再用 VelocityEngine 把 .vm 模版和 VelocityContext 揉合在一起就得到输出结果了。

如果我们想输出 Excel，PDF 之类的，我们只要选取合适的 View 实现类就可以了。

## Spring MVC 中的配角

Spring MVC 中除了前面讨论的的几个主角，还有一些配角，例如：

1. MultipartResolver：用来处理文件上传的请求
2. HandlerInterceptor：对处理流程进行拦截
3. HandlerAdaptor：让我们使用除了 Controller 之外的 Handler
4. HandlerExceptionResolver：在处理 Web 请求过程中，如果 Handler 抛出异常该如何处理
5. LocaleResolver, ThemeResolver：如果我们想根据用户的地理信息显示不同的视图，或者用户可以选择不同的主题，我们就需要这两个。

接下来，我们会稍微讨论下 HandlerInterceptor，HandlerAdaptor，HandlerExceptionResolver。

*未完待续*

## 基于注解的 Controller

前面我们讨论的传统的 Handler 类型，例如 Controller，在使用的时候我们都要继承某个基类或实现接口。但使用基于注解的 Controller 的话，我们只要定义一个普通的 POJO 就可以了，再在这个 POJO 上注解一些相关的元数据信息，我们的 @Controller，@RequestMapping 所包含的就是这些元数据信息。

接下来，我们就只要让 MVC 框架发现这些可用的类就可以了，我们可以通过在 WebApplicationContext 中添加如下配置：

```
<context:component-scan base-package="xx.xxx.xx.xx" />
```

这样 MVC 框架就会去搜索、获取并调用这些基于注解的 Controller。

*未完待续*

---

参考资料：《Spring 揭秘》