## Floats

Float values are encoded using the IEEE-754 specification in little-endian byte order. Floats can be serialized in
four sizes:

* 0 bits (0 bytes), representing the value 0e0 and indicated by opcode `0x6A`
* 16 bits (2 bytes in little-endian order, [half-precision](https://en.wikipedia.org/wiki/Half-precision_floating-point_format)),
indicated by opcode `0x6B`
* 32 bits (4 bytes in little-endian order, [single precision](https://en.wikipedia.org/wiki/Single-precision_floating-point_format)),
indicated by opcode `0x6C`
* 64 bits (8 bytes in little-endian order, [double precision](https://en.wikipedia.org/wiki/Double-precision_floating-point_format)),
indicated by opcode `0x6D`

> [!NOTE]
> In the Ion data model, float values are always 64 bits. However, if a value can be losslessly serialized
> in fewer than 64 bits, Ion implementations may choose to do so.

`0xEB 0x02` represents `null.float`.

##### Encoding of float `0e0`
```
┌──── Opcode in range 6A-6D indicates a float
│┌─── Low nibble A indicates
││    a 0-length float; 0e0
6A
```

##### Encoding of float `3.14e0`
```
┌──── Opcode in range 6A-6D indicates a float
│┌─── Low nibble B indicates a 2-byte float
││
6B 47 42
   └─┬─┘
half-precision 3.14
```

##### Encoding of float `3.1415927e0`
```
┌──── Opcode in range 6A-6D indicates a float
│┌─── Low nibble C indicates a 4-byte,
││    single-precision value.
6C DB 0F 49 40   
   └────┬────┘
single-precision 3.1415927
```

##### Encoding of float `3.141592653589793e0`
```
┌──── Opcode in range 6A-6D indicates a float
│┌─── Low nibble D indicates an 8-byte,
││    double-precision value.
6D 18 2D 44 54 FB 21 09 40       
   └──────────┬──────────┘
double-precision 3.141592653589793
```

##### Encoding of `null.float`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: float
│  │
EB 02
```