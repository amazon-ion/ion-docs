## `FlexUInt`

A variable-length unsigned integer.

The bytes of a `FlexUInt` are written in
[little-endian byte order](https://en.wikipedia.org/wiki/Endianness). This means that the first bytes will contain
the `FlexUInt`'s least significant bits.

The least significant bits in the `FlexUInt` indicate the number of bytes that were used to encode the integer.
If a `FlexUInt` is `N` bytes long, its `N-1` least significant bits will be `0`; a terminal `1` bit will be
in the next most significant position.

All bits that are more significant than the terminal `1` represent the magnitude of the `FlexUInt`.

#### `FlexUInt` encoding of `14`
```
              ┌──── Lowest bit is 1 (end), indicating
              │     this is the only byte.
0 0 0 1 1 1 0 1
└─────┬─────┘
unsigned int 14
```

#### `FlexUInt` encoding of `729`
```
             ┌──── There's 1 zero in the least significant bits, so this
             │     integer is two bytes wide.
            ┌┴┐
0 1 1 0 0 1 1 0  0 0 0 0 1 0 1 1
└────┬────┘      └──────┬──────┘
lowest 6 bits    highest 8 bits
of the unsigned  of the unsigned
integer          integer
```

#### `FlexUInt` encoding of `21,043`
```
            ┌───── There are 2 zeros in the least significant bits, so this
            │      integer is three bytes wide.
          ┌─┴─┐
1 0 0 1 1 1 0 0  1 0 0 1 0 0 0 1  0 0 0 0 0 0 1 0
└───┬───┘        └──────┬──────┘  └──────┬──────┘
lowest 6 bits    next 8 bits of   highest 8 bits
of the unsigned  the unsigned     of the unsigned
integer          integer          integer
```
