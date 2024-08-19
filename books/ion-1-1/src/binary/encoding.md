# Ion 1.1 Binary Encoding

A binary Ion stream consists of an [_Ion version marker_](todo.md) followed by a series of
[value literals](values.md) and/or [encoding expressions](e_expressions.md).

Both value literals and e-expressions begin with an [opcode](opcode.md) that indicates
what the next expression represents and how the bytes that follow should be interpreted.