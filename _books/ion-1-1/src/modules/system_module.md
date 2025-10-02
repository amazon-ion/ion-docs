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
| 14 | 0x0E | `macros`                       |
| 15 | 0x0F | `module`                       |
| 16 | 0x10 | `export`                       |
| 17 | 0x11 | `import`                       |
| 18 | 0x12 | `flex_symbol`                  |
| 19 | 0x13 | `flex_int`                     |
| 20 | 0x14 | `flex_uint`                    |
| 21 | 0x15 | `uint8`                        |
| 22 | 0x16 | `uint16`                       |
| 23 | 0x17 | `uint32`                       |
| 24 | 0x18 | `uint64`                       |
| 25 | 0x19 | `int8`                         |
| 26 | 0x1A | `int16`                        |
| 27 | 0x1B | `int32`                        |
| 28 | 0x1C | `int64`                        |
| 29 | 0x1D | `float16`                      |
| 30 | 0x1E | `float32`                      |
| 31 | 0x1F | `float64`                      |
| 32 | 0x20 | _zero-length text_ (i.e. `''`) |
| 33 | 0x21 | `for`                          |
| 34 | 0x22 | `literal`                      |
| 35 | 0x23 | `if_none`                      |
| 36 | 0x24 | `if_some`                      |
| 37 | 0x25 | `if_single`                    |
| 38 | 0x26 | `if_multi`                     |
| 39 | 0x27 | `none`                         |
| 40 | 0x28 | `values`                       |
| 41 | 0x29 | `default`                      |
| 42 | 0x2A | `meta`                         |
| 43 | 0x2B | `repeat`                       |
| 44 | 0x2C | `flatten`                      |
| 45 | 0x2D | `delta`                        |
| 46 | 0x2E | `sum`                          |
| 47 | 0x2F | `annotate`                     |
| 48 | 0x30 | `make_string`                  |
| 49 | 0x31 | `make_symbol`                  |
| 50 | 0x32 | `make_decimal`                 |
| 51 | 0x33 | `make_timestamp`               |
| 52 | 0x34 | `make_blob`                    |
| 53 | 0x35 | `make_list`                    |
| 54 | 0x36 | `make_sexp`                    |
| 55 | 0x37 | `make_field`                   |
| 56 | 0x38 | `make_struct`                  |
| 57 | 0x39 | `parse_ion`                    |
| 58 | 0x3A | `set_symbols`                  |
| 59 | 0x3B | `add_symbols`                  |
| 60 | 0x3C | `set_macros`                   |
| 61 | 0x3D | `add_macros`                   |
| 62 | 0x3E | `use`                          |

In Ion 1.1 Text, system symbols can never be referenced by symbol ID; `$1` always refers to the first symbol in the user symbol table.
This allows the Ion 1.1 system symbol table to be relatively large without taking away SID space from the user symbol table.

### Directives

Ion 1.1 includes seven directives that describe encoding metadata in an Ion stream. Their binary opcodes are listed below.

| ID  | Hex  | Text                                                   |
|----:|:----:|:-------------------------------------------------------|
| 225 | 0xE1 | [`set_symbols`](../macros/directives.md#set_symbols)   |
| 226 | 0xE2 | [`add_symbols`](../macros/directives.md#add_symbols)   |
| 227 | 0xE3 | [`set_macros`](../macros/directives.md#set_macros)     |
| 228 | 0xE4 | [`add_macros`](../macros/directives.md#add_macros)     |
| 229 | 0xE5 | [`use`](../macros/directives.md#use)                   |
| 230 | 0xE6 | [`module`](../macros/directives.md#module)             |
| 231 | 0xE7 | [`encoding`](../macros/directives.md#encoding)         |

----

[1]: https://github.com/amazon-ion/ion-docs/issues/345

<small>

[^note0]: System symbols require the same number of bytes whether they are encoded using the system symbol or the user 
symbol encoding. The reasons the system symbols are initially loaded into the user symbol table are twofold—to be 
consistent with loading the system macros into user space, and so that implementors can start testing user symbols 
even before they have implemented support for reading encoding directives.[^](#footnote-0)

</small>
