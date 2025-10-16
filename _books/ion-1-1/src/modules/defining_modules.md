# Defining modules

A module is defined by two kinds of subclauses which, if present, always appear in the same order.

1. `macros` - an exported list of macro definitions
2. `symbols` - an exported list of text values

The lexical name given to a module definition must be an [identifier](../modules.md#identifiers).
However, it must not begin with a `$`—this is reserved for system-defined bindings like `$ion`.

### Internal environment

The body of a module tracks an internal environment by which macro references are resolved.
This environment is constructed incrementally by each clause in the definition and consists of:

* the _exported symbols_, an array containing symbol texts
* the _exported macros_, an array containing name/macro pairs

Before any clauses of the module definition are examined, each of these is empty.

Each clause affects the environment as follows:

* A `macros` declaration defines the exported macros.
* A `symbols` declaration defines the exported symbols.

### `macros`

The `macros` clause assembles a list of macro definitions for the module to export. It takes any number of arguments.
All modules have a macro table, so when a module has no `macros` clause, the module has an empty macro table.

Most commonly, a macro table entry is a definition of a new macro expansion function, following this general shape:

```ion
//  ┌─── `macro` keyword
//  │   ┌─── macro name
//  │   │   ┌─── template
//  │   │   │
(macro foo {a:(:?),b:(:?)})
```
(See the [_Defining macros_](../macros/defining_macros.md) for details.)

When the value `null` is given for the macro name, this defines an anonymous macro that can be referenced by its numeric
address (that is, its index in the enclosing macro table).

Module names can be intermingled with macro definition s-expressions inside the `macros` clause;
together, they determine the bindings that make up the module’s exported macro array.

The _module-name_ export form is shorthand for referencing all exported macros from that module,
in their original order with their original names.

> [!TIP]
> No name can be repeated among the exported macros, including macro definitions.

#### Processing

When the `macros` clause is encountered, the reader constructs an empty list. The arguments to the clause are then processed from left to right.

For each `arg`:
* **If the `arg` is an s-expression**, it is processed as a macro definition, which is appended
  to the end of the macro table being constructed.
* **If the `arg` is the name of a module**, the macro definitions in that module's macro table are appended
  to the end of the macro table being constructed.
* **If the `arg` is anything else**, the reader must raise an error.


A macro name is a symbol that can be used to reference a macro, both inside and outside the module.
Macro names are optional, and improve legibility when using, writing, and debugging macros.
When a name is used, it must be an identifier per Ion’s syntax for symbols.
Macro definitions being added to the macro table must have a unique name.
If a macro is added whose name conflicts with one already present in the table, the implementation must raise an error.

#### S-expressions in `macros`

An s-expression in `macros` [defines a new macro](../macros/defining_macros.md).
When the macro declaration uses a name, an error must be signaled if it already appears in the exported macro array.

#### Module names in `macros`
A module name appends all exported macros from the module to the exported macro array.
If any exported macro uses a name that already appears in the exported macro array, an error must be signaled.


### `symbols`

A module can define a list of exported symbols by copying symbols from other modules and/or declaring new symbols.

```bnf
symbol-table       ::= '(symbols' symbol-table-entry* ')'

symbol-table-entry ::= module-name | symbol-list

symbol-list        ::= '[' ( symbol-text ',' )* ']'

symbol-text        ::= symbol | string
```

The `symbols` clause assembles a list of text values for the module to export.
It takes any number of arguments, each of which may be the name of visible module or a list of symbol-texts.
The symbol table is a list of symbol-texts by concatenating the symbol tables of named modules and lists of symbol/string values.

Where a module name occurs, its symbol table is appended.
(The module name must refer to another module that is visible to the current module.)
Unlike Ion 1.0, no _symbol-maxid_ is needed because Ion 1.1 always requires exact matches for imported modules.

> [!TIP]
> When redefining a top-level module binding,
> the binding being redefined can be added to the symbol table in order to retain its symbols.
> For example:
>
> ```ion
> // Define module `foo`
> (:$ion module foo
>     (symbols ["b", "c"]))
>
> // Redefine `foo` in terms of its former definition
> (:$ion module foo
>     (symbols
>         ["a"]
>         foo // The old definition of `foo` with symbols ["b", "c"]
>         ["d"]))
>
> // Now `foo`'s symbol table is ["a", "b", "c", "d"]
> ```

Where a list occurs, it must contain only non-null, unannotated strings and symbols.
The text of these strings and/or symbols are appended to the symbol table.
Upon encountering any non-text value, null value, or annotated value in the list, the implementation shall signal an error.  
To add a symbol with unknown text to the symbol table, one may use `$0`.

All modules have a symbol table, so when a module has no `symbols` clause, the module has an empty symbol table.

#### Symbol zero `$0`


Symbol zero (i.e. `$0`) is a special symbol that is not assigned text by any symbol table, even the system symbol table.
Symbol zero always has unknown text, and can be useful in synthesizing symbol identifiers where the text of the symbol is not known in a particular operating context.

All symbol tables (even an empty symbol table) can be thought of as implicitly containing `$0`.
However, `$0` precedes all symbol tables rather than belonging to any symbol table.
When adding the exported symbols from one module to the symbol table of another, the preceding `$0` is not copied into the destination symbol table (because it is not part of the source symbol table).

It is important to note that `$0` is only semantically equivalent to itself and to locally-declared SIDs with unknown text.
It is not semantically equivalent to SIDs with unknown text from shared symbol tables, so replacing such SIDs with `$0` is a destructive operation to the semantics of the data.

#### Processing

When the `symbols` clause is encountered, the reader constructs an empty list. The arguments to the clause are then processed from left to right.

For each `arg`:
* **If the `arg` is a list of text values**, the nested text values are appended to the end of the symbol table being constructed.
  * When `$0` appears in the list of text values, this creates a symbol with unknown text.
  * The presence of any other Ion value in the list raises an error.
* **If the `arg` is the name of a module**, the symbols in that module's symbol table are appended to the end of the symbol table being constructed.
* **If the `arg` is anything else**, the reader must raise an error.

#### Example

```ion
(symbols         // Constructs an empty symbol table (list)
  ["a", b, 'c']       // The text values in this list are appended to the table
  foo                 // Module `foo`'s symbol table values are appended to the table
  ['''g''', "h", i])  // The text values in this list are appended to the table
```
If module `foo`'s symbol table were `[d, e, f]`, then the symbol table defined by the above clause would be:
```ion
["a", "b", "c", "d", "e", "f", "g", "h", "i"]
```
This is an Ion 1.0 symbol table that imports two shared symbol tables and then declares some symbols of its own.

```ion
$ion_1_0
$ion_symbol_table::{
  imports: [{ name: "com.example.shared1", version: 1, max_id: 10 },
            { name: "com.example.shared2", version: 2, max_id: 20 }],
  symbols: ["s1", "s2"]
}
```
Here’s the Ion 1.1 equivalent in terms of symbol allocation order:

```ion
$ion_1_1
(:$ion import m1 "com.example.shared1" 1)
(:$ion import m2 "com.example.shared2" 2)
(:$ion module _ 
  (symbols m1 m2 ["s1", "s2"])
)
```

> [!NOTE]
> Alternately, one could use the default module directives to avoid the boilerplate of creating bindings for the imported modules.
> However, this has slightly different semantics because `use` also brings in the macros from the imported modules.
> ```ion
> $ion_1_1
> (:$ion use "com.example.shared1" 1)
> (:$ion use "com.example.shared2" 2)
> (:$ion add_symbols "s1" "s2")
> ```
