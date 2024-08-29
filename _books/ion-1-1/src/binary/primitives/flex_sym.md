## `FlexSym`

A variable-length symbol token whose UTF-8 bytes can be inline, found in the symbol table, or derived from a macro
expansion.

A `FlexSym` begins with a [`FlexInt`](#flexint); once this integer has been read, we can evaluate it to determine how to proceed. If the FlexInt is:

* **greater than zero**, it represents a symbol ID. The symbol’s associated text can be found in the local symbol table.
No more bytes follow.
* **less than zero**, its absolute value represents a number of UTF-8 bytes that follow the `FlexInt`. These bytes
represent the symbol’s text.
* **exactly zero**, another byte follows that is a [`FlexSymOpCode`](#flexsymopcode).

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
1 1 1 1 0 1 1 1  01101000  01100101 01101100 01101100 01101111
└─────┬─────┘    └─────────────────────┬─────────────────────┘
  2's comp.              5-byte UTF-8 encoded "hello"
  negative 5
```

### `FlexSymOpCode`

`FlexSymOpCode`s are a combination of [system symbols](../../modules/system_module.md#system-symbols) and a subset of the general [opcodes](../opcodes.md).
The `FlexSym` parser is not responsible for evaluating a `FlexSymOpCode`, only returning it—the caller will decide whether the opcode is legal in the current context.

Example usages of the `FlexSymOpCode` include:
* Representing SID `$0`
* Representing system symbols
  * Note that the empty symbol (i.e. the symbol `''`) is now a system symbol and can be referenced this way.
* When used to encode a struct field name, the opcode can invoke a macro that will evaluate 
  to a struct whose key/value pairs are spliced into the parent [struct](../values/struct.md).
* In a [delimited struct](../values/struct.md#delimited-encoding), terminating the sequence of `(field name, value)` pairs with `0xF0`.


|   OpCode Byte   | Meaning                                       | Additional Notes                                                                                                                                                                                                             |
|:---------------:|:----------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `0x00` - `0x5F` | E-Expression                                  | May be used when the `FlexSym` occurs in the field name position of any struct                                                                                                                                               |
|     `0x60`      | Symbol with unknown text (also known as `$0`) |                                                                                                                                                                                                                              |
| `0x61` - `0xDF` | System SID (with `0x60` bias)                 | While the range of `0x61` - `0xDF` is reserved for system symbols, not all of these bytes correspond to a system symbol. See [system symbols](../../modules/system_module.md#system-symbols) for the list of system symbols. |
|     `0xEE`      | _TODO: Add meaning_                           |                                                                                                                                                                                                                              |
|     `0xEF`      | E-Expression invoking a system macro          | May be used when the `FlexSym` occurs in the field name position of any struct                                                                                                                                               |
|     `0xF0`      | Delimited container end marker                | May only be when the `FlexSym` occurs in the field name position of a delimited struct                                                                                                                                       |
|     `0xF5`      | Length-prefixed macro invocation              | May be used when the `FlexSym` occurs in the field name position of any struct                                                                                                                                               |



#### `FlexSym` encoding of `''` (empty text) using an opcode
```
              ┌─── The leading FlexInt ends in a `1`,
              │    no more FlexInt bytes follow.
              │
0 0 0 0 0 0 0 1   01110111
└─────┬─────┘     └───┬──┘
  2's comp.     FixedInt 0x77,
  zero          System SID 23
                (the empty symbol)
```
