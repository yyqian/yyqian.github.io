---
title: Java 最佳实践
---

类成员的可访问性最小化

可变性最小化

避免使用 Enum 的 ordinal 方法

避免使用位域（用 EnumSet 代替）

坚持使用 @Override

方法的参数一定要检查有效性

类在传入或传出可变的对象时，要小心外界对类造成破坏，可以考虑进行保护性拷贝

缩短方法的参数列表有两个方法：创建一个辅助类；用 Builder 模式

方法的参数类型优先用接口而不是类

要调用哪个重载方法是在编译时做出决定的

返回零长度的数组或集合，而不是null

API 必须写 Javadoc

for-each 循环优于传统的 for 循环和迭代器。只要对象实现 Iterable 接口，就可以用 for-each 循环

尽可能使用标准类库，java.lang, java.util, java.io, java.util.concurrent 需要熟悉。总而言之，不要重新发明轮子，如果有些需求看上去十分常见，很有可能类库中已经有某个类实现了这个需求。

float 和 double 不能适用于精确值求解，尤其是货币。货币建议用 BigDecimal，或者自己用 int 或 long 实现数据结构

基本类型优于装箱基本类型, primary key 可以用 Long 或者 long，前者的优点是可以是 null，譬如说新建一项的时候

如果多个字符串需要连接，可以用 StringBuilder

通过接口引用对象，譬如：`List<User> userList = new ArrayList<User>();`。这条不适应的情况是：1. 值类（比如 String），没有对应的接口；2. 对象属于一个框架，框架的基本类型是类，不是接口；3. 类实现了接口，但是它提供了接口不存在的方法，而你又需要用到这个方法

谨慎使用反射

谨慎使用本地方法（JNI，不是类型安全的，特定于平台，不可移植）

不要过早地优化，优化的弊大于利，特别是不成熟的优化

命名规则：

- 包的组成部分命名通常不要超过 8 个字符，鼓励用缩写，譬如 util。
- 类型参数用 T、E、K、V、X
- boolean 类型一般用 is 开头，后面跟名词或名词短语

使用标准的异常：

- IllegalArgumentException，非 null 的参数值不正确
- IllegalStateException，对于方法调用而言，对象状态不合适
- NullPointerException，禁止使用 null 的情况下参数为 null
- IndexOutOfBoundsException，下标参数值越界
- ConcurrentModificationException，在禁止并发修改的情况下，检测到对象的并发修改
- UnsupportedOperationException，对象不支持用户请求的方法

努力使失败保持原子性，为此常见的办法是在执行操作之前检查参数的有效性。

不要使用空的 catch 块，至少应当重新抛出它

谨慎实现 Serializable 接口

Always use 'single quotes' for char literals and "double quotes" for String literals.

By convention, method names should be a verb in lowercase or a multi-word name that begins with a verb in lowercase, followed by adjectives, nouns, etc.

return types 建议是父类、Interface
