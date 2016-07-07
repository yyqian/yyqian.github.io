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

接下来，我们会稍微讨论下 HandlerAdaptor，HandlerInterceptor，HandlerExceptionResolver。

### Handler 与 HandlerAdaptor

Spring MVC 中任何可用于 Web 请求处理的对象统称为 Handler。Controller 是 handler 的一种特殊类型。Struts 的 Action 也是一种 Handler。

DispatcherServlet 为了能够调用各种各样的 Handler，就用了 HandlerAdaptor 这一接口。

这个接口主要的方法是 supports 和 handle。DispatcherServlet 先从 HandlerMapping 那获取合适的 Handler，然后用 HandlerAdaptor 的 support 方法询问是否支持该 Handler 的调用，如果支持，则调用 handle 方法，这个方法将返回 ModelAndView。

除了 Controller，Spring MVC 中还有一种 Handler：ThrowawayController。它不依赖于任何 Servlet API，并且可以定义状态。由于它拥有状态，就不能作为 Singleton 类型的 Bean 了，每次 Web 请求都要构造一个新的实例，所以要把该 Bean 的 scope 设定为 prototype。

如果我们要自定义一个 Handler，除了写一个注解了 @Handler 的 POJO 类之外，还要构造一个能识别该 Handler 的 HandlerMapping，还需要实现一个 HandlerAdaptor 以便能让 DispatcherServlet 调用。

HandlerAdaptor 的实现很简单，supports 方法用 instanceof 去判断，handle 方法只要把 Handler 对象强制转换为自定义的 Handler 实现类，让后调用相应的方法就可以了。

### HandlerInterceptor

前面我们提到过 HandlerMapping 返回的是一个 HandlerExecutionChain 对象，这个对象封装了两类数据：

1. Handler：用于处理 Web 请求
2. HandlerInterceptor：可以在 Handler 前后对处理流程进行拦截

```
public interface HandlerInterceptor {
    boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception;
    
    void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception;

    void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception;
}
```

从这几个方法可以看出，HandlerInterceptor 可以在指定的 handler 执行前、后、完成之后进行拦截并进行逻辑处理。

它有若干个实现类：

```
org.springframework.web.servlet.handler.UserRoleAuthorizationInterceptor
org.springframework.web.servlet.mvc.WebContentInterceptor
org.springframework.web.servlet.i18n.LocaleChangeInterceptor
org.springframework.web.servlet.theme.ThemeChangeInterceptor
```

UserRoleAuthorizationInterceptor 用于实现验证相关的功能，类似于 Spring Security 框架的功能。

WebContentInterceptor 可以检查请求方法是否在支持范围内、是否有必要的 Session 实例、缓存时间的设置等。

如果我们要自定义一个 HandlerInterceptor，我们可以继承 HandlerInterceptorAdapter，override 其中的 preHandle 或者其他方法。

注：Spring 中很多接口都有一个 XXXXAdapter 实现类，它与 Adapter Pattern 不同，目的是为了减少我们实现某个接口的工作量。

在定义完之后，我们需要配置一个 bean，把它加入到 WebApplicationContext 中。

到这里，我们自定义的 HandlerInterceptor 还不能发挥作用，我们还需要在注册 HandlerMapping 实现类的 bean 的时候，调用它的 setInterceptors 方法，把我们的 HandlerInterceptor 添加到其中。这样才算完成了 HandlerInterceptor 的所有配置。

前面说过 HandlerMapping 可以有多个，因此我们可以给各个 HandlerMapping 注入不同的 HandlerInterceptor，这样就可以灵活地根据特定的请求给予不同的拦截了。

**Servlet Filter**

Web 请求的拦截功能，Servlet 标准组件：Filter 也可以提供，因为 Spring MVC 基于 Servlet API 构建，所以在 Spring MVC 中还可以用 Filter 来进行拦截，但它与 HandlerInterceptor 拦截的位置不同，如下图所示：

![Screen Shot 2016-07-07 at 3.30.30 PM.png](http://cdn.yyqian.com/201607071530-FjXIiOvT95plVto59sB3QGv8GyO8?imageView2/2/w/800/h/600)

Filter 的拦截在 DispatcherServlet 外部，而 HandlerInterceptor 在内部。Filter 可以提供全局的、粗粒度的拦截，优先级更高。而 HandlerInterceptor 在配合 HandlerMapping  的 Chaining 特性之后，可以提供细粒度的拦截。因此我们可以根据拦截的覆盖面、粒度来决定使用哪一个进行拦截。

Filter 是 Servlet 标准组件，需要在 web.xml 中配置，它的生命周期由 Web 容器进行管理（而不是 Spring MVC 的 WebApplicationContext），如果我们想让 Spring MVC 能接纳它，可以使用 DelegatingFilterProxy，让 DelegatingFilterProxy 成为 Servlet Filter 注入到 Web 容器中，然后把实际的工作转交给提供了实际拦截逻辑的类，再把这个类注册成一个 Bean。

两者关系如下：

![Screen Shot 2016-07-07 at 3.48.47 PM.png](http://cdn.yyqian.com/201607071549-FnPP7v4Em-xiYjnk2fbPypYXwibV?imageView2/2/w/800/h/600)

### HandlerExceptionResolver

我们从 Controller 接口的方法可以看到，它会抛出 checked exception，并且是 Exception，这在 *Effective Java* 一书中不提倡的。之所以 Spring 框架可以这样做，一是因为确实很难预料 Controller 会抛出哪些异常，二是因为 Spring 有一个框架内统一的异常处理方式。

```
public interface Controller {
    ModelAndView handleRequest(HttpServletRequest request, HttpServletResponse response) throws Exception;
}
```

Handler 和 HandlerExceptionResolver 就像双子座两兄弟，一旦 Handler 执行期间抛出异常，HandlerExceptionResolver 就会接手异常情况的处理，它的接口定义如下。我们可以看到它也会返回 ModelAndView，只不过这里是跳转的错误信息页面和相关异常信息。返回 ModelAndView 之后还是由 DispatcherServlet 寻求 ViewResolver 和 View 进行处理。

```
public interface HandlerExceptionResolver {
    ModelAndView resolveException(
            HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex);
}
```

HandlerExceptionResolver 对异常的处理范围仅限于 Handler 查找以及 Handler 执行期间。

框架中该接口只有一个实现：SimpleMappingExceptionResolver，它可以将异常类名映射到特定的错误信息视图，这样不同的异常有各自的错误页面。

## 基于注解的 Controller

前面我们讨论的传统的 Handler 类型，例如 Controller，在使用的时候我们都要继承某个基类或实现接口。但使用基于注解的 Controller 的话，我们只要定义一个普通的 POJO 就可以了，再在这个 POJO 上注解一些相关的元数据信息，我们的 @Controller，@RequestMapping 所包含的就是这些元数据信息。

接下来，我们就只要让 MVC 框架发现这些可用的类就可以了，我们可以通过在 WebApplicationContext 中添加如下配置：

```
<context:component-scan base-package="xx.xxx.xx.xx" />
```

这样 MVC 框架就会去搜索、获取并调用这些基于注解的 Controller。

我们的 Controller 只是一个普通的 POJO，不依赖于任何 Servlet API，也不需要做任何 XML 配置，如果没有 Spring MVC 框架在幕后的支持，这个孤零零的 POJO 也发挥不了什么作用。

### 原型分析

对于 Spring MVC 来说，基于注解的 Controller 和其他实现了 Controller 接口的类没有区别，两者实际上都是在自定义一个 Handler。对于基于注解的 Controller，我们同样需要思考几点：

1. 如何让 DispatcherServlet 知道当前 Web 请求应该由哪个基于注解的 Controller 处理
2. 如何让 MVC 框架知道要调用该 POJO 的哪个方法

这两点我们前面就已经讨论过了：

1. 我们要为基于注解的 Controller 提供相应的 HandlerMapping 处理映射关系
2. 为基于注解的 Controller 提供相应的 HandlerAdapter 来执行处理逻辑

所以我们关注点在 HandlerMapping 和 HandlerAdapter 上面。

**用于「基于注解的 Controller」的 HandlerMapping**

我们的 POJO 中的 @RequestMapping 要通过 Java 的反射机制来读取内容，之前的 HandlerMapping 实现类都没有提供该功能。所以我们要为「基于注解的 Controller」提供特定的 HandlerMapping 实现。

原理上来说，我们只要遍历所有「基于注解的 Controller」，通过反射机制读取它们其中的 @RequestMapping 的内容，然后进行路径信息的匹配，就可以得到一个基于注解的 HandlerMapping。

Spring 框架有现成的实现类：DefaultAnnotationHandlerMapping（Deprecated），RequestMappingHandlerMapping。它会先扫描应用程序的 Classpath，寻找所有标注了 @Controller 的类，这个工作是由 `<context:component-scan/>` 来完成的，所以我们必须要标注 @Controller，否则该类不会被发现。

这些 Bean 一般默认就都启用了，所以不需要在 WebApplicationContext 中注册它们。

**用于「基于注解的 Controller」的 HandlerAdapter**

有了用于「基于注解的 Controller」的 HandlerMapping，我们的工作就完成一半了，另一半就是 用于「基于注解的 Controller」的 HandlerAdapter，也就是针对「基于注解的 Controller」自定义一个 HandlerAdapter。

回顾下我们如何构用于 Contoller 类的 HandlerAdapter：我们只要在 HandlerAdapter 中调用 Controller 接口的 handleRequest 方法就行了。但我们的 POJO 没有实现任何接口，没有这种「契约」关系。并且我们的 POJO 一个类中有若干个方法，可以映射多个 Web 请求。所以在这里不能通过这种方式。

这里我们的实现思路和前面 HandlerMapping 的类似，也是用反射查找 @RequestMapping，然后通过反射去调用。实际的工作还要考虑很多细节，我们这里只要理解原理就可以了。实际情况下我们只要用官方的 AnnotationMethodHandlerAdapter（Deprecated），RequestMappingHandlerAdapter 就可以了。

这种基础的 Bean 我们一般也不用在 WebApplicationContext 中注册它们，在框架启动的时候就默认注册了。

### 详细使用

简单地说，要声明一个「基于注解的 Controller」，我们只需要三样必要的东西：

1. POJO
2. @Controller 注解
3. @RequestMapping 注解

POJO 中的是处理逻辑，这个不用多说。@Controller 注解是为了能被 IoC 容器自动查找并注册，进而能构建一个 HandlerMapping。@RequestMapping 注解是为了让框架知道针对某个 Web 请求，应该调用哪个方法，也就是为了构建 HandlerAdapter。

被 @RequestMapping 注解的方法，可以有多种方法参数：

1. HttpServletRequest, HttpServletResonse, HttpSession
2. WebRequest，与上面的类似
3. Locale
4. InputStream/OutputStream, Reader/Write，相当于调用相关的 HttpServletResonse.getXXX() 方法
5. Map 或 ModelMap，这个就是模型数据，你可以在这对模型数据为所欲为。
6. Errors 或 BindingResult，这个用于数据验证返回的结果
7. SessionStatus

@RequestMapping 注解的方法，返回值有可以有多种：

1. ModelAndView
2. String，这个是视图名称
3. ModelMap，这个只返回模型数据，没有视图，框架将按默认规则来提取逻辑视图
4. void，视图和模型数据都由框架的默认值来处理

**参数绑定**

如果我们的 @RequestMapping 注解的方法的方法参数在前面列表中，框架可以为这些特殊类型提供相应对象的引用。如果参数类型在这列表之外，我们要让 MVC 以某种规则将请求参数与方法参数绑定。

在这里我们可以用 @RequestParam，@ModelAttribute, @SessionAttribute，@PathVariable 等。这些注解的详细使用，以及参数验证等功能请参考 Spring Framework Reference Documentation，这里就不详解了。

---

参考资料：《Spring 揭秘》