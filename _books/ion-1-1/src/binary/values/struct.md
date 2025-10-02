## Structs

Each field in the struct is encoded as a field name followed by an opcode-prefixed value.
The encoding of field names depends on the current mode:

* **SID Mode**: Field names are encoded as [`FlexUInt`](../primitives/flex_uint.md) symbol addresses.
* **FlexSym Mode**: Field names are encoded as [`FlexSym`](../primitives/flex_sym.md)s.

All structs start in SID Mode, except for opcodes `0xF3` and `0xFD` which start in FlexSym Mode.

`0x8F 0x0C` represents `null.struct`.

### Length-prefixed encoding

If the high nibble of the opcode is `0xD_`, it represents a struct. The lower nibble of the opcode
indicates how many bytes were used to encode all of its nested `(field name, value)` pairs. Opcode
`0xD0` represents an empty struct.

> [!WARNING]
> Opcode `0xD1` is illegal. Non-empty structs must have at least two bytes: a field name and a value. 

If the struct's encoded byte-length is too large to be encoded in a nibble, writers may use the `0xFC` opcode
to write a variable-length struct in SID Mode or the `0xFD` opcode to write a variable-length struct in FlexSym Mode.
These opcodes are followed by a [`FlexUInt`](../primitives/flex_uint.md) that indicates the byte length.

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

##### Length-prefixed encoding of `{$10: "variable length struct"}` in SID Mode
```
 ┌───────────── Opcode `FC` indicates a struct with a FlexUInt length prefix (SID Mode)
 │  ┌────────── Length: FlexUInt 25
 │  │  ┌─────── Field name: FlexUInt 10 ($10)
 │  │  │  ┌──── Opcode `F8` indicates a variable length string
 │  │  │  │  ┌─ FlexUInt: 22 the string is 22 bytes long
 │  │  │  │  │  v  a  r  i  a  b  l  e     l  e  n  g  t  h     s  t  r  u  c  t
FC 33 15 F8 2D 76 61 72 69 61 62 6c 65 20 6c 65 6e 67 74 68 20 73 74 72 75 63 74
               └─────────────────────────────┬─────────────────────────────────┘
                                        UTF-8 bytes
```

##### Encoding of `null.struct`
```
┌──── Opcode 0x8F indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: struct
│  │
8F 0C
```

### Delimited encoding

Opcode `0xF2` indicates the beginning of a delimited struct in SID Mode.
Opcode `0xF3` indicates the beginning of a delimited struct in FlexSym Mode.

Delimited structs are closed by putting the delimited container end opcode (`0xEF`) in the _value_ position.
The field name immediately prior is discarded.
By convention, you should use `$0`, but the field name itself is of no consequence.

#### Delimited encoding of the empty struct (`{}`) in SID Mode
```
┌─── Opcode 0xF2 indicates the beginning of a delimited struct in SID Mode
│  ┌─── Throwaway field name: FlexUInt 0 ($0)
│  │  ┌─── Opcode 0xEF indicates the end of the delimited container
F2 01 EF
```

#### Delimited encoding of the empty struct (`{}`) in FlexSym Mode
```
┌─── Opcode 0xF3 indicates the beginning of a delimited struct in FlexSym Mode
│  ┌─── Throwaway field name: FlexSym 0 ($0)
│  │  ┌─── Opcode 0xEF indicates the end of the delimited container
F3 01 EF
```

> [!NOTE]
> It is much more compact to write `0xD0`—the [empty length-prefixed struct](#length-prefixed-encoding-of-an-empty-struct-).

#### Delimited encoding of `{"foo": 1, $11: 2}` in FlexSym Mode
```
┌─── Opcode 0xF3 indicates the beginning of a delimited struct in FlexSym Mode
│  ┌─ FlexSym -4 (3 UTF-8 bytes follow)
│  │                 ┌─ FlexSym: 11 ($11)
│  │                 │        ┌─── Throwaway field name
│  │   f  o  o       │        │  ┌─── Opcode 0xEF indicates the end of the delimited container
F3 FB 66 6F 6F 61 01 17 61 02 01 EF
      └──┬───┘ └─┬─┘    └─┬─┘
      3 UTF-8    1        2
       bytes
```

### Mode Switching

Structs may switch between SID Mode and FlexSym Mode by placing a mode-switch opcode (`0xEE`) in the _value_ position of a struct.
This causes the prior field name to be discarded (just like a `NOP`), and switches the struct from FlexSym Mode to SID Mode or from SID Mode to FlexSym Mode.

Mode-switching works with both prefixed and delimited structs. It costs 2 bytes to switch modes (one for the discarded field name, and one for the mode-switch opcode).
It is possible, but not recommended, to switch back and forth between modes.

In **SID Mode**, each field name is a `FlexUInt` which is the SID.
In **FlexSym Mode**, each field name is a `FlexSym`.

> [!NOTE]
> The ability to switch modes exists to allow writer implementations to start in the more compact SID mode and then switch to FlexSym mode if needed without having to backtrack and rewrite all prior fields in the struct. If you know ahead of time that you will have a mix of inline text and SIDs, you should usually prefer to start a struct in FlexSym mode rather than switching to SID mode later.


##### Switching to FlexSym Mode while encoding `{$10: 1, foo: 2, $11: 3}`
In this example, the writer switches to FlexSym Mode before encoding `foo` so it can write the UTF-8 bytes inline.
```
┌──── An opcode in the range 0xD0-0xDF indicates a length-prefixed struct
│  ┌─── Field name: FlexUInt 10 ($10) [SID Mode]
│  │        ┌─── Throwaway field name
│  │        │  ┌─── Mode switch opcode 0xEE (switches to FlexSym Mode)
│  │        │  │  ┌─── FlexSym: -4 (3 UTF-8 bytes follow)
│  │        │  │  │                 ┌─── Field name: FlexSym 11 ($11) [FlexSym Mode]
│  │        │  │  │   f  o  o       │
DB 15 61 01 01 EE FB 66 6F 6F 61 02 17 61 03
      └─┬─┘          └──┬───┘ └─┬─┘    └─┬─┘
        1            3 UTF-8    2        3
                      bytes
```
