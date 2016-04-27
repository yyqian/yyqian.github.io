---
title: Spring 技术内幕
---
对象之间的相互依赖关系由 IoC 容器进行统一管理，这样就不需要考虑复杂的对象依赖关系

OOP 系统中的对象分类大致有几种：

- 数据对象
- 用来处理数据的对象，这种一般能以单件形式存在，一般不涉及数据和状态共享
- 如果涉及数据共享，需要在单件的基础上做进一步处理

Spring IoC 提供的是 JavaBean 容器

注入的实现上有：

- 接口注入
- setter 注入
- 构造器注入

Spring IoC 容器有两种：

- 实现 BeanFactory 接口的简单容器
- ApplicationContext 应用上下文

不管什么 IoC 容器，都需要实现 BeanFactory 接口

