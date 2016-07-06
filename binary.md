---
title: The Amazon Ion Binary Encoding
---

# {{ page.title }}

## Value Streams

In the binary format, a [value stream](glossary.html#value_stream) always starts with a
_binary version marker_ (BVM) that specifies the precise Ion version used to
encode the data that follows:

<pre class="textdiagram">
                       7    0 7     0 7     0 7    0
                      +------+-------+-------+------+
binary version marker | 0xE0 | major | minor | 0xEA |
                      +------+-------+-------+------+
</pre>

The four-octet BVM also acts as a "magic cookie" to distinguish Ion binary data
from other formats, including Ion text data. Its first octet (in sequence from
the beginning of the stream) is `0xE0` and its fourth octet is `0xEA`. The
second and third octets contain major and minor version numbers. The only valid
BVM, identifying Ion 1.0, is `0xE0 0x01 0x00 0xEA`.

An Ion value stream starts with a BVM, followed by zero or more _values_ which
contain the actual data. These values are generally referred to as "top-level
values".

<pre class="textdiagram">
              31                      0 
             +-------------------------+
value stream |  binary version marker  |
             +-------------------------+
             :          value          :
             +=========================+
                          ⋮
             +=========================+
             :  binary version marker  :
             +=========================+
             :          value          :
             +=========================+
                          ⋮
</pre>

A value stream can contain other, perhaps different, BVMs interspersed with the
top-level values. Each BVM resets the decoder to the appropriate initial state
for the given version of Ion. This allows the stream to be constructed by
concatenating data from different sources, without requiring transcoding to a
single version of the format.

**Note:** The BVM is _not_ a value and should not be visible to or manipulable
by the user; it is internal data managed by and for the Ion implementation.


## Basic Field Formats

Binary-encoded Ion values are comprised of one or more fields, and the fields
use a small number of basic formats (separate from the Ion types visible to
users).

### UInt and Int Fields

_UInt_ and _Int_ fields represent fixed-length unsigned and signed integer
values. These field formats are always used in some context that clearly
indicates the number of octets in the field.

<pre class="textdiagram">
            7                       0
           +-------------------------+
UInt field |          bits           |
           +-------------------------+
           :          bits           :
           +=========================+
                       ⋮
           +=========================+
           :          bits           :
           +=========================+
            n+7                     n
</pre>

UInts are sequences of octets, interpreted as big-endian.

<pre class="textdiagram">
             7  6                   0
           +---+---------------------+
Int field  |   |      bits           |
           +---+---------------------+
             ^
             |
             +--sign
           +=========================+
           :          bits           :
           +=========================+
                       ⋮
           +=========================+
           :          bits           :
           +=========================+
            n+7                     n
</pre>

Ints are sequences of octets, interpreted as sign-and-magnitude big endian
integers (with the sign on the highest-order bit of the first octet). This
means that the representations of 123456 and -123456 should only differ in
their sign bit. (See http://en.wikipedia.org/wiki/Signed\_number\_representation
for more info.)

### VarUInt and VarInt Fields

_VarUInt_ and _VarInt_ fields represent self-delimiting, variable-length
unsigned and signed integer values. These field formats are always used in a
context that does not indicate the number of octets in the field; the last
octet (and only the last octet) has its high-order bit set to terminate the
field.

<pre class="textdiagram">
                7  6                   0       n+7 n+6                 n
              +===+=====================+     +---+---------------------+
VarUInt field : 0 :         bits        :  …  | 1 |         bits        |
              +===+=====================+     +---+---------------------+
</pre>

VarUInts are a sequence of octets. The high-order bit of the last octet is one,
indicating the end of the sequence. All other high-order bits must be zero.

<pre class="textdiagram">
               7   6  5               0       n+7 n+6                 n
             +===+                           +---+
VarInt field : 0 :       payload          …  | 1 |       payload
             +===+                           +---+
                 +---+-----------------+         +=====================+
                 |   |   magnitude     |  …      :       magnitude     :
                 +---+-----------------+         +=====================+
               ^   ^                           ^
               |   |                           |
               |   +--sign                     +--end flag
               +--end flag
</pre>

VarInts are sign-and-magnitude integers, like Ints. Their layout is
complicated, as there is one special leading bit (the sign) and one special
trailing bit (the terminator). In the above diagram, we put the two concepts on
different layers.

The high-order bit in the top layer is an end-of-sequence marker. It must be
set on the last octet in the representation and clear in all other octets. The
second-highest order bit (0x40) is a sign flag in the first octet of the
representation, but part of the extension bits for all other octets. For
single-octet VarInt values, this collapses down to:

<pre class="textdiagram">
                            7   6  5           0
                          +---+---+-------------+
single octet VarInt field | 1 |   |  magnitude  |
                          +---+---+-------------+
                                ^
                                |
                                +--sign
</pre>

## Typed Value Formats

A _value_ consists of a one-octet type descriptor, possibly followed by a
length in octets, possibly followed by a representation.

<pre class="textdiagram">
       7       4 3       0
      +---------+---------+
value |    T    |    L    |
      +---------+---------+======+
      :     length [VarUInt]     :
      +==========================+
      :      representation      :
      +==========================+
</pre>

The type descriptor octet has two subfields: a four-bit type code _T_, and a
four-bit length _L_.

Each value of _T_ identifies the format of the representation, and generally
(though not always) identifies an Ion datatype. Each type code _T_ defines the
semantics of its length field _L_ as described below.

The length value -- the number of octets in the _representation_ field(s) -- is
encoded in _L_ and/or _length_ fields, depending on the magnitude and on some
particulars of the actual type. The _length_ field is empty (taking up no
octets in the message) if we can store the length value inside _L_ itself. If
the _length_ field is not empty, then it is a single VarUInt field. The
representation may also be empty (no octets) in some cases, as detailed below.

Unless otherwise defined, the length of the representation is encoded as
follows:

  * If the value is null (for that type), then _L_ is set to 15.
  * If the representation is less than 14 bytes long, then _L_ is set to the
    length, and the length field is omitted.
  * If the representation is at least 14 bytes long, then _L_ is set to 14, and
    the length field is set to the representation length, encoded as a VarUInt
    field.


### 0: null

<pre class="textdiagram">
            7       4 3       0
           +---------+---------+
Null value |    0    |    15   |
           +---------+---------+
</pre>

Values of type `null` always have empty lengths and representations. The only
valid _L_ value is 15, representing the only value of this type, `null.null`.

#### NOP Padding {#nop-pad}

<pre class="textdiagram">
         7       4 3       0
        +---------+---------+
NOP Pad |    0    |    L    |
        +---------+---------+======+
        :     length [VarUInt]     :
        +--------------------------+
        |      ignored octets      |
        +--------------------------+
</pre>

In addition to `null.null`, the null type code is used to encode padding
that has no operation (NOP padding).  This can be used for "binary whitespace"
when alignment of octet boundaries is needed or to support in-place editing.
Such encodings are not considered values and are ignored by the processor.

In this encoding, _L_ specifies the number of octets that should be ignored.

The following is a single byte NOP pad:

    0x00

The following is a two byte NOP pad:

    0x01 0xFE

Note that the single byte of "payload" `0xFE` is arbitrary and ignored by the
parser.

The following is a 16 byte NOP pad:

    0x0E 0x90 0x00 ... <12 arbitrary octets> ... 0x00

NOP padding is valid anywhere a value can be encoded, except for within an
[annotation](#annotations) wrapper. [NOP padding in `struct`](#nop-pad-struct)
requires additional encoding considerations.

### 1: bool

<pre class="textdiagram">
            7       4 3       0
           +---------+---------+
Bool value |    1    |   rep   |
           +---------+---------+
</pre>

Values of type `bool` always have empty lengths, and their representation is
stored in the typedesc itself (rather than after the typedesc). A
representation of 0 means false; a representation of 1 means true; and a
representation of 15 means `null.bool`.


### 2 and 3: int

Values of type `int` are stored using two type codes: 2 for positive values
and 3 for negative values. Both codes use a UInt subfield to store the magnitude.

<pre class="textdiagram">
           7       4 3       0
          +---------+---------+
Int value |  2 or 3 |    L    |
          +---------+---------+======+
          :     length [VarUInt]     :
          +==========================+
          :     magnitude [UInt]     :
          +==========================+
</pre>

Zero is always stored as positive; negative zero is illegal.

If the value is zero then _T_ must be 2, _L_ is zero, and there are no length or
magnitude subfields. As a result, when _T_ is 3, both _L_ and the magnitude
subfield must be non-zero.

With either type code 2 or 3, if _L_ is 15, then the value is `null.int` and
the magnitude is empty. Note that this implies there are two equivalent
binary representations of null integer values.


### 4: float

<pre class="textdiagram">
              7       4 3       0
            +---------+---------+
Float value |    4    |    L    |
            +---------+---------+-----------+
            |   representation [IEEE-754]   |
            +-------------------------------+
</pre>

Floats are encoded as big endian octets of their IEEE 754 bit patterns.

The _L_ field of floats encodes the size of the IEEE-754 value.

  * If _L_ is 4, then the representation is 32 bits (4 octets).
  * If _L_ is 8, then the representation is 64 bits (8 octets).

There are two exceptions for the _L_ field:

  * If _L_ is 0, then the the value is `0e0` and representation is empty.
    * Note, this is not to be confused with `-0e0` which is a distinct value
      and in current Ion must be encoded as a normal IEEE float bit pattern.
  * If _L_ is 15, then the value is `null.float` and the representation is
    empty.

**Note:** Ion 1.0 only supports 32-bit and 64-bit float values
(_i.e._ _L_ size 4 or 8), but future versions of the standard may support
16-bit and 128-bit float values.


### 5: decimal

<pre class="textdiagram">
               7       4 3       0
              +---------+---------+
Decimal value |    5    |    L    |
              +---------+---------+======+
              :     length [VarUInt]     :
              +--------------------------+
              |    exponent [VarInt]     |
              +--------------------------+
              |    coefficient [Int]     |
              +--------------------------+
</pre>

Decimal representations have two components: _exponent_ (a VarInt) and
_coefficient_ (an Int). The decimal's value is _coefficient_ * 10 ^ _exponent_.

The length of the coefficient subfield is the total length of the representation
minus the length of _exponent_. The subfield should not be present (that is, it
has zero length) when the coefficient's value is (positive) zero.

If the value is `0.` (_aka_ `0d0`) then _L_ is zero, there are no length or
representation fields, and the entire value is encoded as the single byte
`0x50`.


### 6: timestamp


<pre class="textdiagram">
                 7       4 3       0
                +---------+---------+
Timestamp value |    6    |    L    |
                +---------+---------+========+
                :      length [VarUInt]      :
                +----------------------------+
                |      offset [VarInt]       |
                +----------------------------+
                |       year [VarUInt]       |
                +----------------------------+
                :       month [VarUInt]      :
                +============================+
                :         day [VarUInt]      :
                +============================+
                :        hour [VarUInt]      :
                +====                    ====+
                :      minute [VarUInt]      :
                +============================+
                :      second [VarUInt]      :
                +============================+
                : fraction_exponent [VarInt] :
                +====                    ====+
                : fraction_coefficient [Int] :
                +============================+
</pre>


Timestamp representations have 7 components, where 5 of these components are
optional depending on the precision of the timestamp. The 2 non-optional
components are _offset_ and _year_. The 5 optional components are (from least
precise to most precise): _month_, _day_, _hour and minute_, _second_,
_fraction\_exponent_ and _fraction\_coefficient_. All of these 7 components are
in Universal Coordinated Time (UTC).

The _offset_ denotes the local-offset portion of the timestamp, in minutes
difference from UTC.

The _hour and minute_ is considered as a single component, that is, it is
illegal to have _hour_ but not _minute_ (and vice versa). The
_fraction\_exponent_ and _fraction\_coefficient_ is also considered as a single
component.

The _fraction\_exponent_ and _fraction\_coefficient_ denotes the fractional
seconds of the timestamp as a decimal value. The fractional seconds' value is
_coefficient_ * 10 ^ _exponent_, and it must be greater than zero and less than
1.

If a timestamp representation has a component of a certain precision, each of
the less precise components must also be present or else the representation is
illegal. For example, a timestamp representation that has a
_fraction\_exponent_ and _fraction\_coefficient_ component but not the _month_
component, is illegal.

**Note:** The component values in the binary encoding are always in UTC, while
components in the text encoding are in the local time! This means that
transcoding requires a conversion between UTC and local time.


### 7: symbol

<pre class="textdiagram">
              7       4 3       0
             +---------+---------+
Symbol value |    7    |    L    |
             +---------+---------+======+
             :     length [VarUInt]     :
             +--------------------------+
             |     symbol ID [UInt]     |
             +--------------------------+
</pre>

In the binary encoding, all Ion symbols are stored as integer _symbol IDs_
whose text values are provided by a symbol table.  If L is zero then the
symbol ID is zero and the length and symbol ID fields are omitted.

See [Ion Symbols](symbols.html) for more details about symbol representations
and symbol tables.


### 8: string

<pre class="textdiagram">
              7       4 3       0
             +---------+---------+
String value |    8    |    L    |
             +---------+---------+======+
             :     length [VarUInt]     :
             +==========================+
             :  representation [UTF8]   :
             +==========================+
</pre>

These are always sequences of Unicode characters, encoded as a sequence of
UTF-8 octets.


### 9: clob

<pre class="textdiagram">
            7       4 3       0
           +---------+---------+
Clob value |    9    |    L    |
           +---------+---------+======+
           :     length [VarUInt]     :
           +==========================+
           :       data [Bytes]       :
           +==========================+
</pre>

Values of type `clob` are encoded as a sequence of octets that should be
interpreted as text with an unknown encoding (and thus opaque to the
application).

Zero-length clobs are legal, so _L_ may be zero.


### 10: blob

<pre class="textdiagram">
            7       4 3       0
           +---------+---------+
Blob value |   10    |    L    |
           +---------+---------+======+
           :     length [VarUInt]     :
           +==========================+
           :       data [Bytes]       :
           +==========================+
</pre>

This is a sequence of octets with no interpretation (and thus opaque to the
application).

Zero-length blobs are legal, so _L_ may be zero.


### 11: list

<pre class="textdiagram">
            7       4 3       0
           +---------+---------+
List value |   11    |    L    |
           +---------+---------+======+
           :     length [VarUInt]     :
           +==========================+
           :           value          :
           +==========================+
                         ⋮
</pre>

The representation fields of a `list` value are simply nested Ion values.

When _L_ is 15, the value is `null.list` and there's no length or nested
values. When _L_ is 0, the value is an empty list, and there's no length or
nested values.

Because values indicate their total lengths in octets, it is possible to locate
the beginning of each successive value in constant time.


### 12: sexp

<pre class="textdiagram">
            7       4 3       0
           +---------+---------+
Sexp value |   12    |    L    |
           +---------+---------+======+
           :     length [VarUInt]     :
           +==========================+
           :           value          :
           +==========================+
                         ⋮
</pre>

Values of type `sexp` are encoded exactly as are `list` values, except with a
different type code.


### 13: struct

Structs are encoded as sequences of symbol/value pairs. Since all symbols are
encoded as positive integers, we can omit the typedesc on the field names and
just encode the integer value.

<pre class="textdiagram">
              7       4 3       0
             +---------+---------+
Struct value |   13    |    L    |
             +---------+---------+======+
             :     length [VarUInt]     :
             +======================+===+==================+
             : field name [VarUInt] :        value         :
             +======================+======================+
                         ⋮                     ⋮
</pre>

Binary-encoded structs support a special case where the fields are known to be
sorted such that the field-name integers are increasing. This state exists when
_L_ is one. Thus:

  * When _L_ is 0, the value is an empty struct, and there's no _length_ or
    nested fields.
  * When _L_ is 1, the struct has at least one symbol/value pair, the _length_
    field exists, and the field name integers are sorted in increasing order.
  * When _L_ is 15, the value is `null.struct`, and there's no _length_ or
    nested fields.
  * Otherwise, the _length_ field exists, and no assertion is made about field
    ordering.

**Note:** Because VarUInts depend on end tags to indicate their lengths,
finding the succeeding value requires parsing the field name prefix. However,
VarUInts are a more compact representation than Int values.

<a id="nop-pad-struct"></a>

#### NOP Padding in `struct` Fields
[NOP Padding](#nop-pad) in `struct` values requires additional consideration
of the field name element.  If the "value" of a `struct` field is the
[NOP pad](#nop-pad), then the field name is ignored. This means that it
is not possible to encode padding in a `struct` value that is less than
two bytes.

Implementations should use symbol ID zero as the field name
to emphasize the lack of meaning of the field name. For more general details
about the semantics of symbol ID zero, refer to [Ion Symbols](symbols.html).

For example, consider the following empty `struct` with three bytes of
padding:

    0xD3 0x80 0x01 0xAC

In the above example, the struct declares that it is three bytes large, and
the encoding of the pair of symbol ID zero followed by a pad that is two bytes
large (note the last octet `0xAC` is completely arbitrary and never
interpreted by an implementation).

The following is an example of struct with a single field with four total
bytes of padding:

    0xD7 0x84 0x81 "a" 0x80 0x02 0x01 0x02

The above is equivalent to `{name:"a"}`.

The following is also a empty struct, with a two byte pad:

    0xD2 0x8F 0x00

In the above example, the field name of symbol ID 15 is ignored (regardless
of if it is a valid symbol ID).

The following is malformed because there is an annotation "wrapping"
a NOP pad, which is not allowed generally for annotations:

    // {$0:name::<NOP>}
    0xD5 0x80 0xE3 0x81 0x84 0x00

### 14: Annotations {#annotations}

This special type code doesn't map to an Ion value type, but instead is a
wrapper used to associate annotations with content.

_Annotations_ are a special type that wrap content identified by the other type
codes. The annotations themselves are encoded as integer symbol ids.

<pre class="textdiagram">
                    7       4 3       0
                   +---------+---------+
Annotation wrapper |   14    |    L    |
                   +---------+---------+======+
                   :     length [VarUInt]     :
                   +--------------------------+
                   |  annot_length [VarUInt]  |
                   +--------------------------+
                   |      annot [VarUInt]     |  …
                   +--------------------------+
                   |          value           |
                   +--------------------------+
</pre>

The length field _L_ field indicates the length from the beginning of the
_annot\_length_ field to the end of the enclosed value. Because at least one
annotation and exactly one content field must exist, _L_ is at least 3 and is
never 15.

The _annot\_length_ field contains the length of the (one or more) _annot_
fields.

It is illegal for an annotation to wrap another annotation atomically, _i.e._,
_annotation(annotation(value))_. However, it is legal to have an annotation on
a container that holds annotated values. Note that it is possible to enforce
the illegality of _annotation(annotation(value))_ directly in a grammar, but we
have not chosen to do that in this document.

Furthermore, it is illegal for an annotation to wrap a [NOP Pad](#nop-pad)
since this encoding is not an Ion value.  Thus, the following sequence is
malformed:
  
    0xE3 0x81 0x84 0x00

**Note:** Because _L_ cannot be zero, the octet `0xE0` is not a valid type
descriptor. Instead, that octet signals the start of a binary version marker.


### 15: reserved

The remaining type code, 15, is reserved for future use and is not legal in Ion
1.0 data.

### Illegal Type Descriptors

The preceding sections define valid type descriptor octets, composed of a type
code (_T_) in the upper four bits and a length field (_L_) in the lower four bits.
As mentioned, many possible combinations are illegal and
*must cause parsing errors*.

The following table enumerates the illegal type descriptors in Ion 1.0 data.

<table style="width: 100%">
<thead>
<tr class="header">
<th align="left" style="width: 5%">T</th>
<th align="left" style="width: 15%">L</th>
<th align="left" style="width: 80%">Reason</th>
</tr>
</thead>
<tbody>
</tr>
<tr class="even">
<td align="left">1</td>
<td align="left">[3-14]</td>
<td align="left">
For <code>bool</code> values, <i>L</i> is used to encode the value, and may be
0 (<code>false</code>), 1 (<code>true</code>), or 15 (<code>null.bool</code>).
</td>
</tr>
<tr class="odd">
<td align="left">3</td>
<td align="left">[0]</td>
<td align="left">
The <code>int</code> 0 is always stored with type code 2. Thus,
type code 3 with <i>L</i> equal to zero is illegal.
</td>
</tr>
<tr class="even">
<td align="left">4</td>
<td align="left">[1-3],[5-7],[9-14]</td>
<td align="left">
For <code>float</code> values, only 32-bit and 64-bit IEEE-754 values are
supported. Additionally, <code>0e0</code> and <code>null.float</code> are
represented with <i>L</i> equal to 0 and 15, respectively.
</td>
</tr>
<tr class="odd">
<td align="left">14</td>
<td align="left">[0]*,[1-2],[15]</td>
<td align="left">
Annotation wrappers must have one <i>annot_length</i> field, at least one
<i>annot</i> field, and exactly one <i>value</i> field. Null annotation wrappers
are illegal.<p>
*Note: Since <code>0xE0</code> signals the start of the BVM, encountering this
octet where a type descriptor is expected should <i>only</i> cause parsing
errors when it is not followed by the rest of the BVM octet sequence.
</td>
</tr>
<tr class="even">
<td align="left">15</td>
<td align="left">[0-15]</td>
<td align="left">
The type code 15 is illegal in Ion 1.0 data.
</td>
</tr>
</tbody>
</table>
