# Directives

_Directives_ are system values that modify the encoding context.

Syntactically, a directive is a top-level s-expression annotated with `$ion`.
Its first child value is an operation name.
The operation determines what changes will be made to the encoding context and which clauses may legally follow.

```ion
$ion::
(operation_name
    (clause_1 /*...*/)
    (clause_2 /*...*/)
    /*...more clauses...*/
    (clause_N /*...*/))
```

In Ion v1.1, there are three directive operations:
1. [`module`](#module-directives)
2. [`import`](#import-directives)
3. [`encoding`](#encoding-directives)

## Top-level bindings

Module bindings at the stream-level can be redefined.

> [!TIP]
> The [`add_macros`](../macros/system_macros.md#add_macros) and [`add_symbols`](../macros/system_macros.md#add_symbols)
> work by redefining the default module (`_`) in terms of itself.

This differs from module bindings created inside another module;
[attempting to redefine these will raise an error](defining_modules.md#internal-environment).

## `module` directives
The `module` directive binds a name to a [local module](local_modules.md) definition at the top level of the stream.

```ion
$ion::
(module foo
    /*...imports, if any...*/
    /*...submodules, if any...*/
    (macro_table /*...*/)
    (symbol_table /*...*/)
)
```

Once created, module bindings at this level endure until the file ends or another Ion version marker is encountered.

## `import` directives

The _import_ directive looks up the module corresponding to the given `(name, value)` pair in the catalog.
Upon success, it creates a new binding to that module at the top level of the stream.

```ion
$ion::
(import
    bar               // Binding
    "com.example.bar" // Module name
    2)                // Module version
```

Once created, module bindings at this level endure until the file ends or another Ion version marker is encountered.

## `encoding` directives

The `encoding` directive accepts a sequence of module bindings and definitions whose contained symbols and macros will be used to encode the following stream segment.

```ion
$ion::
(encoding
    mod_a
    (module mod_b
        (macro_table
            (macro foo () Foo)))
    mod_c)
```

The new encoding module sequence takes effect immediately after the directive and remains the same until the next `encoding` directive or Ion version marker.

An _encoding directive_ defines a sequence of modules whose macros and symbols will be used to define the stream segment to follow.

```ion
$ion::(encoding foo bar baz)
```

These modules—the segment's _encoding modules_—must be defined or imported in the stream prior to appearing in an encoding directive.
Modules that are in the encoding module sequence for the current segment are said to be _active_,
while modules that are defined or imported but not in the encoding module sequence are _available_.


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
