## S-Expressions

S-expressions use the same encodings as [lists](list.md), but with different opcodes.

| Opcode        | Encoding                                                                                             |
|---------------|------------------------------------------------------------------------------------------------------|
| `0xC0`-`0xCF` | Length-prefixed S-expression; low nibble of the opcode represents the byte-length.                   |
| `0xFC`        | Variable-length prefixed S-expression; a `FlexUInt` following the opcode represents the byte-length. |
| `0xF2`        | Starts a delimited S-expression; `0xF0` closes the most recently opened delimited container.         |

`0xEB 0x0A` represents `null.sexp`.

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
┌──── Opcode 0xFC indicates a variable-length sexp. A FlexUInt length follows.
│  ┌───── Length: FlexUInt 22
│  │  ┌────── Opcode 0xF9 indicates a variable-length string. A FlexUInt length follows.
│  │  │  ┌─────── Length: FlexUInt 20
│  │  │  │   v  a  r  i  a  b  l  e     l  e  n  g  t  h     s  e  x  p
FC 2D F9 29 76 61 72 69 61 62 6C 65 20 6C 65 6E 67 74 68 20 73 65 78 70
      └─────────────────────────────┬─────────────────────────────────┘
                          Nested string element
```


##### Encoding of `null.sexp`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: sexp
│  │
EB 0A
```

### Delimited encoding

##### Delimited encoding of an empty S-expression (`()`)
```
┌──── Opcode 0xF2 indicates a delimited S-expression
│  ┌─── Opcode 0xF0 indicates the end of the most recently opened container
F2 F0
```

##### Delimited encoding of `(1 2 3)`
```
┌──── Opcode 0xF2 indicates a delimited S-expression
│                    ┌─── Opcode 0xF0 indicates the end of
│                    │    the most recently opened container
F2 61 01 61 02 61 03 F0
   └─┬─┘ └─┬─┘ └─┬─┘
     1     2     3
```

##### Delimited encoding of `(1 (2) 3)`
```
┌──── Opcode 0xF2 indicates a delimited S-expression
│        ┌─── Opcode 0xF2 begins a nested delimited S-expression
│        │        ┌─── Opcode 0xF0 closes the most recently
│        │        │    opened delimited container: the nested S-expression.
│        │        │        ┌─── Opcode 0xF0 closes the most recently opened (and
│        │        │        │     still open)delimited container: the outer S-expression.
│        │        │        │
F2 61 01 F2 61 02 F0 61 03 F0
   └─┬─┘    └─┬─┘    └─┬─┘
     1        2        3
```

