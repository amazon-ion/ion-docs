## Strings

If the high nibble of the opcode is `0x9_`, it represents a string. The low nibble of the opcode
indicates how many UTF-8 bytes follow. Opcode `0x90` represents a string with empty text (`""`).

Strings longer than 15 bytes can be encoded with the `F9` opcode, which takes a [`FlexUInt`](#flexuint)-encoded length
after the opcode.

`0xEB x05` represents `null.string`.

#### Encoding of the empty string, `""`
```
┌──── Opcode in range 90-9F indicates a string
│┌─── Low nibble 0 indicates that no UTF-8 bytes follow
90
```

#### Encoding of a 14-byte string
```
┌──── Opcode in range 90-9F indicates a string
│┌─── Low nibble E indicates that 14 UTF-8 bytes follow
││  f  o  u  r  t  e  e  n     b  y  t  e  s
9E 66 6F 75 72 74 65 65 6E 20 62 79 74 65 73
   └──────────────────┬────────────────────┘
                 UTF-8 bytes
```

#### Encoding of a 24-byte string
```
┌──── Opcode F9 indicates a variable-length string
│  ┌─── Length: FlexUInt 24
│  │   v  a  r  i  a  b  l  e     l  e  n  g  t  h     e  n  c  o  d  i  n  g
F9 31 76 61 72 69 61 62 6C 65 20 6C 65 6E 67 74 68 20 65 6E 63 6f 64 69 6E 67
      └────────────────────────────────┬────────────────────────────────────┘
                                  UTF-8 bytes
```

#### Encoding of `null.string`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: string
│  │
EB 05
```
