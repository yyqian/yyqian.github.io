---
title: Elasticsearch API 笔记
tags:
---

## API

- 创建新的 index：`curl -XPUT localhost:9200/index-name`
- 获取 shards 信息：`curl 'localhost:9200/_cat/shards?v'`

## Mapping

```
# 获取某个 type 的 mapping
curl -XGET 'localhost:9200/index-name/_mapping/type-name?pretty'

# 新建某个 type 的 mapping，如果这个 type 已存在，会合并之前的 mapping。但是不能修改已存在的某个 field 的数据类型。
curl -XPUT 'localhost:9200/index-name/_mapping/type-name' -d '{
  "new-events" : {
    "properties" : {
      "host": {
        "type" : "string"
      }
    }
  }
}'
```

## Index

```
# index with id
curl -XPUT 'localhost:9200/index-name/type-name/doc-id/?pretty' -d '{
  "name": "Elasticsearch Denver",
  "organizer": "Lee"
}'
```

## Update

document 是 immutable，每次更新实际是四步操作：

- Retrieve the JSON from the old document
- Change it
- Delete the old document
- Index a new document

部分更新：

The simplest form of the update request accepts a partial document as the doc parameter, which just gets merged with the existing document. Objects are merged together, existing scalar fields are overwritten, and new fields are added.

```
curl -XPOST 'localhost:9200/index-name/type-name/doc-id/_update' -d '{
  "doc": {
    "your-key": "your-value"
  }
}'

# 用 retry_on_conflict 来控制并发
curl -XPOST 'localhost:9200/index-name/type-name/doc-id/_update?retry_on_conflict=3' -d '{
  "script": "ctx._source.price = 2"
}'

# 用 version 来控制并发
curl -XPUT 'localhost:9200/index-name/type-name/doc-id?version=3' -d '{
  "caption": "I Know about Elasticsearch Versioning",
  "price": 5
}'
```

## Delete

```
# 删除指定 id 的 document，这里可以指定 version
curl -XDELETE 'localhost:9200/index-name/type-name/doc-id'

# 删除整个 type 的 documents
curl -XDELETE 'localhost:9200/index-name/type-name

# 删除整个 index
curl -XDELETE 'localhost:9200/index-name'

# close index
curl -XPOST 'localhost:9200/index-name/_close'

# open index
curl -XPOST 'localhost:9200/index-name/_open'
```

## Search

Search request 有以下基础的组成部分：`query`, `from`, `size`, `_source`, `sort`，以下是使用示例：

```
curl 'localhost:9200/index-name/type-name/_search' -d '{
  "query": {
    "match_all": {}
  },
  "from": 10,
  "size": 10,
  "_source": ["field1", "field2"],
  "sort": [
    {"created_on": "asc"},
    {"name": "desc"},
    "_score"
  ]
}'

# _source 也可以是这种形式
curl 'localhost:9200/index-name/_search' -d '{
  "query": {
    "match_all": {}
  },
  "_source": {
    "include": ["location.*", "date"],
    "exclude": ["location.geolocation"]
  }
}'
```

搜索结果解释：

![Screen Shot 2016-05-18 at 2.24.07 PM.png](http://cdn.yyqian.com/201605181424-FgLAoNQpSySZqv84G2r2jspc7Tyx?imageView2/2/w/800/h/600)

## Query and Filter DSL

下面将介绍几种形式的 query：match_all, match, term, filtered

filter 和 query 的区别是：filter 可以挑选出符合规则的 documents，但不计算 score；而 query 则在挑选出符合规则的 documents 之后，就计算 score，然后再返回 documents。

```
# match
curl 'localhost:9200/get-together/event/_search?pretty' -d '{
  "query": {
    "match": {
      "title": "hadoop"
    }
  }
}'

# term
curl 'localhost:9200/get-together/event/_search?pretty' -d '{
  "query": {
    "term": {
      "title": "hadoop"
    }
  }
}'

# filtered，先用 filter "host": "andy"，然后再用 query "title": "hadoop"
curl 'localhost:9200/get-together/_search' –d '
{
  "query": {
    "filtered": {
      "query": {
        "match": {
          "title": "hadoop"
        }
      },
      "filter": {
        "term": {
          "host": "andy"
        }
      }
    }
  }
}'
```

## 分析

```
curl -XPOST 'localhost:9200/_analyze?analyzer=standard' -d '
share your experience with NoSql & big data technologies'
```

---

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

## Searching—The Basic Tools

### 查询结果

- `hits`：包含结果的数量 `total`，以及结果 hits 数组
- `took`：查询所耗的毫秒数
- `_shards`：参与查询的 shards 数目
- `timeout`：判断查询是否超时

### 查询多个 index 和 type：

```
/_search
    Search all types in all indices
/gb/_search
    Search all types in the gb index
/gb,us/_search
    Search all types in the gb and us indices
/g*,u*/_search
    Search all types in any indices beginning with g or beginning with u
/gb/user/_search
    Search type user in the gb index
/gb,us/user,tweet/_search
    Search types user and tweet in the gb and us indices
/_all/user,tweet/_search
    Search types user and tweet in all indices
```

### Pagination

- size: 返回结果的数目
- from：跳过的数目

```
GET /_search?size=5&from=10
```

尽量避免 Deep Paging，正常不要查询超过 1000 条的数目。

### Search Lite

search API 有两个版本：

- query-string version：生产环境不建议用这个版本。查询的时候可以只写 value，不写 key，ES 会把所有的字段连接起来成为 `_all` 字段，然后用这个字段来查询。
- request body version

## Mapping and Analysis

### Exact Values Versus Full Text

ES 中的 Data 可以分为两类：

- Exact values：这种查询很简单，类似数据库中的查询，结果要么是匹配，要么是不匹配。例如：Foo 不等同于 foo，2014 不匹配 2014-09-15
- Full text

Full text 不一定是非结构化的数据，自然语言是结构化的，只是规则非常复杂。查询 Full text 比较繁琐，我们的问题不是数据是否匹配，而是数据匹配的程度如何，它们的相关程度如何。

并且，我们还要满足以下一些情形：

- A search for UK should also return documents mentioning the United Kingdom.
- A search for jump should also match jumped, jumps, jumping, and perhaps even leap.
- johnny walker should match Johnnie Walker, and johnnie depp should match Johnny Depp.
- fox news hunting should return stories about hunting on Fox News, while fox hunting news should return news stories about fox hunting.

### Analysis and Analyzers

Analysis 包含两个步骤：

- tokenizing
- normalizing

完成这两步分析的构件是 analyzer，analyzer 由几个功能模块组成：

- Character filters：过滤掉一些无关的字符
- Tokenizer：例如按照标点符号来划分单词
- Token filters：修改、去除、增加 token，例如：lowercasing，去除 a the and 等，将 leap 转换为 jump

Built-in Analyzers:

- Standard analyzer
- Simple analyzer
- Whitespace analyzer
- Language analyzers

当我们 index 一个 document 的时候，会使用 analyzer 将 full-text fields 转换为 tokens；当我们查询的时候，也要用相同的 analyzer，将查询语句转换成同样的 tokens。


### Search

其中 query_string, term 和 filtered 是 query type，再深一层的是参数

```
curl localhost:9200/index-name/type-name/_search?pretty -d '{
  "query": {
    "query_string": {
      "query": "elasticsearch san francisco",
      "default_field": "name",
      "default_operator": "AND"
    }
  }
}'

curl localhost:9200/index-name/type-name/_search?pretty -d '{
  "query": {
    "term": {
      "name": "elasticsearch"
    }
  }
}'

curl localhost:9200/index-name/type-name/_search?pretty -d '{
  "query": {
    "filtered": {
      "filter": {
        "term": {
          "name": "elasticsearch"
        }
      }
    }
  }
}'
```
