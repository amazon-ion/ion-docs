## Special Forms

When a template-expression is syntactically an S-expression, its first element must be a symbol that matches either a 
set of keywords denoting the special forms, or the name of a previously-defined macro.
The interpretation of the S-expression’s remaining elements depends on how the symbol resolves.
In the case of macro invocations, the elements following the operator are arbitrary template expressions, but for special forms that is not always the case.

Special forms are "special" precisely because they cannot be expressed as macros and must therefore receive bespoke syntactic treatment.
Since the elements of macro-invocation expressions are themselves expressions, when you want something to not be evaluated that way, it must be a special form.

Finally, these special forms are part of the template language itself, and are not visible to encoded data;
the E-expression `(:literal foo)` must necessarily refer to some user-defined macro named literal, not to this special form.


> [!TODO]
> Many of these could be system macros instead of special forms. Being unrepresentable in TDL is not a reason for something
> to be a special form.
> Candidates to be moved to system macros are `if_*` and `fail`.
> Additionally, the system macro `parse_ion` may need to be classified as a special form since it only accepts literals.

### `literal`

```ion
(macro USD_price (dollars) (.price dollars (.literal USD)))
```
In this template, we cannot write `(.price dollars USD)` because the symbol `USD` would be treated as an unbound variable reference and a syntax error, so we turn it into literal data by "escaping" it with `literal`. As an aside, there is no need for such a form in E-expressions, because in that context symbols and S-expressions are not "evaluated", and everything is literal except for E-expressions (which are not data, but encoding artifacts).

### `if_none`

```ion
(macro if_none (stream* true_branch* false_branch*) /* Not representable in TDL */)
```

The `if_none` form is if/then/else syntax testing stream emptiness.
It has three sub-expressions, the first being a stream to check. 
If and only if that stream is empty (it produces no values), the second sub-expression is expanded and its results are returned by the `if_none` expression. Otherwise, the third sub-expression is expanded and returned.

> [!Note]
> Exactly one branch is expanded, because otherwise the empty `stream` might be used in a context that requires a value, resulting in an errant expansion error.

```ion
(macro temperature (degrees scale) {degrees: degrees, scale: (.if_none scale (.literal K) scale)})
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
> You can define a macro that wraps `if_none` to create a void-coalescing operator.
> ```ion
> (macro coalesce (maybe_none* else+) (.if_none maybe_none else maybe_none))
> ```

### `if_some`

```ion
(macro if_some (stream* true_branch* false_branch*) /* Not representable in TDL */)
```

If `stream` evaluates to one or more values, it produces `true_branch`. Otherwise, it produces `false_branch`.
Exactly one branch is evaluated. The `true_branch` and `false_branch` arguments are only evaluated if they are to be returned.

Example:
```ion
(macro foo ($foo)
       {
         foo: (.if_some $foo [$foo] null)
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
(macro foo ($foo)
       {
         foo: (.if_some $foo [$foo])
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

If `expressions` evaluates to exactly one value, it returns `true_branch`. Otherwise, it returns `false_branch`.
Exactly one branch is evaluated. The `true_branch` and `false_branch` arguments are only evaluated if they are to be returned.

### `if_multi`

```ion
(macro if_multi (expressions* true_branch* false_branch*) /* Not representable in TDL */)
```

If `expressions` evaluates to more than one value, it produces `true_branch`. Otherwise, it produces `false_branch`.
Exactly one branch is evaluated. The `true_branch` and `false_branch` arguments are only evaluated if they are to be returned.

### `for`

```ion
(for name_and_values template)
```

`name_and_values` is a list or s-expression containing one or more s-expressions of the form `(name value1 value2 ... valueN)`. The first value is a symbol to act as a variable name. The remaining values in the s-expression will be visited one at a time; for each value, expansion will produce a copy of the `template` argument expression with any appearance of the variable name replaced by the value.

For example:

```ion
(:for
  [($word                    // Variable name
   (.literal foo bar baz))]   // Values over which to iterate
  (.values $word $word))     // Template expression; `$word` will be replaced
=>
foo foo bar bar baz baz
```

Multiple s-expressions can be specified. The streams will be iterated over in lockstep.

```ion
(:for
  (($x 1 2 3)  // for $x in...
   ($y 4 5 6)) // for $y in...
  ($x $y))     // Template; `$x` and `$y` will be replaced
=>
(1 4)
(2 5)
(3 6)
```
Iteration will end when the shortest stream is exhausted.
```ion
(:for
  [($x 1 2),   // for $x in...
  ($y 3 4 5)] // for $y in...
  ($x $y))   // Template; `$x` and `$y` will be replaced
=>
(1 3)
(2 4)
// no more output, `x` is exhausted
```

Names defined inside a `for` shadow names in the parent scope.

```ion
(macro triple ($x)
  (.for
    (($x // Shadows macro argument `$x`
      1 2 3))
    $x
  )
)
(:triple 1)
=>
1 1 1
```

The `for` special form can only be invoked in the body of template macro. It is not valid to use as an E-Expression.

### `fail`

```ion
(macro fail (message?) /* Not representable in TDL */)
```

Causes macro evaluation to immediately halt and causes the Ion reader to return an error to the user. 
