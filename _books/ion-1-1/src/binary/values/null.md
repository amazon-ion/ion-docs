## Nulls

The opcode `0x8E` indicates an untyped null (that is: `null`, or its alias `null.null`).

The opcode `0x8F` indicates a typed null; a byte follows whose value represents an offset into the following table:


| Byte   | Type             |
|--------|------------------|
| `0x01` | `null.bool`      |
| `0x02` | `null.int`       |
| `0x03` | `null.float`     |
| `0x04` | `null.decimal`   |
| `0x05` | `null.timestamp` |
| `0x06` | `null.string`    |
| `0x07` | `null.symbol`    |
| `0x08` | `null.blob`      |
| `0x09` | `null.clob`      |
| `0x0A` | `null.list`      |
| `0x0B` | `null.sexp`      |
| `0x0C` | `null.struct`    |

All other byte values are reserved for future use.

#### Encoding of `null`
```
┌──── The opcode `0x8E` represents a null (null.null)
8E
```

#### Encoding of `null.string`
```
┌──── The opcode `0x8F` indicates a typed null; a byte indicating the type follows
│  ┌──── Byte 0x06 indicates the type `string`
8F 06
