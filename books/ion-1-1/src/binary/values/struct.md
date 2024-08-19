## Structs

### Length-prefixed encoding

If the high nibble of the opcode is `0xD_`, it represents a struct. The lower nibble of the opcode
indicates how many bytes were used to encode all of its nested `(field name, value)` pairs. Opcode
`0xD0` represents an empty struct.

> [!WARNING]
> Opcode `0xD1` is illegal. Non-empty structs must have at least two bytes: a field name and a value. 

If the struct's encoded byte-length is too large to be encoded in a nibble, writers may use the `0xFD` opcode
to write a variable-length struct. The `0xFD` opcode is followed by a [`FlexUInt`](../primitives/flex_uint.md)
that indicates the byte length.

Each field in the struct is encoded as a [`FlexUInt`](#flexuint) representing the address of the field name's
text in the symbol table, followed by an opcode-prefixed value.

`0xEB 0x0B` represents `null.struct`.

##### Length-prefixed encoding of an empty struct (`{}`)
```
┌──── An opcode in the range 0xD0-0xDF indicates a length-prefixed struct
│┌─── A lower nibble of 0 indicates that the struct's fields took zero bytes to encode
D0
```

##### Length-prefixed encoding of `{$10: 1, $11: 2}`
```
┌──── An opcode in the range 0xD0-0xDF indicates a length-prefixed struct
│  ┌─── Field name: FlexUInt 10 ($10)
│  │        ┌─── Field name: FlexUInt 11 ($11)
│  │        │
D6 15 61 01 17 61 02
      └─┬─┘    └─┬─┘
        1        2
```

##### Length-prefixed encoding of `{$10: "variable length struct"}`
```
 ┌───────────── Opcode `FD` indicates a struct with a FlexUInt length prefix
 │  ┌────────── Length: FlexUInt 25
 │  │  ┌─────── Field name: FlexUInt 10 ($10)
 │  │  │  ┌──── Opcode `F9` indicates a variable length string
 │  │  │  │  ┌─ FlexUInt: 22 the string is 22 bytes long
 │  │  │  │  │  v  a  r  i  a  b  l  e     l  e  n  g  t  h     s  t  r  u  c  t
FD 33 15 F9 2D 76 61 72 69 61 62 6c 65 20 6c 65 6e 67 74 68 20 73 74 72 75 63 74
               └─────────────────────────────┬─────────────────────────────────┘
                                        UTF-8 bytes
```

##### Encoding of `null.struct`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: struct
│  │
EB 0B
```

#### Optional `FlexSym` field name encoding

By default, all struct field names are encoded as [`FlexUInt`](../primitives/flex_uint.md) symbol addresses.
However, a writer has the option of encoding the field names as [`FlexSym`](../primitives/flex_sym.md)s instead,
granting additional flexibility at the expense of some compactness.

Writing a field names as a `FlexSym`s allows the writer to:
* encode the UTF-8 bytes of the field name inline (for example, to avoid modifying the symbol table).
* call a macro whose output (another struct) will be merged into the current struct.
* encode the field name as a symbol address if it's already in the symbol table. (just like a `FlexUInt` would,
  but slightly less compactly.)

To switch to `FlexSym` field names, the writer emits a [`FlexUInt`](../primitives/flex_uint.md) zero
(byte `0x01`) in field name position to inform the reader that subsequent field names will be encoded
as `FlexSym`s.

This switch is _one way_. Once the writer switches to using `FlexSym`, the encoding cannot be switched
back to `FlexUInt` for the remainder of the struct.

##### Switching to `FlexSym` while encoding `{$10: 1, foo: 2, $11: 3}`
In this example, the writer switches to `FlexSym` field names before encoding `foo` so it can write the UTF-8 bytes inline.
```
┌──── An opcode in the range 0xD0-0xDF indicates a length-prefixed struct
│  ┌─── Field name: FlexUInt 10 ($10)
│  │        ┌─── FlexUInt 0: Switch to FlexSym field name encoding
│  │        │
│  │        │  ┌─── FlexSym: 3 UTF-8 bytes follow
│  │        │  │           ┌─── Field name: FlexSym 11 ($11)
│  │        │  │   f  o  o │
D6 15 61 01 01 FB 66 6F 6F 17 61 02
      └─┬─┘                   └─┬─┘
        1                       2
```

> [!NOTE]
> Because `FlexUInt` zero indicates a mode switch, encoding symbol ID `$0` requires switching to `FlexSym`.


##### Length-prefixed encoding of `{$0: 1}`
```
┌─── Opcode with high nibble `D` indicates a struct
│┌── Length: 5
││ ┌── FlexUInt 0 in the field name position indicates that the struct
││ │   is switching to FlexSym mode
││ │  ┌── FlexSym "escape"
││ │  │  ┌── Symbol address: 1-byte FixedUInt follows 
││ │  │  │  ┌─ FixedUInt 0
││ │  │  │  │
D5 01 01 E1 00 61 01
      └───┬──┘ └─┬─┘
         $0      1
```

### Delimited encoding

Opcode `0xF3` indicates the beginning of a delimited struct. Unlike [length-prefixed structs](#length-prefixed-encoding),
delimited structs _always_ encode their field names as [`FlexSym`](#flexsym)s.

Unlike lists and S-expressions, structs cannot use opcode `0xF0` by itself to indicate the end of the delimited
container. This is because `0xF0` is a valid `FlexSym` (a symbol with 16 bytes of inline text). To close the delimited
struct, the writer emits a `0x01` byte (a `FlexSym` escape) followed by the opcode `0xF0`.

> [!NOTE]
> It is much more compact to write `0xD0`-- the [empty length-prefixed struct](#length-prefixed-encoding-of-an-empty-struct-).

#### Delimited encoding of the empty struct (`{}`)
```
┌─── Opcode 0xF3 indicates the beginning of a delimited struct
│  ┌─── FlexSym escape code 0 (0x01): an opcode follows
│  │  ┌─── Opcode 0xF0 indicates the end of the most
│  │  │    recently opened delimited container
F3 01 F0
```

#### Delimited encoding of `{"foo": 1, $11: 2}`
```
┌─── Opcode 0xF3 indicates the beginning of a delimited struct
│
│  ┌─ FlexSym -3     ┌─ FlexSym: 11 ($11)
│  │                 │        ┌─── FlexSym escape code 0 (0x01): an opcode follows
│  │                 │        │  ┌─── Opcode 0xF0 indicates the end of the most
│  │   f  o  o       │        │  │    recently opened delimited container
F3 FB 66 6F 6F 61 01 17 61 02 01 F0
      └──┬───┘ └─┬─┘    └─┬─┘
      3 UTF-8    1        2
       bytes
```
