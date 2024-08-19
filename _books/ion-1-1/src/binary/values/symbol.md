## Symbols

### Symbols With Inline Text

If the high nibble of the opcode is `0xA_`, it represents a symbol whose text follows the opcode. The low nibble of the
opcode indicates how many UTF-8 bytes follow. Opcode `0xA0` represents a symbol with empty text (`''`).

`0xEB x06` represents `null.symbol`.

##### Encoding of a symbol with empty text (`''`)
```
┌──── Opcode in range A0-AF indicates a symbol with inline text
│┌─── Low nibble 0 indicates that no UTF-8 bytes follow
A0
```

##### Encoding of a symbol with 14 bytes of inline text
```
┌──── Opcode in range A0-AF indicates a symbol with inline text
│┌─── Low nibble E indicates that 14 UTF-8 bytes follow
││  f  o  u  r  t  e  e  n     b  y  t  e  s
AE 66 6F 75 72 74 65 65 6E 20 62 79 74 65 73
   └──────────────────┬────────────────────┘
                 UTF-8 bytes
```

##### Encoding of a symbol with 24 bytes of inline text
```
┌──── Opcode FA indicates a variable-length symbol with inline text
│  ┌─── Length: FlexUInt 24
│  │   v  a  r  i  a  b  l  e     l  e  n  g  t  h     e  n  c  o  d  i  n  g
FA 31 76 61 72 69 61 62 6C 65 20 6C 65 6E 67 74 68 20 65 6E 63 6f 64 69 6E 67
      └────────────────────────────────┬────────────────────────────────────┘
                                  UTF-8 bytes
```

##### Encoding of `null.symbol`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: symbol
│  │
EB 06
```


### Symbols With a Symbol Address

Symbol values whose text can be found in the local symbol table are encoded using opcodes `0xE1` through `0xE3`:

* `0xE1` represents a symbol whose address in the symbol table (aka its symbol ID) is a 1-byte
[`FixedUInt`](#fixeduint) that follows the opcode.
* `0xE2` represents a symbol whose address in the symbol table is a 2-byte [`FixedUInt`](#fixeduint) that follows
the opcode.
* `0xE3` represents a symbol whose address in the symbol table is a [`FlexUInt`](#flexuint) that follows the opcode.

Writers MUST encode a symbol address in the smallest number of bytes possible. For each opcode above, the symbol
address that is decoded is biased by the number of addresses that can be encoded in fewer bytes.

| Opcode | Symbol address range | Bias   |
|--------|----------------------|--------|
| `0xE1` | 0 to 255             | 0      |
| `0xE2` | 256 to 65,791        | 256    |
| `0xE3` | 65,792 to infinity   | 65,792 |
