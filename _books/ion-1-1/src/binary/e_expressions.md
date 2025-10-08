
## Encoding Expressions

> [!NOTE]
> This chapter focuses on the binary encoding of e-expressions.
> The [_Macros_](../macros.md) section explains what they are and how they are used.

### E-expression with the address in the opcode

Opcodes `0x00`-`0x47` are single byte macro addresses.

If the value of the opcode is less than `72` (`0x48`), it represents an E-expression invoking the macro at the
corresponding __address__—-an offset within the local macro table.

#### Invocation of macro address `7`
```
┌──── Opcode in 00-47 range indicates an e-expression
│     where the opcode value is the macro address
│
07
└── FixedUInt 7
```

#### Invocation of macro address `31`
```
┌──── Opcode in 00-47 range indicates an e-expression
│     where the opcode value is the macro address
│
1F
└── FixedUInt 31
```

Note that the opcode alone tells us which macro is being invoked, but it does not supply enough information for the
reader to parse any arguments that may follow. The parsing of arguments is described in detail in the section
[_E-expression argument encoding_](#e-expression-argument-encoding).

### E-expressions with extended addresses

Opcodes `0x48`-`0x4F` are extensible macro addresses, with an offset of 72.
The opcodes `0x48` through `0x4F` share the same 5 most-significant bits. The 3 least-significant bits are used as the
3 least-significant bits of the macro address.
The opcode is followed by a `FlexUInt`, which, once decoded, represents the most-significant bits of the macro address.
Finally, the offset of 72 is added.

To get the macro address from the opcode and `FlexUInt` is straightforward, and can be implemented using bitwise operations or simple arithmetic operations.
```text
// Given an `opcode` and `flexUInt`...
let lsb = opcode & 0b111           // or opcode - 0x48
let msb = flexUInt << 3            // or flexUInt * 8
let macroId = (msb | lsb) + 72     // or msb + lsb + 72
```
The reverse transformation is also simple:
```text
// Given `macroId`...
let opcode = 0x48 | (macroId & 0b111)   // or 0x48 + (macroId % 8)
let flexUInt = macroId >>> 3            // or macroId / 8 
```

| Macro Address Range  | Opcode Range  | Encoded size, including opcode |
|----------------------|:-------------:|-------------------------------:|
| `0`..`71`            | `0x00`-`0x47` |                              1 |
| `72`..`1095`         | `0x48`-`0x4F` |                              2 |
| `1096`..`131143`     | `0x48`-`0x4F` |                              3 |
| `131144`..`16777287` | `0x48`-`0x4F` |                              4 |

This table stops at 16777287, but the encoding does not impose any limit on the number of macro addresses.
Practically, Ion implementations will have limits based on the programming language and the runtime environment used.

#### Invocation of macro address `287`

To encode macro address 287:

* Subtract 72 to get `215` (`0b11010111`)
* Take the 3 least-significant bits (`111`) and add them to `0x48` (`0b01001000`) to get `0x4F` (`0b01001111`). 
  The opcode will be `0x4F`.
* Shift `215` left by 3 (discarding the 3 least-significant bits), and then encode the result (`26`) as a `FlexUInt`.
  The `FlexUInt` encoding of `26` is `0x35`. 

```
┌──── Opcode in range 48-4F indicates a macro address with extended address.
│     Least-significant 3 bits are `111`
│  ┌──── FlexUInt 26
4F 35
```

### Length-prefixed E-Expressions

The opcode `F4` represents an E-expression with a `FlexUInt` macro address and a `FlexUInt` length prefix.
The length prefix indicates the number of argument bytes for the e-expression.
The encoding of the arguments themselves are covered in [E-expression argument encoding](#e-expression-argument-encoding).

```
┌──── Opcode F4 indicates FlexUInt address and FlexUInt length prefix     
│  ┌──── FlexUInt 26
│  │   ┌──── FlexUInt 6
F4 35 0D __ __ __ __ __ __
         └───────┬───────┘
          6 argument bytes
```

## E-expression argument encoding

The example invocations in prior sections have demonstrated how to encode an invocation of the simplest
form of macro--one with no parameters. This section explains how to encode macro invocations when they take
parameters.

The encoding of E-Expression arguments follows the macro address (and length-prefix if present).
For every placeholder in the macro template, there must be exactly one argument expression provided.

### Tagged Arguments

When a macro parameter does not specify an encoding (the parameter name is not annotated), arguments
passed to that parameter use the 'tagged' encoding. The argument begins with a leading [opcode](opcodes.md)
that dictates how to interpret the bytes that follow.

This is the same encoding used for values in other Ion 1.1 contexts like lists, s-expressions, or at the top level.

When invoking a template macro, the E-expression must have one argument for each parameter in the macro signature.
Every argument must be exactly one value or explicitly an _absent argument_.

The _absent argument_ is a special construct used in macro invocations to explicitly indicate that no value is provided for a particular parameter. The absent argument is distinct from `NOP` and serves a different purpose.
Opcode `0xEB` indicates an absent argument; no additional bytes follow.



##### Example – two tagged arguments

Given a macro definition:
```ion
(point { x: (:?), y: (:? 0) })
```
This macro has two tagged parameters, the second of which has a default value.

**Encoding of `(:point 2 3)`**
```
┌──── E-expression with macro address 0 (assuming point is macro 0)
│  ┌─── Argument 1: integer 2
│  │     ┌─── Argument 2: integer 3
00 61 02 61 03
```

This would expand to `{ x: 2, y: 3 }`.


**Encoding of `(:point 5 (:))`**
```
┌──── E-expression with macro address 0 (assuming point is macro 0)
│  ┌─── Argument 1: integer 5
│  │     ┌─── Argument 2: absent argument
00 61 05 E0
```

This would expand to `{ x: 5, y: 0 }` since the second argument is absent and `y` has a default value of 0.

**Encoding of `(:point (:) 10)`**
```
┌──── E-expression with macro address 0
│  ┌─── Argument 1: absent argument
│  │  ┌─── Argument 2: integer 10
00 E0 61 0A
```
This would expand to `{ y: 10 }` since the first argument is absent and `x` has no default value.

An absent argument is encoded the same way regardless of whether the placeholder has a default value.


### Tagless Arguments

In contrast to the [tagged encoding](#tagged-arguments), [_tagless encodings_](../todo.md) do not begin with an opcode.
This means that they are potentially more compact than a tagged type, but are also less flexible.
Because tagless encodings do not have an opcode, tagless arguments cannot have annotation sequences nor can the argument itself be absent.

Primitive encodings are self-delineating, either by having a statically known size in bytes or by including length
information in their serialized form.

Given the following macro definition
```ion
(foo { foo: (:?\int8\), bar: (:?\int16\), baz: (?:\string\) })
```

The text E-expression `(:foo 1 2 "three")` would be encoded like this:
```
┌──── Opcode 0x00 is less than 0x48; this is an e-expression
│     invoking the macro at address 0.
│  ┌─── First argument: 1-byte FixedInt 1
│  │    ┌─── Second argument: 2-byte FixedInt 2
│  │    │           ┌─── Third argument: length-prefixed string "three"
│  │  ┌─┴─┐ ┌───────┴───────┐    
00 03 02 00 0B 74 68 72 65 65
            │  └──────┬─────┘
            │         └── 5 UTF-8 bytes
            └──────────── FlexUInt (Length) 5    
```
