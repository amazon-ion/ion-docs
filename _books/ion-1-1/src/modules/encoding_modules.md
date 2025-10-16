# Encoding modules

The encoding of each segment of a stream is shaped by the currently configured _encoding modules_,
an ordered sequence of modules that determine which symbols and macros are available for use in the stream.
A writer can modify this sequence by emitting an [encoding directive](directives.md#encoding-directives).

By logically concatenating the encoding modules' symbol and macro tables respectively,
they can be viewed as unified local symbol and macro tables.

For example, consider these module definitions and the subsequent encoding directive:
```ion
(:$ion module mod_a
    (macros
        (macro foo () Foo)
        (macro bar () Bar))
    (symbols ["a", "b", "c"]))
(:$ion module mod_b
    (macros
        (macro baz () Baz)
        (macro quux () Quux))
    (symbols ["c", "d", "e"]))
(:$ion module mod_c
    (macros
        (macro quuz () Quuz)
        (macro foo () Foo2))
    (symbols ["f", "g", "h"]))

(:$ion encoding
    mod_a
    mod_b
    mod_c)
```
It produces the encoding module sequence `$ion _ mod_a mod_b mod_c`.
(The [`$ion` module](system_module.md#the-ion-module) and [default module](#the-default-module), `_`, is always implicitly at the head of the encoding sequence.)

The segment's local symbol table, formed by logically concatenating the symbol tables of `mod_a`,
`mod_b`, and `mod_c` in that order, is:

| Address | Symbol text                |
|:-------:|:---------------------------|
|   `0`   | _&lt;unknown text&gt;_     |
|   `1`   | `$ion`                     |
|   `2`   | `$ion_1_0`                 |
|   `3`   | `$ion_symbol_table`        |
|   `4`   | `name`                     |
|   `5`   | `version`                  |
|   `6`   | `imports`                  |
|   `7`   | `symbols`                  |
|   `8`   | `max_id`                   |
|   `9`   | `$ion_shared_symbol_table` |
|  `10`   | `a`                        |
|  `11`   | `b`                        |
|  `12`   | `c`                        |
|  `13`   | `c`                        |
|  `14`   | `d`                        |
|  `15`   | `e`                        |
|  `16`   | `f`                        |
|  `17`   | `g`                        |
|  `18`   | `h`                        |

Notice that no de-duplication takes place; `c` appears in both addresses `4` and `5`.

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
(:$ion module mod_a
    (macros
        (macro foo () Foo)))

// `mod_a` is now available

(:$ion module mod_b
    (macros
        (macro bar () Bar)))

// `mod_b` is now available

(:$ion encoding mod_a)

// `mod_a` is now active

(:mod_a::foo) // Foo
(:mod_b::bar) // ERROR: `mod_b` is not in the encoding module sequence
```

## The default module

The default module, `_`, is an empty top-level module that is implicitly defined at the beginning of every stream.

When resolving an unqualified macro name, readers look for the corresponding macro definition in `_`.
If it is not found, the reader will raise an error.

This makes it possible to leverage macros in a lightweight way;
writers do not have to first name/define a custom module to house their macros,
and the macros themselves can be invoked in text without having to write out the module name.

Macros and symbols can be added to the default module by redefining `_`.
Like all modules, `_` can be redefined in terms of itself, making appends and prepends straightforward.

```ion
$ion_1_1

// `_` exists, but is empty

(:$ion module _
    (macros
        (foo Foo)))

// `_` now contains macro `foo`

(:$ion module _
    (macros
        _ // Add all macros in `_` to its redefinition
        (bar Bar)))

// `_` now contains macros `foo` and `bar`

(:foo) // Equivalent to `(:_::foo)`
(:bar) // Equivalent to `(:_::bar)`
```

Directives like [`add_symbols`](../directives.md#add_symbols)
and [`add_macros`](../directives.md#add_macros) apply their changes to `_`,
so we can rewrite the above more succinctly as:
```ion
$ion_1_1

// `_` exists, but is empty

(:$ion add_macros
    (foo () Foo)
    (bar () Bar))

// `_` now contains macros `foo` and `bar`

(:foo) // Equivalent to `(:_::foo)`
(:bar) // Equivalent to `(:_::bar)`
```

`_` can also be redefined by an [`import`](directives.md#import-directives) directive.

## Default encoding module sequence

At the beginning of a stream, the encoding module sequence contains two modules:
1. the [system module](system_module.md), `$ion`
2. the [default module](#the-default-module), `_`

Recall that a segment's symbol and macro tables are logical concatenations of those found in the segment's encoding modules.
Because `_` is empty at the beginning of the stream,
the stream's initial symbol and macro tables are identical to those of the system module, `$ion`.

## Modifying active modules

If a module binding in the encoding module sequence is redefined,
the new module definition replaces the old one in the sequence.

For example after these directives are evaluated:
```ion
(:$ion module mod_a
    (macros
        (foo Foo)
        (bar Bar)))

(:$ion module mod_b)

(:$ion module mod_c
    (macros
        (quux Quux)
        (quuz Quuz)))

(:$ion encoding mod_a mod_b mod_c)
```
the encoding sequence is `$ion _ mod_a mod_b mod_c`, and `mod_b` is empty.

```ion
(:0) // => Foo
(:1) // => Bar
(:2) // => Quux
(:3) // => Quuz
```

If we then add macros to `mod_b`, those macros will immediately become available.

```ion
(:$ion module mod_b
    (macros
        (baz () Baz)))

(:0) // => Foo
(:1) // => Bar
(:2) // => Baz
(:3) // => Quux
(:4) // => Quuz
```

> [!IMPORTANT]
> Notice that modifying a module (in this case `mod_b`) can cause the addresses of all subsequent macros to be modified.

## Clearing the symbol and macro tables
```ion
(:$ion module _) // Redefine `_` to be an empty module
// If other modules are in use, remove them from the encoding module sequence
(:$ion encoding)
```
You can also consider writing an Ion version marker, which is more compact, although the behavior is slightly different.
See the [Default encoding module sequence](#default-encoding-module-sequence) section for details.
