## Special Forms

When a [TDL expression](defining_macros.md#template-definition-language-tdl) is syntactically an S-expression and its
first element is the symbol `.`, its next element must be a symbol that matches either a set of keywords denoting the 
special forms, or the name of a previously-defined macro.
The interpretation of the S-expression’s remaining elements depends on how the symbol resolves.
In the case of macro invocations, the elements following the operator are arbitrary TDL expressions, but for special 
forms that is not always the case.

Special forms are "special" precisely because they cannot be expressed as macros and must therefore receive bespoke 
syntactic treatment. Since the elements of macro-invocation expressions are themselves expressions, when you want 
something to not be evaluated that way, it must be a special form. Argument expressions are passed to the special form
without interpretation, and each special form has custom logic for interpreting its arguments.

```ion
// The argument being passed in is the _expansion_ of the foo macro
(.regular_macro (.foo))

// This argument being passed in is literally `( '.' 'foo' )`.
(.special_form (.foo))
```

These special forms are part of the template language itself, and most are not addressable outside TDL;
the E-expression `(:if_none foo bar baz)` must necessarily refer to some user-defined macro named `if_none`, not to the special form of the same name. The only exception is `parse_ion`, which is explicitly included in the system macro table.

### `literal`

```ion
(literal (values*) /* Not representable in TDL */)
```

The `literal` form is an identity function that accepts its arguments as literal values and then produces them without any evaluation.
Both `literal` and `values` are identity functions, but they differ in regard to how their arguments are interpreted:

```ion
(.literal (.make_string "a" "b")) ⇒ (.make_string "a" "b")
(.values (.make_string "a" "b"))  ⇒ "ab"
```


### `if_none`

```ion
(if_none (stream* true_branch* false_branch*) /* Not representable in TDL */)
```

The `if_none` form is if/then/else syntax testing stream emptiness.
It has three sub-expressions, the first being a stream to check. 
If and only if that stream is empty (it produces no values), the second sub-expression is expanded.
Otherwise, the third sub-expression is expanded. 
The expanded second or third sub-expression becomes the result that is produced by `if_none`.

> [!Note]
> Exactly one branch is expanded, because otherwise the empty `stream` might be used in a context that requires a value, resulting in an errant expansion error.

```ion
(macro temperature (degrees scale?) 
       {
         degrees: (%degrees),
         scale: (.if_none (%scale) K (%scale)),
       })
```
```ion
(:temperature 96 F)     ⇒ {degrees:96,  scale:F}
(:temperature 283 (::)) ⇒ {degrees:283, scale:K}
```

To refine things a bit further, trailing optional arguments can be omitted entirely:
```ion
(:temperature 283) ⇒ {degrees:283, scale:K}
```

> [!TIP]
> If you're using `if_none` to specify an expression to default to, you can use the [`default`](system_macros.md#default) system macro to be more concise.
> ```ion
> (macro temperature (degrees scale)
>     {
>       degrees: (%degrees),
>       scale: (.default (%scale) K),
>     }
> )
> ```

### `if_some`

```ion
(if_some (stream* true_branch* false_branch*) /* Not representable in TDL */)
```

If `stream` evaluates to one or more values, it produces `true_branch`. Otherwise, it produces `false_branch`.
Exactly one of `true_branch` and `false_branch` is evaluated.
The `stream` expression must be expanded enough to determine whether it produces any values, but implementations are not required to fully expand the expression. 

Example:
```ion
(macro foo (x)
       {
         foo: (.if_some (%x) [(%x)] null)
       })
```

```ion
(:foo (::))     => { foo: null }
(:foo 2)        => { foo: [2] }
(:foo (:: 2 3)) => { foo: [2, 3] }
```

The `false_branch` parameter may be elided, allowing `if_some` to serve as a _map-if-not-none_ function.

Example:
```ion
(macro foo (x)
       {
         foo: (.if_some (%x) [(%x)])
       })
```

```ion
(:foo (::))     => { }
(:foo 2)        => { foo: [2] }
(:foo (:: 2 3)) => { foo: [2, 3] }
```

### `if_single`

```ion
(if_single (stream* true_branch* false_branch*) /* Not representable in TDL */)
```

If `stream` evaluates to exactly one value, `if_single` produces the expansion of `true_branch`. Otherwise, it produces the expansion of `false_branch`.
Exactly one of `true_branch` and `false_branch` is evaluated.
The `stream` argument must be expanded enough to determine whether it produces exactly one value, but implementations are not required to fully expand the expression.

### `if_multi`

```ion
(if_multi (stream* true_branch* false_branch*) /* Not representable in TDL */)
```

If `stream` evaluates to more than one value, it produces `true_branch`. Otherwise, it produces `false_branch`.
Exactly one of `true_branch` and `false_branch` is evaluated.
The `stream` argument must be expanded enough to determine whether it produces more than one value, but implementations are not required to fully expand the expression.

### `for`

```ion
(for name_and_expressions template)
```

`name_and_expressions` is a list or s-expression containing one or more s-expressions of the form `(name expr0 expr1 ... exprN)`.
The first value is a symbol to act as a variable name. 
The remaining expressions in the s-expression will be expanded and concatenated into a single stream; for each value in the stream, the `for` expansion will produce a copy of the `template` argument expression with any appearance of the variable replaced by the value.

For example:

```ion
(.for
  [(word                     // Variable name
   foo bar baz)]             // Values over which to iterate
  (.values (%word) (%word))) // Template expression; `(%word)` will be replaced
=>
foo foo bar bar baz baz
```

Multiple s-expressions can be specified. The streams will be iterated over in lockstep.

```ion
(.for
  ((x 1 2 3)   // for x in...
   (y 4 5 6))  // for y in...
  ((%x) (%y))) // Template; `(%x)` and `(%y)` will be replaced
=>
(1 4)
(2 5)
(3 6)
```
Iteration will end when the shortest stream is exhausted.
```ion
(.for
  [(x 1 2),    // for x in...
   (y 3 4 5)]  // for y in...
  ((%x) (%y))) // Template; `(%x)` and `(%y)` will be replaced
=>
(1 3)
(2 4)
// no more output, `x` is exhausted
```

Names defined inside a `for` shadow names in the parent scope.

```ion
(macro triple (x)
  //           └─── Parameter `x` is declared here...
  (.for
  //    ...but the `for` expression introduces a
  //  ┌─── new variable of the same name here.
    ((x a b c))
    (%x)
  //  └─── This refers to the `for` expression's `x`, not the parameter.
  )
)
(:triple 1) // Argument `1` is ignored
=>
a b c
```

The `for` special form can only be invoked in the body of template macro. It is not valid to use as an E-Expression.

### `parse_ion`

Ion documents may be embedded in other Ion documents using the `parse_ion` form.

```ion
(parse_ion (data) /* Not representable in TDL */)
```

The `parse_ion` form constructs a stream of values by parsing a blob literal or string literal as a single, self-contained Ion document.

The argument must be a literal value because macros are not allowed to contain recursive calls, and composing 
an embedded document from multiple expressions would make it possible to implement recursion in the macro system.

The data argument is evaluated in a clean environment that cannot read anything from the parent document.
Allowing context to leak from the outer scope into the document being parsed would also enable recursion.

All values produced by the expansion of `parse_ion` are application values.
(i.e. it is as if they are all annotated with `$ion_literal`.)

The IVM at the beginning of an Ion data stream is sufficient to identify whether it is text or binary, so text Ion
can be embedded as a blob containing the UTF-8 encoded text.


Embedded text example:
```ion
(:parse_ion
    '''
    $ion_1_1
    $ion::(module _ (symbol_table ["foo" "bar"]]))
    $1 $2
    '''
)
=> foo bar
```

Embedded binary example:
```ion
(:parse_ion {{ 4AEB6qNmb2+jYmFy }} )
=> foo bar
```

The `parse_ion` form has an address in the [system macro table](../modules/system_module.md#system-macros), making it 
the only special form that can be invoked as an e-expression.

For normative examples, see [`parse_ion`](https://github.com/amazon-ion/ion-tests/tree/main/conformance/system_macros/parse_ion.ion) in the Ion conformance test suite.
