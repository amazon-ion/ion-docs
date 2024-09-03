# Macros by example

Before getting into the technical details of Ion’s macro and module system, it will help to be more
familiar with the _use_ of macros. We’ll step through increasingly sophisticated use cases, some
admittedly synthetic for illustrative purposes, with the intent of teaching the core concepts and
moving parts without getting into the weeds of more formal specification.

Ion macros are defined using a domain-specific language that is in turn expressed via the Ion
data model. That is, macro definitions are Ion data, and use Ion features like S-expressions and
symbols to represent code in a Lisp-like fashion. In this document, the fundamental construct we
explore is the _macro definition_, denoted using an S-expression of the form `(macro name …)`
where `macro` is a keyword and `name` must be a symbol denoting the macro's name.

NOTE: S-expressions of that shape only declare macros when they occur in the context of an encoding
module, which is the topic of a chapter to come. We will completely ignore modules for now, and
the examples below omit this context to keep things simple.


## Constants

The most basic macro is a constant:


```ion
(macro pi            // name
  ()                 // signature
  3.141592653589793) // template
```

This declaration defines a macro named `pi`. The `()` is the macro’s _signature_, in this
case a trivial one that declares no parameters. The `3.141592653589793` is a similarly trivial
_template_, an expression in Ion 1.1's domain-specific language for defining macro functions.
This macro accepts no arguments and always returns a constant value.

To use `pi` in an Ion document, we write an _encoding expression_ or _E-expression_:

```ion
$ion_1_1
(:pi)
```

The syntax `(:pi)` looks a lot like an S-expression. It’s not, though, since colons
cannot appear unquoted in that context. Ion 1.1 makes use of syntax that is not valid in Ion
1.0—specifically, the `(:` digraph—to denote E-expressions. Those characters must be followed by
a reference to a macro, and we say that the E-expression is an invocation of the macro. Here,
`(:pi)` is an invocation of the macro named `pi`.

> [!NOTE]
> We also call these “smile expressions” when we’re feeling particularly casual. (:

That document is equivalent to the following, in the sense that they denote the same data:


```ion
$ion_1_1
3.141592653589793
```

The process by which the Ion implementation turns the former document into the latter is called
_macro expansion_ or just _expansion_. This happens transparently to
Ion-consuming applications: the stream of values in both cases are the same. The documents have
the same content, encoded in two different ways. It’s reasonable to think of `(:pi)` as a custom
encoding for `3.141592653589793`, and the notation’s similarity to S-expressions leads us to the
term “encoding expression”.

> [!NOTE]
> Any Ion 1.1 document with macros can be fully-expanded into an equivalent Ion 1.0 document.

We can streamline future examples with a couple conventions. First, assume that any E-expression
is occurring within an Ion 1.1 document; second, we use the relation notation, `⇒`, to mean “expands to”.
So we can say:

```ion
(:pi) ⇒ 3.141592653589793
```


## Simple Templates

Most macros are not constant--they accept inputs that determine their results.

```ion
(macro price
  (a c)                           // signature
  { amount: a, currency: c })     // template
```

This macro has a signature that declares two parameters, named `a` and `c`, and it
therefore accepts two arguments when invoked.

```ion
(:price 99 USD) ⇒ { amount: 99, currency: USD }
```

> [!NOTE]
> We are careful to distinguish between the views from “inside” and “outside” the macro:
> _parameters_ are the names used by a macro’s implementation to refer to its expansion-time
> inputs, while _arguments_ are the data provided to a macro at the point of invocation.
> In other words, we have “formal” parameters and “actual” arguments.

The struct
in this macro is our first non-trivial _template_, an expression in Ion’s new domain-specific language
for defining macro functions. This expression language treats Ion scalar values (except for
symbols) as literals, giving the decimal in ``pi``’s template its intended meaning. Expressions
that are structs are interpreted _almost_ literally: the field names are literal, but the field
“values” are arbitrary expressions. This is why the `amount` and `currency` field names show up
as-is in the expansion. We call these almost-literal forms _quasi-literals_.

The template language also treats lists quasi-literally, and every element inside the list is an
expression. Here’s a silly macro to illustrate:

```ion
(macro reverse (a b) [b, a])
```
```ion
(:reverse first 1990) ⇒ [1990, first]
```

The sub-expressions in these templates demonstrate that the expression language treats symbols as
variable references. The symbols in the templates above (`a` and `c` in `price`; `a` and `b`
in `reverse`) refer to the parameters of their respective surrounding macros, and during
expansion they are “filled in” with the values supplied by the invocation of the macro.

These names are part of the macro language that have no relation to data encoded using the macro:

```ion
(:reverse c {amount:a, currency:c}) ⇒ [{amount:a, currency:c}, c]
```

Symbols in an E-expression are _not_ part of the expression language and do not reference macro
parameters or any other named entity.
From the point of view of ``reverse``’s template, the inputs are literal data.

E-expressions can nest, so we could also encode the same data using `price`:

```ion
(:reverse first (:price a c))
  ⇒ (:reverse first {amount:a, currency:c})
  ⇒ [{amount:a, currency:c}, first]
```

As the example suggests, expansion steps proceed "inside out" and the outer macro receives the
results from the inner invocation.


## Invoking Macros from Templates

Template expressions that are S-expressions are _operator invocations_, where the operators are
either macros or _special forms_. We start with the former:

```ion
(macro website_url
  (path)
  (make_string "https://www.amazon.com/" path))
```

In this case, the S-expression `(make_string …)` is an invocation of the system macro (that is, a
built-in function) `make_string`, which concatenates its arguments to produce a single string:

```ion
(:website_url "gp/cart") ⇒ "https://www.amazon.com/gp/cart"
```

In the template language, macro invocations can appear almost anywhere:

```ion
(macro detail_page_url
  (asin)
  (website_url (make_string "dp/" asin)))
```

```ion
(:detail_page_url "B08KTZ8249") ⇒ "https://www.amazon.com/dp/B08KTZ8249"
```

> [!NOTE]
> While this doesn’t look like much of an improvement, the full string takes 38 bytes to encode,
> but the macro invocation takes as few as 12 bytes.

Careful readers will note that templates can use `[…]` and `{…}` notation to construct lists and
structs, but `(…)` doesn't construct S-expressions. This gap is filled by the built-in macro
`make_sexp` which accepts any number of arguments and puts them in a sexp:

```ion
(macro double_sexp (val) (make_sexp val val))
```
```ion
(:make_sexp true 19.3 null) ⇒ (true 19.3 null)
(:double_sexp double) ⇒ (double double)
```


## E-expressions Versus S-expressions

We've now seen two ways to invoke macros, and their difference deserves thorough exploration.

An E-expression is an encoding artifact of a serialized Ion document. It has no intrinsic meaning
other than the fact that it represents a macro invocation. The meaning of the document can only
be determined by expanding the macro, passing the E-expression's arguments to the function
defined by the macro. This all happens as the Ion document is parsed, transparent to the reader
of the document. In casual terms, E-expressions are expanded away before the application sees
the data.

Within the template-expression language, you can define new macros in terms of other macros, and
those invocations are written as S-expressions. Unlike E-expressions, these are normal Ion data
structures, consumed by the Ion system and interpreted as code. Further, they only exist in the
context of a macro definition, inside an encoding module, while E-expressions can occur
_anywhere_ in an Ion document.

> [!WARNING]
> It's entirely possible to write a macro that can generate all or part of a macro
> definition. We don't recommend that you spend time considering such things at this point.

These two invocation forms are syntactically aligned in their calling convention, but are
distinct in context and "immediacy". E-expressions occur anywhere and are invoked immediately,
as they are parsed. S-expression invocations occur only within macro definitions, and are only
invoked if and when that code path is ever executed by invocation of the surrounding macro.


## Special Form: `literal`

When a template-expression is syntactically an S-expression, its first
element must be a symbol that matches either a set of keywords denoting the special forms, or the
name of a previously-defined macro. The interpretation of the S-expression’s remaining elements
depends on how the symbol resolves. In the case of macro invocations, we’ve seen above that the
following elements are (so far!) arbitrary template expressions, but for special forms that’s not
always the case. The `literal` form makes this clear:

```ion
(macro USD_price (dollars) (price dollars (literal USD)))
```
```ion
(:USD_price 12.99) ⇒ { amount: 12.99, currency: USD }
```

In this template, we can’t just write `(price dollars USD)` because the symbol `USD` would be
treated as an unbound variable reference and a syntax error, so we turn it into literal data by
“escaping” it with `literal`.

The critical point is that special forms are “special” precisely because they cannot be expressed
as macros and must therefore receive bespoke syntactic treatment. Since the elements of
macro-invocation expressions are themselves expressions, when you want something to _not_ be
evaluated that way, it must be a special form.

Finally, these special forms are part of the template language itself, and are not visible to
encoded data: the E-expression `(:literal foo)` must necessarily refer to some user-defined macro
named `literal`, not to this special form. As an aside, there is no need for such a form in
E-expressions, because in that context symbols and S-expressions are not “evaluated”, and
everything is literal except for E-expressions (which are not data, but encoding artifacts).

> [!NOTE]
> Ion 1.1 defines a number of built-in macros and special forms. While this document covers
> the highlights, it is not a complete reference to all features.


### Rest Parameters

Sometimes we want a macro to accept an arbitrary number of arguments, in particular _all the rest
of them_. The `make_string` macro is one of those, concatenating all of its arguments into a
single string:

```ion
(:make_string)                 ⇒ ""
(:make_string "a")             ⇒ "a"
(:make_string "a" "b"    )     ⇒ "ab"
(:make_string "a" "b" "c")     ⇒ "abc"
(:make_string "a" "b" "c" "d") ⇒ "abcd"
```

To make this work, the definition of make_string is effectively:

```ion
(macro make_string (parts*) …)
```

This says that `parts` is comprised of zero or more argument expressions.
The `*` cardinality modifier, when applied to a final parameter, declares that
“all the rest” of the arguments will be passed to that one name.

> [!NOTE]
> The Ion grammar treats identifiers like `text` and operators like `*` as separate tokens
> regardless of whether they are separated by whitespace. We think it's easier to read without
> whitespace and will use that convention from now on.

At this point our distinction between parameters and arguments becomes apparent, since
they are no longer one-to-one: this macro with one parameter can be invoked with one argument, or
twenty, or none. We describe the acceptable number of expressions for a parameter as its
_cardinality_. In the examples so far, all parameters have had _exactly-one_ cardinality, while
`parts` has _zero-or-more_ cardinality. We’ll see additional cardinalities soon!

> [!TIP]
> To declare a final parameter that requires at least one rest-argument, use the `+` modifier.


### Arguments and results are streams

The inputs to and results from a macro are modeled as streams of values.
When a macro is invoked, each argument produces a stream of values,
and within the macro definition, each parameter name refers to the corresponding stream,
not to a specific value. The declared cardinality of a parameter constrains the number of
elements produced by its stream, and is verified by the macro expansion system.

More generally, the results of all template expressions are streams. While most expressions
produce a single value, various macros and special forms can produce zero or more values.

We have everything we need to illustrate this, via another system macro, `values`:

```ion
(macro values (vals*) vals)
```

```ion
(:values 1)           ⇒ 1
(:values 1 true null) ⇒ 1 true null
(:values)             ⇒ _nothing_
```

The `values` macro accepts any number of arguments and returns their values, effectively a
multi-value identity function. We can use this to explore how streams combine in E-expressions.


#### Splicing in encoded data

When an E-expression occurs at top-level or within a list or S-expression, the results are
spliced into the surrounding container:

```ion
[first, (:values), last]          ⇒ [first, last]
[first, (:values "middle"), last] ⇒ [first, "middle", last]
(first (:values left right) last) ⇒ (first left right last)
```

This also applies wherever a [tagged type](../binary/values.md) can appear inside an E-expression:

```ion
(first (:values (:values left right) (:values)) last) ⇒ (first left right last)
```

Note that each argument-expression always maps to one parameter, even when that expression
returns too-few or too-many values.

```ion
(macro reverse (a b)
  [b, a])
```

```ion
(:reverse (:values 5 USD))   ⇒ _error: 'reverse' expects 2 arguments, given 1_
(:reverse 5 (:values) USD)   ⇒ _error: 'reverse' expects 2 arguments, given 3_
(:reverse (:values 5 6) USD) ⇒ _error: argument 'a' expects 1 value, given 2_
```

In this example, the parameters expect exactly one argument, producing exactly one value. When
the cardinality allows multiple values, then the argument result-streams are concatenated. We saw
this (rather subtly) above in the nested use of `values`, but can also illustrate using the
rest-parameter to `make_string`, which we'll expand here in steps:

```ion
(:make_string (:values) a (:values b (:values c) d) e)
  ⇒ (:make_string a (:values b (:values c) d) e)
  ⇒ (:make_string a (:values b c d) e)
  ⇒ (:make_string a b c d e)
  ⇒ "abcde"
```

Splicing within sequences is straightforward, but structs are trickier due to their key/value
nature. When used in field-value position, each result from a macro is bound to the field-name
independently, leading to the field being repeated or even absent:

```ion
{ name: (:values) }          ⇒ { }
{ name: (:values v) }        ⇒ { name: v }
{ name: (:values v ann::w) } ⇒ { name: v, name: ann::w }
```

An E-expression can even be used in place of a key-value pair, in which case it must return
structs, which are merged into the surrounding container:

```ion
{ a:1, (:values), z:3 }             ⇒ { a:1, z:3 }
{ a:1, (:values {}), z:3 }          ⇒ { a:1, z:3 }
{ a:1, (:values {b:2}), z:3 }       ⇒ { a:1, b:2, z:3 }
{ a:1, (:values {b:2} {z:3}), z:3 } ⇒ { a:1, b:2, z:3, z:3 }

{ a:1, (:values key "value") } ⇒ _error: struct expected for splicing into struct_
```


#### Splicing in template expressions

The preceding examples demonstrate splicing of E-expressions into encoded data, but similar
stream-splicing occurs within the template language, making it trivial to convert a stream to a
list:

```ion
(macro list_of
  (vals*)
  [ vals ])
(macro clumsy_bag
  (elts*)
  { '': elts })
```
```ion
(:list_of)   ⇒ []
(:clumsy_bag) ⇒ {}

(:list_of 1 2 3)    ⇒ [1, 2, 3]
(:clumsy_bag true 2) ⇒ {'':true, '':2}
```

TODO: demonstrate splicing in TDL macro invocations

### Mapping templates over streams: `for`

Another way to produce a stream is via a mapping form. The `for` special form evaluates a
template once for each value provided by a stream or streams. Each time, a local variable is
created and bound to the next value on the stream.

```ion
(macro prices
  (currency amounts*)
  (for [(amt amounts)]                          // <1>
    (price amt currency)))
```

<1> The first subform of `for` is a list of binding pairs, S-expressions containing a variable
names and a template expressions. Here, that template expression is simply a parameter
reference, so each individual value from the `amounts` is bound to the name `amt` before the
`price` invocation is expanded.

```
(:prices GBP 10 9.99 12.)
  ⇒ {amount:10, currency:GBP} {amount:9.99, currency:GBP} {amount:12., currency:GBP}
```

More than one stream can be iterated in parallel, and iteration terminates when any stream
becomes empty.

```ion
(macro zip (front* back*)  // <1>
  (for [(f front),
        (b back)]
    [f, b]))
```

<1> The `*` means that the parameter accepts any number of values; see
[Zero-or-more](#zero-or-more).

```ion
(:zip (:values 1 2 3) (:values a b))
  ⇒ [1, a] [2, b]
```

> [!NOTE]
> This termination rule is under discussion; see <https://github.com/amazon-ion/ion-docs/issues/201>


### Empty Streams: `none`

The empty stream is an important edge case that requires careful handling and communication.
The built-in macro `none` accepts no values and produces an empty stream:

```ion
(:int_list (:none)) ⇒ []
(:int_list 1 (:none) 2) ⇒ [1, 2]
[(:none)]   ⇒ []
{a:(:none)} ⇒ {}
```

When used as a macro argument, a `none` invocation (like any other expression) counts as one
argument:

```ion
(:pi (:none)) ⇒ _error: 'pi' expects 0 arguments, given 1_
```

The special form `(:)` is an [empty argument group](../todo.md), similar to
`(:none)` but used specifically to express the absence of an argument:

```ion
(:int_list (:)) ⇒ []
(:int_list 1 (:) 2) ⇒ [1, 2]
```

TIP: While `none` and `values` both produce the empty stream, the former is preferred for
clarity of intent and terminology.


### Cardinality

As described earlier, parameters are all streams of values, but the number of values can be
controlled by the parameter's cardinality. So far we have seen the default exactly-one
and the `*` (zero-or-more) cardinality modifiers, and in total there are four:


| Modifier | Cardinality         |
|:--------:|---------------------|
|   `!`    | exactly-one value   |
|   `?`    | zero-or-one value   |
|   `+`    | one-or-more values  |
|   `*`    | zero-or-more values |

#### Exactly-One

Many parameters expect exactly one value and thus have _exactly-one cardinality_.
This is the default cardinality, but the `!` modifier can be used for clarity.

This cardinality means that the parameter requires a stream producing a single value, so one
might refer to them as _singleton streams_ or just _singletons_ colloquially.


#### Zero-or-One

A parameter with the modifier `?` has _zero-or-one cardinality_, which is much like
exactly-one cardinality, except the parameter accepts an empty-stream
argument as a way to denote an absent parameter.

```ion
(macro temperature
  (decimal::degrees symbol::scale?)]
  {degrees: degrees, scale: scale})
```

Since the scale accepts the empty stream, we can pass it an empty argument group:

```ion
(:temperature 96 F)    ⇒ {degrees:96, scale:F}
(:temperature 283 (:)) ⇒ {degrees:283}
```

Note that the result’s `scale` field has disappeared because no value was provided. It would be
more useful to fill in a default value, and to do that we introduce a special form that can
detect the empty stream:

```ion
(macro temperature
  (decimal::degrees symbol::scale?)
  {degrees: degrees, scale: (if_none scale (literal K) scale)})
```
```ion
(:temperature 96 F)    ⇒ {degrees:96,  scale:F}
(:temperature 283 (:)) ⇒ {degrees:283, scale:K}
```

The `if_none` form is if/then/else syntax testing stream emptiness. It has three sub-expressions,
the first being a stream to check. If and only if that stream is empty (it produces no
values), the second sub-expression is expanded and its results are returned by the `if_none`
expression. Otherwise, the third sub-expression is expanded and returned.

> [!NOTE]
> Exactly one branch is expanded, because otherwise the empty stream might be used in a context
> that requires a value, resulting in an errant expansion error.

To refine things a bit further, trailing arguments that accept the empty stream can be omitted entirely:

```ion
(:temperature 283) ⇒ {degrees:283, scale:K}
```


#### Zero-or-More

A parameter with the modifier `*` has _zero-or-more cardinality_.

```ion
(macro prices
  (number::amount* symbol::currency)
  (for [(amt amount)]
    (price amt currency)))
```

When `*` is on a non-final parameter, we cannot take the “all the rest” of the arguments
and must use a different calling convention to draw the boundaries of the stream.
Instead, we need a single
expression that produces the desired values:

```ion
(:prices (:) JPY)          ⇒ _void_
(:prices 54 CAD)           ⇒ {amount:54, currency:CAD}
(:prices (: 10 9.99) GBP)  ⇒ {amount:10, currency:GBP} {amount:9.99, currency:GBP}
```

Here we use a non-empty [empty argument group](../todo.md) `(: ...)` to delimit
the multiple elements of the `amount` stream.


#### One-or-More

A parameter with the modifier `+` has _one-or-more cardinality_, which works like `*` except
the resulting stream must produce at least one value. To continue using our `prices` example:

```ion
(macro prices
  (number::amount+ symbol::currency)
  (for [(amt amount)]
    (price amt currency)))
```

```ion
(:prices (:) JPY) ⇒ _error: at least one value expected for + parameter_
(:prices 54 CAD)           ⇒ {amount:54, currency:CAD}
(:prices (: 10 9.99) GBP)  ⇒ {amount:10, currency:GBP} {amount:9.99, currency:GBP}
```

On the final parameter, `+` collects the remaining (one or more) arguments:

```ion
(macro thanks (text::names+)
  (make_string "Thank you to my Patreon supporters:\n"
    (for [(n names)]
      (make_string "  * " n "\n"))))
```

```ion
(:thanks) ⇒ _error: at least one value expected for + parameter_

(:thanks Larry Curly Moe) =>
'''\
Thank you to my Patreon supporters:
  * Larry
  * Curly
  * Moe
'''
```

### Argument Groups

The non-rest versions of multi-value parameters require some kind of delimiting
syntax to contain the applicable sub-expressions. For the tagged-type parameters we've seen
so far, you _could_ use `:values` or some other macro to produce the stream, but that doesn't
work for [tagless types](../todo.md).
The preferred syntax, supporting all argument types, is a special delimiting form
called an _argument group_. Here is a macro to illustrate:

```ion
(macro prices
  (amount* currency)
  (for [(amt amount)]
    (price amt currency)))
```

The parameter `amount` accepts any number of `number`s.
It's easy to provide exactly one:

```ion
(:prices 12.99 GBP) ⇒ {amount:12.99, currency:GBP}
```

To provide a non-singleton stream of values, use an _argument group_.
Inside an E-expression, a group starts with the digraph `(:` similar to a macro
invocation, but without a macro reference:

```ion
(:prices (:) GBP)       ⇒ _void_
(:prices (: 1) GBP)     ⇒ {amount:1, currency:GBP}
(:prices (: 1 2 3) GBP) ⇒ {amount:1, currency:GBP}
                          {amount:2, currency:GBP}
                          {amount:3, currency:GBP}
```

Within the group, the invocation can have any number of expressions that align
with the parameter type.
The macro parameter produces the results of those expressions, concatenated into a
single stream, and the expander verifies that each value on that stream is acceptable by the
parameter’s declared type.

```ion
(:prices (: 1 (:values 2 3) 4) GBP) ⇒ {amount:1, currency:GBP}
                                      {amount:2, currency:GBP}
                                      {amount:3, currency:GBP}
                                      {amount:4, currency:GBP}
```

Argument groups may only appear inside macro invocations where the corresponding
parameter has `?`, `*`, or `+` cardinality.
There is no binary opcode for these constructs; the encoding uses a tagless format to keep
things as dense as possible.
As usual, the text format mirrors this constraint.

> [!WARNING]
> The allowed combinations of cardinality and argument groups is pending
> finalization of the binary encoding.


### Optional Arguments

When a trailing parameter accepts the empty stream, an invocation can omit its corresponding argument expression,
as long as no following parameter is being given an expression. We’ve seen
this as applied to final `*` parameters, but it also applies to `?`
parameters:

```ion
(macro optionals
  (a* b? c! d* e? f*)
  (make_list a b c d e f))
```

Since `d`, `e`, and `f` all accept the empty stream, they can be omitted by invokers. But `c` is required so
`a` and `b` must always be present, at least as an empty group:

```ion
(:optionals (:) (:) "value for c") ⇒ ["value for c"]
```

Now `c` receives the string `"value for c"` while the other parameters are all empty.
If we want to provide `e`, then we must also provide a group for `d`:

```ion
(:optionals (:) (:) "value for c" (:) "value for e")
  ⇒ ["value for c", "value for e"]
```

### Tagless and fixed-Width types

In Ion 1.0, the binary encoding of every value starts off with a “type tag”, an opcode that indicates
the data-type of the next value and thus the interpretation of the following octets of data. In general,
these tags also indicate whether the value has annotations, and whether it’s null.

These tags are necessary because the Ion data model allows values of any type to be used
anywhere. Ion documents are not schema-constrained: nothing forces any part of the data to have a
specific type or shape. We call Ion “self-describing” precisely because each value
self-describes its type via a type tag.

If schema constraints are enforced through some mechanism outside the serializer/deserializer,
the type tags are unnecessary and may add up to a non-trivial amount of wasted space.
Furthermore, the overhead for each value also includes length information: encoding an
octet of data takes two octets on the stream.

Ion 1.1 tries to mitigate this overhead in the binary format by allowing macro parameters to use
more-constrained _tagless types_. These are subtypes of the concrete types,
constrained such that type tags are not necessary in the binary form. In general this can shave
4-6 bits off each value, which can add up in aggregate. In the extreme, that octet of data can
be encoded with no overhead at all.

The following tagless types are available:

| Tagless type                         | Description                          |
|--------------------------------------|--------------------------------------|
| `var_symbol`                         | Tagless symbol (SID or text)         |
| `var_string`                         | Tagless string                       |
| `var_int`                            | Tagless, variable-width signed int   |
| `var_uint`                           | Tagless, variable-width unsigned int |
| `int8`  `int16`   `int32`   `int64`  | Fixed-width signed int               |
| `uint8` `uint16`  `uint32`  `uint64` | Fixed-width unsigned int             |
| `float16` `float32` `float64`        | Fixed-width float                    |


To define a tagless parameter, just declare one of the primitive types:

```ion
(macro point
  (var_int::x var_int::y)
  {x: x, y: y})
```
```ion
(:point 3 17) ⇒ {x:3, y:17}
```

The type constraint has no real benefit here in text, as primitive types aim to improve the binary
encoding.

This density comes at the cost of flexibility. Primitive types cannot be annotated or null, and
arguments cannot be expressed using macros, like we’ve done before:

```ion
(:point null.int 17)   ⇒ _error: primitive var_int does not accept nulls_
(:point a::3 17)       ⇒ _error: primitive var_int does not accept annotations_
(:point (:values 1) 2) ⇒ _error: cannot use macro for a primitive argument_
```

While Ion text syntax doesn’t use tags—the types are built into the syntax—these errors ensure
that a text E-expression may only express things that can also be expressed using an equivalent
binary E-expression.

For the same reasons, supplying a (non-rest) tagless parameter with no value,
or with more than one value, can only be expressed by using an argument group.

// TODO: Add examples of non-single cardinality and use of groups.

A subset of the primitive types are _fixed-width_: they are binary-encoded with no per-value
overhead.

```ion
(macro byte_array
  (uint8::bytes*)
  [bytes])
```

Invocations of this macro are encoded as a sequence of untagged octets, because the
macro definition constrains the argument shape such that nothing else is acceptable. A text
invocation is written using normal ints:

```ion
(:byte_array 0 1 2 3 4 5 6 7 8) ⇒ [0, 1, 2, 3, 4, 5, 6, 7, 8]
(:byte_array 9 -10 11)          ⇒ _error: -10 is not a valid uint8_
(:byte_array 256)               ⇒ _error: 256 is not a valid uint8_
```

As above, Ion text doesn’t have syntax specifically denoting “8-bit unsigned integers”, so to
keep text and binary capabilities aligned, the parser rejects invocations where an argument value
exceeds the range of the binary-only type.

Primitive types have inherent tradeoffs and require careful consideration, but in
the right circumstances the density wins can be significant.

### Macro Shapes

We can now introduce the final kind of input constraint, macro-shaped parameters. To understand
the motivation, consider modeling a scatter-plot as a list of points:

```ion
[{x:3, y:17}, {x:395, y:23}, {x:15, y:48}, {x:2023, y:5}, …]
```

Lists like these exhibit a lot of repetition. Since we already have a `point` macro, we can
eliminate a fair amount:

```ion
[(:point 3 17), (:point 395 23), (:point 15 48), (:point 2023 5), …]
```

This eliminates all the ``x``s and ``y``s, but leaves repeated macro invocations. We can try to
wrap this in another macro, but we find the type constraints insufficient, since the tightest we
can go is `struct`, and things aren’t really any better:

```ion
(macro scatterplot (struct::points*)
  [points])
```
```ion
(:scatterplot (:point 3 17) (:point 395 23) (:point 15 48) (:point 2023 5) …)
```

What we’d like is to eliminate the `point` calls and just write a stream of pairs, something
like:

```
(:scatterplot (3 17) (395 23) (15 48) (2023 5) …)
```

We can achieve exactly that with a macro-shaped parameter, in which we use the `point` macro as a
pseudo-type:

```ion
(macro scatterplot (point::points*)  // <1>
  [points])
```

<1> `point` is not one of the built-in types, so this is a reference to the macro of that name
defined earlier.

```ion
(:scatterplot (3 17) (395 23) (15 48) (2023 5))
  ⇒
  [{x:3, y:17}, {x:395, y:23}, {x:15, y:48}, {x:2023, y:5}]
```

Each argument S-expression like `(3 17)` is _implicitly an
E-expression_ invoking the `point` macro. The argument mirrors the shape of the inner macro,
without repeating its name. Further, expansion of the implied ``point``s happens automatically,
so the overall behavior is just like the preceding struct-based variant and the `points`
parameter produces a stream of structs.

The binary encoding of macro-shaped parameters are similarly tagless, eliding any opcodes
mentioning `point` and just writing its arguments with minimal delimiting.

Macro types can be combined with cardinality modifiers, with invocations using groups
as needed:

```ion
(macro scatterplot
  (point::points+ string::x_label string::y_label)
  { points: [points], x_label: x_label, y_label: y_label })
```
```ion
(:scatterplot (: (3 17) (395 23) (15 48) (2023 5)) "hour" "widgets")
  ⇒
  {
    points: [{x:3, y:17}, {x:395, y:23}, {x:15, y:48}, {x:2023, y:5}],
    x_label: "hour",
    y_label: "widgets"
  }
```

As with other tagless parameters, you cannot replace a group with a macro invocation,
and you can't use a macro invocation as an _element_ of an argument group:

```ion
(:scatterplot (:make_points 3 17 395 23 15 48 2023 5) "hour" "widgets")
  ⇒ _error: Argument group expected, found :make_points_

(:scatterplot (: (3 17) (:make_points 395 23 15 48) (2023 5)) "hour" "widgets")
  ⇒ _error: sexp expected with args for 'point', found :make_points_

(:scatterplot (: (3 17) (:point 395 23) (15 48) (2023 5)) "hour" "widgets")
  ⇒ _error: sexp expected with args for 'point', found :point_
```

This limitation mirrors the binary encoding, where both the argument group and the individual
macro invocations are tagless and there's no way to express a macro invocation.

> [!TIP]
> The primary goal of macro-shaped arguments, and tagless types in general, is to increase
> density by tightly constraining the inputs.
