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
E-expressions are not values, so they may not be annotated; to annotate the result of an e-expression use the 
[`annotate`](../macros/system_macros.md#annotate) macro.

```ion
(:pi)              // Invokes the macro 'pi'
(:1)               // Invokes the macro with address 1 in the macro table
(:constants::pi)   // Invokes the macro 'pi' from the module 'constants'

(: pi)             // ERROR: whitespace is not permitted between '(:' and the macro reference
foo::(:pi)         // ERROR: e-expression may not be annotated
```

E-expressions may also appear in structs in place of an entire name-value pair.
```ion
{
  foo: 1,
  (:bar 2), // Expands to a struct that is spliced into this struct
}
```

### Expression Groups

To pass multiple arguments to a single macro parameter, the arguments to the parameter must be delimited by an _Expression Group_.

Inside an E-expression, an expression group starts with `(::`.
The remainder of the expression group uses the same syntax as an [S-expression](values.md#s-expressions).
Expression groups are not values, so they may not be annotated.
Expression groups may not contain another expression group.


```ion
(:make_string (:: "a" "b" "c" "d"))
//                └──────┬──────┘
//                       └── 4 argument expressions passed to `parts`

(:make_string (:: "a" (:: "b" "c") "d") )    // ERROR: Expression groups may only occur directly in an E-expression
```


### Rest Arguments

Rest arguments are a special-case of expression groups that is only applicable to Ion 1.1 text. 
When the final parameter in the macro signature is `zero-or-more` or `one-or-more`, "all the rest" of the argument expressions will be passed to that parameter.
Rest arguments are an implicit expression group, and may not include any explicit expression groups. 

```ion
(:make_string)
//           └── 0 argument expressions passed to `parts`
(:make_string "a")
//            └┬┘
//             └── 1 argument expression passed to `parts`
(:make_string "a" "b" "c" "d")
//            └──────┬──────┘
//                   └── 4 argument expressions passed to `parts`

(:make_string (:: "a" "b" "c" "d"))
//                └──────┬──────┘
//                       └── Also 4 argument expressions passed to `parts`

(:make_string (:: "a") "b" "c" "d")   // ERROR: Too many arguments
(:make_string "a" (:: "b") "c" "d")   // ERROR: Too many arguments
```


### Macro-shaped parameters

Macro-shaped parameters are tagless parameters whose encoding type is the arguments for another macro.
(See [Macros by Example](../macros/macros_by_example.md#macro-shapes).)
In Ion text, each set of arguments for a macro-shape parameter must be enclosed between `(` and `)`.
The only difference between this and an E-expression is the lack of the ':' and macro reference at the start of the E-expression.
The arguments for a macro-shape use the same syntax as the arguments to any other E-expression.

```ion
// Given the following macro signatures:
//   (macro point (x y) ...)
//   (macro line_segment (point::a point::b) ...)
//   (macro polygon (point::points*) ...)

(:line_segment (0 1) (4 8) )
//             └─┬─┘ └─┬─┘
//               │     └── Implicit invocation of (:point ...) for parameter b
//               └── Implicit invocation of (:point ...) for parameter a

(:polygon (:: (1 1) (1 2) (2 4) (2 5) ))
//            └──────────┬──────────┘
//                       └── 4 macro-shaped arguments passed to `points`
```


