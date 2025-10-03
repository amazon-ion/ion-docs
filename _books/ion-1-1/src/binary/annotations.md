## Annotations

Annotations can be encoded either [as symbol addresses](#annotation-with-symbol-address) or
[as text](#annotation-with-text). One or more annotations is an annotation sequence.

It is illegal for an annotations sequence to appear before any of the following:

* The end of the stream
* A [`NOP`](nop.md)
* An [IVM](opcodes.md)
* A [Directive](directives.md)

### Annotation with Symbol Address

Opcode `0x58` indicates an annotation encoded as a symbol ID. A [`FlexUInt`](primitives/flex_uint.md#flexuint)-encoded symbol address follows.

##### Encoding of `$10::false`
```
┌──── The opcode `0x58` indicates an annotation encoded as a symbol ID follows
│  ┌──── Annotation with symbol address: FlexUInt 10
58 15 6F
      └── The annotated value: `false`
```

### Annotation with Text

Opcode `0x59` indicates an annotation encoded as inline text. A [`FlexUInt`](primitives/flex_uint.md#flexuint) length follows, then that many bytes of UTF-8 text.

##### Encoding of `foo::false`
```
┌──── The opcode `0x59` indicates an annotation encoded as text follows
│  ┌──── Length: FlexUInt 3 (3 bytes of UTF-8 text follow)
│  │   f  o  o
59 07 66 6F 6F 6F
      └──┬───┘ └── The annotated value: `false`
      3 UTF-8
       bytes
```

### Multiple Annotations

Multiple annotations are encoded by repeating the annotation opcodes in sequence.

##### Encoding of `$10::foo::false`
```
┌──── First annotation: symbol ID
│  ┌──── Symbol address: FlexUInt 10 ($10)
│  │  ┌──── Second annotation: text
│  │  │  ┌──── Length: FlexUInt 3
│  │  │  │   f  o  o
58 15 59 07 66 6F 6F 6F
            └──┬───┘ └── The annotated value: `false`
            3 UTF-8
             bytes
```

##### Encoding of `$10::$11::$12::false`
```
  ┌──── First annotation: symbol ID 10
  │      ┌──── Second annotation: symbol ID 11  
  │      │      ┌──── Third annotation: symbol ID 12
┌─┴─┐  ┌─┴─┐  ┌─┴─┐   ┌──── Annotated value: `false`
58 15  58 17  58 19  6F
