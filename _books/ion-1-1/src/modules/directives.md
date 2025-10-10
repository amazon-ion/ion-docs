# Directives

_Directives_ are system values that modify the encoding context.

Syntactically, a directive is a top-level e-expression `$ion`.
Its first child value is an operation name.
The operation determines what changes will be made to the encoding context and which clauses may legally follow.

The operation declared in a directive is applied to the encoding context immediately after the directive's closing delimiter.
This guarantees that the encoding context is immutable while _in_ a directive.

```ion
(:$ion operation_name
    (clause_1 /*...*/)
    (clause_2 /*...*/)
    /*...more clauses...*/
    (clause_N /*...*/))
```

In Ion 1.1, there are eight supported directive operations—
[`module`](#module-directives),
[`import`](#import-directives),
[`encoding`](#encoding-directives),
[`set_symbols`](#set_symbols-directives),
[`add_symbols`](#add_symbols-directives),
[`set_macros`](#set_macros-directives),
[`add_macros`](#add_macros-directives),
and [`use`](#use-directives).


## Top-level bindings

The `module` and `import` directives each create a stream-level binding to a module definition.
Once created, module bindings at this level endure until the file ends or another Ion version marker is encountered.
Module bindings at the stream-level can be redefined.

### `module` directives
The `module` directive binds a name to a [local module](local_modules.md) definition at the top level of the stream.

```ion
(:$ion module foo
    (macros /*...*/)
    (symbols /*...*/)
)
```

### `import` directives

The _import_ directive looks up the module corresponding to the given `(name, version)` pair in the catalog.
Upon success, it creates a new binding to that module at the top level of the stream.

```ion
(:$ion import
    bar               // Binding
    "com.example.bar" // Module name
    2)                // Module version
```
The `version` can be omitted. When it is not specified, it defaults to `1`.

If the catalog does contain an exact match, this operation raises an error.

## `encoding` directives

An `encoding` directive accepts a sequence of module bindings to use as the following stream segment's
[encoding module sequence](encoding_modules.md).

```ion
(:$ion encoding
    mod_a
    mod_b
    mod_c)
```

The new encoding module sequence takes effect immediately after the directive's closing delimiter and remains the same until the next `encoding` directive or Ion version marker.

Note that the [`$ion` module](system_module.md#the-ion-module) and [default module](encoding_modules.md#the-default-module) are always implicitly at the head of the encoding module sequence.

## Default module manipulation

Because of the relative importance of the [default module](encoding_modules.md#the-default-module),
Ion 1.1 provides directives that are optimized for manipulating the default module.
All of these operations can be defined in terms of the `module` and `import` directives, but using these operations
is more compact.

### `set_symbols` directives
Replaces the symbol table of the default module with a new one.

```ion
(:$ion set_symbols "foo" "bar" "baz")
```

Equivalent to:
```ion
(:$ion module _ (macros _) (symbols "foo" "bar" "baz"))
```


### `add_symbols` directives
Adds symbols to the symbol table of the default module.

```ion
(:$ion add_symbols "qux" "quux")
```

Equivalent to:
```ion
(:$ion module _ (macros _) (symbols _ "foo" "bar" "baz"))
```

### `set_macros` directives
Replaces the macro table of the default module with new macro definitions.

All content of this directive must be `macro` clauses, and indeed they are assumed to be, so the `macro` keyword is omitted.

```ion
(:$ion set_macros
  (point2d {x: (:?), y: (:?)})
  (greeting {message: (:? "Hello"), name: (:?)})
)
```

Equivalent to:
```ion
(:$ion module _
              (macros (macro point2d {x: (:?), y: (:?)})
                      (macro greeting {message: (:? "Hello"), name: (:?)}))
              (symbols _))
```

### `add_macros` directives
Adds macro definitions to the macro table of the default module.
All content of this directive must be `macro` clauses, and indeed they are assumed to be, so the `macro` keyword is omitted.

```ion
(:$ion add_macros 
  (rgb [(:?\uint8\), (:?\uint8\), (:?\uint8\)])
)
```

Equivalent to:
```ion
(:$ion module _
              (macros _ (rgb [(:?\uint8\), (:?\uint8\), (:?\uint8\)]))
              (symbols _))
```

### `use` directives
Imports macros and symbols from a shared module and appends them to the default module.
If the catalog does not contain an exact match, this operation raises an error.

```ion
// Adds the content of this shared symbol table to the default module
(:$ion use "com.example.geometry" 2)

// Equivalent to the following, except that `use` does not create any top-level binding like `import` does
($ion import $temp "com.example.geometry" 2)
($ion module _ (macros _ $temp) (symbols _ $temp))
($ion module $temp)
```

When the version is not provided, a default value of 1 is used.
```ion
// Defaults to version 1
(:$ion use "com.example.geometry")
```
