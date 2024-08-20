## `FlexInt`
A variable-length signed integer.

From an encoding perspective, `FlexInt`s are structurally similar to a [`FlexUInt`](flex_uint.md). Both
encode their bytes using little-endian byte order, and both use the count of least-significant zero bits to indicate
how many bytes were used to encode the integer. They differ in the _interpretation_ of their bits; while a
`FlexUInt`'s bits are unsigned, a `FlexInt`'s bits are encoded using
[two's complement notation](https://en.wikipedia.org/wiki/Two%27s_complement).

TIP: An implementation could choose to read a `FlexInt` by instead reading a `FlexUInt` and then reinterpreting its bits
as two's complement.

#### `FlexInt` encoding of `14`
```
              ┌──── Lowest bit is 1 (end), indicating
              │     this is the only byte.
0 0 0 1 1 1 0 1
└─────┬─────┘
 2's comp. 14
```

#### `FlexInt` encoding of `-14`
```
              ┌──── Lowest bit is 1 (end), indicating
              │     this is the only byte.
1 1 1 0 0 1 0 1
└─────┬─────┘
 2's comp. -14
```

#### `FlexInt` encoding of `729`
```
             ┌──── There's 1 zero in the least significant bits, so this
             │     integer is two bytes wide.
            ┌┴┐
0 1 1 0 0 1 1 0  0 0 0 0 1 0 1 1
└────┬────┘      └──────┬──────┘
lowest 6 bits    highest 8 bits
of the 2's       of the 2's
comp. integer    comp. integer
```

#### `FlexInt` encoding of `-729`
```
             ┌──── There's 1 zero in the least significant bits, so this
             │     integer is two bytes wide.
            ┌┴┐
1 0 0 1 1 1 1 0  1 1 1 1 0 1 0 0
└────┬────┘      └──────┬──────┘
lowest 6 bits    highest 8 bits
of the 2's       of the 2's
comp. integer    comp. integer
```