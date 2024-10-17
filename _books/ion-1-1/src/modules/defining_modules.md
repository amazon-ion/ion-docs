# Defining Modules

A module is defined by four kinds of subclauses which, if present, always appear in the same order.

1. `import` - a reference to a shared module definition; repeatable
2. `module` - a nested module definition; repeatable
3. `symbol_table` - an exported list of text values
4. `macro_table` - an exported list of macro definitions


### Internal Environment

The body of a module tracks an internal environment by which macro references are resolved.
This environment is constructed incrementally by each clause in the definition and consists of:

* the _visible modules_, a map from identifier to module
* the _exported macros_, an array containing name/macro pairs

Before any clauses of the module definition are examined, the initial environment is as follows:

* The visible modules map `$ion` to the system module for the appropriate spec version.
  Inside an encoding directive, the visible modules also maps `$ion_encoding` to the current encoding module.
  For an inner module, it also includes the modules previously made available by the enclosing
  module (via `import` or `module`).
* The macro table and symbol table are empty.

Each clause affects the environment as follows:

* An `import` declaration retrieves a shared module from the implementation’s catalog, assigns
  it a name in the visible modules, and makes its macros available for use.
  An error must be signaled if the name already appears in the visible modules.
* A `module` declaration defines a new module and assigns it a name in the visible modules.
  An error must be signaled if the name already appears in the visible modules.
* A `macro_table` declaration defines the exported macros.

### Resolving Macro References

Within a module definition, macros can be referenced in several contexts using the following
_macro-ref_ syntax:

```bnf
qualified-ref      ::= module-name '::' macro-ref

macro-ref          ::= macro-name | macro-addr

macro-name         ::= unannotated-identifier-symbol

macro-addr         ::= unannotated-uint 
```

Macro references are resolved to a specific macro as follows:

* An unqualified _macro-name_ is looked up within the exported macros, and if not found, then the system module.
  If it maps to a macro, that’s the resolution of the reference.
  Otherwise, an error is signaled due to an unbound reference.
* An anonymous local reference  (`__address__`) is resolved by index in the exported macro array.
  If the address exceeds the array boundary, an error is signaled due to an invalid reference.
* A qualified reference (`__module__::__name-or-address__`) resolves solely against the referenced module.
  If the module name does not exist in the visible modules, an error is signaled due to an unbound reference.
  Otherwise, the name or address is resolved within that module’s exported macro array.

> [!WARNING]
> An unqualified macro name can change meaning in the middle of a module if you choose to shadow the
> name of a system macro. The system macros are imported and used with that meaning, then a declaration
> shadows that name and gives it a new meaning.


### `import`

```bnf
import ::= '(import ' module-name catalog-key ')'
```

An import binds a lexically scoped module name to a shared symbol table that is identified by a catalog key—that is a `(name, version)` pair. The `version` of the catalog key is optional—when omitted, the version is implicitly 1.

In Ion 1.0, imports may be substituted with a different version if an exact match is not found.
In Ion 1.1, however, all imports require an exact match to be found in the reader's catalog;
if an exact match is not found, the implementation must signal an error.

<!-- TODO: more details here -->

### `module`

The `module` clause defines a new module that is contained in the current module.

```bnf
inner-module ::= '(module' module-name import* symbol-table? macro-table? ')'
```

Inner modules automatically have access to modules previously declared in the containing module using `module` or `import`.
The new module (and its exported symbols and macros) is available to any following `module`, `symbol_table`, and
`macro_table` clauses in the enclosing container. 

See [inner modules](inner_modules.md) for full explanation.

### `symbol_table`

A module can define a list of exported symbols by copying symbols from other modules and/or declaring new symbols.

```bnf
symbol-table       ::= '(symbol_table' symbol-table-entry* ')'

symbol-table-entry ::= module-name | symbol-list

symbol-list        ::= '[' (symbol | string)* ']'
```

The `symbol_table` clause assembles a list of text values for the module to export.
It takes any number of arguments, each of which may be the name of visible module or a list of symbol-texts.
The symbol table is  a list of symbol-texts by concatenating the symbol tables of named modules and lists of symbol/string values.

Where a module name occurs, its symbol table is appended.
(The module name must refer to another module that is visible to the current module.)
Unlike Ion 1.0, no _symbol-maxid_ is needed because Ion 1.1 always required exact matches for imported modules.

Where a list occurs, it must contain only non-null, unannotated strings and symbols.
The text of these strings and/or symbols are appended to the symbol table.
Upon encountering any non-text value, null value, or annotated value in the list, the implementation shall signal an error.  
To create an intentional gap in the symbol table, one may use `$0`.

All modules have a symbol table, so when a module has no `symbol_table` clause, the module has an empty symbol table. 

#### Processing

When the `symbol_table` clause is encountered, the reader constructs an empty list. The arguments to the clause are then processed from left to right.

For each `arg`:
* **If the `arg` is a list of text values**, the nested text values are appended to the end of the symbol table being constructed.
  * When `$0` appears in the list of text values, this creates a symbol with unknown text.
  * The presence of any other Ion value in the list raises an error.
* **If the `arg` is the name of a module**, the symbols in that module's symbol table are appended to the end of the symbol table being constructed.
* **If the `arg` is anything else**, the reader must raise an error.

#### Example

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
$ion_encoding::(
  (import m1 "com.example.shared1" 1)
  (import m2 "com.example.shared2" 2)
  (symbol_table m1 m2 ["s1", "s2"])
)
```



### `macro_table`

Macros are declared after symbols.
The `macro_table` clause assembles a list of macro definitions for the module to export. It takes any number of arguments.
All modules have a macro table, so when a module has no `macro_table` clause, the module has an empty macro table.

Most commonly, a macro table entry is a definition of a new macro expansion function, following
this general shape:

When no name is given, this defines an anonymous macro that can be referenced by its numeric
address (that is, its index in the enclosing macro table).
Inside the defining module, that uses a local reference like `12`.

The _signature_ defines the syntactic shape of expressions invoking the macro;
see [Macro Signatures](../macros/defining_macros.md#macro-signatures) for details.
The _template_ defines the expansion of the macro, in terms of the signature’s parameters;
see [Template Expressions](../macros/defining_macros.md#template-definition-language-tdl) for details.

Imported macros must be explicitly exported if so desired.
Module names and `export` clauses can be intermingled with `macro` definitions inside the `macro_table`;
together, they determine the bindings that make up the module’s exported macro array.

The _module-name_ export form is shorthand for referencing all exported macros from that module,
in their original order with their original names.

An `export` clause contains a single macro reference followed by an optional alias for the exported macro.
The referenced macro is appended to the macro table.

> [!TIP]
> No name can be repeated among the exported macros, including macro definitions.
> Name conflicts must be resolved by `export`s with aliases.

#### Processing

When the `macro_table` clause is encountered, the reader constructs an empty list. The arguments to the clause are then processed from left to right.

For each `arg`:
* **If the `arg` is a `macro` clause**, the clause is processed and the resulting macro definition is appended 
  to the end of the macro table being constructed.
* **If the `arg` is an `export` clause**, the clause is processed and the referenced macro definition is appended 
  to the end of the macro table being constructed.
* **If the `arg` is the name of a module**, the macro definitions in that module's macro table are appended
  to the end of the macro table being constructed.
* **If the `arg` is anything else**, the reader must raise an error.


A macro name is a symbol that can be used to reference a macro, both inside and outside the module.
Macro names are optional, and improve legibility when using, writing, and debugging macros.
When a name is used, it must be an identifier per Ion’s syntax for symbols.
Macro definitions being added to the macro table must have a unique name.
If a macro is added whose name conflicts with one already present in the table, the implementation must raise an error.

#### `macro`

A `macro` clause [defines a new macro](../macros/defining_macros.md).
When the macro declaration uses a name, an error must be signaled if it already appears in the exported macro array.

#### `export`

An `export` clause declares a name for an existing macro and appends the macro to the macro table.
* If the reference to the existing macro is followed by a name, the existing macro is appended to the exported
  macro array with the latter name instead of the original name, if any.
  An error must be signaled if that name already appears in the exported macro array.
* If the reference to the existing macro is followed by `null`, the macro is appended to the exported macro array 
  without a name, regardless of whether the macro has a name.
* If the reference to the existing macro is anonymous, the macro is appended to the exported macro array without
  a name.
* When the reference to the existing macro uses a name, the name and macro are appended to the exported macro  
  array. An error must be signaled if that name already appears in the exported macro array.


#### Module names in `macro_table`
A module name appends all exported macros from the module to the exported macro array.
If any exported macro uses a name that already appears in the exported macro array, an error must be signaled.
