# Values

## Annotations
In the text format, type annotations are denoted by a [symbol token](symbol-tokens.md) and double-colons preceding any value.
Multiple annotations on the same value are separated by double-colons:

```ion
int32::12                                // Suggests 32 bits as end-user type
degrees::'celsius'::100                  // You can have multiple annotaions on a value
'my.custom.type'::{ x : 12 , y : -1 }    // Gives a struct a user-defined type

{ field: some_annotation::value }        // Field's name must precede annotations of its value

jpeg :: {{ ... }}                        // Indicates the blob contains jpeg data
bool :: null.int                         // A very misleading annotation on the integer null
'' :: 1                                  // An empty annotation
null.symbol :: 1                         // ERROR: type annotation cannot be null 
```

## Nulls

Null values are represented by the keyword `null`, optionally followed by `.` and the name of a type in the Ion data model.

```ion
null
null.null       // Identical to unadorned null
null.bool
null.int
null.float
null.decimal
null.timestamp
null.string
null.symbol
null.blob
null.clob
null.struct
null.list
null.sexp
```

The text format treats all of these as reserved tokens; to use those
same characters as a symbol token, they must be enclosed in single-quotes:

```ion
null        // The type is null
'null'      // The type is symbol
null.list   // The type is list
'null.int'  // The type is symbol
```

Any text token starting with `null.` must be one of the legal null values.

```ion
(llun.foo)  // A s-expression equivalent to (llun . foo)

(null.foo)  // This is illegal; not equivalent to (null . foo) 
            // because null. is never split into separate tokens
```

## Booleans

Boolean values are represented by the literals `true` and `false`.

The text format treats both of these as reserved tokens; to use those
same characters as a symbol token, they must be enclosed in single-quotes.

```ion
true          // a boolean value
'true'        // a symbol value

'true'::1     // an integer annotated with the text "true"
true::1       // ERROR: cannot use an unquoted keyword as an annotation

{ 'true': 1 } // a struct containing a field name with the text "true"
{ true: 1 }   // ERROR: cannot use an unquoted keyword as a field name
```

## Integers

Integer values may be encoded in binary, decimal, and hexadecimal notation.

A decimal-encoded `int` consists of the digit `0` OR a non-zero digit followed by zero-or more base 10 digits (`0123456789`)—leading zeros are not allowed.
A binary-encoded `int` consists of `0b` followed by one or more base 2 digits (`01`).
A hexadecimal-encoded `int` consists of `0x` followed by one or more case-insensitive base 16 digits (`0123456789abcdefABCDEF`).

All integer values may be preceded by an optional minus sign (`-`), indicating that the value is negative.
(The token `-0` is legal and equivalent to `0`.)
Single underscores may be used to separate digits; consecutive underscores are never allowed.
All integer values must be followed by one of the fifteen numeric stop-characters: `{}[](),\"\'\ \t\n\r\v\f`.

Though the text format allows hexadecimal and binary notation, such notation is not guaranteed to be maintained if a data stream is re-transcribed.

```ion
0          // Zero.  Surprise!
-0         //   ...the same value with a minus sign
123        // A normal int
-123       // A negative int
0xBeef     // An int denoted in hexadecimal
-0xBeef    // A negative int denoted in hexadecimal
0b0101     // An int denoted in binary
-0b0101    // A negative int denoted in binary
1_2_3      // An int with underscores
0xFA_CE    // An int denoted in hexadecimal with underscores
0b10_10_10 // An int denoted in binary with underscores

+1         // ERROR: leading plus not allowed
0123       // ERROR: leading zeros not allowed
1_         // ERROR: trailing underscore not allowed
1__2       // ERROR: consecutive underscores not allowed
0x_12      // ERROR: underscore can only appear between digits (the radix prefix is not a digit)
_1         // A symbol (ints cannot start with underscores)
```

## Floats

The text encoding of a _numeric_ `float` value:
* Optionally starts with a minus sign
* Has a whole number part that is either:
  * zero, or
  * starts with 1-9 followed by any number of digits
* Has an optional decimal point followed by zero or more decimal digits
* Has the letter 'e'
* Has an optional minus sign for the exponent
* Ends with one or more digits for the exponent

A numeric Ion `float` value must always contain an `e`—fractional numbers without an `e` are `decimal` values.

Ion `float` values may also be special *non-number* values, represented in text by the following keywords:

* `nan` denotes the *not a number* (NaN) value.
* `+inf` denotes *positive infinity*.
* `-inf` denotes *negative infinity*.

The text format treats `nan` as a reserved token; to use those same characters as a symbol token, they must be enclosed in single-quotes.

While base-10 notation is convenient for human representation, many base-10 real numbers are irrational with respect 
to base-2 and cannot be expressed exactly as a binary floating point number (e.g. `1.1e0`).

When encoding a decimal real number that is irrational in base-2 or has more precision than can be stored in `binary64`,
the exact `binary64` value is determined by using the IEEE-754 *round-to-nearest* mode with a *round-half-to-even* as the tie-break.
This mode/tie-break is the common default used in most programming environments and is discussed in detail in
["Correctly Rounded Binary-Decimal and Decimal-Binary Conversions"](https://ampl.com/_archive/first-website/REFS/rounding.pdf).
This conversion algorithm is illustrated in a straightforward way in [Clinger's Algorithm](https://dl.acm.org/doi/10.1145/93548.93557).

When encoding a `float` value to Ion text, an implementation MAY want to consider the approach described in
["Printing Floating-Point Numbers Quickly and Accurately"](https://dl.acm.org/doi/10.1145/231379.231397).


#### Examples
Although the textual representative of `1.2e0` itself is irrational, its
canonical form in the data model is not (based on the rounding rules), thus
the following text forms all map to the same `float` value:

```ion
// the most human-friendly representation
1.2e0

// the exact textual representation in base-10 for the binary64 value 1.2e0 represents
1.1999999999999999555910790149937383830547332763671875e0

// a shortened, irrational version, but still the same value
1.1999999999999999e0

// a lengthened, irrational version that is still the same value
1.19999999999999999999999999999999999999999999999999999999e0
```

## Decimals

The Hursley rules for describing a _finite value_ [converting from textual notation](https://speleotrove.com/decimal/damodel.html) *must* be followed.
The Hursley rules for describing a _special value_ are **not** followed—the rules for

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

Where `X` is any unsigned integer, all the following formulae can be
demonstrated to be equivalent using the text conversion rules and the data
model.

```ion
// Exponent implicitly zero
X.
// Exponent explicitly zero
Xd0
// Exponent explicitly negative zero (equivalent to zero).
Xd-0
```

Other equivalent representations include the following, where `Y` is the number
of digits in `X`.

```ion
// There are Y digits past the decimal point in the
// decimal-part, making the exponent zero. One leading zero
// is removed.
0.XdY
```

For example, all the following text Ion decimal representations are equivalent to each other.

```ion
0.
0d0
0d-0
0.0d1
```

Additionally, all the following are equivalent to each other (but not to any forms of positive zero).

```ion
-0.
-0d0
-0d-0
-0.0d1
```

Because all forms of zero are distinctly identified by the *exponent*, the
following are **not** equivalent to each other.

```ion
// Exponent implicitly zero.
0.
// Exponent explicitly 5.
0d5
```

All the following are equivalent to each other.

```ion
42.
42d0
42d-0
4.2d1
0.42d2
```

However, the following are **not** equivalent to each other.

```ion
// Text converted to 42.
0.42d2
// Text converted to 42.0
0.420d2
```

In the text notation, decimal values must be followed by one of the
fifteen numeric stop-characters: `{}[](),\"\'\ \t\n\r\v\f`.


## Timestamps

In the text format, timestamps follow the [W3C note on date and time formats](https://www.w3.org/TR/NOTE-datetime),
but they must end with the literal `T` if not at least whole-day precision.
Fractional seconds are allowed, with at least one digit of precision and an unlimited maximum.
Local-time offsets may be represented as either hour:minute offsets from UTC, or as the literal `Z` to denote a local time of UTC.
They are required on timestamps with time and are not allowed on date values.

```ion
2007-02-23T12:14Z                // Seconds are optional, but local offset is not
2007-02-23T12:14:33.079-08:00    // A timestamp with millisecond precision and PST local time
2007-02-23T20:14:33.079Z         // The same instant in UTC ("zero" or "zulu")
2007-02-23T20:14:33.079+00:00    // The same instant, with explicit local offset
2007-02-23T20:14:33.079-00:00    // The same instant, with unknown local offset

2007-01-01T00:00-00:00           // Happy New Year in UTC, unknown local offset
2007-01-01                       // The same instant, with days precision, unknown local offset
2007-01-01T                      //    The same value, different syntax.
2007-01T                         // The same instant, with months precision, unknown local offset
2007T                            // The same instant, with years precision, unknown local offset

2007-02-23                       // A day, unknown local offset 
2007-02-23T00:00Z                // The same instant, but more precise and in UTC
2007-02-23T00:00+00:00           // An equivalent format for the same value
2007-02-23T00:00:00-00:00        // The same instant, with seconds precision

2007                             // Not a timestamp, but an int
2007-01                          // ERROR: Must end with 'T' if not whole-day precision, this results as an invalid-numeric-stopper error
2007-02-23T20:14:33.Z            // ERROR: Must have at least one digit precision after decimal point.
```

In the text notation, timestamp values must be followed by one of the
fifteen numeric stop-characters: `{}[](),\"\'\ \t\n\r\v\f`.

## Strings

In the text format, strings are delimited by double-quotes and follow C/Java backslash-escape conventions (see [Escape Characters](escape-characters.md)).

```ion
null.string            // A null string value
""                     // An empty string value
" my string "          // A normal string
"\""                   // Contains one double-quote character
"\uABCD"               // Contains one unicode character

xml::"<e a='v'>c</e>"  // String with type annotation 'xml'
```

The text format supports an alternate syntax for "long strings", including those that break across lines.
Sequences bounded by three single-quotes (`'''`) can cross multiple lines and still count as a valid, single string.
In addition, any number of adjacent triple-quoted strings are concatenated into a single value. 
The concatenation happens within the Ion text parser and is neither detectable via the data model nor applicable to the binary format.
Note that comments are always treated as whitespace, so concatenation still occurs when a comment falls between two long strings.

```ion
( '''hello '''     // Sexp with one element
  '''world!'''  )

("hello world!")   // The exact same sexp value

// This Ion value is a string containing three newlines. The serialized
// form's first newline is escaped into nothingness.
'''\
The first line of the string.
This is the second line of the string,
and this is the third line.
'''
```

## Symbols

A symbol value is encoded using a [symbol token](symbol-tokens.md).

In the text format, symbols are delimited by single-quotes and use the same [escape characters](escape-characters.md) as strings.

```ion
null.symbol  // A null symbol value
'myVar2'     // A symbol
myVar2       // The same symbol
myvar2       // A different symbol
'hi ho'      // Symbol requiring quotes
'\'ahoy\''   // A symbol with embedded quotes
''           // The empty symbol
```

Within [S-expressions](#s-expressions), the rules for unquoted symbols include another set of tokens: operators.
An *operator* is an unquoted sequence of one or more of the following nineteen ASCII characters: `` !#%&*+-./;<=>?@^`|~ ``.
Operators and identifiers can be juxtaposed without whitespace:

```ion
( 'x' '+' 'y' )  // S-expression with three symbols
( x + y )        // The same three symbols
(x+y)            // The same three symbols
(a==b&&c==d)     // S-expression with seven symbols
```


<!-- TODO: Explain edge cases for identifier symbols and nulls, floats, etc. in s-expressions** -->


## Clobs

In the text format, `clob` values use similar syntax to `blob`, but the data between braces must be one string.
Similar to `string`, adjoining long string literals within an Ion `clob` are concatenated automatically.
Within a `clob`, only one short string literal or multiple long string literals are allowed.

The string may only contain legal 7-bit ASCII characters, using the same [escaping syntax](escape-characters.md) as `string`and `symbol` values.
This guarantees that the value can be transmitted unscathed while remaining generally readable (at least for western language text).
Either form of comment within a `clob` is invalid.


```ion
{{ "This is a CLOB of text." }}

shift_jis::
{{
  '''Another clob with user-defined encoding, '''
  '''this time on multiple lines.'''
}}

// Two equivalent clobs
{{ '''Hello'''    '''World''' }}
{{ "HelloWorld" }}

{{
  // ERROR
  "comments not allowed"
}}
```



## Blobs

In the text format, `blob` values are denoted as [RFC 4648](https://tools.ietf.org/html/rfc4648#section-4)-compliant
[Base64](http://en.wikipedia.org/wiki/Base64) text within two pairs of curly braces.

When parsing `blob` text, an error must be raised if the data:
* Contains characters outside of the [Base64 character set](https://tools.ietf.org/html/rfc4648#section-4).
* Contains a padding character (`=`) anywhere other than at the end.
* Is terminated by an incorrect number of padding characters.

Within `blob` values, whitespace is ignored.
Comments within `blob`s are not supported: the `/` character is always considered part of the Base64 data and the `*` is invalid.

```ion
// A valid blob value with zero padding characters.
{{
  +AB/
}}

// A valid blob value with one required padding character.
{{ VG8gaW5maW5pdHkuLi4gYW5kIGJleW9uZCE= }}

// ERROR: Incorrect number of padding characters.
{{ VG8gaW5maW5pdHkuLi4gYW5kIGJleW9uZCE== }}

// ERROR: Padding character within the data.
{{ VG8gaW5maW5pdHku=Li4gYW5kIGJleW9uZCE= }}

// A valid blob value with two required padding characters.
{{ dHdvIHBhZGRpbmcgY2hhcmFjdGVycw== }}

// ERROR: Invalid character within the data.
{{ dHdvIHBhZGRpbmc_gY2hhcmFjdGVycw= }}
```

## Lists

In the text format, lists are bounded by square brackets and elements
are separated by commas.

```ion
[]                // An empty list value
[1, 2, 3]         // List of three ints
[ 1 , two ]       // List of an int and a symbol
[a , [b]]         // Nested list
[ 1.2, ]          // Trailing comma is legal in Ion (unlike JSON)
[ 1, , 2 ]        // ERROR: missing element between commas
```

## S-expressions

In the text format, S-expressions are bounded by parentheses.
S-expressions also allow unquoted operator symbols, in addition to the
unquoted identifier symbols allowed everywhere.

```ion
()                // An empty expression value
(cons 1 2)        // S-expression of three values
([hello][there])  // S-expression containing two lists

(a+-b)  ( 'a' '+-' 'b' )    // Equivalent; three symbols
(a.b;)  ( 'a' '.' 'b' ';')  // Equivalent; four symbols
```

Note that comments are allowed within S-expressions and have higher precedence
than operators, therefore `//` and `/*` denote the start of comment blocks.
Users are advised to avoid them as operators, though they can be used when
escaped with single quotes:
```ion
(a/* word */b)       // An S-expression with two symbols and a comment
(a '/*' word '*/' b) // An S-expression with five symbols
```

## Structs

In the text format, a `struct` is wrapped by curly braces, with a colon between each name and value, and a comma between the fields.
The field name is a [symbol token](symbol-tokens.md).
For the purposes of JSON compatibility, it is also legal to use a string for field names, but they are converted to symbol tokens by the parser.

```ion
{ }                                 // An empty struct value
{ first : "Tom" , last: "Riddle" }  // Structure with two fields
{"first":"Tom","last":"Riddle"}     // The same value with confusing style
{center:{x:1.0, y:12.5}, radius:3}  // Nested struct
{ x:1, }                            // Trailing comma is legal in Ion (unlike JSON)
{ "":42 }                           // A struct value containing a field with an empty name
{ x:1, x:null.int }                 // WARNING: repeated name 'x' leads to undefined behavior
{ x:1, , }                          // ERROR: missing field between commas
```

Note that field names are symbol *tokens*, not symbol *values*, and thus may not be annotated.
The value of a field may be annotated like any other value.
Syntactically the field name comes first, then annotations, then the content.

```ion
{ annotation:: field_name: value }     // ERROR
{ field_name: annotation:: value }     // Okay
```
