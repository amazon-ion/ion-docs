---
layout: default
title: The Amazon Ion Specification
---

# The Amazon Ion Specification

The Amazon Ion specification has three parts:

  * A set of data types
  * A textual notation for values of those types
  * A binary notation for values of those types

All three views are semantically isomorphic, meaning they can represent
exactly the same data structures, and an Ion processor can transcode
between the formats without loss of data. This allows applications to
optimize different areas for different uses -- say, using text for human
readability and binary for compact persistence -- by transcribing
between the formats with almost complete fidelity. ("Almost" because
converting from text to binary does not preserve whitespace and
comments.)

The Ion [text encoding](text.html) is intended to be easy to read and
write. It may be more suitable for streaming applications since sequences
don't need to be length-prefixed. Whitespace is insignificant and is only
required where necessary to separate tokens. C-style comments are treated
as whitespace, and are not part of the binary encoding.

The [binary encoding](binary.html) is
much more compact and efficient. An important feature is that parts of
the whole can be accessed without "preparation", meaning you don't have
to load it into another form before accessing the values.


The Ion Data Model
------------------

The semantic basis of Ion is an abstract data model, composed of a set
of primitive types and a set of recursively-defined container types. All
types support null values and user-defined type annotations.

It's important to note that the data model is *value-based* and does not
include references. As a result, the data model can express data
hierarchies (we can nest things to arbitrary depth), but not general
directed graphs.

Here's an overview of the core data types:

  * [`null`](#null) - A generic null value
  * [`bool`](#bool) - Boolean values
  * [`int`](#int) - Signed integers of arbitrary size
  * [`float`](#float) - Binary-encoded floating point numbers (IEEE 64-bit)
  * [`decimal`](#decimal) - Decimal-encoded real numbers of arbitrary precision
  * [`timestamp`](#timestamp) - Date/time/timezone moments of arbitrary precision
  * [`string`](#string) - Unicode text literals
  * [`symbol`](#symbol) - Interned, Unicode symbolic atoms (*aka* identifiers)
  * [`blob`](#blob) - Binary data of user-defined encoding
  * [`clob`](#clob) - Text data of user-defined encoding
  * [`struct`](#struct) - Unordered collections of tagged values
  * [`list`](#list) - Ordered collections of values
  * [`sexp`](#sexp) - Ordered collections of values with application-defined
    semantics

### Primitive Types

<a id="null"></a>
#### Null Values

Ion supports distinct null values for every core type, as well as a
separate `null` type that's distinct from all other types.

The `null` type has a single value, denoted in the text format by the
keyword `null`. Null values for all core types are denoted by suffixing
the keyword with a period and the desired type. Thus we can enumerate
all possible null values as follows:

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

The text format treats all of these as reserved tokens; to use those
same characters as a symbol, they must be enclosed in single-quotes:

    null        // The type is null
    'null'      // The type is symbol
    null.list   // The type is list
    'null.int'  // The type is symbol

(As a historical aside, the `null` type exists primarily for
compatibility with JSON, which has only the untyped `null` value.)

<a id="bool"></a>
#### Booleans

The `bool` type is self-explanatory, but note that (as with all Ion
types) there's a null value. Thus the set of all Boolean values consists
of the following three reserved tokens:

    null.bool
    true
    false

(As with the null values, one can single-quote those tokens to force
them to be parsed as symbols.)

<a id="int"></a>
#### Integers

The `int` type consists of signed integers of arbitrary size. The binary
format uses a very compact encoding that uses "just enough" bits to hold
the value.

The text format allows hexadecimal and binary (but not octal) notation,
but such notation will not be maintained during binary-to-text conversions.
It also allows for the use of underscores to separate digits.

    null.int   // A null int value
    0          // Zero.  Surprise!
    -0         //   ...the same value with a minus sign
    123        // A normal int
    -123       // Another negative int
    0xBeef     // An int denoted in hexadecimal
    0b0101     // An int denoted in binary
    1_2_3     // An int with underscores
    0xFA_CE    // An int denoted in hexadecimal with underscores
    0b10_10_10 // An int denoted in binary with underscores

    +1         // ERROR: leading plus not allowed
    0123       // ERROR: leading zeros not allowed (no support for octal notation)
    1_         // ERROR: trailing underscore not allowed
    1__2       // ERROR: consecutive underscores not allowed
    0x_12      // ERROR: underscore can only appear between digits (the radix prefix is not a digit)
    _1         // A symbol (ints cannot start with underscores)

In the text notation, integer values must be followed by one of the
thirteen numeric stop-characters: `{}[](),\"\'\ \t\n\r`.

<a id="float"></a><a id="decimal"/></a>
#### Real Numbers

Ion supports both binary and lossless decimal encodings of real numbers
as, respectively, types `float` and `decimal`. In the text format,
`float` values are denoted much like the decimal formats in C or Java;
`decimal` values use `d` instead of `e` to start the exponent. Reals
without an exponent are treated as decimal. As with JSON, extra leading
zeros are not allowed. Digits may be separated with an underscore.

    null.decimal      // A null decimal value
    null.float        // A null float value

    0.123             // Type is decimal
    -0.12e4           // Type is float
    -0.12d4           // Type is decimal

    0E0               // Zero as float
    0D0               // Zero as decimal
    0.                //   ...the same value with different notation
    -0e0              // Negative zero float   (distinct from positive zero)
    -0d0              // Negative zero decimal (distinct from positive zero)
    -0.               //   ...the same value with different notation
    -0d-1             // Decimal maintains precision: -0. != -0.0

    123_456.789_012   // Decimal with underscores

    123_._456         // ERROR: underscores may not appear next to the decimal point
    12__34.56         // ERROR: consecutive underscores not allowed
    123.456_          // ERROR: trailing underscore not allowed
    -_123.456         // ERROR: underscore after negative sign not allowed
    _123.456          // ERROR: the symbol '_123' followed by an unexpected dot

The `float` type denotes either 32-bit or 64-bit IEEE-754 floating-point values; other
sizes may be supported in future versions of this specification.

In the text notation, real values must be followed by one of the
thirteen numeric stop-characters: `{}[](),\"\'\ \t\n\r`.

The precision of `decimal` values, including trailing zeros, is significant and
is preserved through round-trips. Because most decimal values cannot be
represented exactly in binary floating-point, `float` values may change
"appearance" and precision when reading or writing Ion text.

See also [Ion Float](float.html) and [Ion Decimals](decimal.html) for more notes.

<a id="timestamp"></a>
#### Timestamps

Timestamps represent a specific moment in time, always include a local
offset, and are capable of arbitrary precision.

In the text format, timestamps follow the [W3C note on date and time
formats](http://www.w3.org/TR/NOTE-datetime), but they must end with the
literal "T" if not at least whole-day precision. Fractional seconds are
allowed, with at least one digit of precision and an unlimited maximum.
Local-time offsets may be represented as either hour:minute offsets from
UTC, or as the literal "Z" to denote a local time of UTC. They are
required on timestamps with time and are not allowed on date values.

Ion follows the "Unknown Local Offset Convention" of
[RFC3339](http://www.ietf.org/rfc/rfc3339.txt):

> If the time in UTC is known, but the offset to local time is unknown,
> this can be represented with an offset of "-00:00". This differs
> semantically from an offset of "Z" or "+00:00", which imply that UTC
> is the preferred reference point for the specified time.
> [RFC2822](http://www.ietf.org/rfc/rfc2822.txt) describes a similar
> convention for email.

Values that are precise only to the year, month, or date are assumed to
be UTC values with unknown local offset.

    null.timestamp                   // A null timestamp value

    2007-02-23T12:14Z                // Seconds are optional, but local offset is not
    2007-02-23T12:14:33.079-08:00    // A timestamp with millisecond precision and PST local time
    2007-02-23T20:14:33.079Z         // The same instant in UTC ("zero" or "zulu")
    2007-02-23T20:14:33.079+00:00    // The same instant, with explicit local offset
    2007-02-23T20:14:33.079-00:00    // The same instant, with unknown local offset

    2007-01-01T00:00-00:00           // Happy New Years... somewhere!
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

Zero and negative dates are not valid, so the earliest instant in time
that can be represented as a timestamp is Jan 01, 0001. As per the W3C
note, leap seconds cannot be represented.

In the text notation, timestamp values must be followed by one of the
thirteen numeric stop-characters: `{}[](),\"\'\ \t\n\r`.

<a id="string"></a>
#### Strings

Ion `string` values are Unicode character sequences of arbitrary length.

In the text format, strings are delimited by double-quotes and follow
C/Java backslash-escape conventions (see [below](#escapes)).
The binary format always uses UTF-8 encoding.

    null.string            // A null string value
    ""                     // An empty string value
    " my string "          // A normal string
    "\""                   // Contains one double-quote character
    "\uABCD"               // Contains one unicode character

    xml::"<e a='v'>c</e>"  // String with type annotation 'xml'

##### Long Strings

The text format supports an alternate syntax for "long strings",
including those that break across lines. Sequences bounded by three
single-quotes (''') can cross multiple lines and still count as a valid,
single string. In addition, any number of adjacent triple-quoted strings
are concatenated into a single value. The concatenation happens within
the Ion text parser and is neither detectable via the data model nor
applicable to the binary format. Note that comments are always treated
as whitespace, so concatenation still occurs when a comment falls
between two long strings.

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

<a id="escapes"></a>
##### Escape Characters

The Ion text format supports escape sequences *only* within quoted
strings and symbols. Ion supports most of the escape sequences defined
by C++, Java, and JSON.

The following sequences are allowed:

<table>
<thead>
<tr class="header">
<th align="left">Unicode Code Point</th>
<th align="left">Ion Escape</th>
<th align="left">Meaning</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><code>U+0000</code></td>
<td align="left"><code>\0</code></td>
<td align="left">NUL</td>
</tr>
<tr class="even">
<td align="left"><code>U+0007</code></td>
<td align="left"><code>\a</code></td>
<td align="left">alert BEL</td>
</tr>
<tr class="odd">
<td align="left"><code>U+0008</code></td>
<td align="left"><code>\b</code></td>
<td align="left">backspace BS</td>
</tr>
<tr class="even">
<td align="left"><code>U+0009</code></td>
<td align="left"><code>\t</code></td>
<td align="left">horizontal tab HT</td>
</tr>
<tr class="odd">
<td align="left"><code>U+000A</code></td>
<td align="left"><code>\n</code></td>
<td align="left">linefeed LF</td>
</tr>
<tr class="even">
<td align="left"><code>U+000C</code></td>
<td align="left"><code>\f</code></td>
<td align="left">form feed FF</td>
</tr>
<tr class="odd">
<td align="left"><code>U+000D</code></td>
<td align="left"><code>\r</code></td>
<td align="left">carriage return CR</td>
</tr>
<tr class="even">
<td align="left"><code>U+000B</code></td>
<td align="left"><code>\v</code></td>
<td align="left">vertical tab VT</td>
</tr>
<tr class="odd">
<td align="left"><code>U+0022</code></td>
<td align="left"><code>\&quot;</code></td>
<td align="left">double quote</td>
</tr>
<tr class="even">
<td align="left"><code>U+0027</code></td>
<td align="left"><code>\'</code></td>
<td align="left">single quote</td>
</tr>
<tr class="odd">
<td align="left"><code>U+003F</code></td>
<td align="left"><code>\?</code></td>
<td align="left">question mark</td>
</tr>
<tr class="even">
<td align="left"><code>U+005C</code></td>
<td align="left"><code>\\</code></td>
<td align="left">backslash</td>
</tr>
<tr class="odd">
<td align="left"><code>U+002F</code></td>
<td align="left"><code>\/</code></td>
<td align="left">forward slash</td>
</tr>
<tr class="even">
<td align="left"><em>nothing</em></td>
<td align="left"><code>\<em>NL</em></code></td>
<td align="left">escaped NL expands to nothing</td>
</tr>
<tr class="odd">
<td align="left"><code>U+00<em>HH</em></code></td>
<td align="left"><code>\x<em>HH</em></code></td>
<td align="left">2-digit hexadecimal Unicode code point</td>
</tr>
<tr class="even">
<td align="left"><code>U+<em>HHHH</em></code></td>
<td align="left"><code>\u</em>HHHH</em></code></td>
<td align="left">4-digit hexadecimal Unicode code point</td>
</tr>
<tr class="odd">
<td align="left"><code>U+<em>HHHHHHHH</em></code></td>
<td align="left"><code>\U<em>HHHHHHHH</em></code></td>
<td align="left">8-digit hexadecimal Unicode code point</td>
</tr>
</tbody>
</table>

Any other sequence following a backslash is an error.

Note that Ion does not support the following escape sequences:

  * Java's extended Unicode markers, _e.g._, `"\uuuXXXX"`
  * General octal escape sequences, `\OOO`

<a id="symbol"></a>
#### Symbols

Symbols are much like strings, in that they are Unicode character
sequences. The primary difference is the intended semantics: symbols
represent semantic identifiers as opposed to textual literal values.
Symbols are case sensitive.

In the text format, symbols are delimited by single-quotes and use the
same [escape characters](#escapes).

A subset of symbols called identifiers can be denoted in text without
single-quotes. An *identifier* is a sequence of ASCII letters, digits,
or the characters `$` (dollar sign) or `_` (underscore), not starting
with a digit.

    null.symbol  // A null symbol value
    'myVar2'     // A symbol
    myVar2       // The same symbol
    myvar2       // A different symbol
    'hi ho'      // Symbol requiring quotes
    '\'ahoy\''   // A symbol with embedded quotes
    ''           // The empty symbol

Within [S-expressions](#sexp), the rules for
unquoted symbols include another set of tokens: operators. An *operator*
is an unquoted sequence of one or more of the following nineteen ASCII
characters: `` !#%&*+-./;<=>?@^`|~ `` Operators and
identifiers can be juxtaposed without whitespace:

    ( 'x' '+' 'y' )  // S-expression with three symbols
    ( x + y )        // The same three symbols
    (x+y)            // The same three symbols
    (a==b&&c==d)     // S-expression with seven symbols

Note that the data model does not distinguish between identifiers,
operators, or other symbols, and that -- as always -- the binary format
does not retain whitespace.

See [Ion Symbols](symbols.html) for more details about symbol
representations and symbol tables.

<a id="blob"></a>
#### Blobs

The `blob` type allows embedding of arbitrary raw binary data. Ion
treats such data as a single (though often very large) value. It does no
processing of such data other than passing it through intact.

In the text format, `blob` values are denoted as
[RFC 4648](https://tools.ietf.org/html/rfc4648)-compliant
[Base64](http://en.wikipedia.org/wiki/Base64) text within two
pairs of curly braces.

When parsing `blob` text, an error must be raised if the data:

  * Contains characters outside
    of the [Base64 character set](https://tools.ietf.org/html/rfc4648#section-4).
  * Contains a padding character (`=`) anywhere other than at the end.
  * Is terminated by an incorrect number of padding characters.

Within `blob` values, whitespace is ignored and comments are not allowed.
The `/` character is always considered part of the Base64 data.

    // A null blob value
    null.blob

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

<a id="clob"></a>
#### Clobs

The `clob` type is similar to `blob` in that it holds uninterpreted
binary data. The difference is that the content is expected to be text,
so we use a text notation that's more readable than Base64.

In the text format, `clob` values use similar syntax to `blob`, but the
data between braces must be one string. The string may only contain
legal 7-bit ASCII characters, using the same escaping syntax as `string`
and `symbol` values. This guarantees that the value can be transmitted
unscathed while remaining generally readable (at least for western
language text). Like `blob`s, `clob`s disallow comments everywhere
within the value.

[Strings and Clobs](stringclob.html) gives details on the
subtle, but profound, differences between Ion strings and clobs.

    null.clob  // A null clob value

    {{ "This is a CLOB of text." }}

    shift_jis ::
    {{
      '''Another clob with user-defined encoding, '''
      '''this time on multiple lines.'''
    }}

    {{
      // ERROR
      "comments not allowed"
    }}

Note that the `shift_jis` type annotation above is, like all
[type annotations](#annot), application-defined. Ion does not interpret or
validate that symbol; that's left to the application.


<a id="container"></a>
### Container Types

Ion defines three container types: structures, lists, and S-expressions.
These types are defined recursively and may contain values of any Ion
type.


<a id="struct"></a>
#### Structures

Structures are *unordered* collections of name/value pairs. The names
are symbol tokens, and the values are unrestricted. Each name/value pair
is called a field.

When two fields in the same struct have the same name we say there are
"repeated names" or (somewhat misleadingly) "repeated fields".
Implementations must preserve all such fields, *i.e.*, they may not
discard fields that have repeated names. However, implementations *may*
reorder fields (the binary format identifies structs that are sorted by
symbolID), so certain operations may lead to nondeterministic behavior.

In the text format, structures are wrapped by curly braces, with a colon
between each name and value, and a comma between the fields. For the
purposes of JSON compatibility, it's also legal to use strings for field
names, but they are converted to symbol tokens by the parser.

    null.struct                         // A null struct value
    { }                                 // An empty struct value
    { first : "Tom" , last: "Riddle" }  // Structure with two fields
    {"first":"Tom","last":"Riddle"}     // The same value with confusing style
    {center:{x:1.0, y:12.5}, radius:3}  // Nested struct
    { x:1, }                            // Trailing comma is legal in Ion (unlike JSON)
    { "":42 }                           // A struct value containing a field with an empty name
    { x:1, x:null.int }                 // WARNING: repeated name 'x' leads to undefined behavior
    { x:1, , }                          // ERROR: missing field between commas

Note that field names are symbol *tokens*, not symbol *values*, and thus
may not be annotated. The value of a field may be annotated like any
other value. Syntactically the field name comes first, then annotations,
then the content.

    { annotation:: field_name: value }     // ERROR
    { field_name: annotation:: value }     // Okay


<a id="list"></a>
#### Lists

Lists are ordered collections of values. The contents of the list are
heterogeneous (that is, each element can have a different type).
Homogeneous lists are not supported by the core type system, but may be
imposed by schema validation tools.

In the text format, lists are bounded by square brackets and elements
are separated by commas.

    null.list         // A null list value
    []                // An empty list value
    [1, 2, 3]         // List of three ints
    [ 1 , two ]       // List of an int and a symbol
    [a , [b]]         // Nested list
    [ 1.2, ]          // Trailing comma is legal in Ion (unlike JSON)
    [ 1, , 2 ]        // ERROR: missing element between commas


<a id="sexp"></a>
#### S-Expressions

An S-expression (or [symbolic expression](https://en.wikipedia.org/wiki/S-expression))
is much like a list in that it's an ordered collection
of values. However, the notation aligns with Lisp syntax to connote use
of application semantics like function calls or programming-language
statements. As such, correct interpretation requires a higher-level
context other than the raw Ion parser and data model.

In the text format, S-expressions are bounded by parentheses.
S-expressions also allow unquoted operator symbols (in addition to the
unquoted identifier symbols allowed everywhere), so commas are
interpreted as values rather than element separators.

    null.sexp         // A null S-expression value
    ()                // An empty expression value
    (cons 1 2)        // S-expression of three values
    ([hello][there])  // S-expression containing two lists

    (a+-b)  ( 'a' '+-' 'b' )    // Equivalent; three symbols
    (a.b;)  ( 'a' '.' 'b' ';')  // Equivalent; four symbols

Although Ion S-expressions use a syntax similar to Lisp expressions, Ion does
not define their interpretation or any semantics at all, beyond the pure
sequence-of-values data model indicated above.

<a id="annot"></a>
### Type Annotations

Any Ion value can include one or more annotation symbols denoting the
semantics of the content. This can be used to:

-   Annotate individual values with schema types, for
    validation purposes.
-   Associate a higher-level datatype (e.g. a Java class) during
    serialization processes.
-   Indicate the notation used within a `blob` or `clob` value.
-   Apply other application semantics to a single value.

When multiple annotations are present, the Ion processor will maintain
their order. Duplicate annotation symbols are allowed but discouraged.

In the text format, type annotations are denoted by a non-null symbol
token and double-colons preceding any content:

    int32::12                                // Suggests 32 bits as end-user type
    'my.custom.type' :: { x : 12 , y : -1 }  // Gives a struct a user-defined type

    { field: something::'another thing'::value }  // Field's name must precede annotations of its value

    jpeg :: {{ ... }}                        // Indicates the blob contains jpeg data
    bool :: null.int                         // A very misleading annotation on the integer null
    '' :: 1                                  // An empty annotation
    null.symbol :: 1                         // ERROR: type annotation cannot be null 

Except for a small number of predefined system annotations, Ion itself
neither defines nor validates such annotations; that behavior is left to
applications or tools (such as schema validators).

It's important to understand that annotations are symbol *tokens*, not
symbol *values*. That means they do not have annotations themselves. In
particular, the text `a::c` is a single value consisting of three
textual tokens (a symbol, a double-colon, and another symbol); the first
symbol token is an *annotation* on the value, and the second is the
*content* of the value.
