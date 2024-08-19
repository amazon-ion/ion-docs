## Nulls

The opcode `0xEA` indicates an untyped null (that is: `null`, or its alias `null.null`).

The opcode `0xEB` indicates a typed null; a byte follows whose value represents an offset into the following table:


| Byte   | Type             |
|--------|------------------|
| `0x00` | `null.bool`      |
| `0x01` | `null.int`       |
| `0x02` | `null.float`     |
| `0x03` | `null.decimal`   |
| `0x04` | `null.timestamp` |
| `0x05` | `null.string`    |
| `0x06` | `null.symbol`    |
| `0x07` | `null.blob`      |
| `0x08` | `null.clob`      |
| `0x09` | `null.list`      |
| `0x0A` | `null.sexp`      |
| `0x0B` | `null.struct`    |

All other byte values are reserved for future use.

#### Encoding of `null`
```
┌──── The opcode `0xEA` represents a null (null.null)
EA
```

#### Encoding of `null.string`
```
┌──── The opcode `0xEB` indicates a typed null; a byte indicating the type follows
│  ┌──── Byte 0x05 indicates the type `string`
EB 05
```
