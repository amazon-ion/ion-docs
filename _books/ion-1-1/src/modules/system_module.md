# The system module

The symbols and macros of the system module `$ion` are available everywhere within an Ion document,
with the version of that module being determined by the spec-version of each segment.
The specific system symbols are largely uninteresting to users; while the binary encoding heavily
leverages the system symbol table, the text encoding that users typically interact with does not.
The system macros are more visible, especially to authors of macros.

This chapter catalogs the system-provided symbols and macros.
The examples below use unqualified names, which works assuming no other macros with the same name are in scope. The unambiguous form `$ion::macro-name` is always available to use in the [template definition language](../macros/defining_macros.md#template-definition-language-tdl).

### Relation to local symbol and macro tables

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

| ID | Hex  | Text                           |
|---:|:----:|:-------------------------------|
|  0 | 0x00 | _&lt;reserved&gt;_             |
|  1 | 0x01 | `$ion`                         |
|  2 | 0x02 | `$ion_1_0`                     |
|  3 | 0x03 | `$ion_symbol_table`            |
|  4 | 0x04 | `name`                         |
|  5 | 0x05 | `version`                      |
|  6 | 0x06 | `imports`                      |
|  7 | 0x07 | `symbols`                      |
|  8 | 0x08 | `max_id`                       |
|  9 | 0x09 | `$ion_shared_symbol_table`     |
| 10 | 0x0A | `$ion_encoding`                |
| 11 | 0x0B | `$ion_literal`                 |
| 12 | 0x0C | `$ion_shared_module`           |
| 13 | 0x0D | `macro`                        |
| 14 | 0x0E | `macro_table`                  |
| 15 | 0x0F | `symbol_table`                 |
| 16 | 0x10 | `module`                       |
| 17 | 0x11 | see [ion-docs#345][1]          |
| 18 | 0x12 | `export`                       |
| 19 | 0x13 | see [ion-docs#345][1]          |
| 20 | 0x14 | `import`                       |
| 21 | 0x15 | _zero-length text_ (i.e. `''`) |
| 22 | 0x16 | `literal`                      |
| 23 | 0x17 | `if_none`                      |
| 24 | 0x18 | `if_some`                      |
| 25 | 0x19 | `if_single`                    |
| 26 | 0x1A | `if_multi`                     |
| 27 | 0x1B | `for`                          |
| 28 | 0x1C | `default`                      |
| 29 | 0x1D | `values`                       |
| 30 | 0x1E | `annotate`                     |
| 31 | 0x1F | `make_string`                  |
| 32 | 0x20 | `make_symbol`                  |
| 33 | 0x21 | `make_blob`                    |
| 34 | 0x22 | `make_decimal`                 |
| 35 | 0x23 | `make_timestamp`               |
| 36 | 0x24 | `make_list`                    |
| 37 | 0x25 | `make_sexp`                    |
| 38 | 0x26 | `make_struct`                  |
| 39 | 0x27 | `parse_ion`                    |
| 40 | 0x28 | `repeat`                       |
| 41 | 0x29 | `delta`                        |
| 42 | 0x2A | `flatten`                      |
| 43 | 0x2B | `sum`                          |
| 44 | 0x2C | `set_symbols`                  |
| 45 | 0x2D | `add_symbols`                  |
| 46 | 0x2E | `set_macros`                   |
| 47 | 0x2F | `add_macros`                   |
| 48 | 0x30 | `use`                          |
| 49 | 0x31 | `meta`                         |
| 50 | 0x32 | `flex_symbol`                  |
| 51 | 0x33 | `flex_int`                     |
| 52 | 0x34 | `flex_uint`                    |
| 53 | 0x35 | `uint8`                        |
| 54 | 0x36 | `uint16`                       |
| 55 | 0x37 | `uint32`                       |
| 56 | 0x38 | `uint64`                       |
| 57 | 0x39 | `int8`                         |
| 58 | 0x3A | `int16`                        |
| 59 | 0x3B | `int32`                        |
| 60 | 0x3C | `int64`                        |
| 61 | 0x3D | `float16`                      |
| 62 | 0x3E | `float32`                      |
| 63 | 0x3F | `float64`                      |
| 64 | 0x40 | `none`                         |
| 65 | 0x41 | `make_field`                   |

In Ion 1.1 Text, system symbols can never be referenced by symbol ID; `$1` always refers to the first symbol in the user symbol table.
This allows the Ion 1.1 system symbol table to be relatively large without taking away SID space from the user symbol table.

### System Macros

| ID | Hex  | Text                                                          |
|---:|:----:|:--------------------------------------------------------------|
|  0 | 0x00 | [`none`](../macros/system_macros.md#none)                     |
|  1 | 0x01 | [`values`](../macros/system_macros.md#values)                 |
|  2 | 0x02 | [`annotate`](../macros/system_macros.md#annotate)             |
|  3 | 0x03 | [`make_string`](../macros/system_macros.md#make_string)       |
|  4 | 0x04 | [`make_symbol`](../macros/system_macros.md#make_symbol)       |
|  5 | 0x05 | [`make_blob`](../macros/system_macros.md#make_blob)           |
|  6 | 0x06 | [`make_decimal`](../macros/system_macros.md#make_decimal)     |
|  7 | 0x07 | [`make_timestamp`](../macros/system_macros.md#make_timestamp) |
|  8 | 0x08 | [`make_list`](../macros/system_macros.md#make_list)           |
|  9 | 0x09 | [`make_sexp`](../macros/system_macros.md#make_sexp)           |
| 10 | 0x0A | [`make_struct`](../macros/system_macros.md#make_struct)       |
| 11 | 0x0B | [`set_symbols`](../macros/system_macros.md#set_symbols)       |
| 12 | 0x0C | [`add_symbols`](../macros/system_macros.md#add_symbols)       |
| 13 | 0x0D | [`set_macros`](../macros/system_macros.md#set_macros)         |
| 14 | 0x0E | [`add_macros`](../macros/system_macros.md#add_macros)         |
| 15 | 0x0F | [`use`](../macros/system_macros.md#use)                       |
| 16 | 0x10 | [`parse_ion`](../macros/system_macros.md#parse_ion)           |
| 17 | 0x11 | [`repeat`](../macros/system_macros.md#repeat)                 |
| 18 | 0x12 | [`delta`](../macros/system_macros.md#delta)                   |
| 19 | 0x13 | [`flatten`](../macros/system_macros.md#flatten)               |
| 20 | 0x14 | [`sum`](../macros/system_macros.md#sum)                       |
| 21 | 0x15 | [`meta`](../macros/system_macros.md#meta)                     |
| 22 | 0x16 | [`make_field`](../macros/system_macros.md#make_field)         |
| 23 | 0x17 | [`default`](../macros/system_macros.md#default)               |


----

[1]: https://github.com/amazon-ion/ion-docs/issues/345

<small>

[^note0]: System symbols require the same number of bytes whether they are encoded using the system symbol or the user 
symbol encoding. The reasons the system symbols are initially loaded into the user symbol table are twofold—to be 
consistent with loading the system macros into user space, and so that implementors can start testing user symbols 
even before they have implemented support for reading encoding directives.[^](#footnote-0)

</small>
