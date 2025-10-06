# System modules

The symbols of the system module `$ion` are available everywhere within an Ion document,
with the version of that module being determined by the spec-version of each segment.
The specific system symbols are largely uninteresting to users; while the binary encoding heavily
leverages the system symbol table, the text encoding that users typically interact with does not.

This chapter catalogs the system-provided modules and their symbols and macros.

## Relation to local symbol and macro tables

Ion 1.1 provides more than one system module.

The `$ion` module is equivalent to the Ion 1.0 system symbol table. 
Its symbols are identical, and it contains no macros.
In Ion 1.0, the system symbol table is always the first import of the local symbol table.
Ion 1.1 has slightly different semantics—the `$ion` module is always the first module in the [sequence of encoding modules](encoding_modules.md)—resulting in the `$ion` module symbols always occupying the first 9 symbol IDs.


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

## The `$mod` module

<!-- can we come up with a justification for calling this $ion_shared_symbol_table or something else that's in the standard symtab already -->

The `$mod` module is a system-provided module that contains symbols that are used for declaring local and shared modules.
The binding is always available in an Ion 1.1 stream, but it is not included in the [encoding modules](encoding_modules.md)
unless it is explicitly added.

|   ID | Text                 |
|-----:|----------------------|
|  `1` | `macro`              |
|  `2` | `macros`             |
|  `3` | `export`             |
|  `4` | `import`             |
|  `5` | `module`             |
|  `6` | `encoding`           |
|  `7` | `$ion_shared_module` |
|  `8` | `$ion_1_1`           |
|  `9` | `symbol`             |
| `10` | `int`                |
| `11` | `uint`               |
| `12` | `uint8`              |
| `13` | `uint16`             |
| `14` | `uint32`             |
| `15` | `uint64`             |
| `16` | `int8`               |
| `17` | `int16`              |
| `18` | `int32`              |
| `19` | `int64`              |
| `20` | `float16`            |
| `21` | `float32`            |
| `22` | `float64`            |
| `23` | `small_decimal`      |
| `24` | `timestamp_day`      |
| `25` | `timestamp_min`      |
| `26` | `timestamp_s`        |
| `27` | `timestamp_ms`       |
| `28` | `timestamp_us`       |
| `29` | `timestamp_ns`       |


The conventional way to use this module is:

```ion
(:$ion encoding $mod)
(:$ion module foo 
      // use the symbols in $mod while defining your module
)
```

This places the `$mod` module at the end of the encoding sequence.
When this occurs at (or near) the beginning of a stream, the symbols in `$mod` will have relatively low symbol IDs in the segment symbol table.
Once symbols are added to the default module, the symbols in `$mod` are adjusted to higher symbol IDs.
