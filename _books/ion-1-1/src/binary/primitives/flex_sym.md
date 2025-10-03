## `FlexSym`

A variable-length symbol token whose UTF-8 bytes can be inline or found in the symbol table.

A `FlexSym` begins with a [`FlexInt`](flex_int.md); once this integer has been read, we can evaluate it to determine how to proceed. If the FlexInt is:

* **non-negative**, it represents a symbol ID. The symbol's associated text can be found in the local symbol table. No more bytes follow.
* **negative**, the symbol text is encoded as a number of UTF-8 bytes that follow the FlexInt. The number of bytes is calculated by `-1 - flexInt`.
    (This is because 0 is already in use as SID 0, so text length needs to be offset by 1 to support zero-length text.)

#### `FlexSym` encoding of symbol ID `$10`
```
              ┌─── The leading FlexInt ends in a `1`,
              │    no more FlexInt bytes follow.
              │
0 0 0 1 0 1 0 1
└─────┬─────┘
  2's comp.
  positive 10
```

#### `FlexSym` encoding of symbol text `'hello'`
```
              ┌─── The leading FlexInt ends in a `1`,
              │    no more FlexInt bytes follow.
              │      h         e        l        l        o
1 1 1 1 0 1 0 1  01101000  01100101 01101100 01101100 01101111
└─────┬─────┘    └─────────────────────┬─────────────────────┘
  2's comp.              5-byte UTF-8 encoded "hello"
  negative 6
```

#### `FlexSym` encoding of empty symbol text `''`
```
              ┌─── The leading FlexInt ends in a `1`,
              │    no more FlexInt bytes follow.
              │
1 1 1 1 1 1 1 1
└─────┬─────┘
  2's comp.
  negative 1
