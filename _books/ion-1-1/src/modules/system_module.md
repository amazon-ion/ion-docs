## The System Module

The symbols and macros of the system module `$ion` are available everywhere within an Ion document,
with the version of that module being determined by the spec-version of each segment.
The specific system symbols are largely uninteresting to users; while the binary encoding heavily
leverages the system symbol table, the text encoding that users typically interact with does not.
The system macros are more visible, especially to authors of macros.

This chapter catalogs the system-provided symbols and macros.
The examples below use unqualified names, which works assuming no other macros with the same name are in scope. The unambiguous form `$ion::macro-name` is always available to use in the [template definition language](../macros/defining_macros.md#template-definition-language-tdl).

### Relation to Local Symbol and Macro Tables

In Ion 1.0, the system symbol table is always the first import of the local symbol table.
However, in Ion 1.1, the system symbol and macro tables have a system address space that is distinct from the local address space.
When starting an Ion 1.1 segment (i.e. immediately after encountering an `$ion_1_1` version marker),
the local symbol table is prepopulated with the system symbols[^note0]<a name="footnote-0"></a>. 
The local macro table is also prepopulated with the system macros.
However, the system symbols and macros are not permanent fixtures of the local symbol and macro tables respectively.


When a local macro has the same name as a system macro, it shadows the system macro.
In TDL, it is still possible to invoke a shadowed system macro by using a qualified name, such as `$ion::make_string`.
If a macro in the active local macro table has the same name as a system macro, it is impossible to invoke that system
macro by name using an E-Expression.
(It is still possible to invoke the system macro if the local macro table has assigned an alias for that system macro.)

### System Symbols

The Ion 1.1 System Symbol table _replaces_ rather than extends the Ion 1.0 System Symbol table. The system symbols are as follows:

<!-- make the tables align to the side of the page /-->
<style>table { margin: 1em;}</style>

| ID | Text                            |
|---:|:--------------------------------|
|  0 | _&lt;reserved&gt;_              |
|  1 | `$ion`                          |
|  2 | `$ion_1_0`                      |
|  3 | `$ion_symbol_table`             |
|  4 | `name`                          |
|  5 | `version`                       |
|  6 | `imports`                       |
|  7 | `symbols`                       |
|  8 | `max_id`                        |
|  9 | `$ion_shared_symbol_table`      |
| 10 | `$ion_encoding`                 |
| 11 | `$ion_literal`                  |
| 12 | `$ion_shared_module`            |
| 13 | `macro`                         |
| 14 | `macro_table`                   |
| 15 | `symbol_table`                  |
| 16 | `module`                        |
| 17 | see [ion-docs#345][1]           |
| 18 | `export`                        |
| 19 | see [ion-docs#345][1]           |
| 20 | `import`                        |
| 21 | _zero-length text_ (i.e. `''`)  |
| 22 | `literal`                       |
| 23 | `if_none`                       |
| 24 | `if_some`                       |
| 25 | `if_single`                     |
| 26 | `if_multi`                      |
| 27 | `for`                           |
| 28 | `fail`                          |
| 29 | `values`                        |
| 30 | `annotate`                      |
| 31 | `make_string`                   |
| 32 | `make_symbol`                   |
| 33 | `make_blob`                     |
| 34 | `make_decimal`                  |
| 35 | `make_timestamp`                |
| 36 | `make_list`                     |
| 37 | `make_sexp`                     |
| 38 | `make_struct`                   |
| 39 | `parse_ion`                     |
| 40 | `repeat`                        |
| 41 | `delta`                         |
| 42 | `flatten`                       |
| 43 | `sum`                           |
| 44 | `set_symbols`                   |
| 45 | `add_symbols`                   |
| 46 | `set_macros`                    |
| 47 | `add_macros`                    |
| 48 | `use`                           |
| 49 | `comment`                       |
| 50 | `flex_symbol`                   |
| 51 | `flex_int`                      |
| 52 | `flex_uint`                     |
| 53 | `uint8`                         |
| 54 | `uint16`                        |
| 55 | `uint32`                        |
| 56 | `uint64`                        |
| 57 | `int8`                          |
| 58 | `int16`                         |
| 59 | `int32`                         |
| 60 | `int64`                         |
| 61 | `float16`                       |
| 62 | `float32`                       |
| 63 | `float64`                       |
| 64 | `none`                          |
| 65 | `make_field`                    |

In Ion 1.1 Text, system symbols can never be referenced by symbol ID; `$1` always refers to the first symbol in the user symbol table.
This allows the Ion 1.1 system symbol table to be relatively large without taking away SID space from the user symbol table.

### System Macros

| ID | Text                                                          |
|---:|:--------------------------------------------------------------|
|  0 | [`none`](../macros/system_macros.md#none)                     |
|  1 | [`values`](../macros/system_macros.md#values)                 |
|  2 | [`annotate`](../macros/system_macros.md#annotate)             |
|  3 | [`make_string`](../macros/system_macros.md#make_string)       |
|  4 | [`make_symbol`](../macros/system_macros.md#make_symbol)       |
|  5 | [`make_blob`](../macros/system_macros.md#make_blob)           |
|  6 | [`make_decimal`](../macros/system_macros.md#make_decimal)     |
|  7 | [`make_timestamp`](../macros/system_macros.md#make_timestamp) |
|  8 | [`make_list`](../macros/system_macros.md#make_list)           |
|  9 | [`make_sexp`](../macros/system_macros.md#make_sexp)           |
| 10 | [`make_struct`](../macros/system_macros.md#make_struct)       |
| 11 | [`set_symbols`](../macros/system_macros.md#set_symbols)       |
| 12 | [`add_symbols`](../macros/system_macros.md#add_symbols)       |
| 13 | [`set_macros`](../macros/system_macros.md#set_macros)         |
| 14 | [`add_macros`](../macros/system_macros.md#add_macros)         |
| 15 | [`use`](../macros/system_macros.md#use)                       |
| 16 | [`parse_ion`](../macros/system_macros.md#parse_ion)           |
| 17 | [`repeat`](../macros/system_macros.md#repeat)                 |
| 18 | [`delta`](../macros/system_macros.md#delta)                   |
| 19 | [`flatten`](../macros/system_macros.md#flatten)               |
| 20 | [`sum`](../macros/system_macros.md#sum)                       |
| 21 | [`comment`](../macros/system_macros.md#comment)               |
| 22 | [`make_field`](../macros/system_macros.md#make_field)         |


----

[1]: https://github.com/amazon-ion/ion-docs/issues/345

<small>

[^note0]: System symbols require the same number of bytes whether they are encoded using the system symbol or the user 
symbol encoding. The reasons the system symbols are initially loaded into the user symbol table are twofold—to be 
consistent with loading the system macros into user space, and so that implementors can start testing user symbols 
even before they have implemented support for reading encoding directives.[^](#footnote-0)

</small>
