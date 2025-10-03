## Directives

Directives are system values that modify the encoding context.

> [!NOTE]
> This chapter focuses on the binary encoding of directives. 
> The [_Directives_](../modules/directives.md) section explains what they are and how they are used.

The binary encoding of directives is a specialized delimited container.
Directives are opened using opcodes `0xE1` through `0xE7`.
They may contain any number of tagged values, and they are closed with the end-container opcode (`0xEF`).

Directives may only occur at the top level of a stream and may not be annotated.

### Directive Opcodes

| Opcode | Directive     |
|--------|---------------|
| `0xE1` | `set_symbols` |
| `0xE2` | `add_symbols` |
| `0xE3` | `set_macros`  |
| `0xE4` | `add_macros`  |
| `0xE5` | `use`         |
| `0xE6` | `module`      |
| `0xE7` | `encoding`    |

### Examples

#### Encoding of `(:$set_symbols "foo" "bar")`
```
┌──── Opcode 0xE1 indicates a set_symbols directive
│   ┌─── String "foo"
│   │            ┌─── String "bar"
│   │            │            ┌─── End of directive
E1  93 66 6F 6F  93 62 61 72  EF
```

#### Encoding of `(:$add_symbols "baz")`
```
┌──── Opcode 0xE2 indicates an add_symbols directive
│   ┌─── String "baz"
│   │            ┌─── End of directive
E2  93 62 61 7A  EF
```

#### Encoding of `(:$module foo "com.amazon.foo.Bar" 1)`
```
┌──── Opcode 0xE6 indicates a module directive
│   ┌─── Symbol "foo" (assuming SID 10)
│   │     ┌─── String "com.amazon.Bar"
│   │     │                                             ┌─── Integer 1
│   │     │                                             │      ┌─── End of directive
E6  50 15 9E 63 6F 6D 2E 61 6D 61 7A 6F 6E 2E 42 61 72  61 01  EF
```
