---
title: Thymeleaf
---
## 模版中调用参数的方法：

(1) 使用 Model

```
@RequestMapping(value = "message", method = RequestMethod.GET)
public String messages(Model model) {
    model.addAttribute("messages", messageRepository.findAll());
    return "message/list";
}
```

```
<tr th:each="message : ${messages}">
    <td th:text="${message.id}">1</td>
    <td><a href="#" th:text="${message.title}">Title ...</a></td>
    <td th:text="${message.text}">Text ...</td>
</tr>
```

(2) 用 URL 中的查询参数


```
@Controller
public class SomeController {
    @RequestMapping("/")
    public String redirect() {
        return "redirect:/query?q=Thymeleaf Is Great!";
    }
}
```

```
<span th:text="${param.q[0]}" th:unless="${param.q == null}">Test</span>
```

Parameters are always string arrays, as they can be multivalued

(3) Session 中的参数

```
@RequestMapping({"/"})
String index(HttpSession session) {
    session.setAttribute("mySessionAttribute", "someValue");
    return "index";
}
```

```
	<span th:text="${session.mySessionAttribute}">[...]</span>
```

(4) ServletContext 中的参数

ServletContext 中的参数是 request 和 session 共享的

```
    <table>
        <tr>
            <td>My context attribute</td>
            <!-- Retrieves the ServletContext attribute 'myContextAttribute' -->
            <td th:text="${application.myContextAttribute}">42</td>
        </tr>
        <tr>
            <td>Number of attributes</td>
            <!-- Returns the number of attributes -->
            <td th:text="${application.size()}">42</td>
        </tr>
        <tr th:each="attr : ${application.keySet()}">
            <td th:text="${attr}">javax.servlet.context.tempdir</td>
            <td th:text="${application.get(attr)}">/tmp</td>
        </tr>
    </table>
```

(5) Spring Beans

通过 @beanName 来获取

```
    <div th:text="${@urlService.getApplicationUrl()}">...</div>
```

```
@Configuration
public class MyConfiguration {
    @Bean(name = "urlService")
    public UrlService urlService() {
        return new FixedUrlService("somedomain.com/myapp); // some implementation
    }
}

public interface UrlService {
    String getApplicationUrl();
}
```

(6) Spring Security 相关的

参考：https://github.com/thymeleaf/thymeleaf-extras-springsecurity

```
    <div sec:authorize="hasRole('ROLE_ADMIN')">
      This content is only shown to administrators.
    </div>
    <div sec:authorize="hasRole('ROLE_USER')">
      This content is only shown to users.
    </div>
```

```
Logged user: <span sec:authentication="name">Bob</span>
Roles: <span sec:authentication="principal.authorities">[ROLE_USER, ROLE_ADMIN]</span>
```