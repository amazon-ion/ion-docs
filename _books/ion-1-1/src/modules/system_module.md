## The System Module

The symbols and macros of the system module `$ion` are available everywhere within an Ion document,
with the version of that module being determined by the spec-version of each segment.
The specific system symbols are largely uninteresting to users; while the binary encoding heavily
leverages the system symbol table, the text encoding that users typically interact with does not.
The system macros are more visible, especially to authors of macros.

This chapter catalogs the system-provided symbols and macros.
The examples below use unqualified names, which works assuming no other module exports the same
name, but the unambiguous form `:$ion:macro-name` is always correct.

> [!WARNING]
> This list is not complete. We expect it to grow and evolve as we gain experience writing macros.

### System Symbols

The Ion 1.1 System Symbol table _replaces_ rather than extends the Ion 1.0 System Symbol table. The system symbols are as follows:

<!-- make the tables align to the side of the page /-->
<style>table { margin: 1em;}</style>

| ID | Text                                           |
|---:|:-----------------------------------------------|
|  1 | `$ion`                                         |
|  2 | `$ion_1_0`                                     |
|  3 | `$ion_symbol_table`                            |
|  4 | `name`                                         |
|  5 | `version`                                      |
|  6 | `imports`                                      |
|  7 | `symbols`                                      |
|  8 | `max_id`                                       |
|  9 | `$ion_shared_symbol_table`                     |
| 10 | `$ion_encoding`                                |
| 11 | `$ion_literal`                                 |
| 12 | `$ion_shared_module`                           |
| 13 | `macro`                                        |
| 14 | `macro_table`                                  |
| 15 | `symbol_table`                                 |
| 16 | `module`                                       |
| 17 | `retain`                                       |
| 18 | `export`                                       |
| 19 | `catalog_key`                                  |
| 20 | `use`                                          |
| 21 | `load`                                         |
| 22 | `import`                                       |
| 23 | _&lt;empty string>_ (i.e. `''`)                |
| 24 | `literal`                                      |
| 25 | `if_void`                                      |
| 26 | `if_single`                                    |
| 27 | `if_multi`                                     |
| 28 | `for`                                          |
| 29 | `fail`                                         |
| 30 | `values`                                       |
| 31 | `annotate`                                     |
| 32 | `make_string`                                  |
| 33 | `make_symbol`                                  |
| 34 | `make_blob`                                    |
| 35 | `make_decimal`                                 |
| 36 | `make_timestamp`                               |
| 37 | `make_list`                                    |
| 38 | `make_sexp`                                    |
| 39 | `make_struct`                                  |
| 40 | `parse_ion`                                    |
| 41 | `repeat`                                       |
| 42 | `delta`                                        |
| 43 | `flatten`                                      |
| 44 | `sum`                                          |
| 45 | `local_symtab` (or maybe just `symbol_table`?) |
| 46 | `lst_append` (or maybe just `add_symbols`?)    |
| 47 | `local_mactab` (or maybe just `macro_table`?)  |
| 48 | `lmt_append` (or maybe just `add_macro`?)      |
| 49 | `comment`                                      |
| 50 | `var_symbol`                                   |
| 51 | `var_string`                                   |
| 52 | `var_int`                                      |
| 53 | `var_uint`                                     |
| 54 | `uint8`                                        |
| 55 | `uint16`                                       |
| 56 | `uint32`                                       |
| 57 | `uint64`                                       |
| 58 | `int8`                                         |
| 59 | `int16`                                        |
| 60 | `int32`                                        |
| 61 | `int64`                                        |
| 62 | `float16`                                      |
| 63 | `float32`                                      |
| 64 | `float64`                                      |

 _Logical Parameter Type Names_ (possible in Ion 1.2?)

| ID | Text        |
|---:|:------------|
| 65 | `number`    |
| 66 | `exact`     |
| 67 | `text`      |
| 68 | `lob`       |
| 69 | `sequence`  |
| 70 | `'null'`    |
| 71 | `bool`      |
| 72 | `timestamp` |
| 73 | `int`       |
| 74 | `decimal`   |
| 75 | `float`     |
| 76 | `string`    |
| 77 | `symbol`    |
| 78 | `blob`      |
| 79 | `clob`      |
| 80 | `list`      |
| 81 | `sexp`      |
| 82 | `struct`    |


In Ion 1.1 Text, system symbols can never be referenced by symbol ID; `$1` always refers to the first symbol in the user symbol table.
This allows the Ion 1.1 system symbol table to be relatively large without taking away SID space from the user symbol table.

### System Macros



#### System Macro Addresses


|  ID | Text                                           |
|----:|:-----------------------------------------------|
|   0 | `values`                                       |
|   1 | `annotate`                                     |
|   2 | `make_string`                                  |
|   3 | `make_symbol`                                  |
|   4 | `make_blob`                                    |
|   5 | `make_decimal`                                 |
|   6 | `make_timestamp`                               |
|   7 | `make_list`                                    |
|   8 | `make_sexp`                                    |
|   9 | `make_struct`                                  |
|  10 | `parse_ion`                                    |
|  11 | `repeat`                                       |
|  12 | `delta`                                        |
|  13 | `flatten`                                      |
|  14 | `sum`                                          |
|  15 | `import`                                       |
|  16 | `local_symtab` (or maybe just `symbol_table`?) |
|  17 | `lst_append` (or maybe just `add_symbols`?)    |
|  18 | `local_mactab` (or maybe just `macro_table`?)  |
|  19 | `lmt_append` (or maybe just `add_macros`?)     |
|  20 | `comment`                                      |

#### `values`

```ion
(values (v*)) -> any*
```

Produces a stream from any number of arguments, concatenating the streams produced by the nested expressions.
Used to aggregate multiple values or sub-streams to pass to a single argument, or to return multiple results.

#### `make_string`

```ion
(make_string (text::content*)) -> string
```

Produces a non-null, unannotated string containing the concatenated content produced by the arguments.
Nulls (of any type) and annotations are discarded.

#### `make_symbol`

```ion
(make_symbol (text::content*)) -> symbol
```

Like `make_string` but produces a symbol.

#### `make_blob`

```ion
(make_blob (lob::content*)) -> blob
```

Like `make_string` but accepts lobs and produces a blob.

#### `make_list`

```ion
(make_list (vals*)) -> list
```

Produces a non-null, unannotated list by concatenating the _content_ of any number of list or sexp inputs.
The values `null.list` and `null.sexp` are treated as empty sequences.

#### `make_sexp`

```ion
(make_sexp (vals*)) -> sexp
```

Like `make_list` but produces a sexp.
This is the only way to produce an S-expression from a template: unlike lists, S-expressions in
templates are not quasi-literals.

```ion
(:make_sexp)      ⇒ ()
(:make_sexp null) ⇒ (null)
```


#### `make_struct`

```ion
(make_struct (structs*)) -> struct
```

Produces a non-null, unannotated struct by combining the fields of any number of structs.

```ion
(:make_struct { k1: 1, k2: 2} {k3:3} {k4: 4})  ⇒  {k1:1, k2:2, k3:3, k4:4}
```

#### `make_decimal`


```ion
(make_decimal (flex_int::coefficient flex_int::exponent)) -> decimal
```

This is no more compact than the regular binary encoding for decimals.
However, it can be used in conjunction with other macros, for example, to represent fixed-point numbers.

```ion
(macro usd (cents) (annotate (literal USD) (make_decimal cents -2))


(:usd 199)  ⇒  USD::1.99
```


#### `make_timestamp`

```ion
(make_timestamp (int::year 
                  uint8::month uint8::day 
                  uint8::hour  uint8::minute decimal::second 
                  int::offset_minutes))
  -> timestamp
```
Produces a non-null, unannotated timestamp at various levels of precision.
When `offset` is absent, the result has unknown local offset; offset `0` denotes UTC.

> [!NOTE]
> TODO [ion-docs#256](https://github.com/amazon-ion/ion-docs/issues/256) Reconsider offset semantics, perhaps default should be UTC.

Example:

```ion
(macro ts_today 
       (uint8::hour uint8::minute uint32::seconds_millis)
       (make_timestamp 2022 04 28 hour minute (decimal seconds_millis -3) 0))
```


#### `annotate`

```ion
(annotate (text::ann* value)) -> any
```

Produces the `value` prefixed with the annotations ``ann``s.
Each `ann` must be a non-null, unannotated string or symbol.

```ion
(:annotate (: "a2") a1::true) => a2::a1::true
```

#### `repeat`

The `repeat` system macro can be used for efficient run-length encoding.

```ion
(repeat (int::n! any::value+)) -> any
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
(delta int::initial! int::deltas+) -> int
```

```ion
(:delta 10 1 2 3 -4) => 11 13 16 12
```

#### `flatten`

The `flatten` system macro flattens one or more sequence values into a stream of their contents.

```ion
(flatten (sequence+)) -> any
```
Produces a stream with the contents of all the `sequence` values.
Any `null.sexp` or `null.list` is treated as an empty sequence.
Any annotations on the `sequence` values are discarded.

```ion
(:flatten [a, b, c] (d e f)) => a b c d e f
(:flatten [[], null.list] null.sexp foo::()) => [] null.list
```


The `flatten` macro can also be used to splice the content of one list or s-expression into another list or s-expression.
```ion
[1, 2, (:flatten [a, b]), 3, 4] => [1, 2, a, b, 3, 4]
```

#### `sum`

```ion
(sum (int::i*)) -> int
```
Produces the sum of all the integer arguments.

```ion
(:sum 1 2 3) => 6
(:sum (:)) => 0
```

#### `parse_ion`

Ion documents may be embedded in other Ion documents using the `parse_ion` macro.

```ion
(parse_ion (data!)) -> any
```

The `parse_ion` macro accepts a single, self-contained Ion document as a blob or string, and produces a stream of application values.

```ion
(:parse_ion
    '''
    $ion_1_1
    $ion_encoding::(
      (module local (symbol_table "foo" "bar"))
      (symbol_table local)
    )
    $1 $2
    '''
)
=> foo bar
```

> [!NOTE]
> TODO: Consider adding an example using embedded binary

> [!NOTE]
> TODO: Consider defining parse_ion variants that can
>  - leak encoding context to the outer Ion
>  - consume the encoding context from the outer Ion


#### Local Symtab Declaration

This macro is optimized for representing symbols-list with minimal space.

```ion
(macro import (string::name uint::version? uint::max_id?) -> struct
{ name:name, version:version, max_id:max_id })

(macro local_symtab (import::imports* string::symbols*)
    $ion_symbol_table::{
        imports:(if_void imports (values) [imports]),
        symbols:(if_void symbols (values) [symbols]), 
    })
```

```ion
(:local_symtab ("my.symtab" 4) (: "newsym" "another"))
=>
$ion_symbol_table::{ imports:[{name:"my.symtab", version:4}],
symbols:["newsym", "another"] }
```


#### Local Symtab Appending

```ion
(macro lst_append (string::symbols*)
    (if_void symbols 
             (void)                  // Produce nothing if no symbols provided.
             $ion_symbol_table::{
                 imports: (literal $ion_symbol_table),
                 symbols: [symbols]
             }
    )
)
```

```ion
(:lst_append "newsym" "another") =>

$ion_symbol_table::{ 
  imports:$ion_symbol_table,
  symbols:["newsym", "another"] 
}
```

#### Local Macro Table Appending

```ion
(macro lmt_append (sexp::template_macros*)
    (if_void template_macros
        (values)                  // Produce nothing if no symbols provided.
        $ion_encoding::(
            (retain *)
            (module syms2 (symbol_table ["s3", "s4"]))
            (symbol_table syms syms2)
        )
    )
)
```


#### Compact Module Definitions

**TODO**
