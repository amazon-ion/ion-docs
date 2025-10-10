# Template Placeholders

> [!NOTE]
> This chapter focuses on the binary encoding of template placeholders.
> The [_Macros_](../macros.md) section explains what they are and how they are used.

Template placeholders are special constructs used within macro template bodies to indicate where macro arguments should be substituted.
They are encoded using opcodes `0xE9`, `0xEA`, and `0xEB`.

Placeholders may only occur in _value_ position, only within a macro body; they are illegal anywhere else.

### Placeholder Types

| Opcode | Placeholder Type                           |
|--------|--------------------------------------------|
| `0xE9` | Tagged template placeholder (no default)   |
| `0xEA` | Tagged template placeholder (with default) |
| `0xEB` | Tagless template placeholder               |

### Tagged Template Placeholder with No Default

Opcode `0xE9` indicates a tagged template placeholder with no default value. No additional bytes follow.

##### Encoding of `(:?)`
```
┌──── Opcode 0xE9 indicates a tagged template placeholder with no default
E9
```

##### Encoding of `foo::(:?)`
```
      ┌── Annotation text: foo
┌─────┴──────┐ ┌──── Opcode 0xE9 indicates a tagged template placeholder with no default
59 07 66 6F 6F E9
```

### Tagged Template Placeholder with Default

Opcode `0xEA` indicates a tagged template placeholder with a default value.
The default value follows and may be any value or e-expression that produces a value.
A `NOP` is legal, and ignored.

##### Encoding of `(:? "foo")`
```
┌──── Opcode 0xEA indicates a tagged template placeholder with default
│   ┌─── Default value: string "foo"
EA  93 66 6F 6F
```

##### Encoding of `(:? 42)`
```
┌──── Opcode 0xEA indicates a tagged template placeholder with default
│   ┌─── Default value: integer 42
EA  61 2A
```

##### Encoding of `(:? 42)` with `NOP`
```
┌──── Opcode 0xEA indicates a tagged template placeholder with default
│   ┌─── NOP
│   │   ┌─── Default value: integer 42
EA  EC  61 2A
```

##### Encoding of `(:? $10::false)`
```
┌──── Opcode 0xEA indicates a tagged template placeholder with default
│   
│     ┌──── Annotation SID: $10
│   ┌─┴─┐ ┌─── The annotated value: `false`
EA  58 15 6F
    └──┬───┘
    The default value: `$10::false`
```


### Tagless Template Placeholder

Opcode `0xEB` indicates a tagless template placeholder.
A single byte follows indicating the tagless scalar type that the argument must conform to.
No additional bytes follow.

##### Encoding of `(:? {#int8})`
```
┌──── Opcode 0xEB indicates a tagless template placeholder
│  ┌─── Tagless scalar type: int8 (0x61)
EB 61
```

##### Encoding of `(:? {#uint32})`
```
┌──── Opcode 0xEB indicates a tagless template placeholder
│  ┌─── Tagless scalar type: uint32 (0xE4)
EB E4
```

##### Encoding of `(:? {#string})`
```
┌──── Opcode 0xEB indicates a tagless template placeholder
│  ┌─── Tagless scalar type: string (0xF9)
EB F9
```
