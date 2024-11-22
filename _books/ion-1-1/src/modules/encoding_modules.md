# Encoding modules

The encoding of each segment of a stream is determined by the currently configured _encoding module sequence_.

Modules in the encoding module sequence for the current segment are said to be _active_,
while modules that are defined or imported but are not in the encoding module sequence are _available_.

A writer can modify this sequence by emitting an [encoding directive](directives.md#encoding-directives).

At the beginning of a stream, the encoding module sequence contains a two modules:
1. the [default module](#default-module), `_`
2. the [system module](system_module.md), `$ion`


## Default module

The default module, `_`, is an empty module that is implicitly defined at the beginning of every stream.
It is functionally equivalent to any user-defined module with one exception:
all unqualified macro references initially attempt resolution in `_`.

TODO: THIS MEANS THAT
In both e-expressions and TDL, macros in the default module can be referenced without specifying a module name.


This module sequence—the segment's _encoding modules_—must be defined or imported in the stream prior to appearing in an encoding directive.
Modes that are in the encoding module sequence for the current segment are said to be _active_,
while modules that are defined or imported but not in the encoding module sequence are _available_.

While the [encoding module sequence](#encoding-modules) allows a writer to encode the stream using a variety of modules,
many streams will only use a few locally defined macros.
In such streams, naming a new module and adding that binding to the encoding module sequence is burdensome.
It also forces all named invocations of that module's macros to be qualified even though the writer knows there are no name collisions.

To simplify this use case, an empty stream-level module named `_` is available at the beginning of every stream.
Macros and symbols can be added to it by redefining `_`.
Like all modules, `_` can be redefined in terms of itself, making appends and prepends straightforward.

```ion
$ion_1_1

// `_` exists, but is empty

$ion::
(module _
    (macro_table
        (macro foo () /*...*/)))

// `_` now contains macro `foo`

$ion::
(module _
    (macro_table
        _ // Add all macros in `_` to its redefinition
        (macro bar () /*...*/)))

// `_` now contains macros `foo` and `bar`
```

In e-expressions, unqualified macro name references are always resolved in the default module.

```ion
// This...
(:foo 1 2 3)

//...is the same as this:
(:_::foo 1 2 3)
```

System macros like `add_symbols` and `add_macros` apply their changes to `_`:
```ion
(:add_macros
    (macro foo () /*...*/)
    (macro bar () /*...*/))
```

# The encoding module

The _encoding module_ is the module that is currently being used to encode the data stream.
When the stream begins, the encoding module is the [system module](system_module.md).

The application may define a new encoding module by writing an _encoding directive_ at the top level of the stream.
An encoding directive is an s-expression annotated with `$ion_encoding`; its nested clauses define a new encoding module.

When the reader advances beyond an encoding directive, the module it defined becomes the new encoding module.

In the context of an encoding directive, the active encoding module is named `$ion_encoding`.
The encoding directive may preserve symbols or macros that were defined in the previous encoding directive by referencing `$ion_encoding`.
The `$ion_encoding` module may only be imported to an encoding directive, and it is done so automatically and implicitly.

### Examples

#### An encoding directive
A simple encoding directive—it defines a module that exports three symbols and two macros.
```ion
$ion_encoding::(
    (symbol_table [
        "a",  // $1
        "b",  // $2
        "c"   // $3
    ])
    (macro_table
      (macro pi () 3.14159265)
      (macro moon_landing_ts () 1969-07-20T20:17Z)
    )
)
```

#### Adding symbols to the encoding module
The implicitly imported `$ion_encoding` is used to append to the current symbol and macro tables.

```ion
$ion_encoding::(
    (symbol_table [
        "a",  // $1
        "b",  // $2
        "c",  // $3
    ])
    (macro_table
      (macro pi () 3.14159265)
      (macro moon_landing_ts () 1969-07-20T20:17Z)
    )
)

// ...

$ion_encoding::(
  // The first argument of the symbol_table clause is the module name '$ion_encoding',
  // which adds the symbols from the active encoding module to the new encoding module.
  // The '$ion_encoding' argument in the macro_table clause behaves similarly.
  (symbol_table $ion_encoding
                [
                  "d", // $4
                  "e", // $5
                  "f", // $6
                ])
  (macro_table $ion_encoding
               (macro e () 2.71828182))
)

// ...
```

#### Clearing the local symbols and local macros
```ion
$ion_encoding::()
```
The absence of the `symbol_table` and `macro_table` clauses is interpreted as empty symbol and macro tables.

Note that this is different from the behaviour of an IVM.
When an IVM is encountered, the encoding module is set to the system module.
