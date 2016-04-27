---
title: Spring Data JPA 笔记
date: 2015-12-08 14:14:56
permalink: 1449555296031
tags: Spring
---

traditional JDBC 太麻烦是因为要处理很多 SQLException，很多 boilerplate code，但它的操作比其他框架更底层。

Spring JDBC 所有的异常都继承自 DataAccessException，属于 unchecked exceptions。

Spring 采用 JDBC template 来去掉 boilerplate code (resource-management, exception-handling etc)，用户只需要写 SQL 语句和一些 mapping 的方法。

结合 Spring Security 可以处理 method level 的 access control。

Spring Data JPA 基本都是标准的 JPA(Java Persistence API)，底层是用 Hibernate 来实现的。持久化数据相关的最主要的两种类是：@Entity 和 @Repository 注解的 Class。

## 1. Entity

---

Entity 对应的是数据库中的表，使用 JPA 的话就需要通过配置 @Entity Class来完成 ORM 映射。

Entity 的简单设置：

```
@Entity
@Table(name = "post")
public class Post {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id")
  protected Long id;

  @Version
  @Column(name = "version")
  protected Integer version;

  @Temporal(value = TemporalType.TIMESTAMP)
  @Column(name = "created_at", nullable = false)
  protected Date createdAt;

  @Column(name = "title", nullable = false)
  protected String title;

  protected Post() {}

  // getters, setters
}
```

如果涉及到继承：

```
@MappedSuperclass
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
public abstract class Base implements Serializable {}

@Entity
@Table(name = "post")
public class Post extends Base {}
```

如果有多对一的单向关系：

```
public class BaseUGC {
  @ManyToOne(fetch = FetchType.EAGER)
  @JoinColumn(name = "user_id")
  @NotNull
  protected User user;
}
public class User {}
```

如果有多对一的双向关系：
```
public class Post {
  @OneToMany(
      mappedBy = "post",
      fetch = FetchType.EAGER,
      orphanRemoval = true,
      cascade = {CascadeType.PERSIST, CascadeType.MERGE})
  @JsonIgnore
  protected List<Comment> comments = new ArrayList<Comment>();
}

public class Comment {
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "post_id")
  @NotNull
  @JsonIgnore
  protected Post post;
}
```

如果有自己对自己的关系：

```
public class Comment {
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "parent_comment_id")
  @JsonBackReference
  protected Comment parent;

  @OneToMany(
      mappedBy = "parent",
      fetch = FetchType.EAGER,
      orphanRemoval = true,
      cascade = {CascadeType.PERSIST, CascadeType.MERGE})
  @JsonManagedReference
  protected List<Comment> children = new ArrayList<Comment>();
}
```

如果有多个 key 组成 PK，并且这些 keys 都是 class，譬如说 Join Table：

```
@Entity
@Table(name = "comment_vote", uniqueConstraints = {@UniqueConstraint(columnNames = {"user_id", "comment_id"})})
public class CommentVote extends BaseVote {
  @EmbeddedId
  private CommentVotePK commentVotePK;

  @ManyToOne(fetch = FetchType.LAZY)
  @MapsId(value = "userId")
  @JoinColumn(name = "user_id", referencedColumnName = "id", insertable = false, updatable = false)
  @NotNull
  @JsonIgnore
  private User user;

  @ManyToOne(fetch = FetchType.LAZY)
  @MapsId(value = "commentId")
  @JoinColumn(name = "comment_id", referencedColumnName = "id", insertable = false, updatable = false)
  @NotNull
  @JsonIgnore
  private Comment comment;
}

public class CommentVotePK implements Serializable {
  protected CommentVotePK() {
  }

  public CommentVotePK(Long userId, Long commentId) {
    this.userId = userId;
    this.commentId = commentId;
  }

  private Long userId;
  private Long commentId;

  @Override
  public boolean equals(Object o) {
    if (o == this) {
      return true;
    }
    if ((null == o) || (o.getClass() != getClass())) {
      return false;
    }
    final CommentVotePK cvPK = (CommentVotePK) o;
    return (cvPK.userId.equals(userId)) && (cvPK.commentId.equals(commentId));
  }

  @Override
  public int hashCode() {
    return new HashCodeBuilder()
        .append(userId)
        .append(commentId)
        .toHashCode();
  }

  public Long getUserId() {
    return userId;
  }
  public Long getCommentId() {
    return commentId;
  }
}
```

## 2. Repository

---

Repository 一般通过继承已有的接口来创建。以下最顶层的是基类，下层的是上层的继承：

- Repository
- CrudRepository
- PagingAndSortingRepository
- JpaRepository

这些接口已经实现了 count, delete, remove 等操作，我们可以在此基础上衍生出：

- countByLastname
- deleteByLastname
- removeByLastname

CrudRepository 会暴露所有的 CRUD 的操作，可以考虑 Repository 基类接口，然后 copy 一些 method 来限制可以进行的操作。

如果自定义一些只是用来继承的接口，可以添加 @NoRepositoryBean。

JPA 中可以用 @Query 来定义一些无法通过 method name 描述的操作。

如果 @Query 也不能描述一些复杂操作，可以实现一个 Impl 后缀的 Repository 来调用 EntityManager，进而实现更复杂的操作。

### 创建查询方法

常用的关键词：

1. strips the prefixes find…By, read…By, query…By, count…By, and get…By
2. And and Or: findByEmailAddressAndLastname
3. IgnoreCase, AllIgnoreCase: findByLastnameIgnoreCase, findByLastnameAndFirstnameAllIgnoreCase
4. OrderByXXXAsc, OrderByXXXDesc: findByLastnameOrderByFirstnameAsc
5. first, top: findFirstByOrderByLastnameAsc, queryFirst10ByLastname, findTop3ByLastname
6. Distinct: findDistinctPeopleByLastnameOrFirstname

如果要检索 Person.address.zipCode，要这样定义：`List<Person> findByAddressZipCode(ZipCode zipCode);`

如果上面的分词分错了，譬如：AddressZip, Code，可以用 findByAddress_ZipCode 来强制分词，但不建议这样做，不符合 Java 的代码风格

可以用 Java 8 的 Stream<T>，譬如：

```
try (Stream<User> stream = repository.findAllByCustomQueryAndStream()) {
  stream.forEach(…);
}
```

Async query 也是支持的：

```
@Async
Future<User> findByFirstname(String firstname);

@Async
CompletableFuture<User> findOneByFirstname(String firstname);

@Async
ListenableFuture<User> findOneByLastname(String lastname);
```

### 一些查询方法的例子

Repository 的最简单设置，用继承的`findOne`, `findAll`, `save`等操作：

```
@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {}
```

用约定的函数名生成数据库操作函数：
```
@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {
  List<Comment> findByUser(User user);
}
```

在 Entity 头部定义 @NamedQuery， 然后在 Repository 里调用

```
@Entity
@NamedQueries(value = {
    @NamedQuery(name = "Comment.findRootsByPost",
        query = "SELECT c FROM Comment c WHERE c.parent IS NULL AND c.post = ?1")
})
@Table(name = "comment")
public class Comment {}

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {
  List<Comment> findRootsByPost(Post post);
}
```

用 @PrePersist、@PreUpdate 等自动触发一些 Table 内部的操作

```
@MappedSuperclass
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
public abstract class Base implements Serializable {
  @Temporal(value = TemporalType.TIMESTAMP)
  @Column(name = "created_at", nullable = false)
  protected Date createdAt;

  @Temporal(value = TemporalType.TIMESTAMP)
  @Column(name = "updated_at", nullable = false)
  protected Date updatedAt;

  @PrePersist
  private void onPrePersist() {
    Date now = new Date();
    this.createdAt = now;
    this.updatedAt = now;
  }

  @PreUpdate
  private void onPreUpdate() {
    this.updatedAt = new Date();
  }
}
```

更复杂的，跨越多个表的可以定义成 Service，并且标记为事务：

```
@Service
public class RepositoryService {
  private final PostRepository postRepository;
  private final CommentRepository commentRepository;

  @Autowired
  public RepositoryService(PostRepository postRepository, CommentRepository commentRepository) {
    this.postRepository = postRepository;
    this.commentRepository = commentRepository;
  }

  @Transactional
  public void saveCommentAndUpdateCommentCount(Comment comment) {
    Post post = postRepository.findOne(comment.getPost().getId());
    post.increaseCommentCount();
    postRepository.save(post);
    commentRepository.save(comment);
  }
}
```




