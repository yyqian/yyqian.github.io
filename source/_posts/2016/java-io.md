---
title: Java 中的 IO
date: 2016-08-10 11:50:58
permalink: 1470801058000
tags: Java
---

## Byte Streams

所有的 Byte Stream 都继承自 InputStream 和 OutputStream 抽象类。

InputStream 关键的几个方法定义如下：

```
public abstract class InputStream implements Closeable {

    public abstract int read() throws IOException;

    public int read(byte b[], int off, int len) throws IOException {
        if (b == null) {
            throw new NullPointerException();
        } else if (off < 0 || len < 0 || len > b.length - off) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return 0;
        }

        int c = read();
        if (c == -1) {
            return -1;
        }
        b[off] = (byte)c;

        int i = 1;
        try {
            for (; i < len ; i++) {
                c = read();
                if (c == -1) {
                    break;
                }
                b[off + i] = (byte)c;
            }
        } catch (IOException ee) {
        }
        return i;
    }

    public int read(byte b[]) throws IOException {
        return read(b, 0, b.length);
    }
}
```

read()方法是最基本的方法，它在子类 FileInputStream 中是通过 Native 方法来实现的：

```
    public int read() throws IOException {
        return read0();
    }

    private native int read0() throws IOException;
```

虽然 `read()` 的返回值是 int 类型的，但它的取值范围只有 0 - 255，就是一个 byte 的取值范围，在另外一个方法的源代码中也可以看到，`(byte)c` 这样的强制转换是安全的。除此之外，在遇到 EOF 的时候该方法会返回 -1。

`read(byte b[], int off, int len)` 方法可以控制字节流从 b[] 的哪个位置开始填充，填充的长度是多少。我们从这段源代码中也可以看下 read() 方法是如何使用的。

OutputStream 抽象类的部分定义如下：

```
public abstract class OutputStream implements Closeable, Flushable {
    public abstract void write(int b) throws IOException;

    public void write(byte b[], int off, int len) throws IOException {
        if (b == null) {
            throw new NullPointerException();
        } else if ((off < 0) || (off > b.length) || (len < 0) ||
                   ((off + len) > b.length) || ((off + len) < 0)) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return;
        }
        for (int i = 0 ; i < len ; i++) {
            write(b[off + i]);
        }
    }

    public void write(byte b[]) throws IOException {
        write(b, 0, b.length);
    }
}
```

与 InputStream 类似，write(int b) 也是 OutputStream 最基本的方法，在 FileOutputStream 是通过 Native 方法实现的。

对于参数 int b，源代码的注释中说明了只会取参数的低8位，高24位都会被舍弃。这一点和 InputStream 的 read() 方法也是相互对应的。其他两个方法不做解释了。

Byte Stream 在实际应用中用得不多，因为它操作的最小单位是 Byte，是个较为底层的 IO，但其他 Stream 类都是构建在 Byte Stream 之上的。

## Character Streams

所有的 Character Stream 都继承自 Reader 和 Writer 抽象类。

如果比较 FileInputStream/FileOutputStream 和 FileReader/FileWriter 的使用，你会发现两者几乎相同，其中最主要的不同在于变量 cache 持有的字节数不同，Character Stream 操作的最小单位是 16-bit（两个字节），而 Byte Stream 操作的最小单位是 8-bit（一个字节）。前者可以操作单个中文字符，但是后者不行。

大多数 Character Streams 都是 Byte Streams 的「Wrapper」。真正的读写都是通过 byte stream 来操作的，character stream 只是完成中间的 byte 和 character 转换。我们来看下 FileReader 的继承关系：

```
public class FileReader extends InputStreamReader {
    public FileReader(String fileName) throws FileNotFoundException {
        super(new FileInputStream(fileName));
    }
}

public class InputStreamReader extends Reader {

    public InputStreamReader(InputStream in) {
        super(in);
        try {
            sd = StreamDecoder.forInputStreamReader(in, this, (String)null); // ## check lock object
        } catch (UnsupportedEncodingException e) {
            // The default encoding should always be available
            throw new Error(e);
        }
    }

    public InputStreamReader(InputStream in, String charsetName)
        throws UnsupportedEncodingException
    {
        super(in);
        if (charsetName == null)
            throw new NullPointerException("charsetName");
        sd = StreamDecoder.forInputStreamReader(in, this, charsetName);
    }

}
```

FileReader 其实就是包装了 FileInputStream。它继承自 InputStreamReader，该类可以看作是「byte-to-character bridge」，它的构造函数除了接受 byte stream，也可以传入 charset。

为了进一步方便使用，例如实现 Line-Oriented I/O，我们可以进一步对 Reader 和 Writer 进行包装，于是就有了 BufferedReader and PrintWriter。它们在构造的时候都要传入一个 Reader/Writer 实例。它们的 readLine 和 println 方法可以实现按行的输入输出。我们在下小节中将详细介绍。

## Buffered Streams

前面涉及的 byte stream 和 character stream 都是 unbuffered I/O，也就是说它们是逐个字节或逐个字符进行读写的。如果对队列比较了解的话，它的工作模式类似于 TransferQueue，生产者是数据源，消费者是应用程序，但中间其实是没有真正意义上的 Queue 的，生产者会直接把产品交给消费者。这种模式一般是比较低效的，因为相比 buffered IO，它的读写更频繁。

理解 Buffered Stream 要首先理解装饰器模式，我们把 unbuffered stream 作为被包装的对象，通过 buffered stream 的构造器传入一个实例，然后 buffered stream 内部在该实例基础上做点手脚，满足我们缓冲的需求，就得到了 Buffered Stream。我们可以看下它的构造方式：

```
inputStream = new BufferedReader(new FileReader("xanadu.txt"));
outputStream = new BufferedWriter(new FileWriter("characteroutput.txt"));
```

以上演示的是对 Reader/Writer 的包装，我们总共有四种可以用的 buffered 包装器，分别对应字节流和字符流的读写：

- BufferedInputStream / BufferedOutputStream
- BufferedReader / BufferedWriter

buffered stream 一般会在「关键时刻」自动 flush 缓冲区，如果我们需要手动触发的话，可以调用 flush() 方法。

## Byte Streams、Character Streams 和 Buffered Streams 三者关系

Java IO 包含了很多的类，把握它主要的脉络较为关键，否则容易迷失方向。

Byte Streams 操作的最小单位是字节，最为底层，是所有 Stream 的基础。

Character Streams 通过 InputStreamReader/OutputStreamWriter 这座桥梁，来完成 byte-to-char 和 char-to-byte 的转换，继而形成 Character Streams 对 Byte Streams 包装（这里只是针对 FileReader/FileWriter 而言，其他的 Reader/Writer 实现类并不一定需要 byte 和 char 之间的转换）。

Buffered Streams 则是为了满足对于缓冲区普遍的需求，实现的一种装饰器，对字节流和字符流的读写都可以进行包装。你可以把它想象成一个「马甲」或一个「壳」。

从上面的关系分析也可以看出，理解它们之间关系的关键地方在于理解装饰器模式。

## Scanning 和 Formatting

前面介绍的都是较为底层的 IO，这里介绍几个方便我们使用、构建在这些底层 IO 之上的几个 class。

### Scanner

Scanner 的实现的接口如下：

```
public final class Scanner implements Iterator<String>, Closeable {
}
```

我们可以看到它不是个 Stream 类，它的使用是通过迭代器模式，并且也可以进行 close 操作。它也是个装饰器，但它的作用更类似于一个工具，用来进行内容的迭代访问和最后的关闭操作。它的构造方法如下：

```
Scanner s = new Scanner(new BufferedReader(new FileReader("xanadu.txt")));
```

这个构造方法可以接受 Readable 参数或 InputStream 参数，也就是说 byte stream 和 character stream 它都可以接受。BufferedReader 的继承关系如下：

```
BufferedReader -> Reader -> Readable, Closeable
```

当然，不用 BufferedReader 包装也是可行的：

```
Scanner s = new Scanner(new FileReader("xanadu.txt"));
```

我们通过 Scanner 的迭代器来使用它：

```
while (s.hasNext()) {
    System.out.println(s.next());
}
```

它默认按照空格来拆分字符串，我们也可以自己定义分隔符。

### PrintWriter/PrintStream

PrintWriter 和 PrintStream 前者基于 character 后者基于 byte。PrintStream 我们实际会用到的只有 System.out 和 System.err，正常情况下我们都应当使用 PrintWriter。

这两个类我们会用到的方法有：

1. print 和 println
2. format

这个代表两种 formatting 的方式，第一种一般就是通过拼接字符串，第二种则类似 c 语言的方式。

## Command Line 的 IO

Java 有两种方式和 Command Line 进行 IO 交互：

1. 使用 Standard Streams: System.in, System.out, System.err
2. 使用 Console 对象

这里只讨论 Standard Streams。其中 System.out 和 System.err 实际是 byte stream（type 是 PrintStream），但它的行为和 character streams 更相像，我们可以把它当作 character streams 来使用。

而 System.in 是个纯粹的 byte stream (type 是 InputStream)，在使用的时候我们可能需要用装饰器来包装它，再进行实际使用。以下演示了 System.in 的几种使用方式：

```
public class CommandLineIO {
  public static void main(String[] args) throws IOException {
    rwLine();
  }

  private static void rwSingleByte() throws IOException {
    InputStream in = System.in;
    int unit = in.read(); //  System.in 是字节流, 不能读取单个中文字符（因为一个中文字符要占多个字节）
    System.out.println((char)unit);
  }

  private static void rwSingleChar() throws IOException {
    Reader in = new InputStreamReader(System.in); // 我们通过 InputStreamReader 这座桥梁把 InputStream 转化为 Reader
    int unit = in.read(); // 用 Reader 来读取就能正常得到完整的中文字符
    System.out.println((char)unit);
  }

  private static void rwLine() throws IOException {
    // 先把 InputStream 转换为 Reader, 再把 Reader 包裹成 BufferedReader
    // 利用 BufferedReader 的 readLine 方法进行按行读取
    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
    String line = in.readLine();
    System.out.println(line);
  }

  private static void rwWord() throws IOException {
    // 用 Scanner 来包裹 Reader
    Scanner scanner = new Scanner(new InputStreamReader(System.in));
    // 注意要手动关闭 Scanner, 否则会一直执行下去
    scanner.forEachRemaining(System.out::println);
  }
}
```

## Data Streams 和 Object Streams

前面我们讨论了多种 Stream，但总体来说都是对字节或字符的操作（也就是 8-bit 或 16-bit 大小的数据块），那些粒度更粗的操作（例如按行读写，按分隔符划分单词等）都是在字符流的基础上衍生出来的。所以我们可以想象成这些流中流淌的都是一个个 byte 或 character。

但我们程序中经常使用的数据类型是 int, long, Object 等，它们的长度比 16-bit 更长，虽然我们自己也可以通过拓展 byte stream 来实现对这些数据类型原生的读写，但实际上 Java 类库中已经包含这些类了。

### Data Streams

Data Streams 的实现类都实现了 DataInput/DataOutput 接口，以下是 DataInput 的部分方法定义（DataOutput 的方法类似）：

```
public interface DataInput {
    boolean readBoolean() throws IOException;
    byte readByte() throws IOException;
    short readShort() throws IOException;
    char readChar() throws IOException;
    int readInt() throws IOException;
    long readLong() throws IOException;
    float readFloat() throws IOException;
    double readDouble() throws IOException;
    String readLine() throws IOException;
    String readUTF() throws IOException;
}
```

我们可以看到 Data Streams 支持所有的 primitive type，加上 String。

实现类最常用的是 DataInputStream/DataOutputStream，它们都是 InputStream/OutputStream 的装饰器。以下是使用示例：

```
public class DataIO {
  public static void main(String[] args) throws IOException {
    String filename = "/Users/yyqian/Downloads/transfer";
    DataOutputStream out = new DataOutputStream(new FileOutputStream(filename));
    out.writeFloat(3.2123f);
    out.writeLong(832934L);
    out.writeUTF("你好, 世界");
    out.close();
    DataInputStream in = new DataInputStream(new FileInputStream(filename));
    try {
      while (true) {
        System.out.println(in.readFloat());
        System.out.println(in.readLong());
        System.out.println(in.readUTF());
      }
    } catch (EOFException e) {
      System.out.println("EOF");
      in.close();
    }
  }
}
```

这里我们有几点需要注意：

1. 在 InputStream 或 Reader 中，我们判断 EOF 是通过判断 read 方法的返回值是否为 -1。但 Data Stream 返回的数据类型有多种，我们没法通过这个特殊的返回值 -1 来判断 EOF，而是通过 EOFException，我们要 catch 这个异常来处理结束。

2. 我们可以在 Data Stream 中混用各种类型的数据，但一定要注意读取时候也选择正确的类型，Java 只是把 Data Stream 看作二进制的数据流，开发人员务必自己确保数据类型的匹配。

3. 不要把价格等对精度敏感的数据用 float/double 来放到 Data Stream 中使用，而是应该使用 BigDecimal，但 BigDecimal 属于 Object，所以要用到下面的 Object Stream。

### Object Streams

Data Streams 支持所有的 primitive type 和 String，还缺少的一大块支持就是 Object。

Object Streams 的实现类是 ObjectInputStream 和 ObjectOutputStream。ObjectInputStream 的继承关系如下：

```
public class ObjectInputStream
    extends InputStream implements ObjectInput, ObjectStreamConstants {}

public interface ObjectInput extends DataInput, AutoCloseable {}
```

我们可以看到 ObjectInput 接口还继承了 DataInput 接口，所以实际上 Object Streams 同时支持所有的 primitive type 和 Object。

它的使用就是通过 writeObject 和 readObject 方法：

```
public class ObjectStreamIO {
  public static void main(String[] args) throws IOException, ClassNotFoundException {
    String filename = "/Users/yyqian/Downloads/transfer";
    ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream(filename));
    out.writeObject(new BigDecimal("12231.432"));
    out.close();
    ObjectInputStream in = new ObjectInputStream(new FileInputStream(filename));
    BigDecimal priceCopy = (BigDecimal)in.readObject();
    System.out.println(priceCopy.toString());
    in.close();
  }
}
```

要注意的是 I/O 前后以及多次 I/O 之后得到的 Object reference 是否指向同一个 Object。

## 总结

Java IO 中包含的类和接口众多，它们之间的关系也看似很复杂，但只要理解装饰器模式，并且抓住最基本的字节流和字符流，那么理解在此基础上构建的 buffered stream、更粗粒度的 stream 以及各种数据类型的 stream 也就容易多了。
