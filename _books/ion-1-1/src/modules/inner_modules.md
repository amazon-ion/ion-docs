# Inner Modules

Inner modules are defined within another module, and can be referenced only within the enclosing module.
Their scope is lexical; they can be referenced immediately following their definition, up until the end of the containing module.

Inline modules always have a symbolic name given at the point of definition.
They inherit their spec version from the containing module, and they have no content version.
Inner modules automatically have access to modules previously declared in their containing module using `module` or `import`.
Inner modules may not contain their own nested inner modules.

### Examples

Inner modules can be used to define helper macros and use them by name in the definitions of other macros without 
having to export the helper macro by name.
```ion
$ion_shared_module::$ion_1_1::(
  "org.example.Foo" 1
  (module util (macro_table (macro point2d (x y) { x:(%x), y:(%y) })))
  (macro_table
    (export util::0)
    (macro y_axis_point (y) (.util::point2d 0 (%y)))
    (macro poylgon (util::point2d::points+) [(%points)]))
)
```
In this example, the macro `point2d` is declared in an inner module.
It is added to the shared module's macro table _without a name_, and subsequently referenced by name in the definition
of other macros.

<br/>

Inner modules can also be used for grouping macros into namespaces (only visible within the outer module), and to declare
helper macros that are not added to the macro table of the outer module.
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
Both `polygon` macros are added to the shared module's macro table, each one given an alias in order to resolve the name conflict.
Neither one of the `point2d` macros needs to be added to the shared module's macro table because they can be referenced
in the definitions of both `polygon` macros without needing to be added to the shared module's macro table.

<br/>

When grouping macros in inner modules, there are more than just organizational benefits.
By defining helper macros in an inner module, the order in which the macros are added to the macro table of the outer module does not have to be the same as the order in which the macros are declared:
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

Inner modules can also be used for organization of symbols.
```ion
$ion_encoding::(
  (module diary      (symbol_table [cheese,  yogurt, milk]))
  (module grains     (symbol_table [cereal,  bread,  rice]))
  (module vegetables (symbol_table [carrots, celery, peas]))
  (module meat       (symbol_table [chicken, mutton, beef]))
  
  (symbol_table dairy 
                grains 
                vegetables 
                meat)
)
```