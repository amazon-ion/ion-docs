## S-Expressions

S-expressions use the same encodings as [lists](list.md), but with different opcodes.

| Opcode        | Encoding                                                                                             |
|---------------|------------------------------------------------------------------------------------------------------|
| `0xC0`-`0xCF` | Length-prefixed S-expression; low nibble of the opcode represents the byte-length.                   |
| `0xFB`        | Variable-length prefixed S-expression; a `FlexUInt` following the opcode represents the byte-length. |
| `0xF1`        | Starts a delimited S-expression; `0xEF` closes the most recently opened delimited container.         |
| `0x5C`        | Tagless-element S-expression; opcode is followed by element encoding type and number of elements.    |

`0x8F 0x0B` represents `null.sexp`.

### Length-prefixed encoding

##### Length-prefixed encoding of an empty S-expression (`()`)
```
┌──── An Opcode in the range 0xC0-0xCF indicates an S-expression.
│┌─── A low nibble of 0 indicates that the child values of this S-expression
││    took zero bytes to encode.
C0
```

##### Length-prefixed encoding of `(1 2 3)`
```
┌──── An Opcode in the range 0xC0-0xCF indicates an S-expression.
│┌─── A low nibble of 6 indicates that the child values of this S-expression
││    took six bytes to encode.
C6 61 01 61 02 61 03
   └─┬─┘ └─┬─┘ └─┬─┘
     1     2     3
```

##### Length-prefixed encoding of `("variable length sexp")`
```
┌──── Opcode 0xFB indicates a variable-length sexp. A FlexUInt length follows.
│  ┌───── Length: FlexUInt 22
│  │  ┌────── Opcode 0xF8 indicates a variable-length string. A FlexUInt length follows.
│  │  │  ┌─────── Length: FlexUInt 20
│  │  │  │   v  a  r  i  a  b  l  e     l  e  n  g  t  h     s  e  x  p
FB 2D F8 29 76 61 72 69 61 62 6C 65 20 6C 65 6E 67 74 68 20 73 65 78 70
      └─────────────────────────────┬─────────────────────────────────┘
                          Nested string element
```

### Delimited encoding

##### Delimited encoding of an empty S-expression (`()`)
```
┌──── Opcode 0xF1 indicates a delimited S-expression
│  ┌─── Opcode 0xEF indicates the end of the most recently opened container
F1 EF
```

##### Delimited encoding of `(1 2 3)`
```
┌──── Opcode 0xF1 indicates a delimited S-expression
│                    ┌─── Opcode 0xEF indicates the end of
│                    │    the most recently opened container
F1 61 01 61 02 61 03 EF
   └─┬─┘ └─┬─┘ └─┬─┘
     1     2     3
```

##### Delimited encoding of `(1 (2) 3)`
```
┌──── Opcode 0xF1 indicates a delimited S-expression
│        ┌─── Opcode 0xF1 begins a nested delimited S-expression
│        │        ┌─── Opcode 0xEF closes the most recently
│        │        │    opened delimited container: the nested S-expression.
│        │        │        ┌─── Opcode 0xEF closes the most recently opened (and
│        │        │        │     still open)delimited container: the outer S-expression.
│        │        │        │
F1 61 01 F1 61 02 EF 61 03 EF
   └─┬─┘    └─┬─┘    └─┬─┘
     1        2        3
```

### Tagless-Element S-Expressions

Opcode `0x5C` indicates a tagless-element S-expression. This is a compact encoding for homogeneous collections where all elements have the same type.

The opcode is followed by:
1. One or more bytes describing the tagless type:
   - If the byte is in `0x00`-`0x47`: only one byte (the opcode) is present; this is the macro address
   - If the byte is in `0x48`-`0x4F`: it is followed by a `FlexUInt` to encode the entire macro address
   - If the byte is `0xF4`: it is followed by a `FlexUInt` which encodes the entire macro address
   - For any other byte value: only one byte (the opcode) is present
2. A `FlexUInt` length indicating the number of direct child values in the S-expression
3. Each element encoded without the leading opcode or macro address

##### Tagless-element S-expression of integers `(1 2 3 4)`
```
┌──── Opcode 0x5C indicates a tagless-element S-expression
│  ┌─── Tagless type: 0x61 (int8)
│  │  ┌─── Length: FlexUInt 4 (4 elements)
│  │  │
5C 61 09 01 02 03 04
         └────┬────┘
         4 int8 values
```

##### Tagless-element S-expression with macro shape `[\:point\ (1 3), (1 4), (2 4)]`
```
┌──── Opcode 0x5C indicates a tagless-element sexp
│  ┌─── Tagless type: 0x05 (macro address 5, assuming :point is at address 5)
│  │  ┌─── Length: FlexUInt 3 (3 elements)
│  │  │       ┌─── First element: (1 3)
│  │  │       │           ┌─── Second element: (1 4)
│  │  │       │           │           ┌─── Third element: (2 4)
│  │  │  ┌────┴────┐ ┌────┴────┐ ┌────┴────┐
5C 05 07 61 01 61 03 61 01 61 04 61 02 61 04
         └─┬─┘ └─┬─┘ └─┬─┘ └─┬─┘ └─┬─┘ └─┬─┘
           1     3     1     4     2     4
```

##### Tagless-element S-expression with macro-shape using length-prefixed E-expression `[\:3\ (1 3), (1 259) ]`

```
┌──── Opcode 0x5C indicates a tagless-element sexp
│    ┌─── Tagless type opcode F4 with FlexUInt address 3
│    │   ┌─── Length: FlexUInt 2 (2 elements)
│    │   │        ┌─── First element: (1 3)
│    │   │        │                ┌─── Second element: (1 4)
│  ┌─┴─┐ │  ┌─────┴──────┐ ┌───────┴───────┐
5C F4 07 05 09 61 01 61 03 0B 61 01 62 04 01
            │  └─┬─┘ └─┬─┘ │  └─┬─┘ └───┬──┘
            │    1     3   │    1      259
            └─ FlexUInt    └─ FlexUInt
               Length=4       Length=5
```

### Encoding of `null.sexp`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: sexp
│  │
8F 0B
```
