## `NOP`s

A `NOP` (short for "no-operation") is the binary equivalent of whitespace. `NOP` bytes have no meaning,
but can be used as padding to achieve a desired alignment.

An opcode of `0xEC` indicates a single-byte `NOP` pad. An opcode of `0xED` indicates that a
[`FlexUInt`](#flexuint) follows that represents the number of additional bytes to skip.

It is legal for a `NOP` to appear anywhere that a [value](values.md) can be encoded. It is not legal for a `NOP` to appear in
annotation sequences or struct field names. If a `NOP` appears in place of a struct field _value_, then the associated
field name is ignored; the `NOP` is immediately followed by the next field name, if any.

##### Encoding of a 1-byte NOP
```
┌──── The opcode `0xEC` represents a 1-byte NOP pad
│
EC
```

##### Encoding of a 3-byte NOP
```
┌──── The opcode `0xED` represents a variable-length NOP pad; a FlexUInt length follows
│  ┌──── Length: FlexUInt 2; two more bytes of NOP follow
│  │
ED 05 93 C6
      └─┬─┘
NOP bytes, values ignored
```
