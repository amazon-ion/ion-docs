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

In Ion v1.1, there are three supported directive operations:
1. [`module`](#module-directives)
2. [`import`](#import-directives)
3. [`encoding`](#encoding-directives)

## Top-level bindings

The `module` and `import` directives each create a stream-level binding to a module definition.
Once created, module bindings at this level endure until the file ends or another Ion version marker is encountered.

Module bindings at the stream-level can be redefined.

> [!TIP]
> The [`add_macros`](../macros/system_macros.md#add_macros) and [`add_symbols`](../macros/system_macros.md#add_symbols)
> system macros work by redefining the default module (`_`) in terms of itself.

This behavior differs from module bindings created inside another module;
[attempting to redefine these will raise an error](defining_modules.md#internal-environment).

### `module` directives
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

### `import` directives

The _import_ directive looks up the module corresponding to the given `(name, version)` pair in the catalog.
Upon success, it creates a new binding to that module at the top level of the stream.

```ion
$ion::
(import
    bar               // Binding
    "com.example.bar" // Module name
    2)                // Module version
```
If the catalog does contain an exact match, this operation raises an error.

## `encoding` directives

An `encoding` directive accepts a sequence of module bindings to use as the following stream segment's
[encoding module sequence](encoding_modules.md).

```ion
$ion::
(encoding
    mod_a
    mod_b
    mod_c)
```

The new encoding module sequence takes effect immediately after the directive and remains the same until the next `encoding` directive or Ion version marker.

Note that the [default module](encoding_modules.md#default-module) is always implicitly at the head of the encoding module sequence.