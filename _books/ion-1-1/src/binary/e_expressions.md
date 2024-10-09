
## Encoding Expressions

> [!NOTE]
> This chapter focuses on the binary encoding of e-expressions. [_Macros by example_](../macros/macros_by_example.md) explains what they are and how they are used.

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

#### E-expressions with biased `FixedUInt` addresses

While E-expressions invoking macro addresses in the range `[0, 63]` can be encoded in a single byte using
[E-expressions with the address in the opcode](#e-expression-with-the-address-in-the-opcode),
many applications will benefit from defining more than 64 macros. The `0x4_` and `0x5_` opcodes
can be used to represent macro addresses up to 1,052,734. In both encodings, the address is biased by
the total number of addresses with lower opcodes.

If the high nibble of the opcode is `0x4_`, then a biased address follows as a 1-byte [`FixedUInt`](primitives/fixed_uint.md).
For `0x4_`, the bias is `256 * low_nibble + 64` (or `(low_nibble << 8) + 64`).

If the high nibble of the opcode is `0x5_`, then a biased address follows as a 2-byte [`FixedUInt`](primitives/fixed_uint.md).

For `0x5_`, the bias is `65536 * low_nibble + 4160` (or `(low_nibble << 16) + 4160`)

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

The opcode `0xF4` indicates an e-expression whose address is encoded as a trailing [`FlexUInt`](primitives/flex_uint.md) with no bias.
This encoding is less compact for addresses that can be encoded using opcodes `0x5F` and below, but it is the
only encoding that can be used for macro addresses greater than 1,052,734.

##### Invocation of macro address `4`
```
┌──── Opcode F4 indicates an e-expression with a trailing `FlexUInt` macro address
│
│
F4 09
   │
   └─── FlexUInt 4
```

##### Invocation of macro address `1_100_000`
```
┌──── Opcode F4 indicates an e-expression with a trailing `FlexUInt` macro address
│
│
F4 04 47 86
   └──┬───┘
      └─── FlexUInt 1,100,000
```

### System Macro Invocations

E-expressions that invoke a [system macro](../modules/system_module.md#system-macro-addresses) can be encoded using the `0xEF` opcode followed by a 1-byte `FixedUInt` representing an index in the [system macro table](../modules/system_module.md#system-macros).

##### Encoding of the system macro `values`
```
┌──── Opcode 0xEF indicates a system symbol or macro invocation
│  ┌─── FixedInt 1 indicates macro 1 from the system macro table
│  │
EF 01
```

In addition, system macros MAY be invoked using any of the `0x00`-`0x5F` or `0xF4`-`0xF5` opcodes, provided that the macro being invoked has been given an address in user macro address space.
<!-- TODO: Add or link an example of how this can be done. /-->

## E-expression argument encoding

The example invocations in prior sections have demonstrated how to encode an invocation of the simplest
form of macro--one with no parameters. This section explains how to encode macro invocations when they take
parameters of different encodings and cardinalities.

To begin, we will examine how arguments are encoded when all of the macro's parameters use the [_tagged encoding_](#tagged-encoding)
and have a cardinality of [_exactly-one_](../macros/defining_macros.md#parameter-cardinalities).

### Tagged encoding

When a macro parameter does not specify an encoding (the parameter name is not annotated), arguments
passed to that parameter use the 'tagged' encoding. The argument begins with a leading [opcode](opcodes.md)
that dictates how to interpret the bytes that follow.

This is the same encoding used for values in other Ion 1.1 contexts like lists, s-expressions, or at the top level.

### Encoding a single `exactly-one` argument

A parameter with a cardinality of [_exactly-one_](../macros/defining_macros.md#parameter-cardinalities) expects its corresponding
argument to be encoded as a single expression of the parameter's declared encoding. (The following section will explore the
available encodings in greater depth; for now, our examples will be limited to parameters using the [_tagged encoding_](#tagged-encoding).)

When the macro has a single `exactly-one` parameter, the corresponding encoded argument follows the opcode and (if separate) the encoded address.

#### Example encoding of an e-expression with a tagged, `exactly-one` argument

##### Macro definition
```ion
(:set_macros
  (foo (x) ...)
)
```

##### Text e-expression
```ion
(:foo 1)
```

##### Binary e-expression with the address in the opcode
```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression invoking
│     the macro at address 0.
│  ┌─── Argument 'x': opcode 0x61 indicates a 1-byte integer
│  │   1
00 61 01
```


##### Binary e-expression using a trailing `FlexUInt` address
```
┌──── Opcode F4: An e-expression with a trailing FlexUInt address
│  ┌──── FlexUInt 0: Macro address 0
│  │  ┌─── Argument 'x': opcode 0x61 indicates a 1-byte integer
│  │  │   1
F4 01 61 01
```

### Encoding multiple `exactly-one` arguments

If the macro has more than one parameter, a reader would iterate over the parameters declared in the macro signature
from left to right. For each parameter, the reader would use the parameter's declared encoding to interpret the next
bytes in the stream. When no more parameters remain, parsing of the e-expression's arguments is complete.

#### Example encoding of an e-expression with multiple tagged, `exactly-one` arguments

##### Macro definition
```ion
(:set_macros
  (foo (a b c) ...)
)
```

##### Text e-expression
```ion
(:foo 1 2 3)
```

##### Binary e-expression with the address in the opcode
```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌─── Argument 'a': opcode 0x61 indicates a 1-byte integer
│  │      ┌─── Argument 'b': opcode 0x61 indicates a 1-byte integer
│  │      │    ┌─── Argument 'c': opcode 0x61 indicates a 1-byte integer
│  │   1  │  2 │   3
00 61 01 61 02 61 03
```

##### Binary e-expression using a trailing `FlexUInt` address
```
┌──── Opcode F4: An e-expression with a trailing FlexUInt address
│  ┌──── FlexUInt 0: Macro address 0
│  │  ┌─── Argument 'a': opcode 0x61 indicates a 1-byte integer
│  │  │     ┌─── Argument 'b': opcode 0x61 indicates a 1-byte integer
│  │  │     │     ┌─── Argument 'c': opcode 0x61 indicates a 1-byte integer
│  │  │     │     │
│  │  │   1 │   2 │   3
F4 01 61 01 61 02 61 03
```

### Tagless Encodings

In contrast to the [`tagged encoding`](#tagged-encoding), _tagless encodings_ do not begin with an opcode.
This means that they are potentially more compact than a tagged type, but are also less flexible. Because tagless encodings
do not have an opcode, they cannot represent E-expressions, annotation sequences, or `null` values of any kind.

Tagless encodings are comprised of the [primitive encodings](#primitive-encodings) and [macro shapes](#macro-shapes).

#### Primitive encodings

Primitive encodings are self-delineating, either by having a statically known size in bytes or by including length
information in their serialized form.

| Ion type | Primitive encoding | Size in bytes | Encoding                                                                                                              |
|----------|--------------------|:-------------:|-----------------------------------------------------------------------------------------------------------------------|
| `int`    | `uint8`            |       1       | [`FixedUInt`](primitives/fixed_uint.md)                                                                               |
|          | `uint16`           |       2       |                                                                                                                       |
|          | `uint32`           |       4       |                                                                                                                       |
|          | `uint64`           |       8       |                                                                                                                       |
|          | `flex_uint`        |   variable    | [`FlexUInt`](primitives/flex_uint.md)                                                                                 |
|          | `int8`             |       1       | [`FixedInt`](primitives/fixed_int.md)                                                                                 |
|          | `int16`            |       2       |                                                                                                                       |
|          | `int32`            |       4       |                                                                                                                       |
|          | `int64`            |       8       |                                                                                                                       |
|          | `flex_int`         |   variable    | [`FlexInt`](primitives/flex_int.md)                                                                                   |
| `float`  | `float16`          |       2       | [Little-endian IEEE-754 half-precision float](https://en.wikipedia.org/wiki/Half-precision_floating-point_format)     |
|          | `float32`          |       4       | [Little-endian IEEE-754 single-precision float](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) |
|          | `float64`          |       8       | [Little-endian IEEE-754 double-precision float](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) |
| `symbol` | `flex_sym`         |   variable    | [`FlexSym`](primitives/flex_sym.md)                                                                                   |

#### Example encoding of an e-expression with primitive, `exactly-one` arguments

As first demonstrated in _[Encoding multiple exactly-one arguments](#encoding-multiple-exactly-one-arguments)_,
the bytes of the serialized arguments begin immediately after the opcode and (if separate) the macro address.
The reader iterates over the parameters declared in the macro signature from left to right. For each parameter,
the reader uses the parameter's declared encoding to interpret the next bytes in the stream. When no more parameters
remain, parsing is complete.

##### Macro definition
```ion
(:set_macros
  (foo (flex_uint::a int8::b uint16) ...)
)
```

##### Text e-expression
```ion
(:foo 1 2 3)
```

##### Binary e-expression with the address in the opcode
```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌─── Argument 'a': FlexUInt 1
│  │  ┌─── Argument 'b': 1-byte FixedInt 2
│  │  │    ┌─── Argument 'c': 2-byte FixedUInt 3
│  │  │  ┌─┴─┐
00 03 02 03 00
```

##### Binary e-expression using a trailing `FlexUInt` address
```
┌──── Opcode F4: An e-expression with a trailing FlexUInt address
│  ┌──── FlexUInt 0: Macro address 0
│  │  ┌─── Argument 'a': FlexUInt 1
│  │  │  ┌─── Argument 'b': 1-byte FixedInt 2
│  │  │  │    ┌─── Argument 'c': 2-byte FixedUInt 3
│  │  │  │  ┌─┴─┐
F4 01 03 02 03 00
```

#### Macro shapes

The term _macro shape_ describes a macro that is being used as the encoding of an E-expression argument.
A parameter using a macro shape as its encoding is sometimes called a _macro-shaped parameter_. For example,
consider the following two macro definitions.

The `point2D` macro takes two `flex_int`-encoded values as arguments.
```ion
(macro point2D (flex_int::$x flex_int::$y)
  {
    x: $x,
    y: $y,
  }
)
```

The `line` macro takes a pair of `point2D` invocations as arguments.
```ion
(macro line (point2D::$start point2D::$end)
  {
    start: $start,
    end: $end,
  }
)
```

Normally an e-expression would begin with an opcode and an address communicating what comes next.
However, when we're reading the argument for a macro-shaped parameter, the macro being invoked
is inferred from the parent macro signature instead. As such, there is no need to include an
opcode or address.

```
┌──── Opcode 0x01 is less than 0x40; this is an e-expression
│     invoking the macro at address 1: `line`
│    ┌─── Argument $start: an implicit invocation of macro `point2D`
│    │     ┌─── Argument $end: an implicit invocation of macro `point2D`
│  ┌─┴─┐ ┌─┴─┐
00 03 05 07 09
   │  │  │  └────   $end/$y: FlexInt 4
   │  │  └───────   $end/$x: FlexInt 3
   │  └────────── $start/$y: FlexInt 2
   └───────────── $start/$x: FlexInt 1
```

Any macro can be used as a macro shape except for _constants_--macros which take zero parameters.
Constants cannot be used as a macro shape because their serialized representation would be empty,
making it impossible to encode them in [expression groups](#expression-groups). However, this
limitation not sacrifice any expressiveness; the desired constant can always be invoked directly
in the body of the macro.

```ion
(:add_macros
    (pi () 3.14159265) // A constant `pi`

    (circle_area (pi::Pi radius) (multiply Pi radius radius))
    //            └── ERROR: cannot use a constant as a macro shape

    (circle_area (radius) (multiply (.pi) radius radius))
    //   OK: invokes `pi` as needed ──┘
)
```

### Encoding variadic arguments

The preceding sections have described how to (de)serialize the various parameter encodings,
but these parameters have always had the same [cardinality](../macros/defining_macros.md#parameter-cardinalities):
`exactly-one`.

This section explains how to encode e-expressions invoking a macro whose signature contains
_variadic parameters_--parameters with a cardinality of `zero-or-one`, `zero-or-more`, or `one-or-more`.

#### Argument Encoding Bitmap (AEB)

If a macro signature has one or more variadic parameters, then e-expressions invoking that macro will include an additional
construct: the _Argument Encoding Bitmap (AEB)_. This is a little-endian byte sequence precedes the first serialized argument
and indicates how each argument corresponding to a variadic parameter has been encoded.

Each variadic parameter in the signature is assigned two bits in the AEB. This means that the reader can statically determine
how many AEB bytes to expect in the e-expression by examining the signature.

| Number of variadic parameters | AEB byte length |
|:-----------------------------:|:---------------:|
|               0               |        0        |
|            1 to 4             |        1        |
|            5 to 8             |        2        |
|            9 to 12            |        3        |
|              `N`              | `ceiling(N/4)`  |

Bits in the AEB are assigned from least significant to most significant and correspond to the variadic parameters in the signature
from left to right. This allows the reader to right-shift away the bits of each variadic parameter when its corresponding argument
has been read.

| Example Signature     | AEB Layout                  |
|-----------------------|-----------------------------|
| `()`                  | _&lt;No variadics, no AEB>_ |
| `(a b c)`             | _&lt;No variadics, no AEB>_ |
| `(a b c?)`            | `0b------cc`                |
| `(a b* c?)`           | `0b----ccbb`                |
| `(a+ b* c?)`          | `0b--ccbbaa`                |
| `(a+ b c?)`           | `0b----ccaa`                |
| `(a+ b* c? d*)`       | `0bddccbbaa`                |
| `(a+ b* c? d* e)`     | `0bddccbbaa`                |
| `(a+ b* c? d* e f?)`  | `0bddccbbaa 0b------ff`     |
| `(a+ b* c? d* e+ f?)` | `0bddccbbaa 0b----ffee`     |

Each pair of bits in the AEB indicates what kind of expression to expect in the corresponding argument position.

| Bit sequence | Meaning                                                                                                                           |
|:------------:|:----------------------------------------------------------------------------------------------------------------------------------|
|     `00`     | An **[empty expression group](#empty-groups)**. No bytes are present in the corresponding argument position.                      |
|     `01`     | A **single expression** of the declared encoding is present in the corresponding argument position.                               |
|     `10`     | A **[populated expression group](#populated-groups)** of the declared encoding is present in the corresponding argument position. |
|     `11`     | _Reserved_. A bitmap entry with this bit sequence is illegal in Ion 1.1.                                                          |

#### Expression groups

##### Empty groups

If a parameter has a cardinality of `zero-or-one` or `zero-or-more`, callers can choose to pass an
empty expression group as the corresponding argument. This is done by setting the bit sequence `00`
in the appropriate position in the [Argument Encoding Bitmap](#argument-encoding-bitmap-aeb).

##### Populated groups

If a parameter has a cardinality of `zero-or-more` or `one-or-more`, callers can choose to pass a
populated expression group as the corresponding argument instead of a single expression. This is
done by setting the bit sequence `10` in the appropriate position in the
[Argument Encoding Bitmap](#argument-encoding-bitmap-aeb) and then writing an
[expression sequence](#expression-sequence) in the corresponding argument position to indicate
how many bytes part of this group.

##### Expression sequence

An _expression sequence_ begins with a [`FlexUInt`](primitives/flex_uint.md). If the `FlexUInt`'s value
is:
* **greater than zero**, then it represents the number of bytes used to encode this expression sequence. The reader
  should continue reading expressions of the declared encoding until that number of bytes has been consumed.
* **zero**, then it indicates that this is a delimited expression sequence and the processing varies according to
  whether the declared encoding is tagged or tagless. If the encoding is:
  * a **[tagged](#tagged-encoding)**, then each expression in the group begins with an opcode. The reader
    must consume tagged expressions until it encounters a terminating `END` opcode (`0xF0`).
  * a **[tagless](#tagless-encodings)**, then each expression in the group has no leading opcode; there is no
    way to encode the terminating `END`. Instead, the sequence is broken into 'chunks' that each have a
    `FlexUInt` length prefix. The reader will continue reading chunks until it encounters a length prefix of
    `FlexUInt` `0`, indicating the end of the chunk series. Each chunk in the series must be self-contained;
    an expression of the declared encoding may not be split across multiple chunks.

> [!Note]
> Despite the name, it is possible to encode an empty expression group using this syntax.
> However, doing so will always be significantly less efficient than using the
> [Argument Encoding Bitmap](#argument-encoding-bitmap-aeb).

#### Example encoding of tagged `zero-or-one` with empty group

```ion
(:add_macros
  (foo (a?) ...)
)
```

```ion
(:foo) // `a` is implicitly empty
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa
│  │     a=00, empty expression group
00 00
```

#### Example encoding of tagged `zero-or-one` with single expression
```ion
(:add_macros
  (foo (a?) ...)
)
```

```ion
(:foo 1)
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=01, single expression
│  │    ┌──── Argument 'a': opcode 0x61 indicates a 1-byte int (1)
│  │  ┌─┴─┐
00 01 61 01
```

#### Example encoding of tagged `zero-or-more` with empty group

```ion
(:add_macros
  (foo (a*) ...)
)
```

```ion
(:foo) // `a` is implicitly empty
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=00, empty expression group
│  │
00 00
```

#### Example encoding of tagged `zero-or-more` with single expression
```ion
(:add_macros
  (foo (a*) ...)
)
```

```ion
(:foo 1)
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=01, single expression
│  │    ┌──── Argument 'a': opcode 0x61 indicates a 1-byte int (1)
│  │  ┌─┴─┐
00 01 61 01
```

#### Example encoding of tagged `zero-or-more` with populated group
```ion
(:add_macros
  (foo (a*) ...)
)
```

```ion
(:foo 1 2 3)
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=10, populated expression group
│  │  ┌──── FlexUInt 6: 6-byte expression sequence
│  │  │    ┌──── Opcode 0x61 indicates a 1-byte int (1)
│  │  │    │     ┌──── Opcode 0x61 indicates a 1-byte int (2)
│  │  │    │     │     ┌─── Opcode 0x61 indicates a 1-byte int (3)
│  │  │  ┌─┴─┐ ┌─┴─┐ ┌─┴─┐
00 02 0D 61 01 61 02 61 03
         └───────┬───────┘
      6-byte expression sequence
```

#### Example encoding of tagged `zero-or-more` with delimited group
```ion
(:add_macros
  (foo (a*) ...)
)
```

```ion
(:foo 1 2 3)
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=10, populated expression group
│  │  ┌──── FlexUInt 0: delimited expression sequence
│  │  │    ┌──── Opcode 0x61 indicates a 1-byte int (1)
│  │  │    │     ┌──── Opcode 0x61 indicates a 1-byte int (2)
│  │  │    │     │     ┌─── Opcode 0x61 indicates a 1-byte int (3)
│  │  │    │     │     │   ┌─── Opcode 0xF0 is delimited end
│  │  │  ┌─┴─┐ ┌─┴─┐ ┌─┴─┐ │
00 02 01 61 01 61 02 61 03 F0
         └───────┬───────┘
        expression sequence
```

#### Example encoding of tagged `one-or-more` with single expression
```ion
(:add_macros
  (foo (a+) ...)
)
```

```ion
(:foo 1)
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=01, single expression
│  │  ┌──── Argument 'a': opcode 0x61 indicates a 1-byte int
│  │  │   1
00 01 61 01
```

#### Example encoding of tagged `one-or-more` with populated group
```ion
(:add_macros
  (foo (a+) ...)
)
```

```ion
(:foo 1 2 3)
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=10, populated expression group
│  │  ┌──── FlexUInt 6: 6-byte expression sequence
│  │  │  ┌──── Opcode 0x61 indicates a 1-byte int
│  │  │  │     ┌──── Opcode 0x61 indicates a 1-byte int
│  │  │  │     │     ┌─── Opcode 0x61 indicates a 1-byte int
│  │  │  │   1 │  2  │   3
00 02 0D 61 01 61 02 61 03
         └───────┬───────┘
      6-byte expression sequence
```

#### Example encoding of tagged `one-or-more` with delimited group
```ion
(:add_macros
  (foo (a+) ...)
)
```

```ion
(:foo 1 2 3)
```

```
┌──── Opcode 0x00 is less than 0x40; this is an e-expression
│     invoking the macro at address 0.
│  ┌──── AEB: 0b------aa; a=10, populated expression group
│  │  ┌──── FlexUInt 0: delimited expression sequence
│  │  │  ┌──── Opcode 0x61 indicates a 1-byte int
│  │  │  │     ┌──── Opcode 0x61 indicates a 1-byte int
│  │  │  │     │     ┌─── Opcode 0x61 indicates a 1-byte int
│  │  │  │     │     │      ┌─── Opcode 0xF0 is delimited end
│  │  │  │   1 │  2  │   3  │
00 02 01 61 01 61 02 61 03 F0
         └───────┬───────┘
        expression sequence
```
