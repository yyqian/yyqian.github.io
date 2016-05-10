---
title: Elasticsearch: The Definitive Guide 笔记
tags:
---

## Data In, Data Out

### Update

document 是 immutable，每次更新实际是四步操作：

- Retrieve the JSON from the old document
- Change it
- Delete the old document
- Index a new document

部分更新：

The simplest form of the update request accepts a partial document as the doc parameter, which just gets merged with the existing document. Objects are merged together, existing scalar fields are overwritten, and new fields are added.

```
POST /website/blog/1/_update
{
   "doc" : {
      "tags" : [ "testing" ],
      "views": 0
   }
}
```

### 并发处理机制

处理并发通常有两种方式：

- 悲观的：使用锁，一般数据库中都使用这个。例如，锁定一行，确保只有一个线程能进行修改操作。
- 乐观的：Elasticsearch 中使用，这个是基于竞态并不是经常发生的条件。如果数据在读和写这两步中间被更改了，更新操作就失败了，然后取决于程序怎么处理这个失败，可以是用新的数据重新操作，或者把失败通知用户。

乐观机制的实现主要依靠 version，我们可以在修改或删除的时候附带 version 参数，指定修改某一个版本的数据。如果当前的 version 和我们请求的 version 不同，说明在这读写的期间数据被更改了，就会操作失败，返回错误。

```
PUT /website/blog/1?version=1
{
  "title": "My first blog entry",
  "text":  "Starting to get the hang of this..."
}
```

retry_on_conflict 参数可以用来使得在发生冲突时，进行重试

```
POST /website/pageviews/1/_update?retry_on_conflict=5
{
   "script" : "ctx._source.views+=1",
   "upsert": {
       "views": 0
   }
}
```

### 获取多个 Document

如果一下子要获取多个 Document，可以用一句 API 解决：

```
GET /_mget
{
   "docs" : [
      {
         "_index" : "website",
         "_type" :  "blog",
         "_id" :    2
      },
      {
         "_index" : "website",
         "_type" :  "pageviews",
         "_id" :    1,
         "_source": "views"
      }
   ]
}
```

如果多个 Document 的 `_index` 和 `_type` 相同，可以用以下形式来获取：

```
GET /website/blog/_mget
{
   "docs" : [
      { "_id" : 2 },
      { "_type" : "pageviews", "_id" :   1 }
   ]
}
```

```
GET /website/blog/_mget
{
   "ids" : [ "2", "1" ]
}
```

即使 mget API 返回的数据一个都没找到，也是 200 状态码，因为 mget 操作本身是成功的。

### Bulk 操作

mget 用来获取多个 Doc，而 bulk 可以进行多个修改操作，类似 MySQL 的过程，格式是：

```
{ action: { metadata }}\n
{ request body        }\n
{ action: { metadata }}\n
{ request body        }\n
```

其中 request body 是 JSON 数据，但必须是 one-line JSON，否则解析会出错

action 可以是：

- create: Create a document only if the document does not already exist
- index: Create a new document or replace an existing document
- update: Do a partial update on a document
- delete: Delete a document，这个操作没有 request body

例如：

```
POST /_bulk
{ "delete": { "_index": "website", "_type": "blog", "_id": "123" }}
{ "create":  { "_index": "website", "_type": "blog", "_id": "123" }}
{ "title":    "My first blog post" }
{ "index": { "_index": "website", "_type": "blog" }}
{ "title":    "My second blog post" }
{ "update": { "_index": "website", "_type": "blog", "_id": "123", "_retry_on_conflict" : 3} }
{ "doc" : {"title" : "My updated blog post"} }
```

要注意的是，bulk 操作不是原子的，不能用作事务。

跟 mget 相同，如果多个 Document 的 `_index` 和 `_type` 相同，可以用以下形式来获取：

```
POST /website/_bulk
{ "index": { "_type": "log" }}
{ "event": "User logged in" }
```

```
POST /website/log/_bulk
{ "index": {}}
{ "event": "User logged in" }
{ "index": { "_type": "blog" }}
{ "title": "Overriding the default type" }
```

A good place to start is with batches of 1,000 to 5,000 documents or, if your documents are very large, with even smaller batches. A good bulk size to start playing with is around 5-15MB in size.

## Distributed Document Store

shard # 用以下公式计算，其中 routing 一般是 document 的 id。

```
shard = hash(routing) % number_of_primary_shards
```

primary_shards 的数量一般是不可更改的。所有的 API 都接受 routing 参数，用来控制 document-to-shard mapping，这样就能使得相关的数据在同一个 shard 中。

### Creating, Indexing, and Deleting a Document

create, index, and delete

![Screen Shot 2016-05-10 at 1.55.25 PM.png](http://cdn.yyqian.com/201605101356-FmwudfY99Z293y-IaLIaGH8MxN_2?imageView2/2/w/800/h/600)

### Retrieving a Document

![Screen Shot 2016-05-10 at 1.58.06 PM.png](http://cdn.yyqian.com/201605101358-FkGV_AvkH7QsfwtV_joO_Ezmfl7_?imageView2/2/w/800/h/600)

### Partial Updates to a Document

update

![Screen Shot 2016-05-10 at 2.00.38 PM.png](http://cdn.yyqian.com/201605101401-FhKYDhqMQyVWrfYbhghyPRjfpryY?imageView2/2/w/800/h/600)

### Multidocument

mget and bulk

![Screen Shot 2016-05-10 at 2.05.11 PM.png](http://cdn.yyqian.com/201605101405-FrS_ElQ0GJ0-hOqDxxRj5lNzmS2q?imageView2/2/w/800/h/600)

![Screen Shot 2016-05-10 at 2.05.40 PM.png](http://cdn.yyqian.com/201605101405-FgGQatAPHpdwNlsW5naP8y5L_I2U?imageView2/2/w/800/h/600)

## Searching—The Basic Tools
