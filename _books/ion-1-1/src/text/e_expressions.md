# E-expressions

In Ion text, encoding expressions ([E-expressions](../macros/macros_by_example.md)) start with `(:`, immediately 
followed by a macro reference, which must be one of:
 * a macro name
 * a base-10 integer macro address
 * a qualified macro name consisting of a module name, double-colon (`::`), and the macro name
 * a qualified macro name consisting of a module name, double-colon (`::`), and a base-10 integer macro address

See [Encoding modules](../modules/encoding_modules.md) for details about qualified macro references.

Macro and module names follow the syntax rules for _identifier_ [symbol tokens](symbol-tokens.md), excluding _symbol identifiers_.
There may not be any whitespace from the start of the E-expression through to the end of the macro reference.

Values in the E-expression body follow the same syntax as values in an [S-expression](values.md#s-expressions) body.
E-expressions may be annotated.

```ion
(:pi)              // Invokes the macro 'pi'
(:1)               // Invokes the macro with address 1 in the macro table
(:constants::pi)   // Invokes the macro 'pi' from the module 'constants'

(: pi)             // ERROR: whitespace is not permitted between '(:' and the macro reference
foo::(:pi)         // E-expression annotated with 'foo'
```

E-expressions may in structs in value position, but not field name position.
```ion
{
  foo: 1,
  bar: (:bar 2), // Expands to a value associated with the field name 'bar'
  (:bar 3)       // ERROR: e-expressions may not occur in field name position
}
```

When an e-expression represents a macro invocation that contains trailing optional parameters,
any or all of the trailing optionals may be elided from the e-expression.

```ion
($ion set_macros (foo {bar: (:?), baz: (:? 123)})) // Both parameters are optional
(:foo abc)     // ⇒ {bar: abc, baz: 123}
(:foo abc (:)) // Equivalent to the previous line. Second optional explicitly suppressed using `(:)`
(:foo)         // ⇒ {baz: 123}
(:foo (:) (:)) // Equivalent to the previous line. Both optionals explicitly suppressed using `(:)`
```

### Template Placeholders

Template placeholders are special E-Expressions that help define template macros.

Examples:

* Tagged value, optional, no default value: `(:?)`
* Tagged value, optional, with default value: `(:? "foo")`
* Tagless value (with type marker), required, default value not allowed: `(:?\int8\)`

### Type Markers

Type markers are used in tagless e-expression placeholders and
[tagless-element sequences](values.md#tagless-element-sequences).
The text syntax for type markers consists of a [tagless type identifier](../macros/tagless_encodings.md)
surrounded by `\`.

Examples:
 * named macro-shape: `\:foo\`, `\:foo_module::bar_macro\`
 * macro-shape by id: `\:12\`, `\:493\`
 * tagless scalar type by name: `\int\`, `\uint8\`, `\string\`, `\symbol\`, `\timestamp\`
 * tagless scalar type by opcode: `\0x61\`, `\0xEE\`

Macros that accept 0 arguments are not eligible to be used in a type marker.

### Macro-shaped parameters

Macro-shaped parameters are tagless parameters whose encoding type is the arguments for another macro.
In Ion text, each set of arguments for a macro-shape parameter must be enclosed between `(` and `)`.
The only difference between this and an E-expression is the lack of the ':' and macro reference at the start of the E-expression.
The arguments for a macro-shape use the same syntax as the arguments to any other E-expression.

```ion
// Given the following macros:
//   (point {x: (:?), y: (:?)})
//   (line_segment {a: (?:\point\), b: (?:\point\)})

(:line_segment (0 1) (4 8) )
//             └─┬─┘ └─┬─┘
//               │     └── Implicit invocation of (:point ...) for parameter b
//               └── Implicit invocation of (:point ...) for parameter a
