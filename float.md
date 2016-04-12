---
layout: default
title: Amazon Ion Floats
---

# Amazon Ion Floats
Amazon Ion supports IEEE-754 binary floating point values using the IEEE-754
32-bit (`binary32`) and 64-bit (`binary64`) encodings.
In the data model, all floating point values are treated as though they are
`binary64` (all `binary32` encoded values can be represented exactly in `binary64`).

## Ion Text and Binary Considerations
In text, binary float is represented using familiar base-10 digits.  While
this is convenient for human representation, there is no explicit notation
for expressing a particular floating point value as `binary32` or `binary64`.
Furthermore, many base-10 real numbers are irrational with respect to base-2 and
cannot be expressed exactly in either binary floating point encoding
(e.g. `1.1e0`).

Because of this asymmetry, the rules for Ion text float notation when 
round-tripping to Ion binary MUST be observed:

* Any text notation that can be exactly represented as `binary32` MAY be
  encoded as either `binary32` or `binary64` in Ion binary.
* Any text notation that can only be exactly represented as `binary64` MUST
  be encoded as `binary64` in Ion binary.
* Any text notation that has no exact representation (i.e. irrational in base-2
  or more precision than the `binary64` mantissa), MUST be encoded as `binary64`.
  This is to ensure that irrational numbers or truncated values
  are represented in the highest fidelity of the `float` data type.

When encoding a decimal real number that is irrational in base-2 or has
more precision than can be stored in `binary64`, the exact `binary64`
value is determined by using the IEEE-754 *round-to-nearest* mode with
a *round-half-to-even* as the tie-break.  This mode/tie-break is the
common default used in most programming environments and is discussed in detail
in ["Correctly Rounded Binary-Decimal and Decimal-Binary Conversions"][1].
This conversion algorithm is illustrated in a straightforward way in [Clinger's Algorithm][2].

When encoding a `binary32` or `binary64` value in text notation, an
implementation MAY want to consider the approach described in
["Printing Floating-Point Numbers Quickly and Accurately"][3].


[1]: http://ampl.com/REFS/rounding.pdf
[2]: http://www.cesura17.net/~will/professional/research/papers/howtoread.pdf
[3]: http://www.cs.indiana.edu/~dyb/pubs/FP-Printing-PLDI96.pdf


### Special Values
The IEEE-754 binary floating point encoding supports special *non-number*
values.  These are represented in the binary format as per the encoding rules
of the IEEE-754 specification, and are represented in text by the following
keywords:

  * `nan` denotes the *not a number* (NaN) value.
  * `+inf` denotes *positive infinity*.
  * `-inf` denotes *negative infinity*.

The Ion data model considers all encodings of *positive infinity* to be equivalent
to one another and all encodings of *negative infinity* to be equivalent to one
another.  Thus, an implementation encoding `+inf` or `-inf` in Ion binary
MAY choose to encode it using the `binary32` or `binary64` form.

The IEEE-754 specification has many encodings of NaN, but the Ion data model
considers all encodings of NaN (i.e. all forms of *signaling* or *quiet* NaN)
to be equivalent.  Note that the text keyword `nan` does not map to any
particular encoding, the only requirement is that an implementation emit
a bit-pattern that represents an IEEE-754 NaN value when converting to binary
(e.g. the `binary64` bit pattern of `0x7FF8000000000000`).

An important consideration is that NaN is not treated in a consistent
manner between programming environments.  For example, Java defines that there
is only one canonical NaN value and it happens to be *signaling*.  On C/C++,
on the other hand, NaN is mostly platform defined, but on platforms that support
it, the `NAN` macro is a *quiet* NaN.  In general, common programming
environments give testing routines for NaN, but no consistent way to represent
it.

## Examples
To illustrate the text/binary round-tripping rules above, consider the
following examples.

The Ion text literal `2.147483647e9` overflows the 23-bits of
significand in `binary32` and MUST be encoded in Ion binary
as a `binary64` value. The Ion binary encoding for this text literal is as
follows:

    0x48 0x41 0xDF 0xFF 0xFF 0xFF 0xC0 0x00 0x00

The base-2 irrational literal `1.2e0` following the rounding and encoding
rules MUST be encoded in Ion binary as:

    0x48 0x3F 0xF3 0x33 0x33 0x33 0x33 0x33 0x33
    
Although the textual representative of `1.2e0` itself is irrational, its
canonical form in the data model is not (based on the rounding rules), thus
the following text forms all map to the same `binary64` value:

    // the most human-friendly representation
    1.2e0
    
    // the exact textual representation in base-10 for the binary64 value 1.2e0 represents
    1.1999999999999999555910790149937383830547332763671875e0
      
    // a shortened, irrational version, but still the same value
    1.1999999999999999e0
    
    // a lengthened, irrational version that is still the same value
    1.19999999999999999999999999999999999999999999999999999999e0
