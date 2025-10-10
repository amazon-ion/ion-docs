# Ion 1.1 modules

In Ion 1.0, each stream has a [symbol table](https://amazon-ion.github.io/ion-docs/docs/symbols.html#processing-of-symbol-tables). The symbol table stores text values that can be referred to by their integer index in the table, providing a much more compact representation than repeating the full UTF-8 text bytes each time the value is used. Symbol tables do not store any other information used by the reader or writer.

Ion 1.1 introduces the concept of a _macro table_. It is analogous to the symbol table, but instead of holding text values it holds macro definitions.

Ion 1.1 also introduces the concept of a _module_, an organizational unit that holds a `(symbol table, macro table)` pair.

> [!TIP]
> You can think of an Ion 1.0 symbol table as a module with an empty macro table.

In Ion 1.1, each stream has an [encoding module sequence](modules/encoding_modules.md)—
a collection of modules whose symbols and macros are being used to encode the current segment.

## Module interface

The interface to a module consists of:

* its _spec version_, denoting the Ion version used to define the module
* its _exported symbols_, an array of strings denoting symbol content
* its _exported macros_, an array of `<name, macro>` pairs, where all names (where specified) are unique identifiers

The spec version is external to the module body and the precise way it is determined depends on the type of module being defined. This is explained in further detail in [Module Versioning](#module-versioning).

The exported macro array is denoted by the module’s `macros` clause, with addresses
allocated to macros or macro bindings in the order they are declared.

The exported symbol array is denoted by the `symbols` clause of a module definition, and
by the `symbols` field of a shared symbol table. The new symbols defined in the `symbols` clause are not available in the preceding `macros` clause.

The exported symbols and exported macros are defined in the [module body](modules/defining_modules.md).


## Types of modules

There are multiple types of modules.
All modules share the same interface, but vary in their implementation in order to support a variety of different use cases.

| Module Type                                     | Purpose                                                         |
|:------------------------------------------------|:----------------------------------------------------------------|
| [Local Modules](modules/local_modules.md)       | Organizing symbols and macros within a scope                    |
| [Shared Modules](modules/shared_modules.md)     | Defining reusable symbols and macros outside of the data stream |
| [System Modules](modules/system_module.md)      | Defining system symbols and macros                              |
| [Encoding Modules](modules/encoding_modules.md) | Encoding the current stream segment                             |


## Module versioning

Every module definition has a _spec version_ that determines the syntax and semantics of the module body.
A module’s spec version is expressed in terms of a specific Ion version;
the meaning of the module is as defined by that version of the Ion specification.

The spec version for a local module is inherited from its parent scope, which may be the stream itself.
The spec version of a system module is the Ion version in which it was specified.

To ensure that all consumers of a module can properly understand it, a module can only import
shared modules defined with the same or earlier spec version.

#### Examples

The spec version of a local module is always the same as the spec version of its enclosing scope.
If the local module is defined at the top level of the stream,
its spec version is the Ion version of the current segment.

```ion
$ion_1_1
(:$ion module foo
  // Module semantics specified by Ion 1.1
  ...
)

// ...

$ion_1_3
(:$ion module foo
  // Module semantics specified by Ion 1.3
  ...
)
//...                  // Assuming no IVM
(:$ion module bar
  // Module semantics specified by Ion 1.3
  ...
)
```

## Identifiers

Many of the grammatical elements used to define modules and macros are _identifiers_--symbols that do not require quotation marks.

More explicitly, an identifier is a sequence of one or more ASCII letters, digits, or the characters `$` (dollar sign) or `_` (underscore), not starting with a digit.
It also cannot be of the form `$\d+`, which is the syntax for symbol IDs (for example: `$3`, `$10`, `$458`, etc.), nor can it be a keyword (`true`, `false`, `null`, or `nan`).
