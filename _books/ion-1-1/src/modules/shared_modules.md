# Shared modules

Shared modules exist independently of the documents that use them.
They are identified by a _catalog key_ consisting of a string name and an integer version.

Unlike local modules, the Ion parser does not intrinsically recognize or process this data;
it is up to higher-level specifications or conventions to define how shared modules are communicated.

The self-declared catalog-names of shared modules are generally long, since they must be more-or-less globally unique.
When imported by another module, they are given local symbolic names—a _binding_—by import declarations.
Once the shared module has been imported and given a binding, it can be referenced by other modules and/or added to the [encoding modules](encoding_modules.md).

```ion
$ion_1_1
(:$ion import geo "org.example.geometry" 2)
(:$ion encoding geo)
(:geo::polygon [:#geo::point2d (1 4) (1 8) (3 6)] rgb::0xFFCC00)
```


Ion 1.1 also provides a convenient directive ([`use`](directives.md#use-directives)) to append a shared module to the default module.
```ion
$ion_1_1
(:$ion use "org.example.geometry" 2)
// The content of the shared module is immediately available through the default module.
(:polygon [:#point2d (1 4) (1 8) (3 6)] rgb::0xFFCC00)
```

### Compatibility with Ion 1.0

Ion 1.0 shared symbol tables are treated as Ion 1.1 shared modules that have an empty macro table.
