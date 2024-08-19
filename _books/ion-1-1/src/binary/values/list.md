## Lists

##### Length-prefixed encoding

An opcode with a high nibble of `0xB_` indicates a length-prefixed list. The lower nibble of the
opcode indicates how many bytes were used to encode the child values that the list contains.

If the list's encoded byte-length is too large to be encoded in a nibble, writers may use the `0xFB` opcode
to write a variable-length list. The `0xFB` opcode is followed by a [`FlexUInt`](../primitives/flex_uint.md)
that indicates the list's byte length.

`0xEB 0x09` represents `null.list`.

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
┌──── Opcode 0xFB indicates a variable-length list. A FlexUInt length follows.
│  ┌───── Length: FlexUInt 22
│  │  ┌────── Opcode 0xF9 indicates a variable-length string. A FlexUInt length follows.
│  │  │  ┌─────── Length: FlexUInt 20
│  │  │  │   v  a  r  i  a  b  l  e     l  e  n  g  t  h     l  i  s  t
FB 2d F9 29 76 61 72 69 61 62 6c 65 20 6c 65 6e 67 74 68 20 6c 69 73 74
      └─────────────────────────────┬─────────────────────────────────┘
                          Nested string element
```

##### Encoding of `null.list`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: list
│  │
EB 09
```

#### Delimited Encoding

Opcode `0xF1` begins a delimited list, while opcode `0xF0` closes the most recently opened delimited container
that has not yet been closed.

##### Delimited encoding of an empty list (`[]`)
```
┌──── Opcode 0xF1 indicates a delimited list
│  ┌─── Opcode 0xF0 indicates the end of the most recently opened container
F1 F0
```

##### Delimited encoding of `[1, 2, 3]`
```
┌──── Opcode 0xF1 indicates a delimited list
│                    ┌─── Opcode 0xF0 indicates the end of
│                    │    the most recently opened container
F1 61 01 61 02 61 03 F0
   └─┬─┘ └─┬─┘ └─┬─┘
     1     2     3
```

##### Delimited encoding of `[1, [2], 3]`
```
┌──── Opcode 0xF1 indicates a delimited list
│        ┌─── Opcode 0xF1 begins a nested delimited list
│        │        ┌─── Opcode 0xF0 closes the most recently
│        │        │    opened delimited container: the nested list.
│        │        │        ┌─── Opcode 0xF0 closes the most recently opened (and 
│        │        │        │    still open) delimited container: the outer list.
│        │        │        │
F1 61 01 F1 61 02 F0 61 03 F0
   └─┬─┘    └─┬─┘    └─┬─┘
     1        2        3
```

