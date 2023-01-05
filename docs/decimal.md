---
redirect_from: "/decimal.html"
title: Decimals
description: "Amazon Ion supports a decimal numeric type to allow accurate representation of base-10 floating point values such as currency amounts."
---

# [Docs][docs]/ {{ page.title }}

Amazon Ion supports a decimal numeric type to allow accurate representation
of base-10 floating point values such as currency amounts. This
representation preserves significant trailing zeros when converting
between text and binary forms.

Decimals are supported in addition to the traditional base-2 floating point
type (see Ion `float`). This avoids the loss of exactness often incurred when
storing a decimal fraction as a binary fraction. Many common decimal numbers with 
relatively few digits cannot be represented as a terminating binary fraction.

* TOC
{:toc}

### Data Model

Ion decimals follow the [IBM Hursley Lab General Decimal Arithmetic Specification][decarith],
which defines an [abstract decimal data model][damodel] represented by the following
3-tuple.

    (<sign 0|1>, <coefficient: unsigned integer>, <exponent: integer>)

Decimals should be considered equivalent if and only if their data
model tuples are equivalent, where *exponents* of `+0` and `-0` are
considered equivalent. All forms of positive zero are distinguished only
by the *exponent*. All forms of negative zero, which are distinct from all
forms of positive zero, also are distinguished only by the *exponent*.

### Text Format

The Hursley rules for describing a _finite value_ [converting from textual notation][damodel] *must* be followed. 
The Hursley rules for describing a _special value_ are **not** followed--the rules for 

* `infinity`  -- rule is **not** applicable for Ion Decimals.
* `nan`       -- rule is **not** applicable for Ion Decimals

Specifically, the rules for getting the integer *coefficient* from the
*decimal-part* (digits preceding the exponent) of the textual representation
are specified as follows.

> If the <i>decimal-part</i> included a decimal point <b>the <i>exponent</i> is
> then reduced by the count of digits following the decimal point (which may
> be zero) and the decimal point is removed</b>. The remaining string of digits
> has any leading zeros removed (except for the rightmost digit) and is then
> converted to form the <i>coefficient</i> which will be zero or positive.

Where `X` is any unsigned integer, all of the following formulae can be
demonstrated to be equivalent using the text conversion rules and the data
model.

```
// Exponent implicitly zero
X.
// Exponent explicitly zero
Xd0
// Exponent explicitly negative zero (equivalent to zero).
Xd-0
```

Other equivalent representations include the following, where `Y` is the number
of digits in `X`.

```
// There are Y digits past the decimal point in the
// decimal-part, making the exponent zero. One leading zero
// is removed.
0.XdY
```

For example, all of the following text Ion decimal representations are equivalent
to each other.

```
0.
0d0
0d-0
0.0d1
```

Additionally, all of the following are equivalent to each other (but not to
any forms of positive zero).

```
-0.
-0d0
-0d-0
-0.0d1
```

Because all forms of zero are distinctly identified by the *exponent*, the
following are **not** equivalent to each other.

```
// Exponent implicitly zero.
0.
// Exponent explicitly 5.
0d5
```

All of the following are equivalent to each other.

```
42.
42d0
42d-0
4.2d1
0.42d2
```

However, the following are **not** equivalent to each other.

```
// Text converted to 42.
0.42d2
// Text converted to 42.0
0.420d2
```

### Binary Format

The encoding of Ion decimals, which follows the decimal data model
described above, is specified in [the Ion Binary Encoding][binary].

The following binary encodings of decimal values are all equivalent to `0d0`.

<pre class="textdiagram">
+-----------------+------------+-------------+
| type descriptor |  exponent  | coefficient |
|                 |  (VarInt)  |    (Int)    |
+-----------------+------------+-------------+

Most compact encoding of 0d0
+-----------------+
:      0x50       :
+-----------------+

Explicit encoding of 0d0
+-----------------+------------+-------------+
:      0x52       :    0x80    :    0x00     |
+-----------------+------------+-------------+

Explicit encoding of 0d(negative)0
+-----------------+------------+-------------+
:      0x52       :    0xC0    :    0x00     |
+-----------------+------------+-------------+

0d0 with overpadded coefficient
+-----------------+------------+-------------+
:      0x53       :    0x80    :  0x00 0x00  |
+-----------------+------------+-------------+

0d0 with overpadded exponent and coefficient
+-----------------+------------+-------------+
:      0x54       :  0x00 0x80 :  0x00 0x00  |
+-----------------+------------+-------------+
</pre>

**Note**: The latter two examples demonstrate overpadded encodings of the
exponent and coefficient subfields. Overpadded encodings such as these are
possible for any decimal and are always equivalent to the unpadded encoding.

The following binary encodings of decimal values are equivalent
to `-0d0` (but not to `0d0`).

<pre class="textdiagram">
+-----------------+------------+-------------+
| type descriptor |  exponent  | coefficient |
|                 |  (VarInt)  |    (Int)    |
+-----------------+------------+-------------+

Explicit encoding of (negative)0d0
+-----------------+------------+-------------+
:      0x52       :    0x80    :    0x80     |
+-----------------+------------+-------------+

Explicit encoding of (negative)0d(negative)0
+-----------------+------------+-------------+
:      0x52       :    0xC0    :    0x80     |
+-----------------+------------+-------------+
</pre>

Finally, the following binary encodings of decimal values are equivalent
to `42d0`.

<pre class="textdiagram">
+-----------------+------------+-------------+
| type descriptor |  exponent  | coefficient |
|                 |  (VarInt)  |    (Int)    |
+-----------------+------------+-------------+

Explicit encoding of 42d0
+-----------------+------------+-------------+
:      0x52       :    0x80    :    0x2A     |
+-----------------+------------+-------------+

Explicit encoding of 42d(negative)0
+-----------------+------------+-------------+
:      0x52       :    0xC0    :    0x2A     |
+-----------------+------------+-------------+
</pre>

<!-- References -->
[docs]: {{ site.baseurl }}/docs.html
[decarith]: http://speleotrove.com/decimal/decarith.html
[damodel]: http://speleotrove.com/decimal/damodel.html
[daconvs]: http://speleotrove.com/decimal/daconvs.html
[binary]: binary.html
