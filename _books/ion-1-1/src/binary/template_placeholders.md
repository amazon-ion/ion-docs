# Template Placeholders

> [!NOTE]
> This chapter focuses on the binary encoding of template placeholders.
> The [_Macros_](../macros.md) section explains what they are and how they are used.

Template placeholders are special constructs used within macro template bodies to indicate where macro arguments should be substituted.
They are encoded using opcodes `0xE8`, `0xE9`, and `0xEA`.

Placeholders may only occur in _value_ position, only within a macro body; they are illegal anywhere else.

### Placeholder Types

| Opcode | Placeholder Type                           |
|--------|--------------------------------------------|
| `0xE8` | Tagged template placeholder (no default)   |
| `0xE9` | Tagged template placeholder (with default) |
| `0xEA` | Tagless template placeholder               |

### Tagged Template Placeholder with No Default

Opcode `0xE8` indicates a tagged template placeholder with no default value. No additional bytes follow.

##### Encoding of `(:?)`
```
┌──── Opcode 0xE8 indicates a tagged template placeholder with no default
E8
```

##### Encoding of `foo::(:?)`
```
      ┌── Annotation text: foo
┌─────┴──────┐ ┌──── Opcode 0xE8 indicates a tagged template placeholder with no default
59 07 66 6F 6F E8
```

### Tagged Template Placeholder with Default

Opcode `0xE9` indicates a tagged template placeholder with a default value.
The default value follows and may be any value or e-expression that produces a value.
A `NOP` is legal, and ignored.

##### Encoding of `(:? "foo")`
```
┌──── Opcode 0xE9 indicates a tagged template placeholder with default
│   ┌─── Default value: string "foo"
E9  93 66 6F 6F
```

##### Encoding of `(:? 42)`
```
┌──── Opcode 0xE9 indicates a tagged template placeholder with default
│   ┌─── Default value: integer 42
E9  61 2A
```

##### Encoding of `(:? 42)` with `NOP`
```
┌──── Opcode 0xE9 indicates a tagged template placeholder with default
│   ┌─── NOP
│   │   ┌─── Default value: integer 42
E9  EC  61 2A
```

##### Encoding of `(:? $10::false)`
```
┌──── Opcode 0xE9 indicates a tagged template placeholder with default
│   
│     ┌──── Annotation SID: $10
│   ┌─┴─┐ ┌─── The annotated value: `false`
E9  58 15 6F
    └──┬───┘
    The default value: `$10::false`
```


### Tagless Template Placeholder

Opcode `0xEA` indicates a tagless template placeholder.
A single byte follows indicating the tagless scalar type that the argument must conform to.
No additional bytes follow.

##### Encoding of `(:?\int8\)`
```
┌──── Opcode 0xEA indicates a tagless template placeholder
│  ┌─── Tagless scalar type: int8 (0x61)
EA 61
```

##### Encoding of `(:?\uint32\)`
```
┌──── Opcode 0xEA indicates a tagless template placeholder
│  ┌─── Tagless scalar type: uint32 (0xE4)
EA E4
```

##### Encoding of `(:?\string\)`
```
┌──── Opcode 0xEA indicates a tagless template placeholder
│  ┌─── Tagless scalar type: string (0xF9)
EA F9
```
