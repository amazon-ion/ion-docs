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
Local modules automatically have access to any modules previously declared in their enclosing scope using a `module` or `import` directive.

### Examples

Local modules can be used to define helper macros without having to export them.
```ion
$ion_shared_module::$ion_1_1::(
  "org.example.Foo" 1
  (module util (macros (macro point2d (x y) { x:(%x), y:(%y) })))
  (macros
    (macro y_axis_point (y) (.util::point2d 0 (%y)))
    (macro poylgon (util::point2d::points+) [(%points)]))
)
```
In this example, the macro `point2d` is declared in a local module.
The macro definitions being exported in the shared module's macro table are able to reference the helper macros by name.

Local modules can also be used for grouping macros into namespaces (only visible within the parent scope).
```ion
$ion_shared_module::$ion_1_1::(
  "org.example.Foo" 1
  (module cartesian (macros (macro point2d (x y) { x:(%x), y:(%y) })
                                 (macro polygon (point2d::points+) [(%points)]) ))

  (module polar (macros (macro point2d (r phi) { r:(%r), phi:(%phi) })
                             (macro polygon (point2d::points+) [(%points)]) ))
  (macros
    (export cartesian::polygon cartesian_poylgon)
    (export polar::polygon polar_poylgon))
)
```
In this example, there are two macros named `point2d` and two named `polygon`.
There is no name conflict between them because they are declared in separate namespaces.
Both `polygon` macros are added to the shared module's macro table,
with each one given an alias in order to resolve the name conflict.
Neither one of the `point2d` macros needs to be added to the shared module's macro table because they can be referenced
in the definitions of both `polygon` macros without needing to be added to the shared module's macro table.

When grouping macros in local modules, there are more than just organizational benefits.
By first defining helper macros in an inner module, a module can export macros in a different order than they are declared:
```ion
$ion_shared_module::$ion_1_1::(
  "org.example.Foo" 1
  // point2d must be declared before polygon...
  (module util (macros (macro point2d (x y) { x:(%x), y:(%y) })))
  (macros
    // ...because it is used in the definition of polygon
    (macro poylgon (util::point2d::points+) [(%points)])
    // But it can be added to the macro table after polygon
    util)
)
```

Local modules can also be used for organization of symbols.
```ion
(:$ion module dairy      (symbols ["cheese",  "yogurt", "milk"]))
(:$ion module grains     (symbols ["cereal",  "bread",  "rice"]))
(:$ion module vegetables (symbols ["carrots", "celery", "peas"]))
(:$ion module meat       (symbols ["chicken", "mutton", "beef"]))
(:$ion encoding
  (symbols dairy
           grains
           vegetables
           meat)
)
```