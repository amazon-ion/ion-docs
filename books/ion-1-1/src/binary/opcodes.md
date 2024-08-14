## Opcodes

An _opcode_ is a 1-byte [`FixedUInt`](primitives/fixed_uint.md) that tells the reader what the next expression represents
and how the bytes that follow should be interpreted.

The meanings of each opcode are organized loosely by their high and low nibbles.

| High nibble      | Low nibble | Meaning                                                         |
|------------------|------------|-----------------------------------------------------------------|
| `0x0_` to `0x3_` | `0`-`F`    | E-expression with 6-bit address                                 |
| `0x4_`           | `0`-`F`    | E-expression with 12-bit address                                |
| `0x5_`           | `0`-`F`    | E-expression with 20-bit address                                |
| `0x6_`           | `0`-`8`    | Integers from 0 to 8 bytes wide                                 |
|                  | `9`        | _Reserved_                                                      |
|                  | `A`-`D`    | Floats                                                          |
|                  | `E`-`F`    | Booleans                                                        |
| `0x7_`           | `0`-`F`    | Decimals                                                        |
| `0x8_`           | `0`-`C`    | Short-form timestamps                                           |
|                  | `D`-`F`    | _Reserved_                                                      |
| `0x9_`           | `0`-`F`    | Strings                                                         |
| `0xA_`           | `0`-`F`    | Symbols with inline text                                        |
| `0xB_`           | `0`-`F`    | Lists                                                           |
| `0xC_`           | `0`-`F`    | S-expressions                                                   |
| `0xD_`           | `0`        | Empty struct                                                    |
|                  | `1`        | _Reserved_                                                      |
|                  | `2`-`F`    | Structs                                                         |
| `0xE_`           | `0`        | Ion version marker                                              |
|                  | `1`-`3`    | Symbols with symbol address                                     |
|                  | `4`-`6`    | Annotations with symbol address                                 |
|                  | `7`-`9`    | Annotations with `FlexSym` text                                 |
|                  | `A`        | `null.null`                                                     |
|                  | `B`        | Typed nulls                                                     |
|                  | `C`-`D`    | NOP                                                             |
|                  | `E`        | _Reserved_                                                      |
|                  | `F`        | System macro invocation                                         |
| `0xF_`           | `0`        | Delimited container end                                         |
|                  | `1`        | Delimited list start                                            |
|                  | `2`        | Delimited S-expression start                                    |
|                  | `3`        | Delimited struct start                                          |
|                  | `4`        | _Reserved_                                                      |
|                  | `5`        | E-expression w/`FlexUInt` length prefix                         |
|                  | `6`        | Integer w/`FlexUInt` length prefix                              |
|                  | `7`        | Decimal w/`FlexUInt` length prefix                              |
|                  | `8`        | Timestamp w/`FlexUInt` length prefix                            |
|                  | `9`        | String w/`FlexUInt` length prefix                               |
|                  | `A`        | Symbol w/`FlexUInt` length prefix and inline text               |
|                  | `B`        | List w/`FlexUInt` length prefix                                 |
|                  | `C`        | S-expression w/`FlexUInt` length prefix                         |
|                  | `D`        | Struct w/`FlexUInt` length prefix                               |
|                  | `E`        | Blob w/`FlexUInt` length prefix                                 |
|                  | `F`        | Clob w/`FlexUInt` length prefix                                 |
