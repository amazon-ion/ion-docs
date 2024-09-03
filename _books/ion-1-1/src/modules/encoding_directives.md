## Encoding directives

The _encoding module_ is the module that is currently being used to encode the data stream. When the stream begins, the encoding module is the [system module](system_module.md).

The application may define a new encoding module by writing an _encoding directive_ at the top level of the stream. An encoding directive is an s-expression annotated with `$ion_encoding`; its nested clauses define a new encoding module.

#### Example encoding directive
```ion
$ion_encoding::(
    (symbol_table [
        "a",  // $1
        "b",  // $2
        "c"   // $3
    ])
    (macro_table
      (macro pi () 3.14159265)
      (macro moon_landing_ts 1969-07-20T20:17Z)
    )
)
```

When the reader advances beyond the encoding directive, the module it defined becomes the new encoding module.

### Modules

In the context of an encoding directive, the encoding module is named `$ion_encoding`.

The encoding directive may preserve symbols or macros that were defined in the previous encoding directive.
<!-- TODO -->

