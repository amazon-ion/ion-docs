# The system module

The symbols and macros of the system module `$ion` are available everywhere within an Ion document,
with the version of that module being determined by the spec-version of each segment.
The specific system symbols are largely uninteresting to users; while the binary encoding heavily
leverages the system symbol table, the text encoding that users typically interact with does not.
The system macros are more visible, especially to authors of macros.

This chapter catalogs the system-provided symbols and macros.
The examples below use unqualified names, which works assuming no other macros with the same name are in scope.
The unambiguous form `$ion::macro-name` is always available to use.

### Relation to local symbol and macro tables

In Ion 1.0, the system symbol table is always the first import of the local symbol table.
However, in Ion 1.1, the system symbol and macro tables have a system address space that is distinct from the 
local address space, but can optionally be included in the user address space.

When starting an Ion 1.1 segment (i.e. immediately after encountering an `$ion_1_1` version marker),
the system module is in the sequence of active encoding modules immediately following the default module.
As a result, both the system macros and system symbols are initially included in the local macro and symbol tables[^note0]<a name="footnote-0"></a>.
The system module is not a permanent fixture in the active encoding modules, so (in contrast to Ion 1.0)
the system symbols and macros can be removed from the local symbol and macro tables.

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
| 10 | 0x0A | `encoding`                     |
| 11 | 0x0B | `$ion_literal`                 |
| 12 | 0x0C | `$ion_shared_module`           |
| 13 | 0x0D | `macro`                        |
| 14 | 0x0E | `macro_table`                  |
| 15 | 0x0F | `symbol_table`                 |
| 16 | 0x10 | `module`                       |
| 17 | 0x11 | `export`                       |
| 18 | 0x12 | `import`                       |
| 19 | 0x13 | `flex_symbol`                  |
| 20 | 0x14 | `flex_int`                     |
| 21 | 0x15 | `flex_uint`                    |
| 22 | 0x16 | `uint8`                        |
| 23 | 0x17 | `uint16`                       |
| 24 | 0x18 | `uint32`                       |
| 25 | 0x19 | `uint64`                       |
| 26 | 0x1A | `int8`                         |
| 27 | 0x1B | `int16`                        |
| 28 | 0x1C | `int32`                        |
| 29 | 0x1D | `int64`                        |
| 30 | 0x1E | `float16`                      |
| 31 | 0x1F | `float32`                      |
| 32 | 0x20 | `float64`                      |
| 33 | 0x21 | _zero-length text_ (i.e. `''`) |
| 34 | 0x22 | `for`                          |
| 35 | 0x23 | `literal`                      |
| 36 | 0x24 | `if_none`                      |
| 37 | 0x25 | `if_some`                      |
| 38 | 0x26 | `if_single`                    |
| 39 | 0x27 | `if_multi`                     |
| 40 | 0x28 | `none`                         |
| 41 | 0x29 | `values`                       |
| 42 | 0x2A | `default`                      |
| 43 | 0x2B | `meta`                         |
| 44 | 0x2C | `repeat`                       |
| 45 | 0x2D | `flatten`                      |
| 46 | 0x2E | `delta`                        |
| 47 | 0x2F | `sum`                          |
| 48 | 0x30 | `annotate`                     |
| 49 | 0x31 | `make_string`                  |
| 50 | 0x32 | `make_symbol`                  |
| 51 | 0x33 | `make_decimal`                 |
| 52 | 0x34 | `make_timestamp`               |
| 53 | 0x35 | `make_blob`                    |
| 54 | 0x36 | `make_list`                    |
| 55 | 0x37 | `make_sexp`                    |
| 56 | 0x38 | `make_field`                   |
| 57 | 0x39 | `make_struct`                  |
| 58 | 0x3A | `parse_ion`                    |
| 59 | 0x3B | `set_symbols`                  |
| 60 | 0x3C | `add_symbols`                  |
| 61 | 0x3D | `set_macros`                   |
| 62 | 0x3E | `add_macros`                   |
| 63 | 0x3F | `use`                          |

In Ion 1.1 Text, system symbols can never be referenced by symbol ID; `$1` always refers to the first symbol in the user symbol table.
This allows the Ion 1.1 system symbol table to be relatively large without taking away SID space from the user symbol table.

### System Macros

| ID | Hex  | Text                                                          |
|---:|:----:|:--------------------------------------------------------------|
|  0 | 0x00 | [`none`](../macros/system_macros.md#none)                     |
|  1 | 0x01 | [`values`](../macros/system_macros.md#values)                 |
|  2 | 0x02 | [`default`](../macros/system_macros.md#default)               |
|  3 | 0x03 | [`meta`](../macros/system_macros.md#meta)                     |
|  4 | 0x04 | [`repeat`](../macros/system_macros.md#repeat)                 |
|  5 | 0x05 | [`flatten`](../macros/system_macros.md#flatten)               |
|  6 | 0x06 | [`delta`](../macros/system_macros.md#delta)                   |
|  7 | 0x07 | [`sum`](../macros/system_macros.md#sum)                       |
|  8 | 0x08 | [`annotate`](../macros/system_macros.md#annotate)             |
|  9 | 0x09 | [`make_string`](../macros/system_macros.md#make_string)       |
| 10 | 0x0A | [`make_symbol`](../macros/system_macros.md#make_symbol)       |
| 11 | 0x0B | [`make_decimal`](../macros/system_macros.md#make_decimal)     |
| 12 | 0x0C | [`make_timestamp`](../macros/system_macros.md#make_timestamp) |
| 13 | 0x0D | [`make_blob`](../macros/system_macros.md#make_blob)           |
| 14 | 0x0E | [`make_list`](../macros/system_macros.md#make_list)           |
| 15 | 0x0F | [`make_sexp`](../macros/system_macros.md#make_sexp)           |
| 16 | 0x10 | [`make_field`](../macros/system_macros.md#make_field)         |
| 17 | 0x11 | [`make_struct`](../macros/system_macros.md#make_struct)       |
| 18 | 0x12 | [`parse_ion`](../macros/system_macros.md#parse_ion)           |
| 19 | 0x13 | [`set_symbols`](../macros/system_macros.md#set_symbols)       |
| 20 | 0x14 | [`add_symbols`](../macros/system_macros.md#add_symbols)       |
| 21 | 0x15 | [`set_macros`](../macros/system_macros.md#set_macros)         |
| 22 | 0x16 | [`add_macros`](../macros/system_macros.md#add_macros)         |
| 23 | 0x17 | [`use`](../macros/system_macros.md#use)                       |


----

[1]: https://github.com/amazon-ion/ion-docs/issues/345

<small>

[^note0]: System symbols require the same number of bytes whether they are encoded using the system symbol or the user 
symbol encoding. The reasons the system symbols are initially loaded into the user symbol table are twofold—to be 
consistent with loading the system macros into user space, and so that implementors can start testing user symbols 
even before they have implemented support for reading encoding directives.[^](#footnote-0)

</small>
