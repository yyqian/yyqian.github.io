---
title: Google Java Style 摘录
date: 2015-11-24 16:35:39
permalink: 1448354139006
tags: Java
---

File encoding: UTF-8

the ASCII horizontal space character (0x20) is the only whitespace character that appears anywhere in a source file. No Tab!

non-ASCII characters depending only on which makes the code easier to read and understand.

A source file consists of in order:

1. License or copyright information, if present
2. Package statement
3. Import statements
4. Exactly one top-level class
<!-- more -->
Exactly one blank line separates each section that is present.

The package statement, import statements are not line-wrapped

No wildcard imports

Import statements are divided into the following groups, in this order, with each group separated by a single blank line:

1. All static imports in a single group
2. com.google imports (only if this source file is in the com.google package space)
3. Third-party imports, one group per top-level package, in ASCII sort order
4. java imports
5. javax imports

Within a group there are no blank lines, and the imported names appear in ASCII sort order.

Exactly one top-level class declaration

Braces are used with if, else, for, do and while statements, even when the body is empty or contains only a single statement.

K & R style:

- No line break before the opening brace.
- Line break after the opening brace.
- Line break before the closing brace.
- Line break after the closing brace if that brace terminates a statement or the body of a method, constructor or named class. For example, there is no line break after the brace if it is followed by else or a comma.

An empty block or block-like construct may be closed immediately after it is opened, with no characters or line break in between ({}), unless it is part of a multi-block statement (one that directly contains multiple blocks: if/else-if/else or try/catch/finally).

Block indentation: +2 spaces

Column limit: 80 or 100

Indent continuation lines at least +4 spaces

A single blank line appears:

1. Between consecutive members (or initializers) of a class: fields, constructors, methods, nested classes, static initializers, instance initializers.
2. Within method bodies, as needed to create logical groupings of statements.
3. Optionally before the first member or after the last member of the class (neither encouraged nor discouraged).

An enum class with no methods and no documentation on its constants may optionally be formatted as if it were an array initializer:

```java
private enum Suit { CLUBS, HEARTS, SPADES, DIAMONDS }
```

One variable per declaration

Declared when needed, initialized as soon as possible

No C-style array declarations: The square brackets form a part of the type, not the variable: String[] args, not String args[].

Annotations applying to a class, method or constructor appear immediately after the documentation block, and each annotation is listed on a line of its own. Example:

```java
@Override
@Nullable
public String getNameIfPresent() { ... }
```

Annotations applying to a field also appear immediately after the documentation block, but in this case, multiple annotations (possibly parameterized) may be listed on the same line; for example:

```java
@Partial @Mock DataLoader loader;
```

Comments

```java
    /*
     * This is          // And so           /* Or you can
     * okay.            // is this.          * even do this. */
     */
```

Class and member modifiers, when present, appear in the order recommended by the Java Language Specification:

```java
public protected private abstract static final transient volatile synchronized native strictfp
```

long-valued integer literals use an uppercase L suffix, never lowercase

Package names are all lowercase, with consecutive words simply concatenated together (no underscores). For example,

    com.example.deepspace, not com.example.deepSpace or com.example.deep_space.

Class names are written in UpperCamelCase.

Method names, Non-constant field names, Parameter names, Local variable names are written in lowerCamelCase.

Constant names use CONSTANT_CASE: all uppercase letters, with words separated by underscores.

@Override: always used

Caught exceptions: not ignored

Static members: qualified using class

Finalizers: not used

> Don't do it. If you absolutely must, first read and understand Effective Java Item 7, "Avoid Finalizers," very carefully, and then don't do it.

A method or constructor name stays attached to the open parenthesis (() that follows it.
