# What's New in Ion 1.1

We will go through a high-level overview of what is new and different in Ion 1.1 from Ion 1.0 from an implementer's
perspective.

## Motivation

Ion 1.1 has been designed to address some of the trade-offs in Ion 1.0 to make it suitable for a wider range of
applications. Ion 1.1 now makes length prefixing of containers optional, and makes the interning of symbolic tokens
optional as well. This allows for applications that write data more than they read data or are constrained by the
writer in some way to have more flexibility. Data density is another motivation. Certain encodings (e.g., timestamps,
integers) have been made more compact and efficient, but more significantly, macros now enable applications to have very
flexible interning of their data's structure. In aggregate, data transcoded from Ion 1.0 to Ion 1.1 should be more
compact.

## Backwards compatibility

Ion 1.1 is backwards compatible with Ion 1.0. While their encodings are distinct, they share the same data model--any data that can be produced and read by an application in Ion 1.1 has an equivalent representation in Ion 1.0.

Ion 1.1 is *not* required to preserve Ion 1.0 binary encodings in Ion 1.1 encoding contexts (i.e., the type codes and
lower-level encodings are not preserved in the new version). The Ion Version Marker (IVM) is used to denote the
different versions of the syntax. Ion 1.1 does retain text compatibility with Ion 1.0 in that the changes are a strict
superset of the grammar, however due to the updated system symbol table, symbol IDs referred to using the `$n` syntax
for symbols beyond the 1.0 system symbol table are not compatible.

## Text syntax changes

Ion 1.1 text *must* use the `$ion_1_1` version marker at the top-level of the data stream or document.

The only syntax change for the text format is the introduction of *encoding expression* (*E-expression*) syntax, which
allows for the invocation of macros in the data stream. This syntax is grammatically similar to S-expressions, except that
these expressions are opened with `(:` and closed with `)`. For example, `(:a 1 2)` would expand the macro named `a` with the
arguments `1` and `2`. See the <<sec:whatsnew-eexp, Macros, Templates, and Encoding-Expressions>> section for details.

This syntax is allowed anywhere an Ion value is allowed:

**E-expression examples**
```ion
// At the top level
(:foo 1 2)

// Nested in a list
[1, 2, (:bar 3 4)]

// Nested in an S-expression
(cons a (:baz b))

// Nested in a struct
{c: (:bop d)}
```

E-expressions are also grammatically allowed in the field name position of a struct and when used there, indicate that
the expression should expand to a struct value that is merged into the enclosing struct:

**E-Expression in field position of struct**
```ion
{
    a:1,
    b:2,
    (:foo 1 2),
    c: 3,
}
```

In the above example, the E-expression `(:foo 1 2)` must evaluate into a struct that will be merged between the `b`
field and the `c` field. If it does not evaluate to a struct, then the above is an error.

## Binary encoding changes

Ion 1.1 binary encoding reorganizes the type descriptors to support compact E-expressions, make certain encodings
more compact, and certain lower priority encodings marginally less compact. The IVM for this encoding is the octet
sequence `0xE0 0x01 0x01 0xEA`.

### Inlined symbolic tokens

In binary Ion 1.0, symbol values, field names, and annotations are required to be encoded using a symbol ID in the local
symbol table. For some use cases (e.g., as write-once, read-maybe logs) this creates a burden on the writer and may not
actually be efficient for an application. Ion 1.1 introduces optional binary syntax for encoding inline UTF-8 sequences
for these tokens which can allow an encoder to have flexibility in whether and when to add a given symbolic token to the
symbol table.

Ion text requires no change for this feature as it already had inline symbolic tokens without using the local symbol
table. Ion text also has compatible syntax for representing the local symbol table and encoding of symbolic tokens with
their position in the table (i.e., the `$id` syntax).

### Delimited containers

In Ion 1.0, all data is length prefixed. While this is good for optimizing the reading of data, it requires an Ion
encoder to buffer any data in memory to calculate the data's length. Ion 1.1 introduces optional binary syntax to allow
containers to be encoded with an end marker instead of a length prefix.

### Low-level binary encoding changes

Ion 1.0's [`VarUInt` and `VarInt` encoding primitives](https://amazon-ion.github.io/ion-docs/docs/binary.html#varuint-and-varint-fields)
used big-endian byte order and used the high bit of each byte to indicate whether it was the final byte in the encoding.
`VarInt` used an additional bit in the first byte to represent the integer's sign. Ion 1.1 replaces these primitives
with more optimized versions called [`FlexUInt`](binary/primitives/flex_uint.md) and [`FlexInt`](binary/primitives/flex_int.md).

`FlexUInt` and `FlexInt` use little-endian byte order, avoiding the need for reordering on common architectures like
x86, aarch64, and RISC-V. 

Rather than using a bit in each byte to indicate the width of the encoding, `FlexUInt` and `FlexInt` front-load
the continuation bits. In most cases, this means that these bits all fit in the first byte of the representation,
allowing a reader to determine the complete size of the encoding without having to inspect each byte individually.

Finally, `FlexInt` does not use a separate bit to indicate its value's sign. Instead, it uses two's complement
representation, allowing it to share much of the same structure and parsing logic as its unsigned counterpart.
Benchmarks have shown that in aggregate, these encoding changes are between 1.25 and 3x faster than Ion 1.0's
`VarUInt` and `VarInt` encodings depending on the host architecture.

Ion 1.1 supplants [Ion 1.0's `Int` encoding primitive](https://amazon-ion.github.io/ion-docs/docs/binary.html#uint-and-int-fields)
with a new encoding called [`FixedInt`](binary/primitives/fixed_int.md), which uses two's complement notation instead of sign-and-magnitude.
A corresponding [`FixedUInt`](binary/primitives/fixed_uint.md) primitive has also been introduced; its encoding is the same as
[Ion 1.0's `UInt` primitive](https://amazon-ion.github.io/ion-docs/docs/binary.html#uint-and-int-fields).

A new primitive encoding type, [`FlexSym`](binary/primitives/flex_sym.md), has been introduced to flexibly encode
symbol IDs and symbolic tokens with inline text.

### Type encoding changes

All Ion types use the new low-level encodings as specified in the previous section. Many of the opcodes used in Ion 1.0
have been re-organized primarily to make E-expressions compact.

Typed `null` values are now [encoded in two bytes using the `0xEB` opcode].

[Lists](binary/values/list.md) and [S-expressions](binary/values/eexp.md) have two encodings:
a length-prefixed encoding and a new delimited form that ends with the `0xF0` opcode.

[Struct](binary/values/struct.md) values have the option of encoding their field names as
a [`FlexSym`](binary/primitives/flex_sym.md), enabling them to write field name text inline
instead of adding all names to the symbol table. There is now also a delimited form.

Similarly, [symbol](binary/values/symbol.md) values now also have the option of encoding
their symbol text inline.

[Annotation sequences](binary/annotations.md) are a prefix to the value they decorate, and no longer have an outer length container. They are now encoded with one of three opcodes:
1. `0xE7`, which is followed by a single annotation and then the decorated value.
2. `0xE8`, which is followed by two annotations and then the decorated value.
3. `0xE9`, which is followed by a `FlexUInt` indicating the number of bytes used to encode the annotations sequence, the sequence itself, and then the decorated value.

The latter encoding is similar to how Ion 1.0 annotations are encoded with the exception that there is no
outer length in addition to the annotations sequence length.

[Integers](binary/values/int.md) now use a `FixedInt` sub-field instead of the Ion 1.0 encoding which used sign-and-magnitude (with two opcodes).

[Decimals](binary/values/decimal.md) are structurally identical to their Ion 1.0 counterpart with the exception
of the negative zero coefficient. The Ion 1.1 `FlexInt` encoding is two's complement, so negative zero cannot be
encoded directly with it. Instead, an opcode is allocated specifically for encoding decimals with a negative zero
coefficient.

[Timestamps](binary/values/timestamp.md) no longer encode their sub-field components as octet-aligned fields.

The Ion 1.1 format uses a packed bit encoding and has a biased form (encoding the year field as an offset from 1970) to
make common encodings of timestamp easily fit in a 64-bit word for microsecond and nanosecond precision (with UTC offset
or unknown UTC offset). Benchmarks have shown this new encoding to be 59% faster to encode and 21% faster to decode.
A non-biased, arbitrary length timestamp with packed bit encoding is defined for uncommon cases.

### Encoding expressions in binary

In binary, [E-expressions](todo.md) are encoded with an opcode that includes the _macro identifier_ or an opcode that
specifies a `FlexUInt` for the macro identifier.
The identifier is followed by the [encoding of the arguments to the E-expression](binary/e_expressions.md).
The macro's definition statically determines how the arguments are to be laid out.
An argument may be a full Ion value with a leading opcode (sometimes called a "tagged" value), or it could be a lower-level encoding (e.g., a fixed width integer or `FlexInt`/`FlexUInt`).

### Macros, templates, and encoding expressions

Ion 1.1 introduces a new primitive called an *encoding expression* (*E-expression*). These expressions are (in text
syntax) similar to S-expressions, but they are not part of the data model and are _evaluated_ into one or more Ion
values (called a _stream_) which enable compact representation of Ion data. E-expressions represent the invocation of
either system defined or user defined *macros* with arguments that are either themselves E-expressions, value literals,
or container constructors (list, sexp, struct syntax containing E-expressions) corresponding to the formal parameters of
the macro's definition. The resulting stream is then expanded into the resulting Ion data model.

At the top level, the stream becomes individual top-level values. Consider for illustrative purposes an E-expression
`(:values 1 2 3)` that evaluates to the stream `1`, `2`, `3` and `(:none)` that evaluates to the empty stream. In the
following examples, `values` and `none` are the names of the macros being invoked and each line is equivalent.

**Top-level e-expressions**
```ion
// Encoding
a (:values 1 2 3) b (:none) c

// Evaluates to
a 1 2 3 b c
```

Within a list or S-expression, the stream becomes additional child elements in the collection.

**E-expressions in lists**
```ion
// Encoding
[a, (:values 1 2 3), b, (:none), c]

// Evaluates to
[a, 1, 2, 3, b, c]
```

**E-expressions in S-expressions**
```ion
(a (:values 1 2 3) b (:none) c)
(a 1 2 3 b c)
```

Within a struct at the field name position, the resulting stream must contain structs and each of the fields in those
structs become fields in the enclosing struct (the value portion is not specified); at the value position, the resulting
stream of values becomes fields with whatever field name corresponded before the E-expression (empty stream elides the
field all together). In the following examples, let us define `(:make_struct c 5)` that evaluates to a single struct
`{c: 5}`.

**E-expressions in structs**
```ion
// Encoding
{
  a: (:values 1 2 3),
  b: 4,
  (:make_struct c 5),
  d: 6,
  e: (:none)
}

// Evaluates to
{
  a: 1,
  a: 2,
  a: 3,
  b: 4,
  c: 5,
  d: 6
}
```

### Encoding context and modules

In Ion 1.0, there is a single _encoding context_ which is the local symbol table. In Ion 1.1, the _encoding context_
becomes the following:

* The local symbol table which is a list of strings. This is used to encode/decode symbolic tokens.

* The local macro table which is a list of macros. This is used to reference macros that can be invoked by
E-expressions.

* A mapping of a string name to *module* which is an organizational unit of symbol definitions and macro definitions.
  Within the encoding context, this name is unique and used to address a module's contents either as the list of symbols
  to install into the local symbol table, the list of macros to install into the local macro table, or to qualify the
  name of a macro in a text E-expression or the definition of a macro.

The *module* is a new concept in Ion 1.1. It contains:

* A list of strings representing the symbol table of the module.

* A list of macro definitions.

Modules can be imported from the catalog (they subsume shared symbol tables), but can also be defined locally. Modules
are referenced as a group to allocate entries in the local symbol table and local macro table (e.g., the local symbol
table is initially, implicitly allocated with the symbols in the `$ion` module).

Ion 1.1 introduces a new system value (an _encoding directive_) for the encoding context (see the *_TBD_* section for
details.)

**Ion encoding directive example**
```ion
$ion_encoding::{
  modules:         [ /* module declarations - including imports */ ],
  install_symbols: [ /* names of declared modules */ ],
  install_macros:  [ /* names of declared modules */ ]
}
```

<div class="warning">
This is still being actively worked and is provisional.
</div>

### Macro definitions

Macros can be defined by a user either directly in a local module within an encoding directive or in a module
defined externally (i.e., shared module). A macro has a name which must be unique in a module *or* it may have no name.

Ion 1.1 defines a list of _system macros_ that are built-in in the module named `$ion`. Unlike the system symbol table,
which is always installed and accessible in the local symbol table, the system macros are both always accessible to
E-expressions and not installed in the local macro table by default (unlike the local symbol table).

In Ion binary, macros are always addressed in E-expressions by the offset in the local macro table. System macros may
be addressed by the system macro identifier using a specific encoding op-code. In Ion text, macros may be addressed by
the offset in the local macro table (mirroring binary), its name if its name is unambiguous within the local encoding
context, or by qualifying the macro name/offset with the module name in the encoding context. An E-expression can
_only_ refer to macros installed in the local macro table or a macro from the system module. In text, an E-expression
referring to a system macro that *is not* installed in the local macro table, must use a qualified name with the `$ion`
module name.

For illustrative purposes let's consider the module named `foo` that has a macro named `bar` at offset 5 installed at
the begining of the local macro table.

**E-expressions name resolution**
```ion
// allowed if there are no other macros named 'bar' 
(:bar)

// fully qualified by module--always allowed
(:foo:bar)

// by local macro table offset
(:5)

// In text, system macros are always addressable by name.
// In binary, system macros may be invoked using a separate
// opcode.
(:$ion:none)
```

### Macro definition language

User defined macros are defined by their parameters and *template* which defines how they are invoked and what stream of
data they evaluate to. This template is defined using a domain specific Ion macro definition language with
S-expressions. A template defines a list of zero or more parameters that it can accept. These parameters each have
their own cardinality of expression arguments which can be specified as _exactly one_, _zero or one_, _zero or more_,
and _one or more_. Furthermore the template defines what type of argument can be accepted by each of these parameters:

* ["Tagged" values](todo.md), whose encodings always begin with an opcode.
* ["Tagless" values](todo.md), whose encodings do not begin with an opcode and are therefore both more compact and less flexible (For example: `flex_int`, `int32`, `float16`).
* Specific [_macro shaped arguments_](todo.md) to allow for structural composition of macros and efficient encoding in binary.

The [macro definition](defining_macros.md) includes a *template body* that defines how the macro is expanded. In the language, system macros, macros defined in previously defined modules in the encoding context, and macros defined previously in the current module are available to be invoked with `(name ...)` syntax where `name` is
the macro to be invoked. Certain names in the expression syntax are reserved for special forms (for example, `literal` and `if_none`). When a macro name is shadowed by a special form, or is ambiguous with respect to all
macros visible, it can always be qualified with `(':module:name' ...)` syntax where `module` is the name of the module
and `name` is the offset or name of the macro. Referring to a previously defined macro name _within_ a module may be
qualified with `(':name' ...)` syntax.

### Shared Modules

Ion 1.1 extends the concept of a _shared symbol table_ to be a _shared module_. An Ion 1.0 shared symbol table is a
shared module with no macro definitions. A new schema for the convention of serializing shared modules in Ion are
introduced in Ion 1.1. An Ion 1.1 implementation should support containing Ion
1.0 shared symbol tables and Ion 1.1 shared modules in its catalog.

## System Symbol Table Changes

The system symbol table in Ion 1.1 replaces the Ion 1.0 symbol table with new symbols. However, the system symbols are
not required to be in the symbol table—they are always available to use.
