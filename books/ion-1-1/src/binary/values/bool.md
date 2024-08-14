## Booleans

`0x6E` represents boolean `true`, while `0x6F` represents boolean `false`.

`0xEB 0x00` represents `null.bool`.

##### Encoding of boolean `true`
```
6E
```

##### Encoding of boolean `false`
```
6F
```

##### Encoding of `null.bool`
```
┌──── Opcode 0xEB indicates a typed null; a byte follows specifying the type
│  ┌─── Null type: boolean
│  │
EB 00
```