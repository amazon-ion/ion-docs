# Encoding modules

The encoding of each segment of a stream is shaped by the currently configured _encoding modules_,
an ordered sequence of modules that determine which symbols and macros are available for use in the stream.
A writer can modify this sequence by emitting an [encoding directive](directives.md#encoding-directives).

By logically concatenating the encoding modules' symbol and macro tables respectively,
they can be viewed as unified local symbol and macro tables.

For example, consider these module definitions and the subsequent encoding directive:
```ion
$ion::
(module mod_a
    (symbol_table ["a", "b", "c"])
    (macro_table
        (macro foo () Foo)
        (macro bar () Bar)))
$ion::
(module mod_b
    (symbol_table ["c", "d", "e"])
    (macro_table
        (macro baz () Baz)
        (macro quux () Quux)))
$ion::
(module mod_c
    (symbol_table ["f", "g", "h"])
    (macro_table
        (macro quuz () Quuz)
        (macro foo () Foo2)))

$ion::
(encoding
    mod_a
    mod_b
    mod_c)
```
It produces the encoding module sequence `_ mod_a mod_b mod_c`.
(The [default module](#the-default-module), `_`, is always implicitly at the head of the encoding sequence.)

The segment's local symbol table, formed by logically concatenating the symbol tables of `mod_a`,
`mod_b`, and `mod_c` in that order, is:

| Address | Symbol text |
|:-------:|-------------|
|   `0`   | `a`         |
|   `1`   | `b`         |
|   `2`   | `c`         |
|   `3`   | `c`         |
|   `4`   | `d`         |
|   `5`   | `e`         |
|   `6`   | `f`         |
|   `7`   | `g`         |
|   `8`   | `h`         |

Notice that no de-duplication takes place; `c` appears in both addresses `3` and `4`.

The segment's macro table, formed by logically concatenating the macro tables of `mod_a`,
`mod_b`, and `mod_c` in that order, is:

| Address | Macro         |
|:-------:|---------------|
|   `0`   | `mod_a::foo`  |
|   `1`   | `mod_a::bar`  |
|   `2`   | `mod_b::baz`  |
|   `3`   | `mod_b::quux` |
|   `4`   | `mod_c::quuz` |
|   `5`   | `mod_c::foo`  |

Notice that `mod_a::foo` and `mod_c::foo` can coexist in this unified view without issue.
Invocations of these macros require that they be qualified by their enclosing module's name.

Because lower addresses take fewer bytes to encode than higher addresses,
writers should place the modules they anticipate referencing the most frequently at the beginning of the encoding module sequence.

Modules in the current segment's encoding module sequence are said to be _active_,
while modules that are defined or imported but which are not in the encoding module sequence are _available_.
E-expressions can only invoke macros in an active module.

For example:
```ion
$ion::
(module mod_a
    (macro_table
        (macro foo () Foo)))

// `mod_a` is now available

$ion::
(module mod_b
    (macro_table
        (macro bar () Bar)))

// `mod_b` is now available

$ion::
(encoding mod_a)

// `mod_a` is now active

(:mod_a::foo) // Foo
(:mod_b::bar) // ERROR: `mod_b` is not in the encoding module sequence
```

## The default module

The default module, `_`, is an empty top-level module that is implicitly defined at the beginning of every stream.

When resolving an unqualified macro name, readers first look for the corresponding macro definition in `_`.
If it is not found in `_`, they will then look in [`$ion`](system_module.md).
If it is still not found, the reader will raise an error.

This makes it possible to leverage macros in a lightweight way;
writers do not have to first name/define a custom module to house their macros,
and the macros themselves can be invoked in text without having to write out the module name.

Macros and symbols can be added to the default module by redefining `_`.
Like all modules, `_` can be redefined in terms of itself, making appends and prepends straightforward.

```ion
$ion_1_1

// `_` exists, but is empty

$ion::
(module _
    (macro_table
        (macro foo () Foo)))

// `_` now contains macro `foo`

$ion::
(module _
    (macro_table
        _ // Add all macros in `_` to its redefinition
        (macro bar () Bar)))

// `_` now contains macros `foo` and `bar`

(:foo) // Equivalent to `(:_::foo)`
(:bar) // Equivalent to `(:_::bar)`
```

System macros like [`add_symbols`](../macros/system_macros.md#add_symbols)
and [`add_macros`](../macros/system_macros.md#add_macros) apply their changes to `_`,
so we can rewrite the above more succinctly as:
```ion
$ion_1_1

// `_` exists, but is empty

(:add_macros
    (macro foo () Foo)
    (macro bar () Bar))

// `_` now contains macros `foo` and `bar`

(:foo) // Equivalent to `(:_::foo)`
(:bar) // Equivalent to `(:_::bar)`
```

`_` can also be redefined by an [`import`](directives.md#import-directives) directive.

## Default encoding module sequence

At the beginning of a stream, the encoding module sequence contains two modules:
1. the [default module](#the-default-module), `_`
2. the [system module](system_module.md), `$ion`

Recall that a segment's symbol and macro tables are logical concatenations of those found in the segment's encoding modules.
Because `_` is empty at the beginning of the stream,
the stream's initial symbol and macro tables are identical to those of the system module, `$ion`.

This is beneficial because it allows all system macros to be invoked from the stream's macro table
[in a single byte](../binary/e_expressions.md#e-expression-with-the-address-in-the-opcode)
rather than [the two-byte sequence](http://localhost:3000/binary/e_expressions.html#system-macro-invocations)
needed to invoke them from the system macro table.
In this way, a writer can define its macros and symbols in a maximally compact fashion at the head of the stream.

## Modifying active modules

If a module binding in the encoding module sequence is redefined,
the new module definition replaces the old one in the sequence.

For example after these directives are evaluated:
```ion
$ion::
(module mod_a
    (macro_table
        (macro foo () Foo))
        (macro bar () Bar)))

$ion::
(module mod_b)

$ion::
(module mod_c
    (macro_table
        (macro quux () Quux)
        (macro quuz () Quuz)))

$ion::(encoding mod_a mod_b mod_c)
```
the encoding sequence is `_ mod_a mod_b mod_c`, and `mod_b` is empty.

```ion
(.0) // => Foo
(.1) // => Bar
(.2) // => Quux
(.3) // => Quuz
```

If we then add macros to `mod_b`, those macros will immediately become available.

```ion
$ion::
(module mod_b
    (macro_table
        (macro baz () Baz)))

(.0) // => Foo
(.1) // => Bar
(.2) // => Baz
(.3) // => Quux
(.4) // => Quuz
```

> [!IMPORTANT]
> Notice that modifying a module (in this case `mod_b`) can cause the addresses of all subsequent macros to be modified.

## Clearing the symbol and macro tables
```ion
(module _) // Redefine `_` to be an empty module
// If other modules are in use, remove them from the encoding module sequence
$ion::(encoding)
```

Note that this is different from the behaviour of an IVM.
When an IVM is encountered, the encoding module is set to the system module.