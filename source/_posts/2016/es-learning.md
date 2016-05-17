---
title: Elasticsearch 学习笔记
date: 2016-05-17 12:59:16
permalink: 1463461156000
tags: Elasticsearch
---

本文将分析 Elasticsearch 中的一些关键概念

## 倒排索引

倒排索引是搜索引擎中核心的数据结构。以下的列表左侧是数据库中存储的数据结构，右侧是搜索引擎中的数据结构。

![Screen Shot 2016-05-17 at 1.11.52 PM.png](http://cdn.yyqian.com/201605171312-FitMXe_LTsHD0ikgm2toEVviCEbH?imageView2/2/w/800/h/600)

在数据库中，如果我们要搜索 tag 含有 peace 的 blog，就需要遍历整个表，以及比对 tag 列中的多个值，这种做法开销非常大。而如果数据格式是上图右侧所示，则非常迅速。因此，搜素引擎中采用的是后者，称为 Inverted index，它把 ID - Keywords 的索引方式进行了反转，变成 Keyword - IDs 的方式。

接下来，我们用一个实例来看下如何建立倒排索引:
<!-- more -->
首先，我们获取两个需要进行倒排索引的文档：

1. The quick brown fox jumped over the lazy dog
2. Quick brown foxes leap over lazy dogs in summer

然后，我们进行 tokenize，把内容分割成一个一个关键词（称为 token 或 term）：

1. The, quick, brown, fox, jumped, over, lazy, dog
2. Quick, brown, foxes, leap, over, lazy, dogs, in, summer

紧接着，我们需要进行 normalize token 的过程，例如：转换为小写，复数转换为单数，同义词转换等：

1. the, quick, brown, fox, jump, over, lazy, dog
2. quick, brown, fox, jump, over, lazy, dog, in, summer

最后，建立 Inverted index:

Term | IDs
--- | ---
brown   |   1, 2
dog     |   1, 2
fox     |   1, 2
in      |   2
jump    |   1, 2
lazy    |   1, 2
over    |   1, 2
quick   |   1, 2
summer  |   2
the     |   1, 2

这里，中文和英文的处理有较大差别：英文 tokenize 过程可以通过标点符号进行分割，而中文则复杂得多，中文的这一过程一般称为分词；并且，normalize token 的过程也有差别，例如中文就没有大小写，单复数，时态等概念。

除此之外，Inverted index 也适合计算相关度。当我们搜索单词 in 的时候，我们会发现几乎所有文档都有这个单词，这说明查询得到的结果跟我们期望的结果并不相关；但如果我们搜索 fox，可能数目就很少，这说明搜索的结果和我们期望的结果相关度较大。

采用 Inverted index 可以提高搜索的效率和相关度，但代价是需要更多的存储空间，以及写入时间变长（因为需要更新 Inverted index）

## 计算 Relevancy Score 的算法

在默认情况下，Elasticsearch 采用 TF-IDF (term frequency–inverse document frequency) 算法。从命名我们可以看出：

- Term frequency：某个 term 在一个文档中出现的次数越多，这个文档的分值就越高
- Inverse document frequency：如果包含有某个 term 的文档越少，这个 term 的权重就越高

除此之外，你有多个选择来对这个算法进行改动。例如：

- 增加某个 field 的权重，例如 blog 的 title 比 content 权重更高
- 严格匹配的分值比部分匹配的分值更高

## 使用场景

作为单独的数据源，完成数据存储和查询。要注意的是，Elasticsearch 是一种 NoSQL DB，不支持事务，但是支持并发控制（使用 version 实现，不使用锁）。它也可以被当作 NoSQL DB 来使用，但需要有所取舍。它提供了强大的搜索能力，但其他方面不一定比得上其他的 NoSQL DB。

![Screen Shot 2016-05-17 at 2.28.56 PM.png](http://cdn.yyqian.com/201605171429-FrwxpI-IuJQs-4h290-Zx_NxvAuj?imageView2/2/w/800/h/600)

和 SQL DB 配合使用。由于 ES 不支持事务和复杂的关系处理，所以一般需要和 SQL DB 配合使用。可以将 SQL DB 作为主数据库，然后通过工具将数据同步到 ES 中。

![Screen Shot 2016-05-17 at 2.39.48 PM.png](http://cdn.yyqian.com/201605171440-Flj9j1tUPCbcUBQky4XQAVie0QvC?imageView2/2/w/800/h/600)

使用 ELK 组合进行日志分析。Logstash 传输日志，ES 存储和分析，Kibana 进行数据可视化、以图表形式展现。

![Screen Shot 2016-05-17 at 2.46.24 PM.png](http://cdn.yyqian.com/201605171446-Fm6dAaZd_xL7DClreWYZkdZZuxCb?imageView2/2/w/800/h/600)

## Analysis

不管是 indexing 还是 searching，都要将输入的 text 进行 analyze，获得 normalized token。下图的 Indexed Data 中既包含了原始的数据，也包含了倒排索引之后的数据。

![Screen Shot 2016-05-17 at 3.00.01 PM.png](http://cdn.yyqian.com/201605171500-Fp9Z1XdInN7XzFGynLsdcULqVKE3?imageView2/2/w/800/h/600)

## 并发处理机制

处理并发通常有两种方式：

- 悲观的：使用锁，一般数据库中都使用这个。例如，锁定一行，确保只有一个线程能进行修改操作。
- 乐观的：Elasticsearch 中使用，这个是基于竞态并不是经常发生的条件。如果数据在读和写这两步中间被更改了，更新操作就失败了，然后取决于程序怎么处理这个失败，可以是用新的数据重新操作，或者把失败通知用户。

乐观机制的实现主要依靠 version 字段，我们可以在修改或删除的时候附带 version 参数，指定修改某一个版本的数据。如果当前的 version 和我们请求的 version 不同，说明在这读写的期间数据被更改了，就会操作失败，返回错误。

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

## 分布式的数据存储

我们可以从逻辑和物理两个角度来看 ES 的数据存储。

从逻辑的角度来看，ES 的数据存储和 SQL DB 类似，index 对应 database，type 对应 table，document 对应 row。

从物理的角度来看，ES 会把一个 index 的 documents 分配到多个 shards 中，同一个 shard 中的 documents 在逻辑上并没有关系。这些 shards 可以有多份拷贝，然后这些 primary shards 和 replica shards 又会被分配到多个 Node 中，分配的规则会保证当有一个 Node down 的时候，数据还是完整的。

![Screen Shot 2016-05-17 at 3.23.24 PM.png](http://cdn.yyqian.com/201605171523-FtXMLEAMbSAa8KiinizqxACUzVD7?imageView2/2/w/800/h/600)

### 从逻辑的角度来看 ES

![Screen Shot 2016-05-17 at 3.52.50 PM.png](http://cdn.yyqian.com/201605171553-FhQzI29pVq9EhXberLDeFR_b9xJ5?imageView2/2/w/800/h/600)

Document 对应于 SQL DB 的 row，它的数据结构和其他 NoSQL DB 的相同：

- 一个 Document 同时包含 key(field) 和 value（SQL DB 的 row 只有 value，而 key 的定义在 table 中）
- 可以有层级关系，和 JSON 表现的形式相同
- scheme-free，不像 SQL DB 那样需要预先定义 table 的结构（因为 document 本身就存了 field），但是 document 的每个 field 对应的数据类型是需要知道的，因此这种 mapping 是特定于某个 index 的某个 type

Type 对应于 SQL DB 的 table，但是概念上有一定差别：

- type 中所有 fields 与其数据类型的对应关系组成的集合叫 mapping，这个是特定于某个 type 的，这一点看上去貌似不那么 scheme-free
- mapping 包含了这个 type 中所有 documents 的 fields，但是反过来则不是，某个 document 可以只包含某几个 field，因此从这个意义上来讲，还是 scheme-free 的
- 如果新增的一个 document 含有新的 field，ES 会通过这个 field 的 value 来猜测数据类型，这种方式是不靠谱的，因此在生成环境要在 indexing 之前预先定义 mapping

要注意的是， Type 仅仅提供逻辑上的隔离，在物理上同一个 index 中的 documents 的分布情况跟 type 无关，这里如果同一个 shard 中的两个不同 type 包含同名的 field，这两个 fields 应该是相同数据类型的，否则 ES 会有额外的开销来区分这两个 fields。

Index 是多个 types 的集合，它有一些自身的设置，譬如：

- refresh_interval，这个表示 indexing 的频率，新增数据一般不是立即进行 indexing，而是有一定的时间间隔，否则开销太大，所以 ES 自称是 near-real-time，这个说法就是从这来的
- 设置 primary shards 的数量、replica 的数量

### 从物理的角度来看 ES

一个 ES 进程就是一个 Node，一个服务器如果跑多个 ES 进程，就有多个 Nodes，如果这些 Nodes 的 Cluster name 相同，那么它们就自动组成了一个 Cluster。访问 Cluster 中任何一个 Node 都是等同的。

前面说了 ES 会把一个 index 的数据分配到多个 shards 中，那具体是如何分配的呢？默认情况下，shard number 会用以下公式计算，其中 routing 一般是 document id。

```
shard = hash(routing) % number_of_primary_shards
```

所有的 API 都接受 routing 参数，用来控制 document-to-shard mapping。例如，如果我们用 type id 作为 routing 参数，这样就能使得相同 type 的数据在同一个 shard 中。

primary_shards 的数量一般是不可更改的，而 replica 的数量是可以随意改变的。

ES 中的每个 shard 都是一个 Lucene index（inverted index）。它包含了 Documents 的原始数据，以及额外的数据，例如 term dictionary 和 term frequencies：

- term dictionary 用来定位相关的 documents
- term frequencies 用来计算 relevancy score of results

![Screen Shot 2016-05-17 at 4.45.41 PM.png](http://cdn.yyqian.com/201605171645-FgLtXTfbLVuXpzSjKcxwxUToJLR9?imageView2/2/w/800/h/600)

## 各个 API 背后的运作机制

Creating, Indexing, and Deleting a Document

![Screen Shot 2016-05-10 at 1.55.25 PM.png](http://cdn.yyqian.com/201605101356-FmwudfY99Z293y-IaLIaGH8MxN_2?imageView2/2/w/800/h/600)

Retrieving a Document

下图中第二步的 forwards the request to Node 2 用了 round-robin 算法

![Screen Shot 2016-05-10 at 1.58.06 PM.png](http://cdn.yyqian.com/201605101358-FkGV_AvkH7QsfwtV_joO_Ezmfl7_?imageView2/2/w/800/h/600)

Partial Updates to a Document

![Screen Shot 2016-05-10 at 2.00.38 PM.png](http://cdn.yyqian.com/201605101401-FhKYDhqMQyVWrfYbhghyPRjfpryY?imageView2/2/w/800/h/600)

mget

![Screen Shot 2016-05-10 at 2.05.11 PM.png](http://cdn.yyqian.com/201605101405-FrS_ElQ0GJ0-hOqDxxRj5lNzmS2q?imageView2/2/w/800/h/600)

bulk

![Screen Shot 2016-05-10 at 2.05.40 PM.png](http://cdn.yyqian.com/201605101405-FgGQatAPHpdwNlsW5naP8y5L_I2U?imageView2/2/w/800/h/600)

---

参考链接：

- [A first take at building an inverted index](http://nlp.stanford.edu/IR-book/html/htmledition/a-first-take-at-building-an-inverted-index-1.html)
- [Elasticsearch: The Definitive Guide](https://www.elastic.co/guide/en/elasticsearch/guide/current/inverted-index.html)
- Elasticsearch in Action
