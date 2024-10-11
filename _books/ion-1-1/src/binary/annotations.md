## Annotations

Annotations can be encoded either [as symbol addresses](#annotations-with-symbol-addresses) or
[as `FlexSym`s](#annotations-with-flexsym-text). In both encodings, the annotations sequence appears
just before the value that it decorates.

It is illegal for an annotations sequence to appear before any of the following:

* The end of the stream
* Another annotations sequence
* A [`NOP`](nop.md)
* An e-expression. To add annotations to the _expansion_ of an E-expression, see [the `annotate` macro](../todo.md).


### Annotations With Symbol Addresses
Opcodes `0xE4` through `0xE6` indicate one or more annotations encoded as symbol addresses. If the opcode is:

* `0xE4`, a single [`FlexUInt`](primitives/flex_uint.md#flexuint)-encoded symbol address follows.
* `0xE5`, two [`FlexUInt`](primitives/flex_uint.md#flexuint)-encoded symbol addresses follow.
* `0xE6`, a [`FlexUInt`](primitives/flex_uint.md#flexuint) follows that represents the number of bytes needed to encode
the annotations sequence, which can be made up of any number of `FlexUInt` symbol addresses.

##### Encoding of `$10::false`
```
┌──── The opcode `0xE4` indicates a single annotation encoded as a symbol address follows
│  ┌──── Annotation with symbol address: FlexUInt 10
E4 15 6F
      └── The annotated value: `false`
```

##### Encoding of `$10::$11::false`
```
┌──── The opcode `0xE5` indicates that two annotations encoded as symbol addresses follow
│  ┌──── Annotation with symbol address: FlexUInt 10 ($10)
│  │  ┌──── Annotation with symbol address: FlexUInt 11 ($11)
E5 15 17 6F
         └── The annotated value: `false`
```

##### Encoding of `$10::$11::$12::false`
```
┌──── The opcode `0xE6` indicates a variable-length sequence of symbol address annotations;
│     a FlexUInt follows representing the length of the sequence.
│   ┌──── Annotations sequence length: FlexUInt 3 with symbol address: FlexUInt 10 ($10)
│   │  ┌──── Annotation with symbol address: FlexUInt 10 ($10)
│   │  │  ┌──── Annotation with symbol address: FlexUInt 11 ($11)
│   │  │  │  ┌──── Annotation with symbol address: FlexUInt 12 ($12)
E5 07 15 17 19 6F
               └── The annotated value: `false`
```

### Annotations With `FlexSym` Text

Opcodes `0xE7` through `0xE9` indicate one or more annotations encoded as [`FlexSym`](primitives/flex_sym#flexsym)s.

If the opcode is:

* `0xE7`, a single `FlexSym`-encoded symbol follows.
* `0xE8`, two `FlexSym`-encoded symbols follow.
* `0xE9`, a `FlexUInt` follows that represents the byte length of the annotations sequence, which is
made up of any number of annotations encoded as ``FlexSym``s.

While this encoding is more flexible than [annotations with symbol addresses](#annotations-with-symbol-addresses)
it can be slightly less compact when all the annotations are encoded as symbol addresses.

##### Encoding of `$10::false`
```
┌──── The opcode `0xE7` indicates a single annotation encoded as a FlexSym follows
│  ┌──── Annotation with symbol address: FlexSym 10 ($10)
E7 15 6F
      └── The annotated value: `false`
```

##### Encoding of `foo::false`
```
┌──── The opcode `0xE7` indicates a single annotation encoded as a FlexSym follows
│  ┌──── Annotation: FlexSym -3; 3 bytes of UTF-8 text follow
│  │   f  o  o
E7 FD 66 6F 6F 6F
      └──┬───┘ └── The annotated value: `false`
      3 UTF-8
       bytes
```

Note that `FlexSym` annotation sequences can switch between symbol address and inline text
on a per-annotation basis.

##### Encoding of `$10::foo::false`
```
┌──── The opcode `0xE8` indicates two annotations encoded as FlexSyms follow
│  ┌──── Annotation: FlexSym 10 ($10)
│  │  ┌──── Annotation: FlexSym -3; 3 bytes of UTF-8 text follow
│  │  │   f  o  o
E8 15 FD 66 6F 6F 6F
         └──┬───┘ └── The annotated value: `false`
         3 UTF-8
          bytes
```

##### Encoding of `$10::foo::$11::false`
```
┌──── The opcode `0xE9` indicates a variable-length sequence of FlexSym-encoded annotations
│  ┌──── Length: FlexUInt 6
│  │  ┌──── Annotation: FlexSym 10 ($10)
│  │  │  ┌──── Annotation: FlexSym -3; 3 bytes of UTF-8 text follow
│  │  │  │           ┌──── Annotation: FlexSym 11 ($11)
│  │  │  │   f  o  o │
E9 0D 15 FD 66 6F 6F 17 6F
            └──┬───┘    └── The annotated value: `false`
            3 UTF-8
             bytes
```
