# System module

The symbols of the system module `$ion` are available everywhere within an Ion document,
with the version of that module being determined by the spec-version of each segment.
The specific system symbols are largely uninteresting to users; while the binary encoding heavily
leverages the system symbol table, the text encoding that users typically interact with does not.

## Relation to local symbol and macro tables

The `$ion` module is equivalent to the Ion 1.0 system symbol table. 
Its symbols are identical, and it contains no macros.
In Ion 1.0, the system symbol table is always the first import of the local symbol table.

Ion 1.1 has slightly different semantics, but the result is the same.
The `$ion` module is always the first module in the [sequence of encoding modules](encoding_modules.md), so the `$ion` module symbols always occupying the first 9 symbol IDs.


## The `$ion` module

This is the same as the Ion 1.0 system symbol table.
This binding is always available in an Ion 1.1 stream at the head of the [encoding modules](encoding_modules.md).

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

