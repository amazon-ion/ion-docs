## Special Forms

When a [TDL expression](defining_macros.md#template-definition-language-tdl) is syntactically an S-expression and its
first element is the symbol `.`, its next element must be a symbol that matches either a set of keywords denoting the 
special forms, or the name of a previously-defined macro.
The interpretation of the S-expression’s remaining elements depends on how the symbol resolves.
In the case of macro invocations, the elements following the operator are arbitrary TDL expressions, but for special 
forms that is not always the case.

Special forms are "special" precisely because they cannot be expressed as macros and must therefore receive bespoke syntactic treatment.
Since the elements of macro-invocation expressions are themselves expressions, when you want something to not be evaluated that way, it must be a special form.

Finally, these special forms are part of the template language itself, and are not addressable outside of TDL;
the E-expression `(:if_none foo bar baz)` must necessarily refer to some user-defined macro named `if_none`, not to the special form of the same name.


> [!TODO]
> Many of these could be system macros instead of special forms. Being unrepresentable in TDL is not a reason for something
> to be a special form.
> Candidates to be moved to system macros are `if_*` and `fail`.
> Additionally, the system macro `parse_ion` may need to be classified as a special form since it only accepts literals.

### `if_none`

```ion
(macro if_none (stream* true_branch* false_branch*) /* Not representable in TDL */)
```

The `if_none` form is if/then/else syntax testing stream emptiness.
It has three sub-expressions, the first being a stream to check. 
If and only if that stream is empty (it produces no values), the second sub-expression is expanded.
Otherwise, the third sub-expression is expanded. 
The expanded second or third sub-expression becomes the result that is produced by `if_none`.

> [!Note]
> Exactly one branch is expanded, because otherwise the empty `stream` might be used in a context that requires a value, resulting in an errant expansion error.

```ion
(macro temperature (degrees scale) 
       {
         degrees: (%degrees),
         scale: (.if_none (%scale) K (%scale)),
       })
```
```ion
(:temperature 96 F)     ⇒ {degrees:96,  scale:F}
(:temperature 283 (::)) ⇒ {degrees:283, scale:K}
```

To refine things a bit further, trailing voidable arguments can be omitted entirely:
```ion
(:temperature 283) ⇒ {degrees:283, scale:K}
```

> [!TIP]
> You can define a macro that wraps `if_none` to create a none-coalescing operator.
> ```ion
> (macro coalesce (maybe_none* default_expr+) 
>        (.if_none (%maybe_none) (%default_expr) (%maybe_none)))
> ```

### `if_some`

```ion
(macro if_some (stream* true_branch* false_branch*) /* Not representable in TDL */)
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

The `false_branch` parameter may be elided, allowing `if_some` to serve as a _map-if-not-void_ function.

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
(macro if_single (expressions* true_branch* false_branch*) /* Not representable in TDL */)
```

If `expressions` evaluates to exactly one value, `if_single` produces the expansion of `true_branch`. Otherwise, it produces the expansion of `false_branch`.
Exactly one of `true_branch` and `false_branch` is evaluated.
The `stream` expression must be expanded enough to determine whether it produces exactly one value, but implementations are not required to fully expand the expression.

### `if_multi`

```ion
(macro if_multi (expressions* true_branch* false_branch*) /* Not representable in TDL */)
```

If `expressions` evaluates to more than one value, it produces `true_branch`. Otherwise, it produces `false_branch`.
Exactly one of `true_branch` and `false_branch` is evaluated.
The `stream` expression must be expanded enough to determine whether it produces more than one value, but implementations are not required to fully expand the expression.

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
   (.literal foo bar baz))]  // Values over which to iterate
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

### `fail`

```ion
(macro fail (message?) /* Not representable in TDL */)
```

Causes macro evaluation to immediately halt and causes the Ion reader to raise an error to the user. 
