## Lists

| Opcode        | Encoding                                                                                     |
|---------------|----------------------------------------------------------------------------------------------|
| `0xB0`-`0xBF` | Length-prefixed list; low nibble of the opcode represents the byte-length.                   |
| `0xFA`        | Variable-length prefixed list; a `FlexUInt` following the opcode represents the byte-length. |
| `0xF0`        | Starts a delimited list; `0xEF` closes the most recently opened delimited container.         |
| `0x5B`        | Tagless-element list; opcode is followed by element encoding type and number of elements.    |

`0x8F 0x0A` represents `null.list`.

### Length-prefixed encoding

An opcode with a high nibble of `0xB_` indicates a length-prefixed list. The lower nibble of the
opcode indicates how many bytes were used to encode the child values that the list contains.

If the list's encoded byte-length is too large to be encoded in a nibble, writers may use the `0xFA` opcode
to write a variable-length list. The `0xFA` opcode is followed by a [`FlexUInt`](../primitives/flex_uint.md)
that indicates the list's byte length.

`0x8F 0x0A` represents `null.list`.

##### Length-prefixed encoding of an empty list (`[]`)
```
┌──── An Opcode in the range 0xB0-0xBF indicates a list.
│┌─── A low nibble of 0 indicates that the child values of this
││    list took zero bytes to encode.
B0
```

##### Length-prefixed encoding of `[1, 2, 3]`
```
┌──── An Opcode in the range 0xB0-0xBF indicates a list.
│┌─── A low nibble of 6 indicates that the child values of this
││    list took six bytes to encode.
B6 61 01 61 02 61 03
   └─┬─┘ └─┬─┘ └─┬─┘
     1     2     3
```

##### Length-prefixed encoding of `["variable length list"]`
```
┌──── Opcode 0xFA indicates a variable-length list. A FlexUInt length follows.
│  ┌───── Length: FlexUInt 22
│  │  ┌────── Opcode 0xF8 indicates a variable-length string. A FlexUInt length follows.
│  │  │  ┌─────── Length: FlexUInt 20
│  │  │  │   v  a  r  i  a  b  l  e     l  e  n  g  t  h     l  i  s  t
FA 2d F8 29 76 61 72 69 61 62 6c 65 20 6c 65 6e 67 74 68 20 6c 69 73 74
      └─────────────────────────────┬─────────────────────────────────┘
                          Nested string element
```

### Delimited Encoding

Opcode `0xF0` begins a delimited list, while opcode `0xEF` closes the most recently opened delimited container
that has not yet been closed.

##### Delimited encoding of an empty list (`[]`)
```
┌──── Opcode 0xF0 indicates a delimited list
│  ┌─── Opcode 0xEF indicates the end of the most recently opened container
F0 EF
```

##### Delimited encoding of `[1, 2, 3]`
```
┌──── Opcode 0xF0 indicates a delimited list
│                    ┌─── Opcode 0xEF indicates the end of
│                    │    the most recently opened container
F0 61 01 61 02 61 03 EF
   └─┬─┘ └─┬─┘ └─┬─┘
     1     2     3
```

##### Delimited encoding of `[1, [2], 3]`
```
┌──── Opcode 0xF0 indicates a delimited list
│        ┌─── Opcode 0xF0 begins a nested delimited list
│        │        ┌─── Opcode 0xEF closes the most recently
│        │        │    opened delimited container: the nested list.
│        │        │        ┌─── Opcode 0xEF closes the most recently opened (and 
│        │        │        │    still open) delimited container: the outer list.
│        │        │        │
F0 61 01 F0 61 02 EF 61 03 EF
   └─┬─┘    └─┬─┘    └─┬─┘
     1        2        3
```

### Tagless-Element Lists

Opcode `0x5B` indicates a tagless-element list. This is a compact encoding for homogeneous collections where all elements have the same type.
The elements of the list can be a _primitive encoding_ or a _macro-shape_.

The opcode is followed by:
1. One or more bytes describing the tagless type:
   - If the byte is in `0x00`-`0x47`: only one byte (the opcode) is present; this is the macro address
   - If the byte is in `0x48`-`0x4F`: it is followed by a `FlexUInt` to encode the entire macro address
   - If the byte is `0xF4`: it is followed by a `FlexUInt` which encodes the entire macro address
   - For any other byte value: only one byte (the opcode) is present
2. A `FlexUInt` length indicating the number of direct child values in the list
3. Each element encoded without the leading opcode or macro address

##### Tagless-element list of integers `[{#int8} 1, 2, 3, 4]`
```
┌──── Opcode 0x5B indicates a tagless-element list
│  ┌─── Tagless type: 0x61 (int8)
│  │  ┌─── Length: FlexUInt 4 (4 elements)
│  │  │
5B 61 09 01 02 03 04
         └────┬────┘
         4 int8 values
```

##### Tagless-element list with macro shape `[{:point} (1 3), (1 4), (2 4)]`
```
┌──── Opcode 0x5B indicates a tagless-element list
│  ┌─── Tagless type: 0x05 (macro address 5, assuming :point is at address 5)
│  │  ┌─── Length: FlexUInt 3 (3 elements)
│  │  │       ┌─── First element: (1 3)
│  │  │       │           ┌─── Second element: (1 4)
│  │  │       │           │           ┌─── Third element: (2 4)
│  │  │  ┌────┴────┐ ┌────┴────┐ ┌────┴────┐
5B 05 07 61 01 61 03 61 01 61 04 61 02 61 04
         └─┬─┘ └─┬─┘ └─┬─┘ └─┬─┘ └─┬─┘ └─┬─┘
           1     3     1     4     2     4
```

##### Tagless-element list with macro-shape using length-prefixed E-expression `[{:3} (1 3), (1 259) ]`

```
┌──── Opcode 0x5B indicates a tagless-element list
│    ┌─── Tagless type opcode F4 with FlexUInt address 3
│    │   ┌─── Length: FlexUInt 2 (2 elements)
│    │   │        ┌─── First element: (1 3)
│    │   │        │                ┌─── Second element: (1 4)
│  ┌─┴─┐ │  ┌─────┴──────┐ ┌───────┴───────┐
5B F4 07 05 09 61 01 61 03 0B 61 01 62 04 01
            │  └─┬─┘ └─┬─┘ │  └─┬─┘ └───┬──┘
            │    1     3   │    1      259
            └─ FlexUInt    └─ FlexUInt
               Length=4       Length=5
```

### Encoding of `null.list`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: list
│  │
8F 0A
```
