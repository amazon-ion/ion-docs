## Integers

Opcodes in the range `0x60` to `0x68` represent an integer. The opcode is followed by a [`FixedInt`](#fixedint) that
represents the integer value. The low nibble of the opcode (`0x_0` to `0x_8`) indicates the size of the `FixedInt`.
Opcode `0x60` represents integer `0`; no more bytes follow.

Integers that require more than 8 bytes are encoded using the variable-length integer opcode `0xF6`,
followed by a
<<flexuint, FlexUInt>> indicating how many bytes of representation data follow.

`0xEB 0x01` represents `null.int`.

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
┌──── Opcode F6 indicates a variable-length integer, FlexUInt length follows
│   ┌─── FlexUInt 2; a 2-byte FixedInt follows
│   │
F6 05 50 FC
      └─┬─┘
   FixedInt -944
```

##### Encoding of `null.int`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: integer
│  │
EB 01
```