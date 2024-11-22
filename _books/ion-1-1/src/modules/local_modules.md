# Local modules

Local modules are lexically scoped.
They can be referenced immediately following their definition, up until the end of their enclosing scope.
They can be defined either:
1. **At the top level of a stream**, in which case the enclosing scope is the stream itself.
2. **Inside another module**, in which case the enclosing scope is the parent module.
   The parent module can be a shared or local module.

Local modules always have a symbolic name given at the point of definition, also known as a "binding."
It is legal for a module binding to "shadow" a module binding in its parent scope by using the same name.

```ion
$ion::
(module foo // <-- Top-level module `foo`
  (macro_table
    (macro quux () Quux)))

$ion::
(module bar
  (module foo // <-- Shadows the top-level module `foo`
    (macro_table
      (macro quuz () Quuz)))
  (macro_table foo::quuz) // <-- Refers to the innermost `foo`
)
```

However, it is _not_ legal for a local module to use the same name as a module previously defined in the _same_ scope.

```ion
$ion::
(module bar
  (module foo // <-- First definition of `foo` inside `bar`
    (macro_table
      (macro quux () Quux)))
  (module foo // <-- ERROR: module `foo` already defined in this scope
    (macro_table
      (macro quuz () Quuz)))
  /*...*/
)
```

The only exception to this rule is at the top level; stream-level bindings can be redefined.

```ion
$ion::
(module foo // <-- Top-level module `foo`
  (macro_table
    (macro quux () Quux)))

$ion::
(module foo // <-- Redefines the top-level binding `foo`
  (macro_table
    (macro quuz () Quuz)))
```

Local modules inherit their spec version from the enclosing scope.
Unlike shared modules, local modules have no content version.
Local modules automatically have access to modules previously declared in their enclosing scope using `module` or `import`.

### Examples

Local modules can be used to define helper macros without having to export them.
```ion
$ion_shared_module::$ion_1_1::(
  "org.example.Foo" 1
  (module util (macro_table (macro point2d (x y) { x:(%x), y:(%y) })))
  (macro_table
    (macro y_axis_point (y) (.util::point2d 0 (%y)))
    (macro poylgon (util::point2d::points+) [(%points)]))
)
```
In this example, the macro `point2d` is declared in a local module.
The macro definitions being exported in the shared module's macro table are able to reference the helper macros by name.

<br/>

Local modules can also be used for grouping macros into namespaces (only visible within the parent scope).
```ion
$ion_shared_module::$ion_1_1::(
  "org.example.Foo" 1
  (module cartesian (macro_table (macro point2d (x y) { x:(%x), y:(%y) })
                                 (macro polygon (point2d::points+) [(%points)]) ))

  (module polar (macro_table (macro point2d (r phi) { r:(%r), phi:(%phi) })
                             (macro polygon (point2d::points+) [(%points)]) ))
  (macro_table
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

<br/>

When grouping macros in local modules, there are more than just organizational benefits.
By first defining helper macros in an inner module, a module can export macros in a different order than they are declared:
```ion
$ion_shared_module::$ion_1_1::(
  "org.example.Foo" 1
  // point2d must be declared before polygon...
  (module util (macro_table (macro point2d (x y) { x:(%x), y:(%y) })))
  (macro_table
    // ...because it is used in the definition of polygon
    (macro poylgon (util::point2d::points+) [(%points)])
    // But it can be added to the macro table after polygon
    util)
)
```

<br/>

Local modules can also be used for organization of symbols.
```ion
$ion::
(encoding
  (module dairy      (symbol_table [cheese,  yogurt, milk]))
  (module grains     (symbol_table [cereal,  bread,  rice]))
  (module vegetables (symbol_table [carrots, celery, peas]))
  (module meat       (symbol_table [chicken, mutton, beef]))

  (symbol_table dairy
                grains
                vegetables
                meat)
)
```