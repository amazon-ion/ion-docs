# Ion 1.1 Text Encoding

The Ion text encoding is a stream of UTF-8 encoded text.
It is intended to be easy to read and write by humans in any text-based application.

Whitespace is insignificant and is only required where necessary to separate tokens, and C-style comments 
(either block or in-line) are treated as whitespace (and are not part of the binary encoding).

A text Ion 1.1 stream begins with the Ion 1.1 [version marker](../todo.md) (`$ion_1_1`) followed by a series of
[value literals](values.md) and/or [encoding expressions](e_expressions.md).
