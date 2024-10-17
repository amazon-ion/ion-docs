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

#### Example macro clause
```ion
//      ┌─── name
//      │     ┌─── signature
//     ┌┴┐ ┌──┴──┐
(macro foo (x y z)
  {           // ─┐
    x: (%x),  //  │
    y: (%y),  //  ├─ template
    z: (%z),  //  │
  }           // ─┘
)
```

### Macro names

Syntactically, macro names are [identifiers](../modules.md#identifiers). Each macro name in a macro table must be unique.

In some circumstances, it may not make sense to name a macro. (For example, when the macro is generated automatically.) In such cases, authors may set the macro name to `null` or `null.symbol` to indicate that the macro does not have a name. Anonymous macros can only be referenced by their address in the macro table.

### Macro Parameters

A _parameter_ is a named stream of Ion values. The stream's contents are determined by the macro's invocation.
A macro's parameters are declared in the [macro signature](#macro-signatures).

Each parameter declaration is comprised of three elements:
1. A [name](#parameter-names)
2. An optional [encoding](#parameter-encodings)
3. An optional [cardinality](#parameter-cardinalities)

#### Example parameter declaration
```ion
//     ┌─── encoding
//     │      ┌─── name
//     │      │┌─── cardinality
// ┌───┴───┐  ││
   flex_uint::x*
```

#### Parameter names

A parameter's name is an [identifier](../modules.md#identifiers). The name is required; any non-identifier (including `null`, quoted symbols, `$0`, or a non-symbol) found in parameter-name position will cause the reader to raise an error.

All of a macro's parameters must have unique names.

#### Parameter encodings

In binary Ion, the default encoding for all parameters is _tagged_. Each argument passed into the macro from the callsite is prefixed by an [opcode](../binary/opcodes.md) (or "tag") that indicates the argument's type and length.

Parameters may choose to specify an alternative encoding to make the corresponding arguments' binary representation more compact and/or fixed width. These "tagless" encodings do not begin with an opcode, an arrangement which saves space but also limits the domain of values they can each represent. Arguments passed to tagless parameters cannot be `null`, cannot be annotated, and may have additional range restrictions.

To specify an encoding, the [parameter name](#parameter-names) is annotated with one of the following tokens:

| Tagless encodings                    | Description                                                       |
|--------------------------------------|-------------------------------------------------------------------|
| `flex_int`                           | Variable-width, signed int                                        |
| `flex_uint`                          | Variable-width, unsigned int                                      |
| `int8`  `int16`   `int32`   `int64`  | Fixed-width, signed int                                           |
| `uint8` `uint16`  `uint32`  `uint64` | Fixed-width, unsigned int                                         |
| `float16` `float32` `float64`        | Fixed-width float                                                 |
| `flex_symbol`                        | [`FlexSym`](../binary/primitives/flex_sym.md)-encoded SID or text |

When writing text Ion, the declared encoding does not affect how values are serialized.
However, it does constrain the domain of values that that parameter will accept.
When transcribing from text to binary, it must be possible to serialize all values passed as an argument using the parameter's declared encoding.
This means that parameters with a primitive encoding cannot be annotated or a `null` of any type.
If an `int` or a `float` is being passed to a parameter with a fixed-width encoding,
that value must fit within the range of values that can be represented by that width.
For example, the value `256` cannot be passed to a parameter with an encoding of `uint8` because a `uint8` can only represent values in the range `[0, 255]`.

#### Parameter cardinalities

A parameter name may optionally be followed by a _cardinality modifier_. This is a sigil that indicates how many values the parameter expects the corresponding argument expression to produce when it is evaluated.

| Modifier |         Cardinality |
|:--------:|--------------------:|
|   `?`    |   zero-or-one value |
|   `*`    | zero-or-more values |
|   `!`    |   exactly-one value |
|   `+`    |  one-or-more values |

If no modifier is specified, the parameter's cardinality will default to exactly-one.
An `exactly-one` parameter will always expand to a stream containing a single value.

Parameters with a cardinality other than `exactly-one` are called _variadic parameters_.

If an argument expression expands to a number of values that the cardinality forbids, the reader must raise an error.

##### Optional parameters

Parameters with a cardinality that can accept an empty expression group as an argument (`?` and `*`) are called
_optional parameters_. In text Ion, their corresponding arguments can be elided from e-expressions and TDL macro
invocations when they appear in tail position. When an argument is elided, it is treated as though an explicit
empty group `(::)` had been passed in its place.

In contrast, parameters with a cardinality that cannot accept an empty group (`!` and `+`) are called _required
parameters_. Required parameters can never be elided.

```ion
(:set_macros
    (foo (x y? z*) // `x` is required, `y` and `z` are optional
        [x, y, z]
    )
)

// `z` is a populated expression group
(:foo 1 2 (:: 3 4 5)) => [1, 2, 3, 4, 5]

// `z` is an empty expression group
(:foo 1 2 (::))       => [1, 2]

// `z` has been elided
(:foo 1 2)            => [1, 2]

// `y` and `z` have been elided
(:foo 1)              => [1]

// `x` cannot be elided
(:foo)                => ERROR: missing required argument `x`
```

Optional parameters that are _not_ in tail position cannot be elided, as this would
cause them to appear in a position corresponding to a different argument.

```ion
(:set_macros
    (foo (x? y) // `x` is optional, `y` is required
        [x, y]
    )
)

(:foo (::) 1) => [(::), 1] => [1]
(:foo 1)                   => ERROR: missing required argument `y`
```

### Macro signatures

A macro's _signature_ is the ordered sequence of parameters which an invocation of that macro must define.
Syntactically, the signature is an s-expression of [parameter declarations](#macro-parameters).

#### Example macro signature
```ion
(w flex_uint::x* float16::y? z+)
```

| Name |  Encoding   |  Cardinality   |
|:----:|:-----------:|:--------------:|
| `w`  |  `tagged`   | `exactly-one`  |
| `x`  | `flex_uint` | `zero-or-more` |
| `y`  |  `float16`  | `zero-or-one`  |
| `z`  |  `tagged`   | `one-or-more`  |

### Template definition language (TDL)

The macro's _template_ is a single Ion value that defines how a reader should expand invovations of the macro.
Ion 1.1 introduces a template definition language (TDL) to express this process in terms of the macro's parameters.
TDL is a small language with only a few constructs.

A TDL _expression_ can be any of the following:
1. A literal [Ion scalar](#ion-scalars)
2. A macro invocation
3. A variable expansion
4. A quasi-literal Ion container
5. A [special form](special_forms.md)

In terms of its encoding, TDL is "just Ion."
As you shall see in the following sections, the constructs it introduces are written as s-expressions with a distinguishing leading value or values.

A [grammar](#tdl-grammar) for TDL can be found at the end of this chapter.

#### Ion scalars

Ion scalars are interpreted literally. These include values of any type except `list`, `sexp`, and `struct`.
`null` values of any type—even `null.list`, `null.sexp`, and `null.struct`—are also interpreted literally.

##### Examples
These macros are constants; they take no parameters.
When they are invoked, they expand to a stream of a single value: the Ion scalar acting as the template expression.
```ion
$ion_encoding::(
  (macro_table
    (macro greeting () "hello")
    (macro birthday () 1996-10-11)
    // Annotations are also literal
    (macro price () USD::29.95)
  )
)

(:greeting) => "hello"
(:birthday) => 1996-10-11
(:price)    => USD::29.95
```

#### Macro invocations

Macro invocations call an existing macro.
The invoked macro could be a [system macro](system_macros.md), a macro imported from a [shared module](../todo.md), or a macro previously defined in the current scope.

Syntactically, a macro invocation is an s-expression whose first value is the operator `.` and whose second value is a macro reference.

##### Grammar
```bnf
macro-invocation   ::= '(.' macro-ref macro-arg* ')',

macro-ref          ::= (module-name '::')? (macro-name | macro-address)

macro-arg          ::= expression | arg-group

macro-name         ::= ion-identifier

macro-address      ::= unsigned-ion-integer

arg-group          ::= '(::' expression* ')'
```

##### Invocation syntax illustration
```ion
// Invoking a macro defined in the same module by name.
(.macro_name              arg1 arg2 /*...*/ argN)

// Invoking a macro defined in another module by name.
(.module_name::macro_name arg1 arg2 /*...*/ argN)

// Invoking a macro defined in the same module by its address.
(.0              arg1 arg2 /*...*/ argN)

// Invoking a macro defined in a different module by its address.
(.module_name::0 arg1 arg2 /*...*/ argN)
```

##### Examples
```ion
$ion_encoding::(
  (macro_table
    // Calls the system macro `values`, allowing it to produce a stream of three values.
    (macro nephews () (.values Huey Dewey Louie))

    // Calls a macro previously defined in this module, splicing its result
    // stream into a list.
    (macro list_of_nephews () [(.nephews)])
  )
)

(:nephews)         => Huey Dewey Louie
(:list_of_nephews) => [Huey, Dewey, Louie]
```

> [!IMPORTANT]
> **There are no forward references in TDL.**
>  If a macro definition includes an invocation of a name or address that is not already valid, the reader must raise an error.
>
> ```ion
> $ion_encoding::(
>   (macro_table
>     (macro list_of_nephews () [(.nephews)])
>     //                          ^^^^^^^^
>     // ERROR: Calls a macro that has not yet been defined in this module.
>     (macro nephews () (.values Huey Dewey Louie))
>   )
> )
> ```

#### Variable expansion

Templates can insert the contents of a macro parameter into their output by using a _variable expansion_,
an s-expression whose first value is the operator `%` and whose second and final value is the variable name of the parameter to expand.

If the variable name does not match one of the declared macro parameters, the implementation must raise an error.

##### Grammar
```bnf
variable-expansion ::= '(%' variable-name ')'

variable-name      ::= ion-identifier
```

##### Examples

```ion
$ion_encoding::(
  (macro_table
    // Produces a stream that repeats the content of parameter `x` twice.
    (macro twice (x*) (.values (%x) (%x)))
  )
)

(:twice foo)     => foo foo
(:twice "hello") => "hello" "hello"
(:twice 1 2 3)   => 1 2 3 1 2 3
```

#### Quasi-literal Ion containers

When an Ion container appears in a template definition, it is interpreted _almost_ literally.

Each nested value in the container is inspected.
* **If the value is an Ion scalar**, it is added to the output as-is.
* **If the value is a variable expansion**, the stream bound to that variable name is added to the output.
    The variable expansion literal (for example: `(%name)`) is discarded.
* **If the value is a macro invocation**, the invocation is evaluated and the resulting stream is added to the output.
    The macro invocation literal (for example: `(.name 1 2 3)`) is discarded.
* **If the value is a container**, the reader will recurse into the container and repeat this process.

##### Expansion within a sequence

When the container is a list or s-expression, the values in the nested expression's expansion are spliced into the sequence at the site of the expression.
If the expansion was empty, no values are spliced into the container.

```ion
$ion_encoding::(
  (macro_table
    (macro bookend_list (x y*) [(%x), (%y), (%x)])
    (macro bookend_sexp (x y*) ((%x) (%y) (%x)))
  )
)

(:bookend_list ! a b c) => ['!', a, b, c, '!']
(:bookend_sexp ! a b c) => (! a b c !)

(:bookend_sexp !) => (! !)
```

##### Expansion within a struct

When the container is a struct, the expansion of each field value is paired with the corresponding field name.
If the expansion produces a single value, a single field with that name will be spliced into the parent struct.
If the expansion produces multiple values, a field with that name will be created for each value and spliced into the parent struct.
If the expansion was empty, no fields are spliced into the parent struct.

##### Examples

```ion
$ion_encoding::(
  (macro_table
    (macro resident (id names*)
        {
            town: "Riverside",
            id: (.make_string "123-" (%id)),
            name: (%names)
        }
     )
  )
)

(:resident "abc" "Alice") =>
{
  town: "Riverside",
  id: "123-abc",
  name: "Alice"
}

(:resident "def" "John" "Jacob" "Jingleheimer" "Schmidt") =>
{
  town: "Riverside",
  id: "123-def",
  name: "John",
  name: "Jacob",
  name: "Jingleheimer",
  name: "Schmidt",
}

(:resident "ghi") =>
{
  town: "Riverside",
  id: "123-ghi",
}
```

#### Special forms

```bnf
special-form       ::= '(.' ('$ion::')?  special-form-name expression* ')'
```

Special forms are similar to macro invocations, but they have their own expansion rules.
See [_Special forms_](special_forms.md) for the list of special forms and a description of each.

Note that unlike macro expansions, special forms cannot accept argument groups.

#### TDL Grammar
```bnf
expression         ::= ion-scalar | ion-ql-container | operation | variable-expansion

ion-scalar         ::= ; <Any Ion scalar value>

ion-ql-container   ::= ; <An Ion container quasi-literal>

operation          ::= macro-invocation | special-form

variable-expansion ::= '(%' variable-name ')'

variable-name      ::= ion-identifier

macro-invocation   ::= '(.' macro-ref macro-arg* ')'

special-form       ::= '(.' ('$ion::')?  special-form-name expression* ')'

macro-ref          ::= (module-name '::')? (macro-name | macro-address)

macro-arg          ::= expression | arg-group

macro-name         ::= ion-identifier

macro-address      ::= ion-unsigned-integer

arg-group          ::= '(::' expression* ')'
```

