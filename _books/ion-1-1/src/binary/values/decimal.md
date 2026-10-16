## Decimals

If an opcode has a high nibble of `0x7_`, it represents a decimal. The low
nibble indicates the number of trailing bytes used to encode the decimal.

If there are no trailing bytes (opcode `0x70`), the decimal is `0d0`. Otherwise,
the body of the decimal is encoded as a 1-byte
[`FixedInt`](../primitives/fixed_int.md) representing its exponent, followed by
a `FixedInt` representing its coefficient. The width of the coefficient is the
number of trailing bytes (the low nibble of the opcode) minus one (the width of
the exponent), so the coefficient may be 0 to 14 bytes wide.

Decimal values whose exponent is outside the range of a 1-byte `FixedInt`
(`-128` to `127`), or whose coefficient requires more than 14 bytes, must be
encoded using the variable-length decimal opcode: `0xF6`. Any decimal value may
be encoded using `0xF6`. The opcode is followed by a
[`FlexUInt`](../primitives/flex_uint.md) indicating the length of the body. If
the body is empty (`0xF6 0x01`), the decimal is `0d0`. Otherwise, the body is a
[`FlexInt`](../primitives/flex_int.md) representing the exponent, followed by a
`FixedInt` representing the coefficient, which fills the remainder of the body.
It is illegal for the `FlexInt` exponent to extend past the end of the body.

In both encodings, when no coefficient bytes are present, the coefficient is
`+0`. When the coefficient is present (of any width) and has a value of `0`, the
coefficient is `-0`.

`0x8F 0x04` represents `null.decimal`.

##### Encoding of decimal `0d0`
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 0 indicates a zero-byte
││    decimal; 0d0
70
```

##### Variable-length encoding of decimal `0d0`
```
┌──── Opcode F6 indicates a variable-length decimal
│
F6 01
   └─────── Decimal length: FlexUInt 0; an empty body indicates 0d0
```

##### Encoding of decimal `7d0`
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 2 indicates a 2-byte decimal
││
72 00 07
   |  └─── Coefficient: 1-byte FixedInt 7
   └─── Exponent: FixedInt 0
```

##### Encoding of decimal `1.27`
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 2 indicates a 2-byte decimal
││
72 FE 7F
   |  └─── Coefficient: FixedInt 127
   └─── Exponent: FixedInt -2
```

##### Variable-length encoding of decimal `1.27`
```
┌──── Opcode F6 indicates a variable-length decimal
│
F6 05 FD 7F
   |  |  └─── Coefficient: FixedInt 127
   |  └───── Exponent: 1-byte FlexInt -2
   └─────── Decimal length: FlexUInt 2
```

##### Encoding of decimal `1d200`, which requires the variable-length encoding
```
┌──── Opcode F6 indicates a variable-length decimal; an exponent of 200
│     does not fit in a 1-byte FixedInt
│
F6 07 22 03 01
   |  └─┬─┘ └─── Coefficient: FixedInt 1
   |    └───── Exponent: 2-byte FlexInt 200
   └─────── Decimal length: FlexUInt 3
```

##### Encoding of `0d3`, which has a coefficient of zero
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 1 indicates a 1-byte decimal
││
71 03
   └────── Exponent: FixedInt 3; no more bytes follow, so the coefficient is implicitly 0
```

##### Encoding of `-0d3`, which has a coefficient of negative zero
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 2 indicates a 2-byte decimal
││
72 03 00
   |  └─── Coefficient: 1-byte FixedInt 0, indicating a coefficient of -0
   └────── Exponent: FixedInt 3
```

##### Encoding of `0d200`, which has a coefficient of zero
```
┌──── Opcode F6 indicates a variable-length decimal
│
F6 05 22 03
   |  └─┬─┘
   |    └───── Exponent: 2-byte FlexInt 200; no more bytes follow, so the
   |           coefficient is implicitly 0
   └─────── Decimal length: FlexUInt 2
```

##### Encoding of `-0d200`, which has a coefficient of negative zero
```
┌──── Opcode F6 indicates a variable-length decimal
│
F6 07 22 03 00
   |  └─┬─┘ └─── Coefficient: 1-byte FixedInt 0, indicating a coefficient of -0
   |    └───── Exponent: 2-byte FlexInt 200
   └─────── Decimal length: FlexUInt 3
```

##### Encoding of `null.decimal`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: decimal
│  │
8F 04
```
