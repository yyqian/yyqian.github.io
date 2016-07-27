---
title: high-perfom-mysql
tags: mysql
---

ab 或 http_load 可以测试 http 性能。

sysbench 可以测试 cpu, fileio, oltp 等性能。

gnuplot 用来绘图

## 性能剖析

### 慢日志查询

在 my.cnf 文件中添加：

```
[mysqld]
slow_query_log=1
long_query_time=3
```

long_query_time 是阈值，单位是秒，设为 0 可以记录所有查询语句

查询是否开启慢日志查询：

```
SHOW GLOBAL VARIABLES LIKE 'slow_query_%';
SHOW GLOBAL VARIABLES LIKE 'long_query_time';
```

### 单条查询

开启单条的剖析

```
SET profiling = 1;
```

查看所有记录

```
SHOW PROFILES;
```

查看单条记录

```
SHOW PROFILE FOR QUERY 1;
```

