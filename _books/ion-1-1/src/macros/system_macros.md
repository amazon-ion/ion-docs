## System Macros

Many of the system macros _MAY_ be defined as template macros, and when possible, the specification includes a template.
Templates are given here as normative example, but system macros are not required to be implemented as template macros.

The macros that can be defined as templates are included as system macros because of their broad applicability, and
so that Ion implementations can provide optimizations for these macros that run directly in the implementations runtime
environment rather than in the macro evaluator.
For example, a macro such as [`add_symbols`](#add_symbols) does not produce user values, so an Ion Reader could bypass
evaluating the template and directly update the encoding context with the new symbols.

### Stream Constructors

#### `none`

```ion
(macro none () (.values))
```

`none` accepts no values and produces nothing (an empty stream).

#### `values`

```ion
(macro values (v*) v)
```

This is, essentially, the identity function. 
It produces a stream from any number of arguments, concatenating the streams produced by the nested expressions.
Used to aggregate multiple values or sub-streams to pass to a single argument, or to produce multiple results.

#### `default`

```ion
(macro default (expr* default_expr*)
    // If `expr` is empty...
    (.if_none (%expr)
        // then expand `default_expr` instead.
        (%default_expr)
        // If it wasn't empty, then expand `expr`.
        (%expr)
    )
)
```

`default` tests `expr` to determine whether it expands to the empty stream.
If it does not, `default` will produce the expansion of `expr`.
If it does, `default` will produce the expansion of `default_expr` instead.

#### `flatten`

```ion
(macro flatten (sequence*) /* Not representable in TDL */)
```
The `flatten` system macro constructs a stream from the content of one or more sequences.

Produces a stream with the contents of all the `sequence` values.
Any annotations on the `sequence` values are discarded.
Any non-sequence arguments will raise an error.
Any null arguments will be ignored.

Examples:
```ion
(:flatten [a, b, c] (d e f)) => a b c d e f
(:flatten [[], null.list] foo::()) => [] null.list
```

The `flatten` macro can also be used to splice the content of one list or s-expression into another list or s-expression.
```ion
[1, 2, (:flatten [a, b]), 3, 4] => [1, 2, a, b, 3, 4]
```

#### `parse_ion`

Ion documents may be embedded in other Ion documents using the `parse_ion` macro.

```ion
(macro parse_ion (uint8::data*) /* Not representable in TDL */)
```

The `parse_ion` macro constructs a stream of values by parsing a blob literal or string literal as a single, self-contained Ion document.
All values produced by the expansion of `parse_ion` are application values.
(I.e. it is as if they are all annotated with `$ion_literal`.) 

The IVM at the beginning of an Ion data stream is sufficient to identify whether it is text or binary, so text Ion
can be embedded as a blob containing the UTF-8 encoded text.

Embedded text example:
```ion
(:parse_ion
    '''
    $ion_1_1
    $ion_encoding::((symbol_table ["foo" "bar"]]))
    $1 $2
    '''
)
=> foo bar
```

Embedded binary example:
```ion
(:parse_ion {{ 4AEB6qNmb2+jYmFy }} )
=> foo bar
```

> [!IMPORTANT]
> Unlike most macros, this macro specifically requires _literals_. Macros are not allowed to contain recursive calls,
> and composing an embedded document from multiple expressions would make it possible to implement recursion in the
> macro system.
> 
> The data argument is evaluated in a clean environment that cannot read anything from the parent document.
> Allowing context to leak from the outer scope into the document being parsed would also enable recursion.

### Value Constructors

#### `annotate`

```ion
(macro annotate (ann* value) /* Not representable in TDL */)
```

Produces the `value` prefixed with the annotations `ann`s[^ann]<a name="footnote-0"></a>.
Each `ann` must be a non-null, unannotated string or symbol.

```ion
(:annotate (: "a2") a1::true) => a2::a1::true
```

#### `make_string`

```ion
(macro make_string (content*) /* Not representable in TDL */)
```

Produces a non-null, unannotated string containing the concatenated content produced by the arguments.
Nulls (of any type) are forbidden. Any annotations on the arguments are discarded.

#### `make_symbol`

```ion
(macro make_symbol (content*) /* Not representable in TDL */)
```

Like `make_string` but produces a symbol.

#### `make_blob`

```ion
(macro make_blob (lobs*) /* Not representable in TDL */)
```

Like `make_string` but accepts lobs and produces a blob.

#### `make_list`

```ion
(macro make_list (sequences*) [ (.flatten sequences) ])
```

Produces a non-null, unannotated list by concatenating the _content_ of any number of non-null list or sexp inputs.

```ion
(:make_list)                  => []
(:make_list (1 2))            => [1, 2]
(:make_list (1 2) [3, 4])     => [1, 2, 3, 4]
(:make_list ((1 2)) [[3, 4]]) => [(1 2), [3, 4]]
```

#### `make_sexp`

```ion
(macro make_sexp (sequences*) ( (.flatten sequences) ))
```

Like `make_list` but produces a sexp.

```ion
(:make_sexp)                  => ()
(:make_sexp (1 2))            => (1 2)
(:make_sexp (1 2) [3, 4])     => (1 2 3 4)
(:make_sexp ((1 2)) [[3, 4]]) => ((1 2) [3, 4])
```

#### `make_struct`

```ion
(macro make_struct (structs*) /* Not representable in TDL */)
```

Produces a non-null, unannotated struct by combining the fields of any number of non-null structs.

```ion
(:make_struct)    => {}
(:make_struct
  {k1: 1, k2: 2}
  {k3:3}
  {k4: 4})        =>  {k1:1, k2:2, k3:3, k4:4}
```

#### `make_field`

```ion
(macro make_field (flex_sym::field_name value) /* Not representable in TDL */)
```

Produces a non-null, unannotated, single-field struct using the given field name and value.

This can be used to dynamically construct field names based on macro parameters.

Example:
```ion
(macro foo_struct (extra_name extra_value)
       (make_struct 
         {
           foo_a: 1,
           foo_b: 2,
         }
         (make_field (make_string "foo_" (%extra_name)) (%extra_value))
       ))
```
Then:
```ion
(:foo_struct c 3) => { foo_a: 1, foo_b: 2, foo_c: 3 }
```

#### `make_decimal`

```ion
(macro make_decimal (flex_int::coefficient flex_int::exponent) /* Not representable in TDL */)
```

This is no more compact than the regular binary encoding for decimals.
However, it can be used in conjunction with other macros, for example, to represent fixed-point numbers.

```ion
(macro usd (cents) (.annotate USD (.make_decimal cents -2))

(:usd 199) =>  USD::1.99
```

#### `make_timestamp`

```ion
(macro make_timestamp (uint16::year
                       uint8::month?
                       uint8::day?
                       uint8::hour?
                       uint8::minute?
                       /*decimal*/ second?
                       int16::offset_minutes?) /* Not representable in TDL */)
```
Produces a non-null, unannotated timestamp at various levels of precision.
When `offset` is absent, the result has unknown local offset; offset `0` denotes UTC.
The arguments to this macro may not be any null value.

> [!NOTE]
> TODO [ion-docs#256](https://github.com/amazon-ion/ion-docs/issues/256) Reconsider offset semantics, perhaps default should be UTC.

Example:

```ion
(macro ts_today 
       (uint8::hour uint8::minute uint32::seconds_millis)
       (.make_timestamp
         2022
         4
         28
         hour
         minute
         (.make_decimal (%seconds_millis) -3) 0))
```

### Encoding Utility Macros

#### `repeat`

The `repeat` system macro can be used for efficient run-length encoding.

```ion
(macro repeat (n! value+) /* Not representable in TDL */)
```
Produces a stream that repeats the specified `value` expression(s) `n` times.

```ion
(:repeat 5 0) => 0 0 0 0 0
(:repeat 2 true false) => true false true false
```

#### `delta`

> [!NOTE]
> 🚧 Name still TBD 🚧

The `delta` system macro can be used for directed delta encoding.

```ion
(macro delta (flex_int::initial! flex_int::deltas+) /* Not representable in TDL */)
```

Example:
```ion
(:delta 10 1 2 3 -4) => 11 13 16 12
```

#### `sum`

```ion
(macro sum (i*) /* Not representable in TDL */)
```
Produces the sum of all the integer arguments.

Examples:
```ion
(:sum 1 2 3) => 6
(:sum (:)) => 0
```

#### `meta`

```ion
(macro meta (anything*) (.none))
```

The `meta` macro accepts any values and emits nothing.
It allows writers to encode data that will be not be surfaced to most readers.
Readers can be configured to intercept calls to `meta`, allowing them to read the otherwise invisible data.

When transcribing from one format to another, writers should preserve invocations of `meta` when possible.

Example:
```ion
(:values
    (:meta {author: "Mike Smith", email: "mikesmith@example.com"})
    {foo:2,foo:1}
)
=>
{foo:2,foo:1}
```

### Updating the Encoding Context

#### `set_symbols`
Sets the local symbol table, preserving any macros in the macro table.

```ion
(macro set_symbols (symbols*)
       $ion_encoding::(
         (symbol_table [(%symbols)])
         (macro_table $ion_encoding)
       ))
```

Example:
```ion
(:set_symbols foo bar)
=>
$ion_encoding::(
  (symbol_table [foo, bar])
  (macro_table $ion_encoding)
)
```

#### `add_symbols`
Appends symbols to the local symbol table, preserving any macros in the macro table.

```ion
(macro add_symbols (symbols*)
       $ion_encoding::(
         (symbol_table $ion_encoding [(%symbols)])
         (macro_table $ion_encoding)
       ))
```

Example:
```ion
(:add_symbols foo bar)
=>
$ion_encoding::(
  (symbol_table $ion_encoding [foo, bar])
  (macro_table $ion_encoding)
)
```

#### `set_macros`
Sets the local macro table, preserving any symbols in the symbol table.

```ion
(macro set_macros (macros*)
       $ion_encoding::(
         (symbol_table $ion_encoding)
         (macro_table (%macros))
       ))
```

Example:
```ion
(:set_macros (macro pi () 3.14159))
=>
$ion_encoding::(
  (symbol_table $ion_encoding)
  (macro_table (macro pi () 3.14159))
)
```

#### `add_macros`
Appends macros to the local macro table, preserving any symbols in the symbol table.

```ion
(macro add_macros (macros*)
       $ion_encoding::(
         (symbol_table $ion_encoding)
         (macro_table $ion_encoding (%macros))
       ))
```

Example:
```ion
(:add_macros (macro pi () 3.14159))
=>
$ion_encoding::(
  (symbol_table $ion_encoding)
  (macro_table $ion_encoding (macro pi () 3.14159))
)
```

#### `use`
Appends the content of the given module to the encoding context.

```ion
(macro use (catalog_key version?)
       $ion_encoding::(
         (import the_module catalog_key (.default (%version) 1))
         (symbol_table $ion_encoding the_module)
         (macro_table $ion_encoding the_module)
       ))
```

Example:
```ion
(:use "org.example.FooModule" 2)
=>
$ion_encoding::(
  (import the_module "org.example.FooModule" 2)
  (symbol_table $ion_encoding the_module)
  (macro_table $ion_encoding the_module)
)
```

----

<!-- 
  MdBook will automatically number the footnotes, but it doesn't automatically put them at the bottom of the page.
  It also does not sort the footnote text in numerical order, so the ordering here must match the ordering the footnotes
  appear in the main content, or else the footnotes here will appear out of order.
/-->

[^ann]: The annotations sequence comes first in the macro signature because it parallels how annotations are read from the data stream.[^](#footnote-0)
