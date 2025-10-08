# Local modules

Local modules are lexically scoped.
They can be defined at the top level of a stream.
They can be referenced immediately following their definition, up until the end of the stream.

Local modules always have a symbolic name given at the point of definition, also known as a _binding_.

Stream-level bindings are mutable.

```ion
(:$ion module foo // <-- Top-level module `foo`
  (macros
    (macro quux () Quux)))

(:$ion module foo // <-- Redefines the top-level binding `foo`
  (macros
    (macro quuz () Quuz)))
```

Local modules inherit their spec version from the enclosing scope.
Local modules automatically have access to modules previously declared in their enclosing scope using `module` or `import`.

The [default module](encoding_modules.md#the-default-module) is an empty, top-level module that is implicitly defined at the beginning of every stream.
