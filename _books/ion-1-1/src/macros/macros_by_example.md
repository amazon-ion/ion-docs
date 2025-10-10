# Macros by example

Before getting into the technical details of Ion's macro and module system, it will help to be more
familiar with the _use_ of macros. We'll step through increasingly sophisticated use cases, some
admittedly synthetic for illustrative purposes, with the intent of teaching the core concepts and
moving parts without getting into the weeds of more formal specification.

Ion macros are defined using Ion data structures to represent their templates, plus _placeholders_.
In this document, the fundamental construct we explore is the _macro 
definition_, denoted using an S-expression of the form `(name template)` where `name` must be a 
symbol denoting the macro's name.

NOTE: Macros can only be defined within directives like `set_macros` or `add_macros`, or within
[modules](../modules.md). We will mostly omit this context in the examples below to keep things simple.


## Constants

The most basic macro is a constant:

```ion
(pi 3.141592653589793)
```

This declaration defines a macro named `pi`. The `3.141592653589793` is the _template_ - just a 
plain Ion decimal value. Since there are no placeholders in the template, this macro accepts no 
arguments and always returns a constant value.

To use `pi` in an Ion document, we write an _encoding expression_ or _E-expression_:

```ion
$ion_1_1
(:pi)
```

The syntax `(:pi)` looks a lot like an S-expression. It's not, though, since colons
cannot appear unquoted in that context. Ion 1.1 makes use of syntax that is not valid in Ion
1.0—specifically, the `(:` digraph—to denote E-expressions. Those characters must be followed by
a reference to a macro, and we say that the E-expression is an invocation of the macro. Here,
`(:pi)` is an invocation of the macro named `pi`.

That document is equivalent to the following, in the sense that they denote the same data:

```ion
$ion_1_1
3.141592653589793
```

The process by which the Ion implementation turns the former document into the latter is called
_macro expansion_ or just _expansion_. This happens transparently to
Ion-consuming applications: the stream of values in both cases are the same. The documents have
the same content, encoded in two different ways. It's reasonable to think of `(:pi)` as a custom
encoding for `3.141592653589793`, and the notation's similarity to S-expressions leads us to the
term "encoding expression" (or "e-expression").

> [!NOTE]
> Any Ion 1.1 document with macros can be fully expanded into an equivalent Ion 1.0 document.

We can streamline future examples with a couple of conventions. First, assume that any E-expression
is occurring within an Ion 1.1 document; second, we use the relation notation, `⇒`, to mean "expands to".
So we can say:

```ion
(:pi) ⇒ 3.141592653589793
```

## Placeholders

Most macros are not constant—they accept inputs that determine their results.

```ion
(wrap_value {value: (:?)})
```

This macro has a template that is a struct containing a single placeholder `(:?)`. The placeholder indicates
that the macro accepts one argument. When invoked, the placeholder is replaced with the argument value.
Note that a template cannot consist solely of a placeholder (annotated or unannotated) - it must be wrapped in a container or have other content.

```ion
(:wrap_value 1)         => {value: 1}
(:wrap_value "foo")     => {value: "foo"}
(:wrap_value [a, b, c]) => {value: [a, b, c]}
```

The `(:?)` is a _tagged placeholder_ - it accepts any Ion value including nulls and annotated values.

## Simple Templates

Here's a more realistic macro:

```ion
(price { amount: (:?), currency: (:?) })
```

This macro's template is a struct with two placeholders. The macro therefore accepts two arguments when invoked.

```ion
(:price 99 USD) ⇒ { amount: 99, currency: USD }
```

Template expressions that are structs are interpreted _almost_ literally;
the field names are literal—which is why the `amount` and `currency` field names show up as-is in the expansion—but the field values may contain placeholders.

Templates also treat lists quasi-literally, where each element inside the list may be a literal value or a placeholder.
Here's a simple macro to illustrate:

```ion
(two_item_list [(:?), (:?)])
```
```ion
(:two_item_list foo bar) ⇒ [foo, bar]
```

E-expressions can accept other e-expressions as arguments. For example:

```ion
(:two_item_list (:price 99 USD) foo)
//              └──────┬──────┘
//                     └─── passing another e-expression as an argument
```

Expansion happens from the "inside out".
The outer e-expression receives the results from the expansion of the inner e-expression.

```ion
(:two_item_list (:price 99 USD) foo)

  // First, the inner invocation of `price` is expanded...
  => (:two_item_list {amount: 99, currency: USD} foo)

  // ...and then the outer invocation of `two_item_list` is expanded.
  => [{amount: 99, currency: USD}, foo]
```

## Default Values

Tagged placeholders can provide default values that are used when no argument is provided:

```ion
(temperature {
  degrees: (:?),
  scale: (:? K)  // Default value is K
})
```

When invoking this macro, you can omit the second argument by passing `(:)` (which means "no argument"):

```ion
(:temperature 96 F)   ⇒ {degrees: 96, scale: F}
(:temperature 283 (:)) ⇒ {degrees: 283, scale: K}
```

Note that when no value is provided for the `scale` placeholder, it uses the default value `K`.

## E-expressions in Templates

Templates can contain E-expressions, which are expanded when the macro is defined, not when it's invoked.
This allows you to use previously defined macros to construct your template.

```ion
(:$ion set_macros (prefix_suffix [(:?), (:?)]))
(:$ion add_macros (website_url (:prefix_suffix "https://www.amazon.com/" (:?))))
```

The `website_url` macro's template contains an E-expression `(:prefix_suffix ...)` which is
expanded when the macro is defined.

For example:

```ion
(:$ion add_macros (website_url (:prefix_suffix "https://www.amazon.com/" (:?))))
  ⇒ (:$ion add_macros (website_url ["https://www.amazon.com/", (:?)]))
```

```ion
(:website_url "gp/cart") ⇒ ["https://www.amazon.com/", "gp/cart"]
```

## Tagless Placeholders

In addition to tagged placeholders, Ion 1.1 supports _tagless placeholders_ that specify a
particular type. These are more restrictive but enable more compact binary encoding.

```ion
(point {x: (:?\int\), y: (:?\int\)})
```

This macro uses tagless placeholders that require integer arguments. The `\int\` is a type marker
indicating the placeholder expects an integer value.

```ion
(:point 3 17) ⇒ {x: 3, y: 17}
```

Tagless placeholders have important restrictions:
- They cannot accept null values
- They cannot accept annotated values
- They cannot be omitted (they're always required)
- Arguments must match the specified type

```ion
(:point null.int 17)   ⇒ // Error: tagless int does not accept nulls
(:point a::3 17)       ⇒ // Error: tagless int does not accept annotations
(:point (:) 17)        ⇒ // Error: tagless parameters cannot be omitted
```

While Ion text syntax doesn’t use tags—the types are built into the syntax—these errors ensure
that a text E-expression may only express things that can also be expressed using an equivalent
binary E-expression.

Tagless encodings have no real benefit in text, as primitive types aim to improve the binary
encoding.

This density comes at the cost of flexibility. Primitive types cannot be annotated or null, and
arguments cannot be expressed using macros.

See [tagless_encodings](todo.md) for the complete list of tagless types.

## Annotated Macros

Macros can be annotated, which causes the expanded value to have that annotation
prepended to any annotations present on the expanded value.

```ion
(bar [bar])
(foobar foo::[bar])
```

```ion
baz::(:bar) ⇒ baz::[bar]
baz::(:foobar) ⇒ baz::foo::[bar]
```

## Annotated Placeholders

Placeholders can be annotated, which causes the expanded value to have that annotation prepended to any existing annotations.

```ion
(annotated_value [foo::(:?)])
```

```ion
(:annotated_value 42) ⇒ [foo::42]
(:annotated_value bar::42) ⇒ [foo::bar::42]
```


## Argument Evaluation

It's important to understand that arguments to macros are always single Ion values. Even if an argument is a collection (like a list or struct), it's passed as a single value and inserted into the template as-is.

When an E-expression is used as an argument, it is fully expanded before being passed to the macro. The macro receives the result of that expansion, which must be a single Ion value.

```ion
(:$ion set_macros
  (wrap_in_list [(:?)])
  (struct_constant {x: 1, y: 2})
)
```

```ion
(:wrap_in_list (:struct_constant)) ⇒ [{x: 1, y: 2}]
```

In this example, `(:struct_constant)` is expanded first to produce `{x: 1, y: 2}`, and then that single struct value is passed to `wrap_in_list`, which wraps it in a list.

## E-expressions in Templates

E-expressions can appear in template definitions, but they are expanded when the macro is defined, not when it's invoked. Additionally, E-expressions may only appear in value position - they cannot appear in field name position in structs.

```ion
(:$ion set_macros
  (base_config {type: "standard", size: 100})
  // The following would be an error:
  // (extended_config {
  //   (:base_config),  // ERROR: E-expressions cannot appear in field position
  //   extra: true
  // })
)
```

## Directives

Ion 1.1 includes built-in directives for managing the encoding context. These directives
produce system values (not user-visible values) and can only appear at the top level of a stream. See [directives](../modules/directives.md).
