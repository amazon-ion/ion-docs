
## Encoding Expressions

> [!NOTE]
> This chapter focuses on the binary encoding of e-expressions. [_Macros by example_](../macros_by_example.md) explains what they are and how they are used.

### E-expression with the address in the opcode

If the value of the opcode is less than `64` (`0x40`), it represents an E-expression invoking the macro at the
corresponding __address__—-an offset within the local macro table.

#### Invocation of macro address `7`
```
┌──── Opcode in 00-3F range indicates an e-expression
│     where the opcode value is the macro address
│
07
└── FixedUInt 7
```

#### Invocation of macro address `31`
```
┌──── Opcode in 00-3F range indicates an e-expression
│     where the opcode value is the macro address
│
1F
└── FixedUInt 31
```

Note that the opcode alone tells us which macro is being invoked, but it does not supply enough information for the
reader to parse any arguments that may follow. The parsing of arguments is described in detail in the section _Macro
calling conventions_. (TODO: Link)


#### E-expression With the Address as a Trailing `FixedUInt`

While E-expressions invoking macro addresses in the range `[0, 63]` can be encoded in a single byte using
<<e_expression_with_the_address_in_the_opcode, E-expressions with the address in the opcode>>,
many applications will benefit from defining more than 64 macros.

The `0x4_` and `0x5_` opcodes can be used to represent over 1 million macro addresses.
If the high nibble of the opcode is `0x4_`, then a biased address follows as a 1-byte FixedUInt.
If the high nibble of the opcode is `0x5_`, then a biased address follows as a 2-byte FixedUInt.
In both cases, the address is biased by the total number of addresses with lower opcodes.
For `0x4_`, the bias is `256 * low_nibble + 64` (or `(low_nibble shift-left 8) + 64`).
For `0x5_`, the bias is `65536 * low_nibble + 4160`.

#### Invocation of macro address `841`
```
┌──── Opcode in range 40-4F indicates a macro address with 1-byte FixedUInt address
│┌─── Low nibble 3 indicates bias of 832
││
43 09
   │
   └─── FixedUInt 9

Biased Address : 9
Bias : 832
Address : 841
```

#### Invocation of macro address `142918`
```
┌──── Opcode in range 50-5F indicates a macro address with 2-byte FixedUInt address
│┌─── Low nibble 2 indicates bias of 135232
││
52 06 1E
   └─┬─┘
     └─── FixedUInt 7686

Biased Address : 7686
Bias : 135232
Address : 142918
```

#### Macro address range biases for `0x4_` and `0x5_`

| Low Nibble | `0x4_` Bias | `0x5_` Bias |
|------------|-------------|-------------|
| `0`        | `64`        | `4160`      |
| `1`        | `320`       | `69696`     |
| `2`        | `576`       | `135232`    |
| `3`        | `832`       | `200768`    |
| `4`        | `1088`      | `266304`    |
| `5`        | `1344`      | `331840`    |
| `6`        | `1600`      | `397376`    |
| `7`        | `1856`      | `462912`    |
| `8`        | `2112`      | `528448`    |
| `9`        | `2368`      | `593984`    |
| `A`        | `2624`      | `659520`    |
| `B`        | `2880`      | `725056`    |
| `C`        | `3136`      | `790592`    |
| `D`        | `3392`      | `856128`    |
| `E`        | `3648`      | `921664`    |
| `F`        | `3904`      | `987200`    |

#### E-expression with the address as a trailing `FlexUInt`

<div class="warning">

> This section was obsolete and needs to be rewritten.

</div>

## Tagged E-expression Argument Encoding

When a macro parameter has a tagged type, the encoding of that parameter's corresponding argument in an E-expression
is identical to how it would be encoded anywhere else in an Ion stream: it has a leading [opcode](#opcodes) that
dictates how many bytes follow and how they should be interpreted. This is very flexible, but makes it possible
for writers to encode values that conflict with the parameter's declared type. Because of this, the macro expander will
read the argument and then check its type against the parameter's declared type. If it does not match, the macro
expander must raise an error.

Macro `foo` (defined below) is used in this section's subsequent examples to demonstrate the encoding of tagged-type
arguments.

#### Definition of example macro `foo` at address `0`
```
(macro
    foo           // Macro name
    (number::x!)  // Parameters
    /*...*/       // Template (elided)
)
```

#### Encoding of e-expression `(:foo 3.14e)`
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a tagged number as a parameter (`x`), so an opcode follows.
│  ┌──── Opcode 0x6B indicates a 2-byte float; an IEEE-754 half-precision float follows
│  │
00 6B 47 42
      └─┬─┘
      3.14e0

// The macro expander confirms that `3.14e0` (a `float`) matches the expected type: `number`.
```

#### Encoding of e-expression `(:foo 9)`
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a tagged number as a parameter (`x`), so an opcode follows.
│  ┌──── Opcode 0x61 indicates a 1-byte integer. A 1-byte FixedInt follows.
│  │  ┌──── A 1-byte FixedInt: 9
00 61 09

// The macro expander confirms that `9` (an `int`) matches the expected type: `number`.
```

#### Encoding of e-expression `(:foo $10::9)`
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a tagged number as a parameter (`x`), so an opcode follows.
│  ┌──── Opcode 0xE4 indicates a single annotation with symbol address. A FlexUInt follows.
│  │  ┌──── Symbol address: FlexUInt 10 ($10); an opcode for the annotated value follows.
│  │  │  ┌──── Opcode 0x61 indicates a 1-byte integer
│  │  │  │   ┌──── 1-byte FixedInt 9
00 E4 15 61 09

// The macro expander confirms that `$10::9` (an annotated `int`) matches the expected type: `number`.
```

#### Encoding of e-expression `(:foo null.int)`
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a tagged number as a parameter (`x`), so an opcode follows.
│  ┌──── Opcode 0xEB indicates a typed null. A 1-byte FixedUInt follows indicating the type.
│  │  ┌──── Null type: FixedUInt: 1; integer
00 EB 01

// The macro expander confirms that `null.int` matches the expected type: `number`.
```

#### Encoding of e-expression `(:foo null)`
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a tagged number as a parameter (`x`), so an opcode follows.
│  ┌──── Opcode 0xEA represents an untyped null (aka `null.null`)
00 EA

// The macro expander confirms that `null` matches the expected type: `number`
```

#### Encoding of e-expression `(:foo (:bar))`
```
// A second macro definition at address 1
(macro
    bar // Macro name
    ()  // Parameters
    5   // Template; invocations of `bar` always expand to `5`.
)

┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a tagged int as a parameter (`x`), so an opcode follows.
│  ┌──── Opcode 0x01 is less than 0x40, so it is an E-expression invoking the macro
│  │     at address 1: `bar`. `bar` takes no parameters, so no bytes follow.
00 01

// The macro expander confirms that the expansion of `(:bar)` (that is: `5`) matches
// the expected type: `number`.
```

#### Encoding of e-expression `(:foo "hello")`
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0, `foo`. `foo` takes a tagged int as a parameter (`x`), so an opcode follows.
│  ┌──── Opcode 0x95 indicates a 5-byte string. 5 UTF-8 bytes follow.
│  │  h  e  l  l  o
00 95 68 65 6C 6C 6F
      └──────┬─────┘
        UTF-8 bytes

// ERROR: Expected a `number` for `foo` parameter `x`, but found `string`
```


#### Tagless Encodings

<div class="warning">

> This section was obsolete and needs to be rewritten.

</div>

In contrast to <<tagged_encodings, tagged encodings>>, _tagless encodings_ do not begin with an opcode. This means
that they are potentially more compact than a tagged type, but are also less flexible. Because tagless encodings
do not have an opcode, they cannot represent E-expressions, annotation sequences, or `null` values of any kind.

Tagless types include the <<primitive_encodings, primitive types>> and <<macro_shapes, macro shapes>>.


##### Primitive Types

Primitive types are self-delineating, either by having a statically known size in bytes or by including length
information in their encoding.

Primitive types include:

| Ion type | Primitive type   | Size in bytes | Encoding                                                                                                              |
|----------|------------------|---------------|-----------------------------------------------------------------------------------------------------------------------|
| `int`    | `uint8`          | 1             | [`FixedUInt`](#fixeduint)                                                                                             |
|          | `uint16`         | 2             |                                                                                                                       |
|          | `uint32`         | 4             |                                                                                                                       |
|          | `uint64`         | 8             |                                                                                                                       |
|          | `compact_uint`   | variable      | [`FlexUInt`](#flexuint)                                                                                               |
|          | `int8`           | 1             | [`FixedInt`](#fixedint)                                                                                               |
|          | `int16`          | 2             |                                                                                                                       |
|          | `int32`          | 4             |                                                                                                                       |
|          | `int64`          | 8             |                                                                                                                       |
|          | `compact_int`    | variable      | [`FlexInt`](#flexint)                                                                                                 |  
| `float`  | `float16`        | 2             | [Little-endian IEEE-754 half-precision float](https://en.wikipedia.org/wiki/Half-precision_floating-point_format)     |
|          | `float32`        | 4             | [Little-endian IEEE-754 single-precision float](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) |
|          | `float64`        | 8             | [Little-endian IEEE-754 double-precision float](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) |
| `symbol` | `compact_symbol` | variable      | [`FlexSym`](#flexsym)                                                                                                 |

##### Macro Shapes

<div class="warning">

> This section was obsolete and needs to be rewritten.

</div>

The term _macro shape_ describes a macro that is being used as the encoding of an E-expression argument. They are
considered "shapes" rather than types because while their encoding is always statically known, the types of data
produced by their expansion is not. A single macro can produce streams of varying length and containing values of
different Ion types depending on the arguments provided in the invocation.

See [Macro Shapes](macros_by_example.md#macro-shapes) for more information.

### Encoding E-expressions With Multiple Arguments

E-expression arguments corresponding to each parameter are encoded one after the other moving from left to right.

#### $1
```
(macro foo             // Macro name
  (                    // Parameters
    string::a
    compact_symbol::b
    uint16::c
  )
  /* ... */            // Body (elided)
)
```

#### $1
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0, `foo`. `foo`'s first parameter is a string, so an opcode follows.
│
│  ┌──── Opcode 0x95 indicates a 5-byte string. 5 UTF-8 bytes follow.
│  │
│  │                 ┌──── `foo`'s second parameter is a compact_symbol, so a `FlexSym` follows.
│  │                 │     FlexSym -3: 3 bytes of UTF-8 text follow.
│  │                 │
│  │                 │           ┌──── `foo`'s third parameter is a uint16, so a 2-byte
│  │                 │           │     2-byte `FixedUInt` follows.
│  │                 │           │     FixedUInt: 512
│  │  h  e  l  l  o  │   b  a  z │
00 95 68 65 6C 6C 6F FD 62 61 7A 00 20
      └──────┬─────┘    └───┬──┘
        UTF-8 bytes    UTF-8 bytes
```


### Argument Encoding Bitmap (AEB)

<div class="warning">

> This section was obsolete and needs to be rewritten.

</div>

### Expression Groups

Grouped parameters can be encoded using either a <<length_prefixed_expression_groups, length-prefixed>> or
<<delimited_expression_groups, delimited>> expression group encoding.

The example encodings in the following sections refer to this macro definition:

#### $1
```
(macro
    foo          // Macro name
    (int::x*)    // Parameters; `x` is a grouped parameter
    /*...*/      // Body (elided)
)
```

#### Length-prefixed Expression Groups

If a grouped parameter's <<argument_encoding_bitmap, AEB bits>> are `0b10`, then the argument expressions belonging
to that parameter will be prefixed by a `FlexUInt` indicating the number of bytes used to encode them.

#### $1
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a group of int expressions as a parameter (`x`),
│     so an argument encoding bitmap (AEB) follows.
│  ┌──── AEB: 0b0000_0010; the arguments for grouped parameter `x` have been encoded
│  │     as a length-prefixed expression group. A FlexUInt length prefix follows.
│  │  ┌──── FlexUInt: 6; the next 6 bytes are an `int` expression group.
│  │  │
00 02 0D 61 01 61 02 61 03
         └─┬─┘ └─┬─┘ └─┬─┘
           1     2     3
```

[#delimited_expression_groups]
#### Delimited Expression Groups

If a grouped parameter's <<argument_encoding_bitmap, AEB bits>> are `0b11`, then the argument expressions belonging
to that parameter will be encoded in a delimited sequence.
Delimited sequences are encoded differently for <<tagged_encodings,tagged types>> and
<<tagless_encodings, tagless types>>.

##### Delimited Tagged Expression Groups

Tagged type encodings begin with an <<opcodes, opcode>>; a delimited sequence of tagged arguments is terminated by
the closing delimiter opcode, `0xF0`.

#### $1
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a group of int expressions as a parameter (`x`),
│     so an argument encoding bitmap (AEB) follows.
│  ┌──── AEB: 0b0000_0011; the arguments for grouped parameter `x` have been encoded
│  │     as a delimited expression group. A series of tagged `int` expressions follow.
│  │                    ┌──── Opcode 0xF0 ends the expression group.
│  │                    │
00 03 61 01 61 02 61 03 F0
      └─┬─┘ └─┬─┘ └─┬─┘
        1     2     3
```

##### Delimited Tagless Expression Groups

Tagless type encodings do not have an opcode, and so cannot use the closing delimiter opcode--`0xF0` is a valid first
byte for many tagless encodings.

Instead, tagless expressions are grouped into 'pages', each of which is prefixed by a [`FlexUInt`](#flexuint)
representing a count (not a byte-length) of the expressions that follow. If a prefix has a count of zero, that marks
the end of the sequence of pages.

#### $1
```
(macro
    compact_foo          // Macro name
    (compact_int::x*)    // Parameters; `x` is a grouped parameter
    /*...*/              // Body (elided)
)
```

#### $1
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a group of int expressions as a parameter (`x`),
│     so an argument encoding bitmap (AEB) follows.
│  ┌──── AEB: 0b0000_0011; the arguments for grouped parameter `x` have been encoded
│  │     as a delimited expression group. Count-prefixed pages of `compact_int`
│  │     expressions follow.
│  │   ┌──── Count prefix: FlexUInt 3; 3 `compact_int`s follow.
│  │   │          ┌──── Count prefix: FlexUInt 0; no more pages follow.
│  │   │          │
00 03 07 03 05 07 01
         └──┬───┘
         First page: 1, 2, 3
```

#### $1
```
┌──── The opcode is less than 0x40, so it is an E-expression invoking the macro at
│     address 0: `foo`. `foo` takes a group of int expressions as a parameter (`x`),
│     so an argument encoding bitmap (AEB) follows.
│  ┌──── AEB: 0b0000_0011; the arguments for grouped parameter `x` have been encoded
│  │     as a delimited expression group. Count-prefixed pages of `compact_int`
│  │     expressions follow.
│  │   ┌──── Count prefix: FlexUInt 2; 2 `compact_int`s follow.
│  │   │        ┌──── Count prefix: FlexUInt 1; a single `compact_int` follows.
│  │   │        │    ┌──── Count prefix: FlexUInt 0; no more pages follow.
│  │   │        │    │
00 03 05 03 05 03 07 01
         └─┬─┘    └─ Second page: 3
           │
         First page: 1, 2
```
