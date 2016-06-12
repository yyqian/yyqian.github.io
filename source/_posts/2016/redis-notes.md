---
title: Redis 核心功能解析
date: 2016-06-09 10:52:01
permalink: 1465440721000
tags: Redis
---

## 持久化

Redis 持久化有两种选择：

1. Snapshot（快照），把内存中的数据转存到文件
2. AOF（append-only file），把所有写命令存储到日志文件中，跟 mysql binlog 类似，但是它不是 bin 而是 text

### 快照

快照相关的 Redis 参数设置：

```
save 60 1000
stop-writes-on-bgsave-error no
rdbcompression yes
dbfilename dump.rdb
```
<!-- more -->
快照要注意的是，当 Redis 服务发生崩溃，从最近一次快照到当前发生的数据更改都会丢失。触发 snapshot 主要有几种方式：

1. Redis 客户端调用 `BGSAVE` 命令，Redis 会 fork 进程，子进程执行保存操作，父进程继续正常服务。
2. Redis 客户端调用 `SAVE` 命令，Redis 拒绝所有服务，直到执行保存操作完成。
3. 如果参数配置了类似 `save 60 1000` 的内容，则当 60 秒内发生了 1000 次写操作，就会触发 `BGSAVE` 命令
4. 如果 Redis 接收到 SHUTDOWN 命令或者 TERM 信号，就会触发 `SAVE` 命令
5. 如果主从 Redis 服务之间进行同步，从服务执行 `SYNC` 命令，主服务就会触发 `BGSAVE` 命令

当数据量在 1G 以下，快照是很好的选择。但是，当数据量到 10G，空闲内存不多，`BGSAVE` 操作可能导致 Redis 服务崩溃。

根据 Redis 服务器硬件虚拟化方式的不同，`BGSAVE` 所执行的 fork 操作的效率会有所不同，每 1G 数据 fork 需要 10-20ms 到 200-300ms 不等，因此 fork 操作可能导致 Redis 服务几秒的停顿。

对于数据量很大的情况，为了避免 fork 导致的挺多，我们可以禁用自动的 save 操作，手动规划执行 `BGSAVE` 或 `SAVE` 操作，`SAVE` 操作在这种情况下的优势是：虽然 Redis 拒绝了所有服务，但是没有 fork 操作，也不需要和父进程争夺资源，所以保存操作执行得更快。

以 50G 数据为例，如果用 `BGSAVE`，fork 操作需要 15 秒，完成保存动作需要 15-20 分钟。但是，如果执行 `SAVE` 命令，则只需要 3-5 分钟，因此适合安排在凌晨三四点钟执行。

### AOF

AOF 相关的参数设置：

```
appendonly no
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

AOF 需要将执行的命令写到磁盘的日志文件中，但是写操作不等同于真正的持久化了。写操作包括：

1. write，把数据写到缓冲区，等待操作系统将它存到本地磁盘
2. flush，告诉操作系统可以将缓冲区的数据写到磁盘，这一步是可选的，也就是说即使不 flush，操作系统也会在「恰当」的时候把数据写到磁盘，而且这步也不是立即执行的，它是异步操作。
3. sync，相当于是 flush 的同步版本，它会阻塞进程直到完成存储到磁盘的操作。

appendfsync 参数可以设置 always, everysec, no。如果是 always，则每次 AOF 同步操作都会触发真正的磁盘写操作，但是机械硬盘的性能大概是 200 writes/sec，固态硬盘是 10000 writes/sec 左右。并且 appendfsync 设置为 always 有可能严重缩短 SSD 的寿命。所以对于需要频繁写操作的 Redis 服务，always 不是个合适的选择，对于机械硬盘，写操作的性能是瓶颈，对于 SSD，寿命是制约的因素。

对于通常的情况，appendfsync 设置为 everysec 是最好的选择，每秒一次的同步操作不会有明显的性能影响。即使服务发生崩溃，也最多丢失一秒的记录。

appendfsync 设置为 no 的情况主要是针对硬盘的性能无法承受 write load，这个时候禁用显式的 sync 就是一个选择。

如果我们单纯使用 AOF 而不用快照的话，AOF 日志文件的体积会持续增长，而且每次重启服务，Redis 都需要执行日志中所有的命令来恢复数据，大体积的 AOF 日志文件会导致 Redis 启动时间很长。

`BGREWRITEAOF` 可以用来减少 AOF 日志文件的冗余命令，但是每次重写都要删除冗余的项，当数据达到 10GB 左右的时候，删除冗余项依然是个性能上的负担。我们可以通过设置百分比和 min-size 来设置自动触发 `BGREWRITEAOF` 命令的时机，类似通过 save 参数来设置触发 `BGSAVE` 的时机。

## Replication（复制）

Redis 可以跟 MySQL 一样，实现 master/slave 结构，master 负责写操作，slave 负责读操作。

单个 Redis 服务大概能处理 100 commands/second，当数据量到几百万的时候，set/zset 操作可能需要几秒才能完成。

配置 Replication 的时候，在 Master 端我们要配置 `dir` 和 `dbfilename` 参数，确保 `BGSAVE` 可以写到本地磁盘上。在 Slave 端，我们要配置 `slaveof host port`。

我们一般让 Master 只使用 50-65% 的总内存，来确保 `BGSAVE` 的执行。Slave 在启动的时候先从本地的 snapshot/AOF 中恢复数据，然后连接到 master 来执行复制操作。

![Screen Shot 2016-06-10 at 10.32.14 AM.png](http://cdn.yyqian.com/201606101032-FuVRVCXkcD4LI2tygloTtuF7Y29s?imageView2/2/w/800/h/600)

当 Slave 得到 snapshot 的时候，它会 flush 所有的数据，然后用 snapshot 的数据来代替。

如果多个 Slave 几乎同时向 Master 发送 SYNC 请求，如果发生在上图中的 step 1 2，其他 slaves 会得到同样的 snapshot（也就是省去了多次 BGSAVE 的过程），但如果发生在 step 3 以及之后，就会重新执行 step 1-5。

如果 Redis 服务负载很高，我们需要添加更多的 Slaves，但是 Slave 达到一定数量之后，单个 Master 就无法承载与多个 Slaves 同步，这个时候，我们可以添加 Helper Slaves（intermediate Redis master/slave nodes），也就是下图中的 Slave 1-3，形成一个 Master/Slave Chain。

![Screen Shot 2016-06-10 at 10.45.54 AM.png](http://cdn.yyqian.com/201606101046-FoC_upg6ViKSWjTTTXZqkoqANudC?imageView2/2/w/800/h/600)

除此之外，我们还可以配置 AOF 来确保 Slaves 可以每秒执行同步操作。

为了确保同步完成，我们可以给 Master 写入一个 dummy value，然后检查 slave 是否同步到这个值，过程中我们可以利用 `INFO` 来检查同步的状态。

## 处理系统错误

Redis 没有 ACID 保障，需要额外的措施来保障数据完整性。

我们有两个工具来检查数据完整性：redis-check-aof，redis-check-dump。

以下是一个替代出错的 Master 的操作过程：我们有 A、B、C 三台 Redis 机器，Master A 出错，Slave B 正常，我们想用机器 C 代替 Master A 成为新的 Master。我们的操作流程是：

1. 从 Slave B `save` 一份 snapshot（dump.rdb），传输到机器 C
2. 启动机器 C 的 Redis 服务，加载这份 snapshot
3. 登录 Slave B，用 `SLAVEOF` 命令来指向新的 Master C。

![Screen Shot 2016-06-10 at 11.18.49 AM.png](http://cdn.yyqian.com/201606101119-FirHKxTwDokfX9uZD2ET6F9I72yV?imageView2/2/w/800/h/600)

Redis Sentinel 也能实现以上类似的功能，主要来处理当 Master 出错时的情况。

## Redis 事务

Redis 的事务和 MySQL 等 SQL DB 不同，从 `MULTI` 开始到 `EXEC` 结束，Redis 不会执行中间任何命令，也就无法根据中间的执行状态来做出回滚等操作。

我们需要使用 `WATCH, UNWATCH, DISCARD, MULTI, EXEC` 多个命令来保证事务的正确性。`WATCH` 的作用是: 我们在 `EXEC` 之前，先 `WATCH` 一个 key，如果这个 key 在 `EXEC` 之前发生了更改，那么在我们执行 `EXEC` 的时候就会报错。

SQL DB 一般是使用锁来解决这个问题。而 Redis 是使用 `WATCH` 来实现 CAS 操作（compare and set），这是一种乐观锁的机制（SQL DB 那种是悲观锁）

`WATCH` 的使用流程大致是：

1. WATCH x
2. 获取或检查 x 的值
3. 如果 x 值不满足条件，则 `UNWATCH` 然后退出
4. 如果 x 值满足条件，则开始 `MULTI`
5. 设置 x 的值等相关命令
6. 最后 `EXEC`

以下是代码示例：

```
(defn list-item
  "首先 watch 玩家的 inventory: 如果他的背包中没有该物品, 就返回; 如果有, 则开始执行事务（把物品添加到 market, 把物品从玩家背包移除）"
  [itemid sellerid price]
  (let [inventory (str "inventory:" sellerid)
        item (str itemid "." sellerid)]
    (wcar* (redis/watch inventory))
    (if (= 1 (wcar* (redis/sismember inventory itemid)))
      (wcar* (redis/multi)
             (redis/zadd "market:" price item)
             (redis/srem inventory itemid)
             (redis/exec))
      (wcar* (redis/unwatch)))))
```

### 非事务性的 pipeline（non-transactional pipelines）

在客户端使用 pipeline 功能可以大幅提升性能，减少网络传输的开销。但是如果在不需要事务处理的地方使用 MULTI/EXEC 会带来事务的额外开销，我们可以选择使用 pipeline，但不在头尾包裹 MULTI/EXEC 来将性能最大化（Python 有这个选项）。

这里我有个疑问：

Redis 的 Clojure 客户端 carmine 通过 wcar 实现 pipeline。它把多条命令一起发送，然后同时返回所有命令的结果。但它是否默认在头尾用 MULTI 和 EXEC 包裹了起来？像上面我们在 pipeline 中间显式地调用了 MULTI 和 EXEC，那么是否是 MULTI/EXEC 又嵌套了一层 MULTI/EXEC，从返回的结果来看貌似是这样的，但实际 Redis 是不支持嵌套 MULTI/EXEC 的，所以这里 pipeline 不应当是在最外面包裹了 MULTI/EXEC。

### 性能方面的考虑

我们可以用 `redis-benchmark -c 1 -q` 命令来测试 Redis 的性能。

一般用客户端的性能会比 benchmark 测出来的差，最常见的原因是没用 pipeline，每个命令都需要建立连接。一般多数 Redis 客户端都有 pipeline 功能，并且在内部会使用 connection pool。

---

参考资料：

- Redis in Action
