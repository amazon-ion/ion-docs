## Timestamps

Timestamps have two encodings:

1. [**Short-form timestamps**](#short-form-timestamps), a compact representation optimized for the most commonly used precisions and date ranges.
2. [**Long-form timestamps**](#long-form-timestamps), a less compact representation capable of representing any timestamp in the Ion data model.

`0xEB x04` represents `null.timestamp`.

##### Encoding of `null.timestamp`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: timestamp
│  │
EB 04
```

> [!NOTE]
> In Ion 1.0, text timestamp fields were encoded using the local time while binary timestamp fields were encoded
> using UTC time. This required applications to perform conversion logic when transcribing from one format to the other.
> *In Ion 1.1, all binary timestamp fields are encoded in local time.*


### Short-form Timestamps

If an opcode has a high nibble of `0x8_`, it represents a short-form timestamp. This encoding focuses on making the
most common timestamp precisions and ranges the most compact; less common precisions can still be expressed via
the variable-length [long form timestamp](#long-form-timestamps) encoding.

Timestamps may be encoded using the short form if they meet all of the following conditions:

The year is between 1970 and 2097.:: The year subfield is encoded as the number of years since 1970. 7 bits are
dedicated to representing the biased year, allowing timestamps through the year 2097 to be encoded in this form.
The local offset is either UTC, unknown, or falls between `-14:00` to `+14:00` and is divisible by 15 minutes.
7 bits are dedicated to representing the local offset as the number of quarter hours from -56 (that is: offset `-14:00`).
The value `0b1111111` indicates an unknown offset. At the time of this writing (2024-08T),
[all real-world offsets fall between `-12:00` and `+14:00` and are multiples of 15 minutes](https://en.wikipedia.org/wiki/List_of_UTC_offsets).
The fractional seconds are a common precision. The timestamp's fractional second precision (if present) is
either 3 digits (milliseconds), 6 digits (microseconds), or 9 digits (nanoseconds).

#### Opcodes by precision and offset

Each opcode with a high nibble of `0x8_` indicates a different precision and offset encoding pair.

| Opcode | Precision        | Serialized size in bytes[^short_form_size_in_bytes] | Offset encoding                                                |
|--------|------------------|:---------------------------------------------------:|----------------------------------------------------------------|
| `0x80` | Year             |                          1                          | Implicitly _Unknown offset_                                    |
| `0x81` | Month            |                          2                          |                                                                |
| `0x82` | Day              |                          2                          |                                                                |
| `0x83` | Hour and minutes |                          4                          | 1 bit to indicate _UTC_ or _Unknown Offset_                    |
| `0x84` | Seconds          |                          5                          |                                                                |
| `0x85` | Milliseconds     |                          6                          |                                                                |
| `0x86` | Microseconds     |                          7                          |                                                                |
| `0x87` | Nanoseconds      |                          8                          |                                                                |
| `0x88` | Hour and minutes |                          5                          | 7 bits to represent a known offset.[^short_form_hours_minutes] |
| `0x89` | Seconds          |                          5                          |                                                                |
| `0x8A` | Milliseconds     |                          7                          |                                                                |
| `0x8B` | Microseconds     |                          8                          |                                                                |
| `0x8C` | Nanoseconds      |                          9                          |                                                                |
| `0x8D` | _Reserved_       |                         --                          |                                                                |
| `0x8E` | _Reserved_       |                         --                          |                                                                |
| `0x8F` | _Reserved_       |                         --                          |                                                                |

[^short_form_size_in_bytes]: Serialized size in bytes does not include the opcode.

[^short_form_hours_minutes]: This encoding can also represent `UTC and Unknown Offset`, though
it is less compact than opcodes `0x83`-`0x87` above.

The body of a short-form timestamp is encoded as a `FixedUInt` of the size specified by the opcode. This integer is
then partitioned into bit-fields representing the timestamp's subfields. Note that endianness does not apply here because the
bit-fields are defined over the body interpreted as an _integer_.

The following letters to are used to denote bits in each subfield in diagrams that follow. Subfields occur in the same
order in all encoding variants, and consume the same number of bits, with the exception of the fractional bits, which
consume only enough bits to represent the fractional precision supported by the opcode being used.

The `Month` and `Day` subfields are one-based; `0` is not a valid month or day.

| Letter code |        Number of bits         | Subfield                          |
|:-----------:|:-----------------------------:|-----------------------------------|
|     `Y`     |               7               | Year                              |
|     `M`     |               4               | Month                             |
|     `D`     |               5               | Day                               |
|     `H`     |               5               | Hour                              |
|     `m`     |               6               | Minute                            |
|     `o`     |               7               | Offset                            |
|     `U`     |               1               | Unknown (`0`) or UTC (`1`) offset |
|     `s`     |               6               | Second                            |
|     `f`     | 10 (ms)<br>20 (μs)<br>30 (ns) | Fractional second                 |
|     `.`     |              n/a              | Unused                            |

We will denote the timestamp encoding as follows with each byte ordered vertically from top to bottom. The
respective bits are denoted using the letter codes defined in the table above.

```
          7       0 <--- bit position
          |       |
         +=========+
byte 0   |  0xNN   | <-- hex notation for constants like opcodes
         +=========+ <-- boundary between encoding primitives (e.g., opcode/`FlexUInt`)
     1   |nnnn:nnnn| <-- bits denoted with a `:` as a delimeter to aid in reading
         +---------+ <-- octet boundary within an encoding primitive
         ...
         +---------+
     N   |nnnn:nnnn|
         +=========+
```

The bytes are read from top to bottom (least significant to most significant), while the bits within each byte should be
read from right to left (also least significant to most significant.)

> [!NOTE]
> While this encoding may complicate human reading, it guarantees that the timestamp's subfields (`year`, `month`,
> etc.) occupy the same bit contiguous indexes regardless of how many bytes there are overall. (The last subfield,
> `fractional_seconds`, always begins at the same bit index when present, but can vary in length according to the
> precision.) This arrangement allows processors to read the Little-Endian bytes into an integer and then mask the
> appropriate bit ranges to access the subfields.

#### Encoding of a timestamp with year precision
```
         +=========+
byte 0   |  0x80   |
         +=========+
     1   |.YYY:YYYY|
         +=========+
```

#### Encoding of a timestamp with month precision
```
         +=========+
byte 0   |  0x81   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |....:.MMM|
         +=========+
```

#### Encoding of a timestamp with day precision
```
         +=========+
byte 0   |  0x82   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +=========+
```

#### Encoding of a timestamp with hour-and-minutes precision at UTC or unknown offset
```
         +=========+
byte 0   |  0x83   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |....:Ummm|
         +=========+
```

#### Encoding of a timestamp with seconds precision at UTC or unknown offset
```
         +=========+
byte 0   |  0x84   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |ssss:Ummm|
         +---------+
     5   |....:..ss|
         +=========+
```

#### Encoding of a timestamp with milliseconds precision at UTC or unknown offset
```
         +=========+
byte 0   |  0x85   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |ssss:Ummm|
         +---------+
     5   |ffff:ffss|
         +---------+
     6   |....:ffff|
         +=========+
```

#### Encoding of a timestamp with microseconds precision at UTC or unknown offset
```
         +=========+
byte 0   |  0x86   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |ssss:Ummm|
         +---------+
     5   |ffff:ffss|
         +---------+
     6   |ffff:ffff|
         +---------+
     7   |..ff:ffff|
         +=========+
```

#### Encoding of a timestamp with nanoseconds precision at UTC or unknown offset
```
         +=========+
byte 0   |  0x87   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |ssss:Ummm|
         +---------+
     5   |ffff:ffss|
         +---------+
     6   |ffff:ffff|
         +---------+
     7   |ffff:ffff|
         +---------+
     8   |ffff:ffff|
         +=========+
```

#### Encoding of a timestamp with hour-and-minutes precision at known offset
```
         +=========+
byte 0   |  0x88   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |oooo:ommm|
         +---------+
     5   |....:..oo|
         +=========+
```

#### Encoding of a timestamp with seconds precision at known offset
```
         +=========+
byte 0   |  0x89   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |oooo:ommm|
         +---------+
     5   |ssss:ssoo|
         +=========+
```

#### Encoding of a timestamp with milliseconds precision at known offset
```
         +=========+
byte 0   |  0x8A   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |oooo:ommm|
         +---------+
     5   |ssss:ssoo|
         +---------+
     6   |ffff:ffff|
         +---------+
     7   |....:..ff|
         +=========+
```

#### Encoding of a timestamp with microseconds precision at known offset
```
         +=========+
byte 0   |  0x8B   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |oooo:ommm|
         +---------+
     5   |ssss:ssoo|
         +---------+
     6   |ffff:ffff|
         +---------+
     7   |ffff:ffff|
         +---------+
     8   |....:ffff|
         +=========+
```

#### Encoding of a timestamp with nanoseconds precision at known offset
```
         +=========+
byte 0   |  0x8C   |
         +=========+
     1   |MYYY:YYYY|
         +---------+
     2   |DDDD:DMMM|
         +---------+
     3   |mmmH:HHHH|
         +---------+
     4   |oooo:ommm|
         +---------+
     5   |ssss:ssoo|
         +---------+
     6   |ffff:ffff|
         +---------+
     7   |ffff:ffff|
         +---------+
     8   |ffff:ffff|
         +---------+
     9   |..ff:ffff|
         +=========+
```

#### Examples of short-form timestamps

| Text                                | Binary                          |
|-------------------------------------|---------------------------------|
| 2023T                               | `80 35`                         |
| 2023-10-15T                         | `82 35 7D`                      |
| 2023-10-15T11:22:33Z                | `84 35 7D CB 1A 02`             |
| 2023-10-15T11:22:33-00:00           | `84 35 7D CB 12 02`             |
| 2023-10-15T11:22:33+01:15           | `89 35 7D CB 2A 84`             |
| 2023-10-15T11:22:33.444555666+01:15 | `8C 35 7D CB 2A 84 92 61 7F 1A` |


> [!WARNING]
> Opcodes `0x8D`, `0x8E`, and `0x8F` are illegal; they are reserved for future use.


### Long-form Timestamps

Unlike the [short-form timestamp encoding](#short-form-timestamps), which is limited to encoding
timestamps in the most commonly referenced timestamp ranges and precisions for which it optimizes,
the long-form timestamp encoding is capable of representing any valid timestamp.

The long form begins with opcode `0xF8`. A [`FlexUInt`](../primitives/flex_uint.md) follows indicating the number
of bytes that were needed to represent the timestamp. The encoding consumes the minimum number
of bytes required to represent the timestamp. The declared length can be mapped to the timestamp’s
precision as follows:

| Length    | Corresponding precision                                                 |
|-----------|-------------------------------------------------------------------------|
| 0         | _Illegal_                                                               |
| 1         | _Illegal_                                                               |
| 2         | Year                                                                    |
| 3         | Month or Day (see below)                                                |
| 4         | _Illegal; the hour cannot be specified without also specifying minutes_ |
| 5         | _Illegal_                                                               |
| 6         | Minutes                                                                 |
| 7         | Seconds                                                                 |
| 8 or more | Fractional seconds                                                      |

Unlike the short-form encoding, the long-form encoding reserves:

* *14 bits for the year (`Y`)*, which is not biased.
* *12 bits for the offset*, which counts the number of minutes (not quarter-hours) from -1440
(that is: `-24:00`). An offset value of `0b111111111111` indicates an unknown offset.

Similar to short-form timestamps, with the exception of representing the fractional seconds, the components of the
timestamp are encoded as bit-fields on a [`FixedUInt`](../primitives/fixed_uint.md) that corresponds to the length that followed the opcode.

If the timestamp's overall length is greater than or equal to `8`, the `FixedUInt` part of the timestamp is `7` bytes
and the remaining bytes are used to encode fractional seconds. The fractional seconds are encoded as a
`(scale, coefficient)` pair, which is _similar_ to a [decimal](decimal.md). The primary difference is that the *scale*
represents a negative *exponent* because it is illegal for the fractional seconds value to be greater than or equal to
`1.0` or less than `0.0`. The scale is encoded as a `FlexUInt` (instead of `FlexInt`) to discourage the
encoding of decimal numbers greater than `1.0`. The coefficient is encoded as a `FixedUInt` (instead of `FixedInt`) to
prevent the encoding of fractional seconds less than `0.0`. Note that validation is still required; namely:

* A scale value of `0` is illegal, as that would result in a fractional seconds greater than `1.0` (a whole second).
* If `coefficient * 10^-scale > 1.0`, that `(coefficient, scale)` pair is illegal.

If the timestamp's length is `3`, the precision is determined by inspecting the day (`DDDDD`) bits. Like the short-form,
the `Month` and `Day` subfields are one-based (`0` is not a valid month or day). If the day subfield is zero, that
indicates month precision. If the day subfield is any non-zero number, that indicates day precision.

#### Encoding of the _body_ of a long-form timestamp
```
         +=========+
byte 0   |YYYY:YYYY|
         +=========+
     1   |MMYY:YYYY|
         +---------+
     2   |HDDD:DDMM|
         +---------+
     3   |mmmm:HHHH|
         +---------+
     4   |oooo:oomm|
         +---------+
     5   |ssoo:oooo|
         +---------+
     6   |....:ssss|
         +=========+
     7   |FlexUInt | <-- scale of the fractional seconds
         +---------+
         ...
         +=========+
     N   |FixedUInt| <-- coefficient of the fractional seconds
         +---------+
         ...
```

#### Examples of long-form timestamps

| Text                          | Binary                             |
|-------------------------------|------------------------------------|
| 1947T                         | `F8 05 9B 07`                      |
| 1947-12T                      | `F8 07 9B 07 03`                   |
| 1947-12-23T                   | `F8 07 9B 07 5F`                   |
| 1947-12-23T11:22:33-00:00     | `F8 0F 9B 07 DF 65 FD 7F 08`       |
| 1947-12-23T11:22:33+01:15     | `F8 0F 9B 07 DF 65 AD 57 08`       |
| 1947-12-23T11:22:33.127+01:15 | `F8 13 9B 07 DF 65 AD 57 08 07 7F` |
