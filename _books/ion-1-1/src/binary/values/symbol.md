## Symbols

### Symbols With Inline Text

If the high nibble of the opcode is `0xA_`, it represents a symbol whose text follows the opcode. The low nibble of the
opcode indicates how many UTF-8 bytes follow. Opcode `0xA0` represents a symbol with empty text (`''`).

`0x8F 0x07` represents `null.symbol`.

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
┌──── Opcode F9 indicates a variable-length symbol with inline text
│  ┌─── Length: FlexUInt 24
│  │   v  a  r  i  a  b  l  e     l  e  n  g  t  h     e  n  c  o  d  i  n  g
F9 31 76 61 72 69 61 62 6C 65 20 6C 65 6E 67 74 68 20 65 6E 63 6f 64 69 6E 67
      └────────────────────────────────┬────────────────────────────────────┘
                                  UTF-8 bytes
```

##### Encoding of `null.symbol`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: symbol
│  │
8F 07
```


### Symbols With a Symbol Address

Symbol values whose text can be found in the local symbol table are encoded using opcodes `0x50` through `0x57`.

The opcodes `0x50` through `0x57` share the same 5 most-significant bits. The 3 least-significant bits are used as the
3 least-significant bits of the symbol ID.
The opcode is followed by a `FlexUInt`, which, once decoded, represents the most-significant bits of the symbol ID.

To get the symbol ID from the opcode and `FlexUInt` is simple, and can be implemented using bitwise operations or simple arithmetic operations.
```text
// Given an `opcode` and `flexUInt`...
let lsb = opcode & 0b111       // or opcode - 0x50
let msb = flexUInt << 3        // or flexUInt * 8
let symbolId = msb | lsb       // or msb + lsb
```
The reverse transformation is also simple:
```text
// Given `symbolId`...
let opcode = 0x50 | (symbolId & 0b111)   // or 0x50 + (symbolId % 8)
let flexUInt = symbolId >>> 3            // or symbolId / 8 
```

The number of bytes required to encode symbol addresses is as follows:

| SID Range                  | Encoded size, including opcode |
|----------------------------|-------------------------------:|
| `$0`..`$1023`              |                              2 |
| `$1024`..`$131071`         |                              3 |
| `$131072`..`$16777215`     |                              4 |
| `$16777216`..`$2147483647` |                              5 |

This table only goes to ~2 billion, but the encoding itself does not have a limit on the number of symbol IDs.
However, most Ion implementations will have some upper bound on the number of symbols that depends on the implementation language and/or the underlying hardware.


##### Encoding of symbol with SID 1 (`$ion`)
```
┌──── Opcode 0x51 indicates a symbol with SID; low 3 bits = 1
│  ┌─── FlexUInt 0 represents the high bits (0 << 3 = 0)
│  │
51 01
```

##### Encoding of symbol with SID 10
```
┌──── Opcode 0x52 indicates a symbol with SID; low 3 bits = 2  
│  ┌─── FlexUInt 1 represents the high bits (1 << 3 = 8)
│  │
52 03
```

##### Encoding of symbol with SID 1000
```
┌──── Opcode 0x50 indicates a symbol with SID; low 3 bits = 0
│  ┌─── FlexUInt 125 represents the high bits (125 << 3 = 1000)
│  │
50 FB 01
```
