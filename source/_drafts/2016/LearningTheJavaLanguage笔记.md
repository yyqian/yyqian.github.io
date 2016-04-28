---
title: Learning the Java Language 笔记
tags: Java
---

## Language Basics

Hiding internal state and requiring all interaction to be performed through an object's methods is known as **data encapsulation**

Keywords: object, class, inheritance, interface, type, package, superclass, subclass, primitive, literal

Object：

- Method(behavior)
- Field(state)

四种 Variables 的形式：

- Instance Variables (Non-Static Fields)
- Class Variables (Static Fields)
- Local Variables
- Parameters

Fields 的指代一般不包括 Local Variables 和 Parameters。Fields 可以被初始化为默认值，而其他两种 Variables 不可以。Local Variables 不初始化就不能通过编译。

### Primitives

八种 primitives：

- byte(8-bit), short(16-bit), int(32-bit), long(64-bit)
- float(32-bit), double(64-bit)
- boolean
- char: 16-bit Unicode character

Fields 的默认值：

- 各种数值：0
- char：\u0000
- Object：null
- boolean：false

Literals:

- 16进制：0x1a
- 2进制：0b11010
- long：123L
- double：123.4、123.4d、123.4D
- float：123.4f、123.4F
- 科学计数（double）：1.234e2


### Array

Declaring: `int[] anArray;`

Creating: `anArray = new int[10];`

Initializing:

```
int[] anArray = {
    100, 200, 300,
    400, 500, 600,
    700, 800, 900, 1000
};
```

java.util.Arrays 有一些有用的工具：

- copyOfRange
- binarySearch
- equals
- fill
- sort
- parallelSort

Array 的长度在 creation 之后就定下了。

### Operators

- `%` Remainder
- `instanceof` use it to test if an object is an instance of a class, an instance of a subclass, or an instance of a class that implements a particular interface.
- `?:` Ternary (shorthand for if-then-else statement)
- bitwise: `& ^ | << >> >>> ~`
- logical: `! < > <= >= && ||`

### Expressions, Statements, and Blocks.

- Operators may be used in building expressions, which compute values.
- Expressions are the core components of statements.
- Statements may be grouped into blocks.

switch 支持：

- byte, short, int, char
- Byte, Short, Integer, Character
- Enum Types
- String

switch 要注意 break 的使用，否则代码流会 fall through

## Classes and Objects

The compiler automatically provides a no-argument, default constructor for any class without constructors.

Primitive arguments are passed into methods by value.

Reference data type parameters, such as objects, are also passed into methods by value. However, the values of the object's fields can be changed in the method, if they have the proper access level.

Access Levels:

- protected: Package, Subclass
- no modifier: Package

A common use for static methods is to access static fields.

Class methods cannot access instance variables or instance methods directly

Static Initialization Blocks:

```
static {
    // whatever code is needed for initialization goes here
}

class Whatever {
    public static varType myVar = initializeClassVariable();

    private static varType initializeClassVariable() {

        // initialization code goes here
    }
}
```

### Nested Classes

Nested classes:

- Static nested classes
- Non-static nested classes (inner classes)

Non-static nested classes have access to other members of the enclosing class, even if they are declared private. Static nested classes do not have access to other members of the enclosing class.

a static nested class cannot refer directly to instance variables or methods defined in its enclosing class: it can use them only through an object reference.

To instantiate an inner class, you must first instantiate the outer class. Then, create the inner object within the outer object with this syntax:

```
OuterClass.InnerClass innerObject = outerObject.new InnerClass();
```

在 inner class 中访问自身的 fields，可以用 this.x；在 inner class 中访问外层的 outter class 的 field，需要用 Outter.this.y

Local Classes, Anonymous Classes 是两种更特殊的 Nested Classes

### Lambda Expressions & Method References

```
public static <X, Y> void processElements(
    Iterable<X> source,
    Predicate<X> tester,
    Function <X, Y> mapper,
    Consumer<Y> block) {
    for (X p : source) {
        if (tester.test(p)) {
            Y data = mapper.apply(p);
            block.accept(data);
        }
    }
}

processElements(
    roster,
    p -> p.getGender() == Person.Sex.MALE
        && p.getAge() >= 18
        && p.getAge() <= 25,
    p -> p.getEmailAddress(),
    email -> System.out.println(email)
);
```

Use Aggregate Operations:

```
roster
    .stream()
    .filter(
        p -> p.getGender() == Person.Sex.MALE
            && p.getAge() >= 18
            && p.getAge() <= 25)
    .map(p -> p.getEmailAddress())
    .forEach(email -> System.out.println(email));
```

- filter 接受 Predicate 参数
- map 接受 Function 参数
- forEach 接受 Consumer 参数

You can omit the data type of the parameters in a lambda expression. In addition, you can omit the parentheses if there is only one parameter.

If you specify a single expression, then the Java runtime evaluates the expression and then returns its value. Alternatively, you can use a return statement:

```
p -> {
    return p.getGender() == Person.Sex.MALE
        && p.getAge() >= 18
        && p.getAge() <= 25;
}
```

Kinds of Method References:

- Reference to a static method: `ContainingClass::staticMethodName`
- Reference to an instance method of a particular object: `containingObject::instanceMethodName`
- Reference to an instance method of an arbitrary object of a particular type: `ContainingType::methodName`
- Reference to a constructor: `ClassName::new`

## Annotations

define annotation type:

```
/**
 * To make the information in @ClassPreamble appear in
 * Javadoc-generated documentation, you must annotate the
 * @ClassPreamble definition with the @Documented
 * annotation
 **/

@Documented
@interface ClassPreamble {
   String author();
   String date();
   int currentRevision() default 1;
   String lastModified() default "N/A";
   String lastModifiedBy() default "N/A";
   // Note use of array
   String[] reviewers();
}
```

use annotations:

```
@ClassPreamble (
   author = "John Doe",
   date = "3/17/2002",
   currentRevision = 6,
   lastModified = "4/12/2004",
   lastModifiedBy = "Jane Doe",
   // Note array notation
   reviewers = {"Alice", "Bob", "Cindy"}
)
public class Generation3List extends Generation2List {

// class code goes here

}
```

Predefined Annotation Types:

- @Deprecated
- @Override
- @SuppressWarnings
- @SafeVarargs
- @FunctionalInterface

meta-annotations:

- @Retention:
	- SOURCE: retained only in the source level and is ignored by the compiler.
	- CLASS: retained by the compiler at compile time, but is ignored by the JVM
	- RUNTIME: retained by the JVM so it can be used by the runtime environment
- @Documented
- @Target:
	- ANNOTATION_TYPE
	- CONSTRUCTOR
	- FIELD
	- LOCAL_VARIABLE
	- METHOD
	- PACKAGE
	- PARAMETER
	- TYPE: can be applied to any element of a class
- @Inherited: indicates that the annotation type can be inherited from the super class
- @Repeatable: check [this](http://docs.oracle.com/javase/tutorial/java/annotations/repeating.html)

## Interface

All abstract, default, and static methods in an interface are implicitly public.

All constant values defined in an interface are implicitly public, static, and final.

**Default Methods**:

```
public interface DoIt {

   void doSomething(int i, double x);
   int doSomethingElse(String s);
   default boolean didItWork(int i, double x, String s) {
       // Method body
       // 如果这个 method 是之后添加的，就不需要更改之前实现的 Class， 因为它们有了默认的实现
   }

}
```

**Static Methods**:

A static method is a method that is associated with the class in which it is defined rather than with any object. Every instance of the class shares its static methods.

This makes it easier for you to organize helper methods in your libraries; you can keep static methods specific to an interface in the same interface rather than in a separate class.

```
public interface TimeClient {
    // ...
    static public ZoneId getZoneId (String zoneString) {
        try {
            return ZoneId.of(zoneString);
        } catch (DateTimeException e) {
            System.err.println("Invalid time zone: " + zoneString +
                "; using default time zone instead.");
            return ZoneId.systemDefault();
        }
    }

    default public ZonedDateTime getZonedDateTime(String zoneString) {
        return ZonedDateTime.of(getLocalDateTime(), getZoneId(zoneString));
    }
}
```

## Inheritance

A subclass inherits all of the public and protected members of its parent, no matter what package the subclass is in. If the subclass is in the same package as its parent, it also inherits the package-private members of the parent.

A subclass does not inherit the private members of its parent class. However, if the superclass has public or protected methods for accessing its private fields, these can also be used by the subclass.

A nested class has access to all the private members of its enclosing class—both fields and methods. Therefore, a public or protected nested class inherited by a subclass has indirect access to all of the private members of the superclass.

Java 不支持 extends multiple classes 的原因是：避免 the issues of multiple inheritance of state。而允许实现多个 interfaces 的原因是 interface 没有 state。

Java 支持 multiple inheritance of type：An object can have multiple types: the type of its own class and the types of all the interfaces that the class implements.

子类可以用同样的 Instance Method 来 Override 父类的 Instance Method

也可以用同样的 Static Method 来 Hide 父类的 Static Method

| | Superclass Instance Method | Superclass Static Method |
| ------------- |:------------- | :-----|
| Subclass Instance Method | Overrides | Generates a compile-time error |
| Subclass Static Method | Generates a compile-time error | Hides |

### Polymorphism

举例来说：

```
public class TestBikes {
  public static void main(String[] args){
    Bicycle bike01, bike02, bike03;

    bike01 = new Bicycle(20, 10, 1);
    bike02 = new MountainBike(20, 10, 5, "Dual");
    bike03 = new RoadBike(40, 20, 8, 23);

    bike01.printDescription();
    bike02.printDescription();
    bike03.printDescription();
  }
}
```

bike02 和 bike03 的 type 虽然都是 Bicycle，但是在调用 printDescription 方法的时候，分别是调用的 MountainBike 和 RoadBike 类中覆盖的方法，所以同一个 type 表现出不同的行为。但要注意这里的方法是 Instace Method，不适用于 Static Method，实例的实际类型是运行时决定的，但 variable 的 type 在编译时就定了。

子类可以 hide 父类的 field，只要 name 相同就可以，但是强烈不建议这么做。

If a constructor does not explicitly invoke a superclass constructor, the Java compiler automatically inserts a call to the no-argument constructor of the superclass. If the super class does not have a no-argument constructor, you will get a compile-time error. Object does have such a constructor, so if Object is the only superclass, there is no problem.

If a subclass constructor invokes a constructor of its superclass, either explicitly or implicitly, you might think that there will be a whole chain of constructors called, all the way back to the constructor of Object. In fact, this is the case. It is called constructor chaining, and you need to be aware of it when there is a long line of class descent.

### Object

Object 有以下常用的方法：

- protected Object clone() throws CloneNotSupportedException
- public boolean equals(Object obj)
- public final Class getClass()
- public int hashCode()
- public String toString()

实现 clone() 最简单的办法就是实现 Cloneable 接口，但是如果这个 object 还有外部 object 的引用，就不能用这个简单的办法，需要自己去实现 clone() 方法，把这个引用 decouple

You should always override the equals() method if the identity operator is not appropriate for your class.

You cannot override getClass.

The value returned by hashCode() is the object's hash code, which is the object's memory address in hexadecimal.

By definition, if two objects are equal, their hash code must also be equal. If you override the equals() method, you change the way two objects are equated and Object's implementation of hashCode() is no longer valid. Therefore, if you override the equals() method, you must also override the hashCode() method as well.

You should always consider overriding the toString() method in your classes.

### Final Classes and Methods

You use the final keyword in a method declaration to indicate that the method cannot be overridden by subclasses.

Methods called from constructors should generally be declared final. If a constructor calls a non-final method, a subclass may redefine that method with surprising or undesirable results.

You can also declare an entire class final. A class that is declared final cannot be subclassed. This is particularly useful, for example, when creating an immutable class like the String class.

### Abstract Methods and Classes

Abstract classes are similar to interfaces. You cannot instantiate them, and they may contain a mix of methods declared with or without an implementation. However, with abstract classes, you can declare fields that are not static and final, and define public, protected, and private concrete methods. With interfaces, all fields are automatically public, static, and final, and all methods that you declare or define (as default methods) are public. In addition, you can extend only one class, whether or not it is abstract, whereas you can implement any number of interfaces.

## Numbers

所有的 Wrapper Class 都继承自 Number Class。

Number 类有 MIN_VALUE 和 MAX_VALUE 两个 field，还有一系列方法：

- xxxValue
- compareTo
- equals

Number 还有很多 Number 和 String 转换的方法。

Formatting numbers 的工具有：

- System.out.format 方法
- java.text.DecimalFormat 对象

java.lang.Math 有很多用于数学计算的静态方法。

还有一个生成伪随机数的 Math.random() 方法，取值范围是 [0.0, 1.0)。这个方法只适用于产生单次的随机数，如果要生成一系列随机数，要使用 java.util.Random 对象。

## Character

 The Character class is immutable, so that once it is created, a Character object cannot be changed.

 Character 常用的一些方法：

 - isLetter, isDigit
 - isWhitespace
 - isUpperCase, isLowerCase
 - toUpperCase, toLowerCase
 - toString

 常用的 Escape Sequences：

 - `\t`
 - `\n`
 - `\'`
 - `\"`
 - `\\`

## String

Most commonly, you create a string with a statement like `String s = "Hello world!";` rather than using one of the String constructors.

The String class is immutable, so that once it is created a String object cannot be changed. The String class has a number of methods, that appear to modify strings. Since strings are immutable, what these methods really do is create and return a new string that contains the result of the operation.

String 常用的方法：

- length
- charAt
- getChars
- concat
- substring
- split
- trim
- toLowerCase, toUpperCase
- indexOf, lastIndexOf
- contains
- replace, replaceAll, replaceFirst

可以用 parseXXXX() 和 valueOf() 来将 String 转换为 Number，前者返回基本类型，后者返回对象

Number to String 有几种方法：

- String s1 = "" + i;
- String s2 = String.valueOf(i);
- String s3 = Integer.toString(i);

String 用于比较的方法有：

- endsWith, startsWith
- compareTo, compareToIgnoreCase
- equals, equalsIgnoreCase
- regionMatches
- matches

StringBuilder 在连接大量字符串时有性能优势，也有一些特有的方法：reverse, append, delete, insert, replace, setCharAt

A string can be converted to a string builder using a StringBuilder constructor. A string builder can be converted to a string with the toString() method.

## Generics

最常用的 type 参数:

E - Element (used extensively by the Java Collections Framework)
K - Key
N - Number
T - Type
V - Value
S,U,V etc. - 2nd, 3rd, 4th types

Java 7 之后可以使用 Diamond <>：

`Box<Integer> integerBox = new Box<>();`

Generic Type: `class name<T1, T2, ..., Tn> {}`

Generic Method:

```
public class Util {
    public static <K, V> boolean compare(Pair<K, V> p1, Pair<K, V> p2) {
        return p1.getKey().equals(p2.getKey()) &&
               p1.getValue().equals(p2.getValue());
    }
}

boolean same = Util.<Integer, String>compare(p1, p2);
```

Type Inference:

- Diamond
- `List<String> listOne = Collections.<String>emptyList();` 可以简写为 `List<String> listOne = Collections.emptyList();`

Although Integer is a subtype of Number, List<Integer> is not a subtype of List<Number> and, in fact, these two types are not related. The common parent of List<Number> and List<Integer> is List<?>.

![Screen Shot 2016-04-18 at 9.17.28 PM.png](http://cdn.yyqian.com/201604182117-Fv4qTsUtj-JgqEo73UqQX4yEeKDO?imageView2/2/w/800/h/600)

![Screen Shot 2016-04-18 at 9.19.28 PM.png](http://cdn.yyqian.com/201604182119-Fk6k83eufioiSZsvLWcULdp3bQSJ?imageView2/2/w/800/h/600)

### Guidelines for Wildcard Use

- An "in" variable is defined with an upper bounded wildcard, using the extends keyword.
- An "out" variable is defined with a lower bounded wildcard, using the super keyword.
- In the case where the "in" variable can be accessed using methods defined in the Object class, use an unbounded wildcard.
- In the case where the code needs to access the variable as both an "in" and an "out" variable, do not use a wildcard.

These guidelines do not apply to a method's return type. Using a wildcard as a return type should be avoided because it forces programmers using the code to deal with wildcards.

### Restrictions on Generics

- Cannot Create Instances of Type Parameters
- Cannot Declare Static Fields Whose Types are Type Parameters
- Cannot Use Casts or instanceof with Parameterized Types
- Cannot Create Arrays of Parameterized Types

## Package

![Screen Shot 2016-04-18 at 10.06.48 PM.png](http://cdn.yyqian.com/201604182206-Fg9ayMdAdb-6--lcnzjPfk4KDLI_?imageView2/2/w/800/h/600)

