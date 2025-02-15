# Escape Characters

### Strings and Symbols

The Ion text format supports unicode escape sequences only within quoted strings and symbols.
Ion supports most of the escape sequences defined by C++, Java, and JSON.

The following sequences are allowed:

| Unicode Code Point | Ion Escape                 | Meaning                                |
|:-------------------|:---------------------------|:---------------------------------------|
| `U+0000`           | `\0`                       | NUL                                    |
| `U+0007`           | `\a`                       | alert BEL                              |
| `U+0008`           | `\b`                       | backspace BS                           |
| `U+0009`           | `\t`                       | horizontal tab HT                      |
| `U+000A`           | `\n`                       | linefeed LF                            |
| `U+000B`           | `\v`                       | vertical tab VT                        |
| `U+000C`           | `\f`                       | form feed FF                           |
| `U+000D`           | `\r`                       | carriage return CR                     |
| `U+0022`           | `\"`                       | double quote                           |
| `U+0027`           | `\'`                       | single quote                           |
| `U+002F`           | `\/`                       | forward slash                          |
| `U+003F`           | `\?`                       | question mark                          |
| `U+005C`           | `\\`                       | backslash                              |
| nothing            | <code>\\<em>NL</em></code> | escaped NL expands to nothing          |
| `U+00HH`           | `\xHH`                     | 2-digit hexadecimal Unicode code point |
| `U+HHHH`           | `\uHHHH`                   | 4-digit hexadecimal Unicode code point |
| `U+HHHHHHHH`       | `\UHHHHHHHH`               | 8-digit hexadecimal Unicode code point |


Any other sequence following a backslash is an error.

Note that Ion does not support the following escape sequences:

* Java's extended Unicode markers, _e.g._, `"\uuuXXXX"`
* General octal escape sequences, `\OOO`

### Clobs

The rules for the quoted strings within a `clob` follow similarly to the `string` type, with the following exceptions.
Unicode newline characters in long strings and all verbatim ASCII characters are interpreted as their ASCII octet values.
Non-printable ASCII and non-ASCII Unicode code points are not allowed un-escaped in the string bodies.
Furthermore, the following table describes the `clob` string escape sequences that have direct octet replacement for both all strings.

| Octet   | Ion Escape                  | Meaning                       |
|:--------|:----------------------------|:------------------------------|
| `0x00`  | `\0`                        | NUL                           |
| `0x07`  | `\a`                        | alert BEL                     |
| `0x08`  | `\b`                        | backspace BS                  |
| `0x09`  | `\t`                        | horizontal tab HT             |
| `0x0A`  | `\n`                        | linefeed LF                   |
| `0x0B`  | `\v`                        | vertical tab VT               |
| `0x0C`  | `\f`                        | form feed FF                  |
| `0x0D`  | `\r`                        | carriage return CR            |
| `0x22`  | `\"`                        | double quote                  |
| `0x27`  | `\'`                        | single quote                  |
| `0x2F`  | `\/`                        | forward slash                 |
| `0x3F`  | `\?`                        | question mark                 |
| `0x5C`  | `\\`                        | backslash                     |
| `0xHH`  | <code>\\x<em>HH</em></code> | 2-digit hexadecimal octet     |
| nothing | <code>\\<em>NL</em></code>  | escaped NL expands to nothing |

The `clob` escape `\x` must be followed by two hexadecimal digits.
Note that `clob` does not support the `\u` and `\U` escapes since it represents an octet sequence and **not** a Unicode encoding.

It is important to note that `clob` is a binary type that is designed for binary values that are either text encoded in a
code page that is ASCII compatible or should be octet editable by a human (escaped string syntax vs. base64 encoded data).
Clearly non-ASCII based encodings will not be very readable (_e.g._ the `clob` for the EBCDIC encoded string 
representing "hello" could be denoted as`{% raw %}{{ "\xc7\xc1%%?" }}{% endraw %}`).