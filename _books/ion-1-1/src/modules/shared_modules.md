# Shared Modules

Shared modules exist independently of the documents that use them.
They are identified by a _catalog key_ consisting of a string name and an integer version.

The self-declared catalog-names of shared modules are generally long, since they must be more-or-less globally unique.
When imported by another module, they are given local symbolic names by import declarations.

They have a spec version that is explicit via annotation, and a content version derived from the catalog version.
The spec version of a shared module must be declared explicitly using an annotation of the form `$ion_1_N`.
This allows the module to be serialized using any version of Ion, and its meaning will not change.

```ion
$ion_shared_module::
$ion_1_1::("com.example.symtab" 3 
           (symbol_table ...) 
           (macro_table ...) )
```

### Example

An Ion 1.1 shared module.
```ion
$ion_shared_module::
$ion_1_1::("org.example.geometry" 2
           (symbol_table ["x", "y", "square", "circle"])
           (macro_table (macro point2d (x y) { x:(%x), y:(%y) })
                        (macro polygon (point2d::points+) [(%points)]) )
)
```

The system module provides a convenient macro ([`use`](../macros/system_macros.md#use)) to append a shared module to the current encoding module.
```ion
$ion_1_1
(:use "org.example.geometry" 2)
(:polygon (:: (1 4) (1 8) (3 6)))
```



### Compatibility with Ion 1.0

Ion 1.0 shared symbol tables are treated as Ion 1.1 shared modules that have an empty macro table.

