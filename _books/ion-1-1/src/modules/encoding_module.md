# The encoding module

The _encoding module_ is the module that is currently being used to encode the data stream. 
When the stream begins, the encoding module is the [system module](system_module.md).

The application may define a new encoding module by writing an _encoding directive_ at the top level of the stream. 
An encoding directive is an s-expression annotated with `$ion_encoding`; its nested clauses define a new encoding module.

When the reader advances beyond an encoding directive, the module it defined becomes the new encoding module.

In the context of an encoding directive, the active encoding module is named `$ion_encoding`.
The encoding directive may preserve symbols or macros that were defined in the previous encoding directive by referencing `$ion_encoding`.
The `$ion_encoding` module may only be imported to an encoding directive, and it is done so automatically and implicitly.

### Examples

#### An encoding directive
A simple encoding directive—it defines a module that exports three symbols and two macros.
```ion
$ion_encoding::(
    (symbol_table [
        "a",  // $1
        "b",  // $2
        "c"   // $3
    ])
    (macro_table
      (macro pi () 3.14159265)
      (macro moon_landing_ts () 1969-07-20T20:17Z)
    )
)
```

#### Adding symbols to the encoding module
The implicitly imported `$ion_encoding` is used to append to the current symbol and macro tables.

```ion
$ion_encoding::(
    (symbol_table [
        "a",  // $1
        "b",  // $2
        "c",  // $3
    ])
    (macro_table
      (macro pi () 3.14159265)
      (macro moon_landing_ts () 1969-07-20T20:17Z)
    )
)

// ...

$ion_encoding::(
  // The first argument of the symbol_table clause is the module name '$ion_encoding',
  // which adds the symbols from the active encoding module to the new encoding module.
  // The '$ion_encoding' argument in the macro_table clause behaves similarly.
  (symbol_table $ion_encoding 
                [
                  "d", // $4
                  "e", // $5
                  "f", // $6
                ])
  (macro_table $ion_encoding
               (macro e () 2.71828182))
)

// ...
```

#### Clearing the local symbols and local macros
```ion
$ion_encoding::()
```
The absence of the `symbol_table` and `macro_table` clauses is interpreted as empty symbol and macro tables.

Note that this is different from the behaviour of an IVM. 
When an IVM is encountered, the encoding module is set to the system module.
