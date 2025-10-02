## Directives

Ion 1.1 includes seven directives that describe encoding metadata in an Ion stream. Directives are special e-expressions that can only appear at the top level of a data stream and cannot be produced by user macros.

### Overview

Directives manage the encoding context by manipulating symbols and macros in the default module. They produce system values (not user-visible values) and are distinct from macros in that they do not expand to values.

The seven directives are:
- `$add_symbols` - Appends symbols to the default module
- `$set_symbols` - Clears and sets the symbols in the default module
- `$add_macros` - Appends macros to the default module
- `$set_macros` - Clears and sets the macros in the default module
- `$use` - Appends the symbols and macros of a given module to the default module
- `$module` - Binds a module name to an imported or locally-defined module
- `$encoding` - Accepts a sequence of module bindings to use as the encoding module sequence

### Important Constraints

- Directives may only occur at the top level of a stream
- Directives may not be annotated
- Macros cannot produce directives
- Directives produce only system values, not user values
- Directives do not expand to values (unlike macros which must expand to exactly one value)

### Symbol Table Directives

#### `$set_symbols`
Redefines the default module's symbol table, preserving any macros in its macro table.

Example:
```ion
(:$set_symbols foo bar baz)
```

This directive clears the default module's symbol table and sets it to contain the symbols `foo`, `bar`, and `baz`.

#### `$add_symbols`
Appends symbols to the default module's symbol table, preserving any macros in its macro table.

Example:
```ion
(:$add_symbols new_symbol_1 new_symbol_2)
```

This directive appends `new_symbol_1` and `new_symbol_2` to the default module's symbol table.

### Macro Table Directives

#### `$set_macros`
Sets the default module's macro table, preserving any symbols in its symbol table.

Example:
```ion
(:$set_macros (pi 3.14159))
```

This directive clears the default module's macro table and sets it to contain a single macro `pi` that expands to `3.14159`.

#### `$add_macros`
Appends macros to the default module's macro table, preserving any symbols in its symbol table.

Example:
```ion
(:$add_macros (e 2.71828))
```

This directive appends a macro `e` that expands to `2.71828` to the default module's macro table.

### Module Management Directives

#### `$use`
Appends the content of the given module to the default module.

Example:
```ion
(:$use "org.example.FooModule" 2)
```

This directive imports version 2 of the module identified by "org.example.FooModule" and appends its symbols and macros to the default module.

#### `$module`
Binds a module name to an imported or locally-defined module.

Examples:

Locally-defined module:
```ion
(:$module foo 
  (macros 
    (point {x: (:?\int\), y: (:?\int\)}))
  (symbols [alpha, beta, gamma]))
```

Redefining the default module:
```ion
(:$module _ 
  (macros 
    (greeting "hello"))
  (symbols [foo, bar]))
```

Imported module:
```ion
(:$module bar "com.amazon.foo.Bar" 1)
```

#### `$encoding`
Accepts a sequence of module bindings to use as the following stream segment's encoding module sequence.

Example:
```ion
(:$encoding
  (module _
    (import shapes "com.example.shapes" 1)
    (symbols [local_sym1, local_sym2])
    (macros
      (custom_shape 
        {type: (:?), size: (:?)}))))
```

This directive sets up the encoding context for the stream segment that follows, defining which symbols and macros are available.

### Binary Encoding

In binary Ion, directives are encoded using opcodes `0xE1` through `0xE7`. The binary encoding of directives is effectively a specialized delimited container—they may contain any number of tagged values, they have no length prefix, and they are closed with the end-container opcode (`0xEF`).

### Usage Guidelines

1. **Symbol Management**: Use `$add_symbols` when you need to add a few symbols without disturbing the existing symbol table. Use `$set_symbols` when you want to completely replace the symbol table.

2. **Macro Management**: Similarly, use `$add_macros` to incrementally add macros, and `$set_macros` to replace the entire macro table.

3. **Module Imports**: Use `$use` for simple imports where you want to add all symbols and macros from a module. Use `$module` when you need more control over module binding and naming.

4. **Encoding Contexts**: Use `$encoding` to establish a complete encoding context for a stream segment, especially when working with shared modules or complex macro libraries.

### Examples

Setting up a custom encoding context:
```ion
// Add some symbols
(:$add_symbols x y start end)

// Define some local macros
(:$add_macros 
  (point {x: (:?\int\), y: (:?\int\)})
  (line {start: (:?), end: (:?)}))

// Now use the macros
(:point 3 5)
(:line (:point 0 0) (:point 10 10))
```

Importing and using a shared module:
```ion
// Import a shared module
(:$use "com.example.geometry" 1)

// The module's macros and symbols are now available
(:circle 5)  // Assuming 'circle' is defined in the module
```
