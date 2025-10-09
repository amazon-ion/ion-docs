---
redirect_from: "/boundaries.html"
title: Token Boundaries in Ion Text
description: "Details regarding how Ion text is tokenized and where values are split in cases where no whitespace is used between them."
---

# [Docs][docs]/ {{ page.title }}

Ion text values are best separated by explicit whitespace (space, horizontal tab, vertical tab, line feed, carriage return, form feed, and comments). However, the specification defines circumstances in which it is acceptable for values to appear immediately adjacent to each other.

In general, Ion text values can appear adjacent to each other when the boundary between the values is unambiguous. The boundaries between quoted symbols, double-quoted strings, triple-quoted strings, lobs, structs, lists, and S-expressions are unambiguous, so these elements can appear adjacent to one another in Ion text:

```ion
{% raw %}
// A valid Ion data stream
(1)[2]{a:struct}'hello'"world"{{ SSBsb3ZlIElvbiE= }}{{ "Same with clob" }}'annotations too!'::123
{% endraw %}
```

Additionally, any value can appear immediately *after* a value of these types, including numeric values, keywords, and identifiers.

Container separators delimit values unambiguously, so any value can also appear adjacent to a container boundary: 

```ion
// Some valid, compact containers
[1,2,"three"]
{name:"Austin",message:"Hello world!"}
```

Indentifiers (unquoted symbols) and reserved keywords (`null` and its typed variants, `true`, `false`, `nan`, `-inf`, and `+inf`) are terminated by the first non-identifier character encountered. The identifier characters are ASCII letters, digits, or the characters `$` (dollar sign) or `_` (underscore). This allows symbols to contain a reserved keyword as a prefix:

```ion
// All single symbols, even when prefixed by a keyword
trueSymbol
null123
nanfalse
```

This means that any value that begins with a non-identifier character can appear immediately after an identifier or reserved keyword:

```ion
// All valid pairs of two top-level values
abc-5
symbol["And a list"]
anotherOne'andAnother'
true(story)
null.float+inf
```

Typed nulls and `+/-inf` do not form valid Ion if not followed by a non-identifier character:

```ion
null.struct5E10      // ERROR: not a valid Ion value - struct5E10 is a bad null decorator
+inftrue             // ERROR: this also is invalid
```

## Numeric stop-characters

Ion text enforces stricter rules on certain "numeric" types. Ion text enforces that integers, real values (decimals and floats, excluding the special float values `nan`, `-inf`, and `+inf`), and timestamps must be followed by one of the following 15 numeric stop-characters: `{}[](),"' \t\n\r\v\f`.

This means that strings, quoted symbols, lobs, structs, lists, and S-expressions can appear immediately after a numeric or timestamp value in a top-level datagram or S-expression:

```ion
// All of this is valid Ion
123{a: "struct"}456
-0.5[a, list]
5.34e9"then a string"
0xdeadbeef'hello'::world
[1,2,3]
(1["list"]2000T{a: "struct"}0b010101("sexp")4)
```

Anything that is not a numeric stop-character appearing immediately after a numeric or timestamp value is a syntax error. This notably includes comments and S-expression operators:

```ion
123// a comment              // ERROR: single-line comment is not a valid numeric stop
5D3/* block this time */     // ERROR: block comment also cannot act as numeric stop
(10-.5*3)                    // ERROR: operators in an S-expression cannot act as numeric stop
(2007-01-01T~2007-12-31T)    // ERROR: same goes for timestamps
```

## Associativity of + and - in S-expressions

`+` and `-` can have two meanings in S-expressions based on context, either as operators or prefixes to a numeric value. If a minus or plus sign appears without another operator symbol immediately preceding it and the value immediately following is an integer or real number (for minus), or `inf` (for either), then the sign binds to the following value rather than acting as an operator symbol. For example, the following S-expressions all contain exactly 2 values:

<!--
    NOTE: this behavior is currently not upheld in most implementations, particularly with +/-inf followed by an operator with no whitespace.
    Try (+inf+inf) vs (+inf +inf) in ion cli.
-->

```ion
// These S-expressions all have two elements
// The sign binds to the following value
(1 -2)
(+inf -.5E3)
(nan-inf)
(+inf-0)
(-16D-3 +inf)
```

The following S-expressions, on the other hand, all contain 3 values, one of which is an operator symbol:

```ion
(1 --123)       // minus sign is immediately preceded by another operator symbol character
(1 *+inf)       // plus sign is immediately preceded by another operator symbol character
(1 -2000T)      // minus sign cannot bind to a timestamp
(1 +infx)       // +infx is not positive infinity, this is an operator and a symbol
```

To use an operator before a token that begins with `+` or `-`, use whitespace around the operator:

```ion
(10 + -6 = 4)
```

It is recommended that you always use explicit whitespace around operators in S-expressions to avoid confusing operator associativity.

<!-- references -->
[docs]: {{ site.baseurl }}/docs.html
