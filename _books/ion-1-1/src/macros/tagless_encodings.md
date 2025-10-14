# Tagless Encodings

Tagless encodings may be specified by encoding tags in template placeholders and in tagless-element sequences. In binary,
this allows the opcode to be elided from the encoding of values that fill tagless slots.

Consider the following data:
```ion
[
  { sum: 123, sample_count: 12 },
  { sum: 54, sample_count: 8 },
  { sum: 125, sample_count: 15 },
  { sum: 314, sample_count: 30 },
]
```
With a macro such as `(metric {sum: (:? {#int}), sample_count: (:? {#int}), unit: ms})`, it can be encoded
using a tagless-element list as follows
```ion
[{:metric} // {:<macro_name>} specifies a macro-shape
  (123 12),
  (54 8),
  (125 15),
  (314 30),
]
```

The available tagless encodings are enumerated in the following table.

| Ion Type    | Encoding Name   | Size in bytes | Binary Encoding Tag | Encoding                                                                        |
|-------------|:----------------|:-------------:|:-------------------:|:--------------------------------------------------------------------------------|
| `int`       | `int`           |   variable    |       `0x60`        | [`FlexInt`][flexint]                                                            |
|             | `int8`          |       1       |       `0x61`        | [`FixedInt`][fixedint]                                                          |
|             | `int16`         |       2       |       `0x62`        | [`FixedInt`][fixedint]                                                          |
|             | `int32`         |       4       |       `0x64`        | [`FixedInt`][fixedint]                                                          |
|             | `int64`         |       8       |       `0x68`        | [`FixedInt`][fixedint]                                                          |
|             | `uint`          |   variable    |       `0xE0`        | [`FlexUInt`][flexuint]                                                          |
|             | `uint8`         |       1       |       `0xE1`        | [`FixedUInt`][fixeduint]                                                        |
|             | `uint16`        |       2       |       `0xE2`        | [`FixedUInt`][fixeduint]                                                        |
|             | `uint32`        |       4       |       `0xE4`        | [`FixedUInt`][fixeduint]                                                        |
|             | `uint64`        |       8       |       `0xE8`        | [`FixedUInt`][fixeduint]                                                        |
| `float`     | `float16`       |       2       |       `0x6B`        | [Little-endian IEEE-754 half-precision float][f16]                              |
|             | `float32`       |       4       |       `0x6C`        | [Little-endian IEEE-754 single-precision float][f32]                            |
|             | `float64`       |       8       |       `0x6D`        | [Little-endian IEEE-754 double-precision float][f64]                            |
| `decimal`   | `small_decimal` | variable (2+) |       `0x70`        | Tuple of (`int`,`int8`) representing the coefficient and exponent respectively. |
| `timestamp` | `timestamp_day` |       2       |       `0x82`        | [Day precision timestamp][t1]                                                   |
|             | `timestamp_min` |       4       |       `0x83`        | [Minute precision timestamp][t2]                                                |
|             | `timestamp_s`   |       5       |       `0x84`        | [Second precision timestamp][t3]                                                |
|             | `timestamp_ms`  |       6       |       `0x85`        | [Millisecond precision timestamp][t4]                                           |
|             | `timestamp_us`  |       7       |       `0x86`        | [Microsecond precision timestamp][t5]                                           |
|             | `timestamp_ns`  |       8       |       `0x87`        | [Nanosecond precision timestamp][t6]                                            |
| `symbol`    | `symbol`        |   variable    |       `0xEE`        | [`FlexSym`][flexsym]                                                            |

Although both primitive and macro-shape encodings may be used in tagless-element sequences, only the primitive encodings in the above table
may be used in tagless template placeholders.
