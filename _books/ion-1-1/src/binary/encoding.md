# Ion 1.1 Binary Encoding

A binary Ion stream consists of an [_Ion version marker_](../glossary.md) followed by a series of
[value literals](values.md), [encoding expressions](e_expressions.md), and/or
[directives](directives.md). The stream may be terminated by an
[`end` directive](directives.md); anything after it is not part of the stream.

Value literals, e-expressions, and directives each begin with an
[opcode](opcodes.md) that indicates what the next expression represents and
how the bytes that follow should be interpreted.