## `FixedInt`

A fixed-width, little-endian, signed integer whose length is known from the context in which it appears. Its bytes
are interpreted as two's complement.

#### `FixedInt` encoding of `-3,954,261`
```

1 0 1 0 1 0 1 1  1 0 1 0 1 0 0 1  1 1 0 0 0 0 1 1
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
lowest 8 bits    next 8 bits of   highest 8 bits
of the 2's       the 2's comp.   of the 2's comp.
comp. integer    integer          integer
```
