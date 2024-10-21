## Decimals

If an opcode has a high nibble of `0x7_`, it represents a decimal. Low nibble values indicate
the number of trailing bytes used to encode the decimal.

The body of the decimal is encoded as a [`FlexInt`](#flexint) representing its exponent, followed by a `FixedInt`
representing its coefficient. The width of the coefficient is the total length of the decimal encoding minus the length
of the exponent. It is possible for the coefficient to have a width of zero, indicating a coefficient of `0`. When
the coefficient is present but has a value of `0`, the coefficient is `-0`.

Decimal values that require more than 15 bytes can be encoded using the variable-length decimal opcode: `0xF7`.

`0xEB 0x03` represents `null.decimal`.

##### Encoding of decimal `0`
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 0 indicates a zero-byte
││    decimal; 0
70
```

##### Encoding of decimal `7`
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 2 indicates a 2-byte decimal
││
72 01 07
   |  └─── Coefficient: 1-byte FixedInt 7
   └─── Exponent: FlexInt 0
```

##### Encoding of decimal `1.27`
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 2 indicates a 2-byte decimal
││
72 FD 7F
   |  └─── Coefficient: FixedInt 127
   └─── Exponent: 1-byte FlexInt -2
```

##### Variable-length encoding of decimal `1.27`
```
┌──── Opcode F7 indicates a variable-length decimal
│
F7 05 FD 7F
   |  |  └─── Coefficient: FixedInt 127
   |  └───── Exponent: 1-byte FlexInt -2
   └─────── Decimal length: FlexUInt 2
```

##### Encoding of `0e3`, which has a coefficient of zero
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 1 indicates a 1-byte decimal
││
71 07
   └────── Exponent: FlexInt 3; no more bytes follow, so the coefficient is implicitly 0
```

##### Encoding of `-0e3`, which has a coefficient of negative zero
```
┌──── Opcode in range 70-7F indicates a decimal
│┌─── Low nibble 2 indicates a 2-byte decimal
││
72 07 00
   |  └─── Coefficient: 1-byte FixedInt 0, indicating a coefficient of -0
   └────── Exponent: FlexInt 3
```

##### Encoding of `null.decimal`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: decimal
│  │
EB 03
```
