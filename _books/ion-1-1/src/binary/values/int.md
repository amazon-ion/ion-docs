## Integers

Opcodes in the range `0x60` to `0x68` represent an integer. The opcode is followed by a [`FixedInt`](../primitives/fixed_int.md) that
represents the integer value. The low nibble of the opcode (`0x_0` to `0x_8`) indicates the size of the `FixedInt`.
Opcode `0x60` represents integer `0`; no more bytes follow.

Integers that require more than 8 bytes are encoded using the variable-length integer opcode `0xF5`,
followed by a [`FlexUInt`](../primitives/flex_uint.md) indicating how many bytes of representation data follow.

`0x8F 0x02` represents `null.int`.

##### Encoding of integer `0`
```
┌──── Opcode in 60-68 range indicates integer
│┌─── Low nibble 0 indicates
││    no more bytes follow.
60
```

##### Encoding of integer `17`
```
┌──── Opcode in 60-68 range indicates integer
│┌─── Low nibble 1 indicates
││    a single byte follows.
61 11
    └── FixedInt 17
```

##### Encoding of integer `-944`
```
┌──── Opcode in 60-68 range indicates integer
│┌─── Low nibble 2 indicates
││    that two bytes follow.
62 50 FC
   └─┬─┘
FixedInt -944
```

##### Encoding of integer `-944`
```
┌──── Opcode F5 indicates a variable-length integer, FlexUInt length follows
│   ┌─── FlexUInt 2; a 2-byte FixedInt follows
│   │
F5 05 50 FC
      └─┬─┘
   FixedInt -944
```

##### Encoding of `null.int`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: integer
│  │
8F 02
```
