## System Macros

Many of the system macros _MAY_ be defined as template macros, and when possible, the specification includes a template.
Templates are given here as normative example, but system macros are not required to be implemented as template macros.

The macros that can be defined as templates are included as system macros because of their broad applicability, and
so that Ion implementations can provide optimizations for these macros that can short-circuit the regular macro evaluation.

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
Used to aggregate multiple values or sub-streams to pass to a single argument, or to return multiple results.

#### `flatten`

```ion
(macro flatten (sequence+) /* Not representable in TDL */)
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
(macro parse_ion (data!) /* Not representable in TDL */)
```

The `parse_ion` macro constructs a stream of values by parsing a blob literal or string literal as a single, self-contained Ion document.

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
> Allowing context to leak from the outer scope into the document being parsed would also enable recursion.
>
> Furthermore, `parse_ion` cannot be invoked from a macro body (i.e. in Template Definition Language (TDL)). 
> (Why not?)


### Value Constructors

#### `annotate`

```ion
(macro annotate (ann* value) /* Not representable in TDL */)
```

Produces the `value` prefixed with the annotations `ann`s.
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
This is the only way to produce an S-expression from a template: unlike lists, S-expressions in
templates are not quasi-literals.

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

#### `make_decimal`

```ion
(macro make_decimal (flex_int::coefficient flex_int::exponent) /* Not representable in TDL */)
```

This is no more compact than the regular binary encoding for decimals.
However, it can be used in conjunction with other macros, for example, to represent fixed-point numbers.

```ion
(macro usd (cents) (annotate (literal USD) (make_decimal cents -2))

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
         (.make_decimal seconds_millis -3) 0))
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

#### `comment`

```ion
(macro comment (anything*) (.none))
```

The `comment` macro accepts any values and emits nothing.
It can be used for comments that must be syntactically valid Ion.

Example:
```ion
(:values
    (:comment equivalent to {foo:1,foo:2})
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
         ((.literal symbol_table) [symbols])
         ((.literal macro_table $ion_encoding))
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
         ((.literal symbol_table $ion_encoding) [symbols])
         ((.literal macro_table $ion_encoding))
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
Sets the local symbol table, preserving any symbols in the symbol table.

```ion
(macro set_macros (macros*)
       $ion_encoding::(
         ((.literal symbol_table $ion_encoding)) 
         ((.literal macro_table) macros)
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
         ((.literal symbol_table $ion_encoding))
         ((.literal macro_table $ion_encoding) macros)
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
         ((.literal import the_module) catalog_key (.if_void version 1 version)) 
         ((.literal symbol_table $ion_encoding the_module))
         ((.literal macro_table $ion_encoding the_module))
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
