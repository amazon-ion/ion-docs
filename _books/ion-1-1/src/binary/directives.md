## Directives

Directives are system values that modify the encoding context.

> [!NOTE]
> This chapter focuses on the binary encoding of directives. 
> The [_Directives_](../modules/directives.md) section explains what they are and how they are used.

Except for `end`, the binary encoding of directives is a specialized delimited
container.
Directives other than `end` are opened using opcodes `0xE1` through `0xE8`.
They may contain any number of tagged values, and they are closed with the end-container opcode (`0xEF`).

Directives may only occur at the top level of a stream and may not be annotated.

The `end` directive is not encoded with an opening opcode and a closing `0xEF`.
It is encoded as a single `0xEF` byte. An `0xEF` is an `end` directive only
where a top-level value, e-expression, Ion version marker, or directive could
begin. An `0xEF` that closes a delimited container or directive is not an `end`
directive. An `0xEF` at any other position where an opcode is expected (for
example, in the tagged-argument position of a top-level e-expression) is an
error. `0xEF` bytes where no opcode is expected (for example, in a payload, a
field name, a macro address, a length prefix, or a tagless argument) are not
affected.

### Directive Opcodes

| Opcode | Directive     |
|--------|---------------|
| `0xE1` | `set_symbols` |
| `0xE2` | `add_symbols` |
| `0xE3` | `set_macros`  |
| `0xE4` | `add_macros`  |
| `0xE5` | `use`         |
| `0xE6` | `module`      |
| `0xE7` | `import`      |
| `0xE8` | `encoding`    |
| `0xEF` | `end`         |

`0xEF` encodes an `end` directive only in the positions described above.

### Examples

#### Encoding of `(:$ion set_symbols "foo" "bar")`
```
┌──── Opcode 0xE1 indicates a set_symbols directive
│   ┌─── String "foo"
│   │            ┌─── String "bar"
│   │            │            ┌─── End of directive
E1  93 66 6F 6F  93 62 61 72  EF
```

#### Encoding of `(:$ion add_symbols "baz")`
```
┌──── Opcode 0xE2 indicates an add_symbols directive
│   ┌─── String "baz"
│   │            ┌─── End of directive
E2  93 62 61 7A  EF
```

#### Encoding of `(:$ion end)`
```
┌──── Opcode 0xEF where a top-level value could begin indicates an end directive
│
EF
```

#### Encoding of `(:$ion add_symbols "baz")` followed by `(:$ion end)`
```
┌──── Opcode 0xE2 indicates an add_symbols directive
│   ┌─── String "baz"
│   │            ┌─── End of directive
│   │            │  ┌─── Opcode 0xEF after the closed directive is an end directive
E2  93 62 61 7A  EF EF
```

#### Encoding of `(:$ion module foo "com.amazon.Bar" 1)`
```
┌──── Opcode 0xE6 indicates a module directive
│   ┌─── Symbol "foo" (assuming SID 10)
│   │     ┌─── String "com.amazon.Bar"
│   │     │                                             ┌─── Integer 1
│   │     │                                             │      ┌─── End of directive
E6  50 15 9E 63 6F 6D 2E 61 6D 61 7A 6F 6E 2E 42 61 72  61 01  EF
```
