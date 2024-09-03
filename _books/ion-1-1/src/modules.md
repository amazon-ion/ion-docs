# Ion 1.1 Modules

In Ion 1.0, each stream has a [symbol table](https://amazon-ion.github.io/ion-docs/docs/symbols.html#processing-of-symbol-tables). The symbol table stores text values that can be referred to by their integer index in the table, providing a much more compact representation than repeating the full UTF-8 text bytes each time the value is used. Symbol tables do not store any other information used by the reader or writer.

Ion 1.1 introduces the concept of a _macro table_. It is analogous to the symbol table, but instead of holding text values it holds macro definitions.

Ion 1.1 also introduces the concept of a _module_, an organizational unit that holds a `(symbol table, macro table)` pair.

> [!TIP]
> You can think of an Ion 1.0 symbol table as a module with an empty macro table.

In Ion 1.1, each stream has an [encoding module](modules/encoding_module.md)--the active `(symbol table, macro table)` pair that is being used to encode the stream.

## Identifiers

Many of the grammatical elements used to define modules and macros are _identifiers_--symbols that do not require quotation marks.

More explicitly, an identifier is a sequence of one or more ASCII letters, digits, or the characters `$` (dollar sign) or `_` (underscore), not starting with a digit. It also cannot be of the form `$\d+`, which is the syntax for symbol IDs. (For example: `$3`, `$10`, `$458`, etc.)

## Defining a module

A module has four kinds of subclauses:

1. `symbol_table` - an exported list of text values.
2. `macro_table` - an exported list of macro definitions.
3. `module` - a nested module definition.
4. `import` - a reference to a shared module definition

<!-- TODO: `export` -->

### `symbol_table`

The `symbol_table` clause assembles a list of text values for the module to export. It takes any number of arguments.

#### Syntax
```ion
(symbol_table arg1 arg2 ... argN)
```

#### Processing

When the `symbol_table` clause is encountered, the reader constructs an empty list. The arguments to the clause are then processed from left to right.

For each `arg`:
* **If the `arg` is a list of text values**, the nested text values are appended to the end of the symbol table being constructed.
  * When `null`, `null.string`, `null.symbol`, or `$0` appear in the list of text values, this creates a symbol with unknown text.
  * The presence of any other Ion value in the list raises an error.
* **If the `arg` is the name of a module**, the symbols in that module's symbol table are appended to the end of the symbol table being constructed.
* **If the `arg` is anything else**, the reader must raise an error.

#### Example `symbol_table`

```ion
(symbol_table         // Constructs an empty symbol table (list)
  ["a", b, 'c']       // The text values in this list are appended to the table
  foo                 // Module `foo`'s symbol table values are appended to the table
  ['''g''', "h", i])  // The text values in this list are appended to the table
```
If module `foo`'s symbol table were `[d, e, f]`, then the symbol table defined by the above clause would be:
```ion
["a", "b", "c", "d", "e", "f", "g", "h", "i"]
```

### `macro_table`

The `macro_table` clause assembles a list of macro definitions for the module to export. It takes any number of arguments.

#### Syntax
```ion
(macro_table arg1 arg2 ... argN)
```
#### Processing

When the `macro_table` clause is encountered, the reader constructs an empty list. The arguments to the clause are then processed from left to right.

For each `arg`:
* **If the `arg` is a `macro` clause**, the clause is processed and the resulting macro definition is appended to the end of the macro table being constructed.
* **If the `arg` is the name of a module**, the macro definitions in that module's macro table are appended to the end of the macro table being constructed.
* **If the `arg` is anything else**, the reader must raise an error.


Macro definitions being added to the macro table must have a unique name. If a macro is added whose name conflicts with one already present in the table, the reader must raise an error.

### `macro`

The `macro` clause defines a new macro. See _[Defining macros](macros/defining_macros.md)_.

<!-- TODO: `import` -->
<!-- TODO: `module` -->
<!-- TODO: `export` -->

## Grammar

Literals appear in `code blocks`. Terminals are described in _italic text_.

<div>
<style>
table  {
  border: none;
  border-collapse: collapse;
}
</style>

| Production           |     | Body                                                   |
|----------------------|-----|--------------------------------------------------------|
| module               | ::= | `(module ` module-name-decl module-body `)`            |
| module-body          | ::= | import* module* symtab? mactab?                        |
| import               | ::= | `(import` module-name catalog-name catalog-version `)` |
| symtab               | ::= | `(symbol_table ` symtab-item* `)`                      |
| symtab-item          | ::= | module-name \| symbol-def-seq                          |
| symbol-def-seq       | ::= | _a list of unannotated text values (string/symbol)_    |
| mactab               | ::= | `(macro_table ` mactab-item* `)`                       |
| mactab-item          | ::= | module-name \| macro-def \| macro-export               |
| macro-def            | ::= | `(macro ` macro-name signature tdl-template `)`        |
| macro-export         | ::= | `(export ` macro-ref macro-name? `)`                   |
| catalog-name         | ::= | _unannotated string_                                   |
| catalog-version      | ::= | _unannotated int_                                      |
| module-name          | ::= | _unannotated idenfitier symbol_                        |
| macro-ref            | ::= | macro-name \| qualified-macro-name \| macro-address    |
| macro-name-decl      | ::= | macro-name-ref \| `null`                               |
| macro-name           | ::= | _unannotated idenfitier symbol_                        |
| qualified-macro-name | ::= | module-name `::` macro-name                            |

</div>