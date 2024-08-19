## Binary Data

### Blobs

Opcode `FE` indicates a blob of binary data. A `FlexUInt` follows that represents the blob's byte-length.

`0xEB x07` represents `null.blob`.

##### Example `blob` encoding
```
┌──── Opcode FE indicates a blob, FlexUInt length follows
│   ┌─── Length: FlexUInt 24
│   │
FE 31 49 20 61 70 70 6c 61 75 64 20 79 6f 75 72 20 63 75 72 69 6f 73 69 74 79
      └────────────────────────────────┬────────────────────────────────────┘
                            24 bytes of binary data
```

##### Encoding of `null.blob`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: blob
│  │
EB 07
```


### Clobs

Opcode `FF` indicates a clob--binary character data of an unspecified encoding. A `FlexUInt` follows that represents
the clob's byte-length.

`0xEB x08` represents `null.clob`.

#### Example `clob` encoding
```
┌──── Opcode FF indicates a clob, FlexUInt length follows
│   ┌─── Length: FlexUInt 24
│   │
FF 31 49 20 61 70 70 6c 61 75 64 20 79 6f 75 72 20 63 75 72 69 6f 73 69 74 79
      └────────────────────────────────┬────────────────────────────────────┘
                            24 bytes of binary data
```

#### Encoding of `null.clob`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: clob
│  │
EB 08
```
