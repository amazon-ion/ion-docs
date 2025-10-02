## Blobs

Opcode `FE` indicates a blob of binary data. A `FlexUInt` follows that represents the blob's byte-length.

`0x8F 0x08` represents `null.blob`.

### Example `blob` encoding
```
┌──── Opcode FE indicates a blob, FlexUInt length follows
│   ┌─── Length: FlexUInt 24
│   │
FE 31 49 20 61 70 70 6c 61 75 64 20 79 6f 75 72 20 63 75 72 69 6f 73 69 74 79
      └────────────────────────────────┬────────────────────────────────────┘
                            24 bytes of binary data
```

### Encoding of `null.blob`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: blob
│  │
8F 08
```
