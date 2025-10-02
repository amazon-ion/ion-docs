## Opcodes

An _opcode_ is a 1-byte [`FixedUInt`](primitives/fixed_uint.md) that tells the reader what the next expression represents
and how the bytes that follow should be interpreted.

The meanings of each opcode are organized loosely by their high and low nibbles.

| High nibble      | Low nibble | Meaning                                                                         |
|------------------|------------|---------------------------------------------------------------------------------|
| `0x0_` to `0x3_` | `0`-`F`    | E-expression, opcode is the address                                             |
| `0x4_`           | `0`-`7`    | E-expression, opcode is the address                                             |
|                  | `8`-`F`    | E-expression with extended address                                              |
| `0x5_`           | `0`-`7`    | Symbols with symbol address                                                     |
|                  | `8`-`9`    | Annotations                                                                     |
|                  | `A`        | _Reserved_                                                                      |
|                  | `B`        | Tagless-element List                                                            |
|                  | `C`        | Tagless-element S-expression                                                    |  
|                  | `D`-`F`    | _Reserved_                                                                      |
| `0x6_`           | `0`-`8`    | Integers from 0 to 8 bytes wide                                                 |
|                  | `9`        | _Reserved_                                                                      |
|                  | `A`-`D`    | Floats                                                                          |
|                  | `E`-`F`    | Booleans                                                                        |
| `0x7_`           | `0`-`F`    | Decimals                                                                        |
| `0x8_`           | `0`-`C`    | Short-form timestamps                                                           |
|                  | `D`        | _Reserved_                                                                      |
|                  | `E`        | `null.null`                                                                     |
|                  | `F`        | Typed nulls                                                                     |
| `0x9_`           | `0`-`F`    | Strings                                                                         |
| `0xA_`           | `0`-`F`    | Symbols with inline text                                                        |
| `0xB_`           | `0`-`F`    | Lists                                                                           |
| `0xC_`           | `0`-`F`    | S-expressions                                                                   |
| `0xD_`           | `0`        | Empty struct                                                                    |
|                  | `1`        | _Reserved_                                                                      |
|                  | `2`-`F`    | Structs                                                                         |
| `0xE_`           | `0`        | Ion version marker                                                              |
|                  | `1`-`7`    | Directives                                                                      |
|                  | `8`-`A`    | Template placeholders                                                           |
|                  | `B`        | Absent Argument                                                                 |
|                  | `C`-`D`    | NOP                                                                             |
|                  | `E`        | Struct switch modes (SID ↔ FlexSym)                                             |
|                  | `F`        | Delimited container end                                                         |
| `0xF_`           | `0`        | Delimited list start                                                            |
|                  | `1`        | Delimited S-expression start                                                    |
|                  | `2`        | Delimited struct start (SID Mode)                                               |
|                  | `3`        | Delimited struct start (FlexSym Mode)                                           |
|                  | `4`        | E-expression with `FlexUInt` macro address followed by `FlexUInt` length prefix |
|                  | `5`        | Integer with `FlexUInt` length prefix                                           |
|                  | `6`        | Decimal with `FlexUInt` length prefix                                           |
|                  | `7`        | Timestamp with `FlexUInt` length prefix                                         |
|                  | `8`        | String with `FlexUInt` length prefix                                            |
|                  | `9`        | Symbol with `FlexUInt` length prefix and inline text                            |
|                  | `A`        | List with `FlexUInt` length prefix                                              |
|                  | `B`        | S-expression with `FlexUInt` length prefix                                      |
|                  | `C`        | Struct with `FlexUInt` length prefix (SID Mode)                                 |
|                  | `D`        | Struct with `FlexUInt` length prefix (FlexSym Mode)                             |
|                  | `E`        | Blob with `FlexUInt` length prefix                                              |
|                  | `F`        | Clob with `FlexUInt` length prefix                                              |


In addition, some opcodes have different meanings when used as tagless types.

| High nibble | Low nibble | Meaning                                           |
|-------------|------------|---------------------------------------------------|
| `0x6_`      | `0`        | `FlexInt` integer value                           |
| `0xE_`      | `0`        | `FlexUInt` integer value                          |
|             | `1`-`8`    | `FixedUInt` integer values from 1 to 8 bytes wide |
|             | `A`        | Symbol value with `FlexUInt` symbol address       |
|             | `E`        | Symbol `FlexSym`                                  |
