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
* Tagless value (with primitive type marker), required, default value not allowed: `(:? {#int8})`

### Type Markers

Type markers are used in tagless e-expression placeholders and
[tagless-element sequences](values.md#tagless-element-sequences).
The text syntax for type markers consists of a [tagless type identifier](../macros/tagless_encodings.md)
preceded by either `#` (for primitive encodings) or `:` (for macro shapes), and surrounded by `{}`.

Examples:
 * named macro-shape: `{:foo}`, `{:foo_module::bar_macro}`. May only be used in tagless-element sequences.
 * macro-shape by id: `{:12}`, `{:493}`. May only be used in tagless-element sequences.
 * tagless scalar type by name: `{#int}`, `{#uint8}`, `{#string}`, `{#symbol}`, `{#timestamp}`. May be used in tagless-element sequences or tagless template placeholders.

Macros that accept 0 arguments are not eligible to be used in a type marker.
