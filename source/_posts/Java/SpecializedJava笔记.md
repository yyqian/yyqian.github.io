---
title: Specialized Java 笔记
---

## Basic I/O

![ioHierarchyTop.gif](http://cdn.yyqian.com/201604191634-FvpJX1yO9k3iJluPb4Zq8aNcrlqB?imageView2/2/w/800/h/600)

![inputHierarchy.gif](http://cdn.yyqian.com/201604191637-Fs8Qm4tfWUSL7igel2FbO-r18PcS?imageView2/2/w/800/h/600)

![outputStreams.gif](http://cdn.yyqian.com/201604191637-Ft1F_D_8dNEq5o1QCQ3JZYHIF40j?imageView2/2/w/800/h/600)

![readerHierarchy.gif](http://cdn.yyqian.com/201604191637-FgrIHYuIHaTsdyiQHwEfHBLCFCoi?imageView2/2/w/800/h/600)

![writerHierarchy.gif](http://cdn.yyqian.com/201604191637-Fr3rl35jSBWajOvhwpdoFWU-TzPY?imageView2/2/w/800/h/600)

Stream 用完之后一定要关闭，为了确保关闭，一般都放在 finally block 中。

Line-Oriented I/O: BufferedReader, PrintWriter

### Buffered Streams

Buffered Streams (wrap unbuffered streams): BufferedInputStream, BufferedOutputStream, BufferedReader, BufferedWriter

Buffered input streams read data from a memory area known as a buffer; the native input API is called only when the buffer is empty. Similarly, buffered output streams write data to a buffer, and the native output API is called only when the buffer is full.

It often makes sense to write out a buffer at critical points, without waiting for it to fill. This is known as flushing the buffer.

An autoflush PrintWriter object flushes the buffer on every invocation of println or format. To flush a stream manually, invoke its flush method. The flush method is valid on any output stream, but has no effect unless the stream is buffered.

### Scanning and Formatting

Objects of type Scanner are useful for breaking down formatted input into tokens and translating individual tokens according to their data type.

By default, a scanner uses white space to separate tokens.

Stream objects that implement formatting: PrintWriter, PrintStream

The only PrintStream objects you are likely to need are System.out and System.err. When you need to create a formatted output stream, instantiate **PrintWriter**, not PrintStream.

Two levels of formatting:

- print, println
- format

In the Java programming language, the \n escape always generates the linefeed character (\u000A). Don't use \n unless you specifically want a linefeed character. To get the correct line separator for the local platform, use **%n**.

The Java platform supports three Standard Streams:

- Standard Input, accessed through System.in
- Standard Output, accessed through System.out
- Standard Error, accessed through System.err

### Data Streams

Data streams support binary I/O of primitive data type values (boolean, char, byte, short, int, long, float, and double) as well as String values.

interface: DataInput, DataOutput

implementations: DataInputStream, DataOutputStream

```java
out = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(dataFile)));
in = new DataInputStream(new BufferedInputStream(new FileInputStream(dataFile)));
```

Output Method: writeDouble, writeInt, writeUTF

Input Method: readDouble, readInt, readUTF

Notice that DataStreams detects an end-of-file condition by catching EOFException, instead of testing for an invalid return value. All implementations of DataInput methods use EOFException instead of return values.

### Object Streams

Just as data streams support I/O of primitive data types, object streams support I/O of objects.

interface: ObjectInput, ObjectOutput (subinterfaces of DataInput and DataOutput)

implementations: ObjectInputStream, ObjectOutputStream

method: writeObject, readObject

The writeObject and readObject methods are simple to use, but they contain some very sophisticated object management logic. This isn't important for a class like Calendar, which just encapsulates primitive values. But many objects contain references to other objects. If readObject is to reconstitute an object from a stream, it has to be able to reconstitute all of the objects the original object referred to. These additional objects might have their own references, and so on. In this situation, writeObject traverses the entire web of object references and writes all objects in that web onto the stream. Thus a single invocation of writeObject can cause a large number of objects to be written to the stream.

---

## Collections

### Collection

![colls-coreInterfaces.gif](http://cdn.yyqian.com/201604191727-FlYlqD6LTUicFl5FyYgmhu7lt9Ue?imageView2/2/w/800/h/600)

常用方法：

- basic operations: size, isEmpty, contains, add, remove
- bulk operations: containsAll, addAll, removeAll, retainAll, clear
- convert to Array: toArray
- aggregate Operations: stream, parallelStream

Three ways to traverse collections:

1. using aggregate operations
2. with the for-each construct
3. using Iterators

In JDK 8 and later, the preferred method of iterating over a collection is to obtain a stream and perform aggregate operations on it. Aggregate operations are often used in conjunction with lambda expressions to make programming more expressive, using less lines of code.


### Set

Set implementations:

- HashSet，性能最好
- TreeSet，用了 red-black tree，按照值的顺序排序
- LinkedHashSet，按照插入顺序排序

Convert Collection to Set: `c.stream().collect(Collectors.toSet());`

Convert Collection to TreeSet:

```java
Set<String> set = people.stream()
.map(Person::getName)
.collect(Collectors.toCollection(TreeSet::new));
```

### List

implementations:

- ArrayList
- LinkedList

List 特有的方法：

- get, set
- indexOf, lastIndexOf
- subList: list view, As the term view implies, the returned List is backed up by the List on which subList was called, so changes in the former are reflected in the latter.

It's highly recommended that you use the List returned by subList only as a transient object — to perform one or a sequence of range operations on the backing List.

### Queue & Deque

![Screen Shot 2016-04-19 at 10.09.47 PM.png](http://cdn.yyqian.com/201604192209-Fi2FNUWJYeLQNkMIPUSL1Lpa12Z8?imageView2/2/w/800/h/600)

![Screen Shot 2016-04-19 at 10.34.18 PM.png](http://cdn.yyqian.com/201604192234-FmiR-ni8ty5vDOctrNv1PcVk4x_U?imageView2/2/w/800/h/600)

Queue implementations:

- LinkedList
- PriorityQueue

Deque implementations:

- LinkedList
- ArrayDeque

### Map

Methods:

- basic operations: put, get, remove, containsKey, containsValue, size, and empty
- bulk operations: putAll and clear
- collection views: keySet, entrySet, and values

Map implementations:

- HashMap, performance
- TreeMap, key-ordered
- LinkedHashMap, near-HashMap performance and insertion-order iteration

Map 不归属于 Collection

### Aggregate Operations

Aggregate operations do not mutate the underlying collection. In fact, you must be careful to never mutate a collection while invoking its aggregate operations. Doing so could lead to concurrency problems should the stream be changed to a parallel stream at some point in the future.

Reduce:

```Java
Integer totalAgeReduce = roster
   .stream()
   .map(Person::getAge)
   .reduce(
       0,
       (a, b) -> a + b);

```

Collect:

```Java
List<String> namesOfMaleMembersCollect = roster
    .stream()
    .filter(p -> p.getGender() == Person.Sex.MALE)
    .map(p -> p.getName())
    .collect(Collectors.toList());
```

不能在遍历集合的时候修改集合，避免使用 Stateful Lambda Expressions

parallelStream 可以用于并发流

### Implementations

![Screen Shot 2016-04-20 at 10.22.39 AM.png](http://cdn.yyqian.com/201604201023-Fjv16f-3JQMg6Q4Bh2ljM5wm_rFR?imageView2/2/w/800/h/600)

As a rule, you should be thinking about the interfaces, not the implementations. For the most part, the choice of implementation affects only performance. The preferred style, as mentioned in the Interfaces section, is to choose an implementation when a Collection is created and to immediately assign the new collection to a variable of the corresponding interface type

The fact that these implementations are unsynchronized represents a break with the past: The legacy collections Vector and Hashtable are synchronized. The present approach was taken because collections are frequently used when the synchronization is of no benefit. Such uses include single-threaded use, read-only use, and use as part of a larger data object that does its own synchronization. In general, it is good API design practice not to make users pay for a feature they don't use. Furthermore, unnecessary synchronization can result in deadlock under certain circumstances.

并发相关的：

- ConcurrentHashMap 需要重点突破
- BlockingQueue 接口下的实现

Wrapper，典型的 decorator pattern:

- Collections.synchronizedXXX
- Collections.unmodifiableXXX

The `Arrays.asList` method returns a **List view** of its array argument. Changes to the List write through to the array and vice versa. The size of the collection is that of the array and cannot be changed. If the add or the remove method is called on the List, an UnsupportedOperationException will result.

Empty Set, List, and Map Constants: Collections.emptyXXX()

Most commonly used implementation:

- Set: HashSet
- List: ArrayList
- Map: HashMap
- Queue: LinkedList
- Deque: ArrayDeque

Collections 中有很多集合相关的算法：

- sort: 复杂度 nlog(n)
- shuffle: useful in implementing games of chance
- reverse, fill, copy, swap, addAll
- binarySearch
- frequency, disjoint
- min, max

上面这些算法一般都有两种形式，一种是 Natural Ordering，另一种是传入一个 Comparator 的实现

如果想自己实现 Collection，可以继承各种 Abstract Class:

- AbstractCollection
- AbstractSet
- AbstractList
- AbstractSequentialList
- AbstractQueue
- AbstractMap

---

## Networking



---

JDBC Database Access, Concurrency
