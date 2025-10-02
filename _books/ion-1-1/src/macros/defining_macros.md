# Defining macros

Macros are defined within directives like `$set_macros` or `$add_macros`, or in [modules](../modules.md).

## Syntax
```ion
(name template)
```

| Argument                                        | Description                                                                                                                    |
|-------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| [`name`](#macro-names)                          | A unique name assigned to the macro. When constructing an anonymous macro `null` is used in the place of a unique name.        |
| [`template`](#template-body)                    | A single Ion value that may contain placeholders.                                                                              |

### Example macro definition
```ion
(foo         // ─── name
  {          // ─┐
    x: (:?), //  │
    y: (:?), //  ├─ template with placeholders
    z: (:?), //  │
  }          // ─┘
)
```

## Macro names

Syntactically, macro names are [identifiers](../text/symbol-tokens.md). Each macro name in a macro table must be unique.

In some circumstances, it may not make sense to name a macro. (For example, when the macro is generated automatically.)
In such cases, authors must use `null` to indicate that the macro does not have a name.
Anonymous macros can only be referenced by their address in the macro table.

## Macro signatures

Macro signatures are derived from the placeholders in the macro template body. The signature is determined by analyzing the placeholders that appear in the template.

**Important:** Within macro definitions, the order of struct fields matters when determining the signature.

### Placeholder types and signatures

The type of placeholder determines the parameter characteristics:

- **Tagged placeholders** `(:?)` - Accept any Ion value, are optional parameters
- **Tagged placeholders with defaults** `(:? default_value)` - Accept any Ion value with a default
- **Tagless placeholders** `(:?\type\)` - Require specific types (from the enumerated set of tagless types), are required parameters

All tagged parameters are optional parameters (can be elided with `(:)`).
All tagless parameters are required parameters (cannot be elided).

### Example signature derivation
```ion
(example {
  a: (:?),           // First parameter: tagged
  b: (:? 10),        // Second parameter: tagged with default
  c: (:?\int8\)      // Third parameter: tagless int8
})
```

This macro accepts 3 arguments:
1. Any Ion value (optional, can be `(:)`)
2. Any Ion value with default 10 (optional, can be `(:)`)
3. An int8 value (required, cannot be null or annotated)

## Template body

The macro's _template_ is a single Ion value that defines how a reader should expand invocations of the macro.

Within the template there may be _placeholders_, which indicate that a macro argument should be substituted into that position in the template body.

**Important restrictions:**
- The template body cannot "call" other macros. Any E-Expressions in the template body are expanded before the template is added to the macro table.
- A template body consisting solely of a placeholder (annotated or unannotated) is not allowed.

### Ion scalars

Ion scalars are interpreted literally. These include values of any type except `list`, `sexp`, and `struct`.
`null` values of any type—even `null.list`, `null.sexp`, and `null.struct`—are also interpreted literally.

#### Examples
These macros are constants; they take no parameters.
When they are invoked, they expand to a single value: the Ion scalar acting as the template expression.
```ion
(:$set_macros
  (greeting "hello")
  (birthday 1996-10-11)
  // Annotations are also literal
  (price USD::29.95)
)

(:greeting) => "hello"
(:birthday) => 1996-10-11
(:price)    => USD::29.95
```

### Placeholders

Templates can insert macro arguments into their output by using _placeholders_.
Placeholders are positional - they correspond to arguments based on their order of appearance in the template.

**Key restrictions:**
- Placeholders may only occur in _value_ position
- Placeholders may only occur in a macro body; they are illegal anywhere else
- Placeholders may represent a tagged parameter or a tagless parameter
- Placeholders for a tagged parameter may optionally provide a single value that will be used as a default value when no value is provided for that parameter
- Placeholders for a tagless parameter must indicate the tagless scalar type of the argument
- All tagged parameters are optional parameters
- All tagless parameters are required parameters
- A template body consisting solely of a placeholder (annotated or unannotated) is not allowed
- A placeholder may be annotated

#### Example
```ion
// Given
(:$set_macros
  (line_from_origin { x0: 0, y0: 0, x1: (:?\int8\), y1: (:? 99) })
)
// When invoked
(:line_from_origin 5 10) => { x0: 0, y0: 0, x1: 5, y1: 10 }
(:line_from_origin 5 (:)) => { x0: 0, y0: 0, x1: 5, y1: 99 }
```

### Quasi-literal Ion containers

When an Ion container appears in a template definition, it is interpreted _almost_ literally.

Each nested value in the container is inspected.
* **If the value is an Ion scalar**, it is added to the output as-is.
* **If the value is a placeholder**, the value bound to that variable name is added to the output.
    The placeholder literal (for example: `(:?)`) is discarded.
* **If the value is an E-Expression**, it is expanded before the template is added to the macro table, and the resulting values are included in the template.
* **If the value is a container**, the reader will recurse into the container and repeat this process.

**Important:** The template body cannot "call" other macros at expansion time. Any E-Expressions in the template body are expanded when the macro is defined, not when it is invoked.

#### Placeholders within a sequence

Placeholders may be used within sequence types (lists or s-expressions). When an argument to such a placeholder is `(:)`,
no value is inserted into the sequence.

```ion
(:$set_macros
  (short_list [(:?), (:?), (:?)])
  (short_sexp ((:?) (:?) (:?)))
)

(:short_list a b c) => [a, b, c]
(:short_sexp a (:) c) => (a c)
```

#### Placeholders within a struct

Placeholders may be used within structs. Arguments are paired with the corresponding field name in the template body.
When an argument is `(:)`, the field name and value are elided.

```ion
(:$set_macros
  (resident
    {
        town: "Riverside",
        id: (:?),
        name: (:?)
    }
  )
)

(:resident "abc" "Alice") =>
{
  town: "Riverside",
  id: "abc",
  name: "Alice"
}

(:resident "def" "John") =>
{
  town: "Riverside",
  id: "def",
  name: "John"
}

(:resident "ghi" (:)) =>
{
  town: "Riverside",
  id: "ghi",
}
