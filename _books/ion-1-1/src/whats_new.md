# What's New in Ion 1.1

We will go through a high-level overview of what is new and different in Ion 1.1 from Ion 1.0 from an implementer's
perspective.

## Motivation

Ion 1.1 has been designed to address some of the trade-offs in Ion 1.0 to make it suitable for a wider range of
applications, giving greater greater representational choice and expressive power.
Some applications want to optimize writes over reads, or are constrained by the writer in some way (e.g. it's prohibitively expensive to buffer an entire value before writing). Ion 1.1 now makes both length prefixing of containers and the interning of symbol tokens independently optional, granting such writers greater flexibility. 
Data density is another motivation. Certain encodings (e.g., timestamps,
integers) have been made more compact and efficient. More significantly, macros now enable applications to have very
flexible interning of their data's structure. In aggregate, data transcoded from Ion 1.0 to Ion 1.1 should be more
compact and more efficient to both read and write.

## Backwards compatibility

Ion 1.0 and Ion 1.1 share the same data model.
Any data that can be represented in Ion 1.0 can also be represented with full fidelity in Ion 1.1 and vice-versa.
This means that it is always possible to convert data from one version to the other without risk of data loss.

Ion 1.1 readers should be able to understand both Ion 1.0 and Ion 1.1 data.

The text encoding grammar of Ion 1.1 is a superset of Ion 1.0's text encoding grammar.
Any Ion 1.0 text data can also be parsed by an Ion 1.1 text parser.

> [!NOTE] Because Ion 1.1 has a different system symbol table,
> symbol IDs in an Ion 1.0 stream do not always refer to the same text as the same symbol ID in an Ion 1.1 stream.
> For example: in an Ion 1.0 stream, `$4` is always the text `"name"`. However, `$4` may or may not be `"name"` in an Ion 1.1 stream. It may instead be user symbol 4 if the user has chosen not to export the system symbols.

Ion 1.1's binary encoding is substantially different from Ion 1.0's binary encoding.
Many changes have been made to make values more compact, faster to read and/or faster to write.
Ion 1.0's [type descriptors](https://amazon-ion.github.io/ion-docs/docs/binary.html#typed-value-formats)
have been supplanted by Ion 1.1's more general [opcodes](binary/opcodes.md),
which have been organized to prioritize the most commonly used encodings and make leveraging macros as inexpensive as possible.

In both text and binary Ion 1.1, the Ion Version Marker syntax is compatible with Ion 1.0's version marker syntax.

This means that an Ion 1.0-only reader can correctly identify when a stream uses Ion 1.1 (allowing it to report an error),
and an Ion 1.1 reader can correctly "downshift" to expecting Ion 1.0 data when it encounters a stream using Ion 1.0.

Two streams using different Ion versions can be safely concatenated together provided that they are both text or both binary.
A concatenated stream containing both Ion 1.0 and Ion 1.1 can only be fully read by a reader that supports Ion 1.1.

Upgrading an existing application to Ion 1.1 often requires little-to-no code changes,
as APIs typically operate at the data model level ("write an integer")
rather than at the encoding level ("write `0x64` followed by four Little-Endian bytes").
However, taking full advantage of macros after upgrading typically requires additional development time.

## Macros, templates, and encoding expressions

Ion 1.1 introduces a new primitive called an *encoding expression* (*E-expression*). These expressions are (in text
syntax) similar to S-expressions, but they are not part of the data model and are _evaluated_ into one or more Ion
values (called a _stream_) which enable compact representation of Ion data. E-expressions represent the invocation of
either system defined or user defined *macros* with arguments that are either themselves E-expressions, value literals,
or container constructors (list, sexp, struct syntax containing E-expressions) corresponding to the formal parameters of
the macro's definition. The resulting stream is then expanded into the resulting Ion data model.

**Top-level e-expressions**
At the top level, the stream becomes individual top-level values. Consider for illustrative purposes an E-expression
`(:values 1 2 3)` that evaluates to the stream `1`, `2`, `3` and `(:none)` that evaluates to the empty stream. In the
following examples, `values` and `none` are the names of the macros being invoked and each line is equivalent.

```ion
// Encoding
a (:values 1 2 3) b (:none) c

// Evaluates to
a 1 2 3 b c
```

**E-expressions in lists or S-expressions**
<!-- TODO: Move this (or copy it) to a dedicated section on e-expression expansion -->
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
// Encoding
(a (:values 1 2 3) b (:none) c)

// Evaluates to
(a 1 2 3 b c)
```

**E-expressions in structs**

Within a struct at the field name position, the resulting stream must contain structs and each of the fields in those
structs become fields in the enclosing struct (the value portion is not specified); at the value position, the resulting
stream of values becomes fields with whatever field name corresponded before the E-expression (empty stream elides the
field all together). In the following examples, let us define `(:make_struct { c: 5 })` that evaluates to a single struct
`{c: 5}`.

```ion
// Encoding
{
  a: (:values 1 2 3),
  b: 4,
  (:make_struct { c: 5 }),
  (:make_field d 6),
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



### Macro definitions

Macros can be defined by a user either directly in a default module within an encoding directive or in a module
defined externally (i.e., shared module). A macro has a name which must be unique in a module *or* it may have no name.

Ion 1.1 defines a list of _system macros_ that are built-in in the module named `$ion`. Unlike the system symbol table,
which is always installed and accessible in the local symbol table, the system macros are both always accessible to
E-expressions and not installed in the local macro table by default (unlike the local symbol table).

In Ion binary, macros are always addressed in E-expressions by integer macro address. For user macros this is the offset in the local macro table. System macros may be addressed by the system macro address using a specific encoding op-code. In Ion text, macros may be addressed by
the offset in the local macro table (mirroring binary), by name, or by qualifying the macro name/offset with the module name in the encoding context. An E-expression can
_only_ refer to macros installed in the local macro table or a macro from the system module. In text, an E-expression
referring to a system macro that *is not* installed in the local macro table, must use a qualified name with the `$ion`
module name.

For illustrative purposes let's consider the module named `foo` that has a macro named `bar` at offset 5 installed at
the begining of the local macro table.

**E-expressions name resolution**
```ion
// allowed if there are no other macros named 'bar' 
(:bar)

// fully qualified by module–always allowed
(:foo::bar)

// by local macro table offset
(:5)

// In text, system macros are always addressable by name.
// In binary, system macros may be invoked using a separate
// opcode.
(:$ion:none)
```

### Template definition language

User defined macros are defined by their parameters and *template* which defines how they are invoked and what stream of
data they evaluate to. This template is defined using a domain specific Ion macro definition language with
S-expressions. A template defines a list of zero or more parameters that it can accept. These parameters each have
their own cardinality of expression arguments which can be specified as _exactly one_, _zero or one_, _zero or more_,
and _one or more_. Furthermore the template defines what type of argument can be accepted by each of these parameters:

* ["Tagged" values](todo.md), whose encodings always begin with an opcode.
* ["Tagless" values](todo.md), whose encodings do not begin with an opcode and are therefore both more compact and less flexible (For example: `flex_int`, `int32`, `float16`).
* Specific [_macro shaped arguments_](todo.md) to allow for structural composition of macros and efficient encoding in binary.

The [macro definition](macros/defining_macros.md) includes a *template body* that defines how the macro is expanded. In the language, system macros, macros defined in previously defined modules in the encoding context, and macros defined previously in the current module are available to be invoked with `(.name ...)` syntax where `name` is
the macro to be invoked. Certain names in the expression syntax are reserved for special forms (for example, `literal` and `if_none`). When a macro name is shadowed by a special form, or is ambiguous with respect to all
macros visible, it can always be qualified with `(.module::name ...)` syntax where `module` is the name of the module
and `name` is the offset or name of the macro. Referring to a previously defined macro name _within_ a module may be
qualified with `(.name ...)` syntax.

## Modules

Ion 1.0 uses symbol tables to group together related text values.
In order to also accommodate macros, Ion 1.1 introduces _modules_, a named organizational unit that contains:
* **An exported symbol table**, a list of text values used to compactly encode symbol tokens like field names, annotations, and symbol values.
* **An exported macro table**, a list of macro definitions used to compactly encode complete values or partially populated containers.
* **An unexported nested modules map**, a set of unique module names and their associated module definitions.

While Ion 1.0 does not have modules, it is reasonable to think of Ion 1.0's local symbol table as a module that only has symbols,
and whose macro table and nested modules map are permanently empty.

Modules can be imported from the catalog (they subsume shared symbol tables) or defined locally.

### Directives

_Directives_ modify the encoding context.
Syntactically, a directive is a top-level s-expression annotated with `$ion`.
Its first child value is an operation name.
The operation determines what changes will be made to the encoding context and which clauses may legally follow.

```ion
$ion::
(operation_name
    (clause_1 /*...*/)
    (clause_2 /*...*/)
    /*...*/
    (clause_N /*...*/))
```

In Ion v1.1, there are three supported directive operations:
1. [`module`](modules/directives.md#module-directives)
2. [`import`](modules/directives.md#import-directives)
3. [`encoding`](modules/directives.md#encoding-directives)

### Shared Modules

Ion 1.1 extends the concept of a _shared symbol table_ to be a _shared module_. An Ion 1.0 shared symbol table is a
shared module with no macro definitions. A new schema for the convention of serializing shared modules in Ion are
introduced in Ion 1.1. An Ion 1.1 implementation should support containing Ion
1.0 shared symbol tables and Ion 1.1 shared modules in its catalog.


## System Symbol Table Changes

The system symbol table in Ion 1.1 replaces the Ion 1.0 symbol table with new symbols. However, the system symbols are
not required to be in the symbol table—they are always available to use.

## Text syntax changes

Ion 1.1 text *must* use the `$ion_1_1` version marker at the top-level of the data stream or document.

The only syntax change for the text format is the introduction of *encoding expression* (*E-expression*) syntax, which
allows for the invocation of macros in the data stream. This syntax is grammatically similar to S-expressions, except that
these expressions are opened with `(:` and closed with `)`. For example, `(:a 1 2)` would expand the macro named `a` with the
arguments `1` and `2`. This syntax is allowed anywhere an Ion value is allowed, and may also appear in the field name position of a struct. See the _[Macros, templates, and encoding expressions](#macros-templates-and-encoding-expressions)_ section for details.


## Binary encoding changes

Ion 1.1 binary encoding reorganizes the type descriptors to support compact E-expressions, make certain encodings
more compact, and certain lower priority encodings marginally less compact (for greater detail see [Type Encoding Changes](#type-encoding-changes)). The IVM for this encoding is the octet
sequence `0xE0 0x01 0x01 0xEA`.

### Inlined symbol tokens

In binary Ion 1.0, symbol values, field names, and annotations are required to be encoded using a symbol ID in the local symbol table. For some use cases (e.g. RPC or small, independent values where the symbol table overhead cannot be amortized) this creates a burden on the writer and may not actually be efficient for an application. Ion 1.1 introduces optional binary syntax for encoding inline UTF-8 sequences for these tokens which can allow an encoder to have flexibility in whether and when to add a given text value to the symbol table.

Ion text requires no change for this feature as it already had inline symbol tokens without using the local symbol
table. Ion text also has compatible syntax for representing the local symbol table and encoding of symbol tokens with
their position in the table (i.e., the `$id` syntax).

See [`FlexSym`](binary/primitives/flex_sym.md) documentation for greater detail. 

### Delimited containers

In Ion 1.0, all data is length prefixed. While this is good for optimizing the reading of data, it requires an Ion
encoder to buffer any data in memory to calculate the data's length. Ion 1.1 introduces optional binary syntax to allow
containers to be encoded with an end marker instead of a length prefix.

See the relevant [list](binary/values/list.md#delimited-encoding), [sexp](binary/values/sexp.md#delimited-encoding), and [struct](binary/values/struct.md#delimited-encoding) deliited encoding sections for greater detail.

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
A corresponding [`FixedUInt`](binary/primitives/fixed_uint.md) primitive has also been introduced; its encoding is nearly the same as
[Ion 1.0's `UInt` primitive](https://amazon-ion.github.io/ion-docs/docs/binary.html#uint-and-int-fields), save that `UInt` is big endian where `FixedUInt` is little endian.

A new primitive encoding type, [`FlexSym`](binary/primitives/flex_sym.md), has been introduced to flexibly encode
symbol IDs and symbol tokens with inline text.

> [!TIP]
> `FlexSym` makes it possible for a writer to emit _any_ Ion value as binary without requiring a symbol table. This is generally less efficient when working with multiple values but there are use cases where it is convenient.

### Type encoding changes

All Ion types use the new low-level encoding primitives described in the previous section.
Ion 1.0's [type descriptors](https://amazon-ion.github.io/ion-docs/docs/binary.html#typed-value-formats)
have been supplanted by Ion 1.1's more general [opcodes](binary/opcodes.md),
which have been organized to prioritize the most commonly used encodings and make leveraging macros as inexpensive as possible.

Typed `null` values are now [encoded in two bytes using the `0xEB` opcode](binary/values/null.md#nulls). 

Symbol IDs greater than two bytes no longer have dedicated type descriptors- the 65537th and on symbols defined in a stream will take an extra byte each to represent in the stream.

[Lists](binary/values/list.md) and [S-expressions](binary/values/sexp.md) have two encodings:
a length-prefixed encoding and a new delimited form that ends with the `0xF0` opcode.

[Struct](binary/values/struct.md) values have the option of encoding their field names as
a [`FlexSym`](binary/primitives/flex_sym.md), enabling them to write field name text inline
instead of adding all names to the symbol table. There is now also a delimited form.

Similarly, [symbol](binary/values/symbol.md) values now also have the option of encoding
their symbol text inline.

[Annotation sequences](binary/annotations.md) are a prefix to the value they decorate, and no longer have an outer length container. They are now encoded with one of the six opcodes `0xE4` through `0xE9`.
* Opcodes `0xE4` through `0xE6` indicate one or more annotations encoded as symbol addresses.
* Opcodes `0xE7` through `0xE9` indicate one or more annotations encoded as a [`FlexSym`](primitives/flex_sym#flexsym).

The `0xE6` encoding is similar to how Ion 1.0 annotations are encoded with the exception that there is no
outer length in addition to the annotations sequence length.

[Integers](binary/values/int.md) now use a `FixedInt` sub-field instead of the Ion 1.0 encoding which used sign-and-magnitude (with two opcodes).

[Decimals](binary/values/decimal.md) are structurally identical to their Ion 1.0 counterpart with the exception
of the negative zero coefficient. The Ion 1.1 `FlexInt` encoding is two's complement, so negative zero cannot be
encoded directly with it. Instead, an opcode is allocated specifically for encoding decimals with a negative zero
coefficient.

[Timestamps](binary/values/timestamp.md) no longer encode their sub-field components as octet-aligned fields.

The Ion 1.1 format uses a packed bit encoding and has a biased form (encoding the year field as an offset from 1970) to
make common encodings of timestamp easily fit in a 64-bit word for microsecond and nanosecond precision (with UTC offset
or unknown UTC offset). Benchmarks have shown this new encoding to be 40% smaller, 59% faster to encode and 21% faster to decode in-range timestamps.
A non-biased, arbitrary length timestamp with packed bit encoding is defined for uncommon cases.

### Encoding expressions in binary

See the binary [E-expressions](binary/e_expressions.md) documentation to learn more about how e-expressions are encoded in binary.

