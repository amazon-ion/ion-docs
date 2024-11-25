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

For normative examples, see [`none`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/none.ion) in the Ion conformance test suite.

#### `values`

```ion
(macro values (v*) v)
```

This is, essentially, the identity function. 
It produces a stream from any number of arguments, concatenating the streams produced by the nested expressions.
Used to aggregate multiple values or sub-streams to pass to a single argument, or to produce multiple results.

For normative examples, see [`values`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/values.ion) in the Ion conformance test suite.

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

For normative examples, see [`values`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/values.ion) in the Ion conformance test suite.

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
(:flatten [a, b, c] (d e f))       => a b c d e f
(:flatten [[], null.list] foo::()) => [] null.list
```

The `flatten` macro can also be used to splice the content of one list or s-expression into another list or s-expression.
```ion
[1, 2, (:flatten [a, b]), 3, 4] => [1, 2, a, b, 3, 4]
```

For normative examples, see [`flatten`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/flatten.ion) in the Ion conformance test suite.

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

For normative examples, see [`parse_ion`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/parse_ion.ion) in the Ion conformance test suite.

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

For normative examples, see [`annotate`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/annotate.ion) in the Ion conformance test suite.

#### `make_string`

```ion
(macro make_string (content*) /* Not representable in TDL */)
```

Produces a non-null, unannotated string containing the concatenated content produced by the arguments.
Nulls (of any type) are forbidden. Any annotations on the arguments are discarded.

For normative examples, see [`make_string`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_string.ion) in the Ion conformance test suite.

#### `make_symbol`

```ion
(macro make_symbol (content*) /* Not representable in TDL */)
```

Like `make_string` but produces a symbol.

For normative examples, see [`make_symbol`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_symbol.ion) in the Ion conformance test suite.

#### `make_blob`

```ion
(macro make_blob (lobs*) /* Not representable in TDL */)
```

Like `make_string` but accepts lobs and produces a blob.

For normative examples, see [`make_blob`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_blob.ion) in the Ion conformance test suite.

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

For normative examples, see [`make_list`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_list.ion) in the Ion conformance test suite.

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

For normative examples, see [`make_sexp`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_sexp.ion) in the Ion conformance test suite.

#### `make_struct`

```ion
(macro make_struct (structs*) /* Not representable in TDL */)
```

Produces a non-null, unannotated struct by combining the fields of any number of non-null structs.

```ion
(:make_struct)    => {}
(:make_struct
  {k1: 1, k2: 2}
  {k3: 3}
  {k4: 4})        => {k1:1, k2:2, k3:3, k4:4}
```

For normative examples, see [`make_struct`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_struct.ion) in the Ion conformance test suite.

#### `make_field`

```ion
(macro make_field (field_name value) /* Not representable in TDL */)
```

Produces a non-null, unannotated, single-field struct using the given field name and value.

The `field_name` parameter may be (or evaluate to) any non-null text value, and the `value` parameter may be (or evaluate to) any single value.

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

For normative examples, see [`make_struct`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_struct.ion) in the Ion conformance test suite.

#### `make_decimal`

```ion
(macro make_decimal (coefficient exponent) /* Not representable in TDL */)
```

This is no more compact than the regular binary encoding for decimals.
However, it can be used in conjunction with other macros, for example, to represent fixed-point numbers.

Both `coefficient` and `exponent` must be (or evaluate to) a single integer value. 

```ion
(macro usd (cents) (.annotate USD (.make_decimal cents -2))

(:usd 199) =>  USD::1.99
```

> [!NOTE]
> It is not possible to use `make_decimal` to construct any negative zero value because Ion integers do not have signed zero.

For normative examples, see [`make_decimal`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_decimal.ion) in the Ion conformance test suite.

#### `make_timestamp`

```ion
(macro make_timestamp (year month? day? hour? minute? second? offset_minutes?) /* Not representable in TDL */)
```
Produces a non-null, unannotated timestamp at various levels of precision.
When `offset` is absent, the result has unknown local offset; offset `0` denotes UTC.

The `make_timestamp` macro has rules that cannot be expressed in the macro signature because it must construct a 
valid Ion timestamp value.

The arguments to this macro may not be any null value.
The evaluated argument for the `year` parameter must be an integer from 1 to 9999 inclusive.
The evaluated argument for the `month` parameter, if present, must be an integer from 1 to 12 inclusive.
The evaluated argument for the `day` parameter, if present, must be an integer that is a valid, 1-indexed day for the given month.
The evaluated argument for the `hour` parameter, if present, must be an integer from 0 to 23 inclusive.
The evaluated argument for the `day` parameter, if present, must be an integer from 0 to 59 inclusive.
The evaluated argument for the `second` parameter, if present, must be a decimal or integer value that is greater than
or equal to zero and less than 60. The evaluated arguments for all other parameters, if present, must be integer values.

The `offset_minutes` and `hour` parameters may only be present if `minute` is present. Aside from `offset_minutes`, if 
any evaluated argument is present, the evaluated arguments for all parameters to the left must also be present.
The precision of the constructed timestamp is determined by which parameters have non-empty arguments.

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

For normative examples, see [`make_timestamp`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/make_timestamp.ion) in the Ion conformance test suite.

### Encoding Utility Macros

#### `repeat`

The `repeat` system macro can be used for efficient run-length encoding.

```ion
(macro repeat (n! value*) /* Not representable in TDL */)
```
Produces a stream that repeats the specified `value` expression(s) `n` times.

The evaluated argument for `n` must be a non-null integer value that is equal to or greater than zero. 

```ion
(:repeat 5 0)          => 0 0 0 0 0
(:repeat 2 true false) => true false true false
```

For normative examples, see [`repeat`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/repeat.ion) in the Ion conformance test suite.

#### `delta`

```ion
(macro delta (deltas*) /* Not representable in TDL */)
```

The `delta` system macro can be used for directed delta encoding.
It produces a stream that is equal in length to the `deltas` argument, defined by the recurrence relation:
```
output₀ = delta₀
outputₙ₊₁ = outputₙ + deltaₙ₊₁
```

Example:
```ion
(:delta 1000 1 2 3 -4) => 1000 1001 1003 1006 1002
```

For normative examples, see [`delta`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/delta.ion) in the Ion conformance test suite.

#### `sum`

```ion
(macro sum (a b) /* Not representable in TDL */)
```
Produces the sum of two non-null integer arguments.

Examples:
```ion
(:sum 1 2) => 3
```

For normative examples, see [`sum`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/sum.ion) in the Ion conformance test suite.

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

For normative examples, see [`meta`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/meta.ion) in the Ion conformance test suite.

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

For normative examples, see [`set_symbols`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/set_symbols.ion) in the Ion conformance test suite.

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

For normative examples, see [`add_symbols`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/add_symbols.ion) in the Ion conformance test suite.

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

For normative examples, see [`set_macros`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/set_macros.ion) in the Ion conformance test suite.

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

For normative examples, see [`add_macros`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/add_macros.ion) in the Ion conformance test suite.

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

For normative examples, see [`use`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/use.ion) in the Ion conformance test suite.

----

<!-- 
  MdBook will automatically number the footnotes, but it doesn't automatically put them at the bottom of the page.
  It also does not sort the footnote text in numerical order, so the ordering here must match the ordering the footnotes
  appear in the main content, or else the footnotes here will appear out of order.
/-->

[^ann]: The annotations sequence comes first in the macro signature because it parallels how annotations are read from the data stream.[^](#footnote-0)
