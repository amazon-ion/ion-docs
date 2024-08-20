## `FixedUInt`

A fixed-width, little-endian, unsigned integer whose length is inferred from the context in which it appears.

#### `FixedUInt` encoding of `3,954,261`
```

0 1 0 1 0 1 0 1  0 1 0 1 0 1 1 0  0 0 1 1 1 1 0 0
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
lowest 8 bits    next 8 bits of   highest 8 bits
of the unsigned  the unsigned     of the unsigned
integer          integer          integer
```