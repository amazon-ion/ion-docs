## Defining macros

A macro is defined using a `macro` clause within a [module](../modules.md)'s [`macro_table` clause](../modules.md#macro_table).

### Syntax
```ion
(macro name signature template)
```

| Argument                                        | Description                                                                                               |
|-------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| [`name`](#macro-names)                          | A unique name assigned to the macro or--to construct an anonymous macro--`null`.                          |
| [`signature`](#macro-signatures)                | An s-expression enumerating the parameters this macro accepts.                                            |
| [`template`](#template-definition-language-tdl) | A template definition language (TDL) expression that can be evaluated to produce zero or more Ion values. |

### Macro names

Syntactically, macro names are [identifiers](../modules.md#identifiers). Each macro name in a macro table must be unique.

In some circumstances, it may not make sense to name a macro. (For example, when the macro is generated automatically.) In such cases, authors may set the macro name to `null` or `null.symbol` to indicate that the macro does not have a name. Anonymous macros can only be referenced by their address in the macro table.

### Macro Parameters

Macros accept zero or more parameters.

Each parameter is comprised of three elements:
1. A name
2. An encoding
3. A cardinality

#### Parameter names

A parameter's name is an [identifier](../modules.md#identifiers). The name is required; any non-identifier (including `null`, quoted symbols, `$0`, or a non-symbol) found in parameter-name position will cause the reader to raise an error.

All of a macro's parameters must have unique names.

#### Parameter encodings

In binary Ion, the default encoding for all parameters is _tagged_. Each argument passed into the macro from the callsite is prefixed by an [opcode](../binary/opcodes.md) (or "tag") that indicates the argument's type and length.

Parameters may choose to specify an alternative encoding to make the corresponding arguments' binary representation more compact and/or fixed width. These "tagless" encodings do not begin with an opcode, an arrangement which saves space but also limits the domain of values they can each represent. Arguments passed to tagless parameters cannot be `null`, cannot be annotated, and may have additional range restrictions.

To specify an encoding, the [parameter name](#parameter-names) is annotated with one of the following tokens:

| Tagless encodings                    | Description                                                       |
|--------------------------------------|-------------------------------------------------------------------|
| `flex_int`                           | Variable-width signed int                                         |
| `flex_uint`                          | Variable-width unsigned int                                       |
| `int8`  `int16`   `int32`   `int64`  | Fixed-width signed int                                            |
| `uint8` `uint16`  `uint32`  `uint64` | Fixed-width unsigned int                                          |
| `float16` `float32` `float64`        | Fixed-width float                                                 |
| `flex_symbol`                        | [`FlexSym`](../binary/primitives/flex_sym.md)-encoded SID or text |


#### Parameter cardinalities

A parameter name may optionally be followed by a _cardinality modifier_. This is a sigil that indicates how many values the parameter expects the corresponding argument expression to produce when it is evaluated.

| Modifier | Cardinality         |
|:--------:|---------------------|
|   `!`    | exactly-one value   |
|   `?`    | zero-or-one value   |
|   `+`    | one-or-more values  |
|   `*`    | zero-or-more values |

If no modifier is specified, the parameter's cardinality will default to exactly-one.

If an argument expression expands to a number of values that the cardinality forbids, the reader must raise an error.

### Macro signatures

A macro signature is an s-expression containing a series of parameter definitions.

### Template definition language (TDL)

<!-- TODO -->