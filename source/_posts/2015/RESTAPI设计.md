---
title: REST API 设计
date: 2015-05-25 14:26:29
permalink: 1432535189699
tags: REST
---

## RESTful API设计思想

1. URL里只包含名词，用来指向资源
2. 用HTTP请求(GET/POST/PUT/PATCH/DELETE)来描述CRUD动作

## 标准的RESTful API

以下为几种常见的RESTful API：

* `GET /post` 获取所有的posts
* `GET /post/:pid` 获取特定的post
* `POST /post` 新建post
* `PUT /post/:pid` 修改post
* `PATCH /post/:pid` 部分修改post
* `DELETE /post/:pid` 删除post
<!-- more -->
## 名词单复数问题

`post`还是`posts`，其实都是可以的。有的文章建议复数，原因是有的工具会自动将单数转换为复数。我这里偏向于单数，原因是现在项目中使用的Sails框架中默认用的是单数。

## 资源之间的依赖关系

譬如说任何一个post都是所属于某一个group的，那么这个API可以设计为：`/group/:gid/post`。

## 如果某个action不能用CRUD来准确描述

这里有几个方案：

1. 把这个action当作是一种sub－resource来处理，譬如在GitHub's API中，star a gist with `PUT /gists/:id/star` and unstar with `DELETE /gists/:id/star`.

2. 把这个action当做是一种resource来处理，但是这种action不能附带参数。譬如active可以用actived来处理。

## 返回资源

默认的返回资源可以尽可能的全面，可以通过以下参数进行进一步处理：

* Filtering: `GET /post?hidden=true`
* Sorting: `GET /post?sort=createdAt`
* Searching: `GET /post?hidden=true&sort=createdAt`，结合上面两者
* Alias: `GET /post/recently_hidden`，效果同上
* Fields: `GET /post?fields=id,title,createdAt&hidden=true&sort=createdAt`，效果同上，但限制返回的字段
* Embed: `GET /post/12?embed=user.name,group.name`，展开链接的user和group

## 错误信息

错误信息需要设计固定格式，这个是 Spring Boot 默认返回的错误信息：

```
{
   "timestamp" : 1413313361387,
   "exception" : "org.springframework.web.bind.MissingServletRequestParameterException",
   "status" : 400,
   "error" : "Bad Request",
   "path" : "/greet",
   "message" : "Required String parameter 'name' is not present"
}
```
