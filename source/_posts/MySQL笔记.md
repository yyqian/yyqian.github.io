---
title: MySQL 笔记
---
## 名词

- 多表检索
- 子查询
- 事务处理
- 外键
- 视图
- 存储函数、存储过程
- 触发器
- 事件
- 索引

## 数据类型最佳实践

CHAR 会在存储时填充空格，检索时删除空格
BINARY 会在存储时填充0x00，检索时不处理

### AUTO_INCREMENT

BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY

### TIMESTAMP

TIMESTAMP NOT NULL

自动初始化选项：DEFAULT CURRENT_TIMESTAMP

自动更新选项：ON UPDATE CURRENT_TIMESTAMP


## 查询优化

（1）用于显示的列不用建索引（SELECT 中的列），这些列要建索引：

- WHERE 子句中的列
- 连接子句中的列
- ORDER BY 或 GROUP BY 中的列

（2）列的基数是指该列非重复元素的个数。基数越大，索引效果越好。例如性别只有 M 和 F 两个值，那么基数是 2，每次检索完性别后，还是有近乎一半的行被挑选出来，索引效果就不好。

（3）索引的数据类型越小，检索速度越快

（4）字符串可以只索引字符串的前缀，不用索引整段字符串，但前缀也不能太短，这样就无法获得大量的唯一值（参照第二条，基数越大越好）

（5）最左前缀。如果一个复合索引，列的名字分别为 country state city，这个索引可以用来搜索下列组合：

- country, state, city
- country, state
- country

如果建了这个索引，再建一个单独的 country 是没有意义的，但建一个单独的 state 或 city 索引是有意义的。

（6）不要建立过多的索引。每增加一个索引就要额外的空间，还会影响写入速度。所以索引是用空间和写入速度，来换取读取速度的。

（7）InnoDB 总会使用 B 树索引

（8）利用慢查询日志找出性能差的查询

（9）利用 EXPLAIN 来检查优化程序的操作

（10）多用数字运算，少用字符串运算

（11）数据列声明为 NOT NULL，这样可以节省检查 NULL 的操作

（12）如果基数很低，考虑使用 ENUM 列

（13）使用 BLOB 和 TEXT 要注意，避免检索这两种列