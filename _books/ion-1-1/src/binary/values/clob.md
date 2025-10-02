## Clobs

Opcode `FF` indicates a clob--binary character data of an unspecified encoding. A `FlexUInt` follows that represents
the clob's byte-length.

`0x8F 0x09` represents `null.clob`.

### Example `clob` encoding
```
┌──── Opcode FF indicates a clob, FlexUInt length follows
│   ┌─── Length: FlexUInt 24
│   │
FF 31 49 20 61 70 70 6c 61 75 64 20 79 6f 75 72 20 63 75 72 69 6f 73 69 74 79
      └────────────────────────────────┬────────────────────────────────────┘
                            24 bytes of binary data
```

### Encoding of `null.clob`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: clob
│  │
8F 09
```
