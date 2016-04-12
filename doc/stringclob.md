# Amazon Ion Strings and Clobs

This document is a proposal to clarify the semantics of the Amazon Ion
`string` and `clob` data types with respect to
escapes and the [Unicode](http://www.unicode.org/) standard.

As of the date of this writing, the Unicode Standard is on [version
5.0](http://www.unicode.org/versions/Unicode5.0.0/). This specification
is to that standard.

Unicode Primer
--------------

The Unicode standard specifies a large set of *code points*, the
Universal Character Set (UCS), which is an integer in the range of 0
(0x0) through 1,114,111 (0x10FFFF) inclusive. Throughout this document,
the notation U+*HHHH* and U+*HHHHHHHH* refer to the Unicode code point
*HHHH* and *HHHHHHHH* respectively as a hexadecimal ordinal. This
notation follows the Unicode standard convention.

Traditionally, from a programmer's perspective, a code point can be
thought of as a *character*, but there is sometimes a subtle
distinction. For example, in Java, the `char` type is an unsigned,
16-bit integer, which is normally used to hold UTF-16 *code units* (_e.g._
[`java.lang.CharSequence`](https://docs.oracle.com/javase/8/docs/api/java/lang/CharSequence.html)).
For the Unicode code point, **Mathematical Bold Capital "A"** (code point
U+0001D400), this encoded in a UTF-16 string as two units: 0xD835 followed by
0xDC00. So in this case, Java's UTF-16 representation actually utilizes two
*character* (_i.e._ `char`) values to represent one Unicode *code point*.

This document attempts to avoid using the term *character* when
referring to Unicode code points. The reasoning for this is partly
stated above, but also has to do with the overloaded nature of the term
(_e.g._ a user character or *grapheme*). For more details, consult section
[3.4 of the Unicode
Standard](http://www.unicode.org/versions/Unicode4.0.0/ch03.pdf).

Another interesting aspect of the UCS, is a block of code points that is
reserved exclusively for use in the UTF-16 encoding (_i.e._ *surrogate*
code points). As such, strictly speaking, no encoding of Unicode are
allowed to represent the code points in the inclusive range U+D800 to
U+DFFF. In the UTF-16 case, these code points are only allowed to be
used in the encoding to specify characters in the U+00010000 to
U+0010FFFF range. Refer to sections [3.8 and 3.9 of the Unicode
Standard](http://www.unicode.org/versions/Unicode4.0.0/ch03.pdf) for
details.

Ion String
----------

The Ion String data type is a sequence of Unicode *code points*. The Ion
semantics of this are agnostic to any particular Unicode encoding (_e.g._
UTF-16, UTF-8), except for the *concrete* syntax specification of the
Ion binary and text formats.

#### Text Format

The formal Ion Text encoding for the `string` type is specified by the
following EBNF:

    string        ::= '"' short '"' | ( "'''" long "'''" )+

    short         ::= short_char*

    long          ::= long_char*

    short_char    ::= (<any valid Unicode code point> - ('\' | control_char | '"'))
                  |   common_escape
                  |   nl_escape

    long_char     ::= (<any valid Unicode code point> - ('\' | control_char | "'''"))
                  |   common_escape
                  |   nl_escape
                  |   nl_raw

    nl_escape     ::= '\' nl_raw

    common_escape ::= '\' ( 'a' | 'b' | 't' | 'n' | 'f' | 'r' | 'v' | '?' | '0' | '\' | '/' | 'U' | 'u' | 'x' )

    nl_raw        ::= U+000A | U+000D | U+000D U+000A

    control_char  ::= <U+0000 to U+001F>

Multiple Ion long `string` literals that are adjacent to each other by
zero or more whitespace are concatenated automatically. For example the
following two blocks of Ion text syntax are semantically equivalent.
Note that short `string` literals do not exhibit this behavior.

    "1234"    '''Hello'''    '''World'''

    "1234"    "HelloWorld"

Each individual long `string` literal must be a valid Unicode character
sequence when unescaped. The following examples are invalid due to
splitting Unicode escapes, an escaped surrogate pair, and a common
escape, respectively.

    '''\u'''    '''1234'''

    '''\U0000'''    '''1234'''

    '''\uD800'''    '''\uDC00'''

    '''\'''    '''n'''

Within long `string` literals unescaped newlines are normalized such that
U+000D U+000A pairs (CARRIAGE RETURN and LINE FEED respectively) and U+000D are
replaced with U+000A. This is to facilitate compatibility across operating
systems.

Normalization can be subverted by using a combination of escapes:

    CARRIAGE RETURN only:
    '''one\r\
    two'''

    CARRIAGE RETURN and LINE FEED:
    '''one\r
    two'''

The `nl_escape` is not replaced with any characters (_i.e._ the newline is
removed). In addition, the following table describes the `string` escape
sequences that have direct code point replacement for both all strings.

<table>
<thead>
<tr class="header">
<th align="left">Unicode Code Point</th>
<th align="left">Ion Escape</th>
<th align="left">Semantics</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><code>U+0007</code></td>
<td align="left"><code>\a</code></td>
<td align="left">BEL (alert)</td>
</tr>
<tr class="even">
<td align="left"><code>U+0008</code></td>
<td align="left"><code>\b</code></td>
<td align="left">BS (backspace)</td>
</tr>
<tr class="odd">
<td align="left"><code>U+0009</code></td>
<td align="left"><code>\t</code></td>
<td align="left">HT (tab)</td>
</tr>
<tr class="even">
<td align="left"><code>U+000A</code></td>
<td align="left"><code>\n</code></td>
<td align="left">LF (linefeed)</td>
</tr>
<tr class="odd">
<td align="left"><code>U+000C</code></td>
<td align="left"><code>\f</code></td>
<td align="left">FF (form feed)</td>
</tr>
<tr class="even">
<td align="left"><code>U+000D</code></td>
<td align="left"><code>\r</code></td>
<td align="left">CR (carriage return)</td>
</tr>
<tr class="odd">
<td align="left"><code>U+000B</code></td>
<td align="left"><code>\v</code></td>
<td align="left">VT (vertical tab)</td>
</tr>
<tr class="even">
<td align="left"><code>U+0022</code></td>
<td align="left"><code>\&quot;</code></td>
<td align="left">double quote</td>
</tr>
<tr class="odd">
<td align="left"><code>U+0027</code></td>
<td align="left"><code>\'</code></td>
<td align="left">single quote</td>
</tr>
<tr class="even">
<td align="left"><code>U+003F</code></td>
<td align="left"><code>\?</code></td>
<td align="left">question mark</td>
</tr>
<tr class="odd">
<td align="left"><code>U+005C</code></td>
<td align="left"><code>\\</code></td>
<td align="left">backslash</td>
</tr>
<tr class="even">
<td align="left"><code>U+002F</code></td>
<td align="left"><code>\/</code></td>
<td align="left">forward slash</td>
</tr>
<tr class="odd">
<td align="left"><code>U+0000</code></td>
<td align="left"><code>\0</code></td>
<td align="left">NUL (null character)</td>
</tr>
</tbody>
</table>

The for the Unicode ordinal `string` escapes, `\U`, `\u`, and `\x`, the
escape must be followed by a number of hexadecimal digits as described below.

<table>
<thead>
<tr class="header">
<th align="left"><p>Unicode<br />
Code Point</p></th>
<th align="left"><p>Ion<br />
Escape</p></th>
<th align="left"><p>Semantics</p></th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><code>U+<em>HHHHHHHH</em></code></td>
<td align="left"><code>\U<em>HHHHHHHH</em></code></td>
<td align="left">8-digit hexadecimal Unicode code point</td>
</tr>
<tr class="even">
<td align="left"><code>U+<em>HHHH</em></code></td>
<td align="left"><code>\u</em>HHHH</em></code></td>
<td align="left">4-digit hexadecimal Unicode code point; equivalent to <code>\U0000<em>HHHH</em></code></td>
</tr>
<tr class="odd">
<td align="left"><code>U+00<em>HH</em></code></td>
<td align="left"><code>\x<em>HH</em></code></td>
<td align="left">2-digit hexadecimal Unicode code point; equivalent to <code>\u00<em>HH</em></code> and <code>\U000000<em>HH</em></code></td>
</tr>
</tbody>
</table>

Ion does not specify the behavior of specifying invalid Unicode code
points or *surrogate* code points (used only for UTF-16) using the
escape sequences. It is highly recommended that Ion implementations
reject such escape sequences as they are not proper Unicode as specified
by the standard. To this point, consider the Ion `string` sequence,
`"\uD800\uDC00"`. A compliant parser may throw an exception because
surrogate characters are specified outside of the context of UTF-16,
accept the string as a technically invalid sequence of two Unicode code
points (_i.e._ U+D800 and U+DC00), or interpret it as the single Unicode
code point U+00010000. In this regard, the Ion `string` data type does
not conform to the Unicode specification. A strict Unicode
implementation of the Ion text should not accept such sequences.

#### Binary Format

The Ion *binary format* encodes the `string` data type directly as a
sequence of UTF-8 octets. A strict, Unicode compliant implementation of
Ion should not allow invalid UTF-8 sequences (_e.g._ surrogate code
points, overlong values, and values outside of the inclusive range,
U+0000 to U+0010FFFF).

Ion Clob
--------

An Ion `clob` type is similar to the `blob` type except that the
denotation in the Ion text format uses an ASCII-based string notation
rather than a *base64* encoding to denote its binary value. It is
important to make the distinction that `clob` is a sequence of raw
octets and `string` is a sequence of Unicode code points.

#### Text Format

The formal Ion Text encoding for the `clob` type is specified by the
following EBNF:

    clob          ::= '{' '{' '"' short '"' | ( "'''" long "'''" )+ '}' '}'
     
    short         ::= short_char*

    long          ::= long_char*

    short_char    ::= <any printable ascii character or
                       the new line (U+000A, U+000D, U+000D followed by U+000A)>
                  |   common_escape
                  |   nl_escape

    long_char     ::= <any printable ascii character>
                  |   common_escape
                  |   nl_escape

    nl_escape     ::= '\' U+000A | '\' U+000D | '\' U+000D U+000A

    common_escape ::= '\' ( 'a' | 'b' | 't' | 'n' | 'f' | 'r' | 'v' | '?' | '0' | '\' | '/' | 'x' )

Similar to `string`, multiple long string literals within an Ion
`clob`that are adjacent to each other by zero or more whitespace are
concatenated automatically. Within a `clob`, only one short string
literal or multiple long string literals are allowed. For example, the
following two blocks of Ion text syntax are semantically equivalent.

    {{ '''Hello'''    '''World''' }}

    {{ "HelloWorld" }}

The rules for the quoted strings within a `clob` follow the similarly to
the `string` type, except for the following exceptions. Unicode newline
characters in long strings and all verbatim ASCII characters are
interpreted as their ASCII octet values. Non-printable ASCII and
non-ASCII Unicode code points are not allowed un-escaped in the string
bodies. Furthermore, the following table describes the `clob` string
escape sequences that have direct octet replacement for both all
strings.

<table>
<thead>
<tr class="header">
<th align="left">Octet</th>
<th align="left">Ion Escape</th>
<th align="left">Semantics</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">0x07</td>
<td align="left"><code>\a</code></td>
<td align="left">ASCII BEL (alert)</td>
</tr>
<tr class="even">
<td align="left">0x08</td>
<td align="left"><code>\b</code></td>
<td align="left">ASCII BS (backspace)</td>
</tr>
<tr class="odd">
<td align="left">0x09</td>
<td align="left"><code>\t</code></td>
<td align="left">ASCII HT (tab)</td>
</tr>
<tr class="even">
<td align="left">0x0A</td>
<td align="left"><code>\n</code></td>
<td align="left">ASCII LF (line feed)</td>
</tr>
<tr class="odd">
<td align="left">0x0C</td>
<td align="left"><code>\f</code></td>
<td align="left">ASCII FF (form feed)</td>
</tr>
<tr class="even">
<td align="left">0x0D</td>
<td align="left"><code>\r</code></td>
<td align="left">ASCII CR (carriage return)</td>
</tr>
<tr class="odd">
<td align="left">0x0B</td>
<td align="left"><code>\v</code></td>
<td align="left">ASCII VT (vertical tab)</td>
</tr>
<tr class="even">
<td align="left">0x22</td>
<td align="left"><code>\&quot;</code></td>
<td align="left">ASCII double quote</td>
</tr>
<tr class="odd">
<td align="left">0x27</td>
<td align="left"><code>\'</code></td>
<td align="left">ASCII single quote</td>
</tr>
<tr class="even">
<td align="left">0x3F</td>
<td align="left"><code>\?</code></td>
<td align="left">ASCII question mark</td>
</tr>
<tr class="odd">
<td align="left">0x5C</td>
<td align="left"><code>\\</code></td>
<td align="left">ASCII backslash</td>
</tr>
<tr class="even">
<td align="left">0x2F</td>
<td align="left"><code>\/</code></td>
<td align="left">ASCII forward slash</td>
</tr>
<tr class="odd">
<td align="left">0x00</td>
<td align="left"><code>\0</code></td>
<td align="left">ASCII NUL (null character)</td>
</tr>
</tbody>
</table>

The for the ordinal `clob` escape, `\x`, the escape must be followed by
must be followed by a number of hexadecimal digits as described below.
Note that `clob` does not support the `\u` and `\U` escape as a `clob`
is raw binary and **not** a Unicode encoding.

<table>
<thead>
<tr class="header">
<th align="left">Octet</th>
<th align="left">Ion Escape</th>
<th align="left">Semantics</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">0x<em>HH</em></td>
<td align="left"><code>\x<em>HH</em></code></td>
<td align="left">2-digit hexadecimal octet</td>
</tr>
</tbody>
</table>

It is important to note that `clob` is a binary type that is designed
for binary values that are either text encoded in a code page that is
ASCII compatible or should be octet editable by a human (escaped string
syntax vs. base64 encoded data). Clearly non-ASCII based encodings will
not be very readable (_e.g._ the `clob` for the EBCDIC encoded string
representing "hello" could be denoted as
`{{ "\xc7\xc1%%?" }}`).

#### Binary Format

This is represented directly as the octet values in the `clob` value.

References
----------

  * [The Unicode Home Page](http://unicode.org)
  * [Unicode Encoding FAQ](http://www.unicode.org/faq/utf_bom.html)
  * [Wikipedia UTF-16 Article](http://en.wikipedia.org/wiki/UTF-16)
  * [Wikipedia UTF-8 Article](http://en.wikipedia.org/wiki/UTF-8)
