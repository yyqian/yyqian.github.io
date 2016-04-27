---
title: transient和@JsonIgnore
date: 2016-04-23 17:02:17
tags: Java
---

一般在遇到到远程过程调用（Remote Procedure Call，RPC）或者 Restful API 的时候，我们就会涉及到对象序列化的问题。RMI 中只要让类实现 Serializable 接口，然后使用 ObjectOutputStream 就可以完成序列化为二进制的过程。而 Restful API 一般用 JSON 格式较为普遍，我个人习惯用 Jackson 2 类库来完成序列化为 JSON 字符串的过程。

在序列化的过程中，我们可能会遇到一些 fields，我们并不希望把它们传输出去，例如用户的密码、银行卡号等，这时候我们就会用到 transient 或 @JsonIgnore，前者是 Java 中的一个描述符，后者是 Jackson 2 类库中的一个注释，下面我们分开来讨论这两个东西的用法。

## transient

transient 可以修饰于 field 上，这样在序列化为二进制的时候，这个 field 就会被忽略掉。例如以下 User 类的 password 字段：

```
public class User implements Serializable {
  private String username;
  private transient String password;
  private static int count = 0;

  public User() {
    User.count++;
  }
  
  public void serialize(String filename) throws IOException {
    OutputStream os;
    ObjectOutputStream oos = null;
    try {
      os = new FileOutputStream(filename);
      oos = new ObjectOutputStream(os);
      oos.writeObject(this);
    } finally {
      if (oos != null) {
        oos.close();
      }
    }
  }

  public static User deserialize(String filename) throws IOException, ClassNotFoundException {
    InputStream is;
    ObjectInputStream ois = null;
    try {
      is = new FileInputStream(filename);
      ois = new ObjectInputStream(is);
      return (User) ois.readObject();
    } finally {
      if (ois != null) {
        ois.close();
      }
    }
  }
}
  \\ 下面省略了 getter setter 方法
```

我们可以测试下 serialize 方法，看下持久化后的文件，其中是没有 password 相关信息的，然后再反序列化回来，得到的 User 对象的 password 字段也是 null。

这里要注意的是 static fields 是不会被序列化的，这个可以自行验证一下。我觉得是因为本质上 static fields 保存的是跟一个类相关的信息，而不是跟单独一个对象相关的，例如上面例子中的 count 字段，如果 static fields 也被序列化和反序列化则会引起混乱。

## @JsonIgnore

在 Jackson 1.9 之后，@JsonIgnore 作用在 field，getter method，setter method 这三者任意一个上面，都会使得在序列化或者反序列化为 JSON 的时候，三者都会被忽略掉。例如下面的例子：

```
public class User implements Serializable {
  private String username;
  @JsonIgnore
  private String password;
  private static int count = 0;

  public User() {
    User.count++;
  }
  
  public String stringfy() throws JsonProcessingException {
    ObjectMapper mapper = new ObjectMapper();
    return mapper.writeValueAsString(this);
  }

  public static User parse(String jsonString) throws IOException {
    ObjectMapper mapper = new ObjectMapper();
    return mapper.readValue(jsonString, User.class);
  }

}
  \\ 下面省略了 getter setter 方法
```

我们可以测试发现，password 不管在序列化还是反序列化过程中，都会被忽略掉。而静态字段 count，也不会在序列化中出现，并且在反序列化的时候，如果包含了 count 字段，会抛出未知参数的错误。

我们也可以用 @JsonIgnoreProperties 作用于类上面，来完成上面同样的功能，这个在需要忽略的字段是继承自父类的时候，就能有用武之地，因为这个时候没有相应的字段或方法可以注释。

Jackson 2 除了给出默认的同时忽略序列化和反序列化的行为，也给出了只忽略一个过程的选择。我们以忽略反序列化，不忽略序列化为例：

```
  @JsonProperty(access = WRITE_ONLY)
  private String password;
```

Jackson 的类库还有很多灵活的用法，不过这篇就只讨论到这了。