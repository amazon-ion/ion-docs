# RFC: Inline Symbols

- [RFC: Inline Symbols](#rfc-inline-symbols)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Short-lived streams](#short-lived-streams)
    - [Long-lived streams](#long-lived-streams)
    - [Serializing maps, dictionaries, and associative arrays](#serializing-maps-dictionaries-and-associative-arrays)
  - [Inline symbols](#inline-symbols)
    - [Text encoding](#text-encoding)
    - [Binary encoding](#binary-encoding)
      - [`0xF3`: Inline symbol values](#0xf3-inline-symbol-values)
      - [`0xF4`: Structs with inlineable field names](#0xf4-structs-with-inlineable-field-names)
      - [Inlineable annotations](#inlineable-annotations)
        - [`0xE1`: Single inlineable annotation](#0xe1-single-inlineable-annotation)
        - [`0xE2`: Multiple inlineable annotations](#0xe2-multiple-inlineable-annotations)
	- [Inline symbols' relationship to Shared Symbol Tables](#inline-symbols-relationship-to-shared-symbol-tables)
    - [Combining inline symbols with Ion templates](#combining-inline-symbols-with-ion-templates)
  - [Alternatives considered](#alternatives-considered)
    - [Add some new encodings, but not others](#add-some-new-encodings-but-not-others)
    - [Encode maps, dicts, etc as something other than a
      struct](#encode-maps-dicts-etc-as-something-other-than-a-struct)
    - [Structs with ordered fields](#structs-with-ordered-fields)
    - [Disallow inline symbols in symbol tables](#disallow-inline-symbols-in-symbol-tables)
      - [The symbol table is treated as user-level data instead.](#invalid-symbol-table-encodings-are-treated-as-user-data)
      - [The symbol table is ignored.](#the-symbol-table-is-ignored)
      - [An error is raised by the reader.](#an-error-is-raised-by-the-reader)

## Summary

This RFC introduces syntax for defining *inline symbols* in binary Ion.

Inline symbols make it possible to write new struct field names, annotations, and symbols to a
binary Ion stream without first having to modify the active symbol table. This functionality is
already supported in Ion text, which has the option of either indexing into the symbol table
(e.g. `$10`) or defining the symbol inline (e.g. `foo` or `'foo'`).

This capability streamlines the writing process, reduces the memory footprint of both readers and
writers, and can shrink the overall size of the stream.

The changes described in this document are part of the larger [Ion 1.1 RFC](ion_1_1.md#rfc-ion-11).

-----

## Motivation

All Ion streams have a *symbol table*. A symbol table is a list of known strings which can be
referenced by their offset into the list--their *symbol ID*--instead of writing out their complete
text each time.

Ion 1.0's [binary encoding spec](https://amzn.github.io/ion-docs/binary.html) requires that all
symbol values, struct field names, and annotations be encoded as [symbol
IDs](http://amzn.github.io/ion-docs/docs/symbols.html). This means that before a given text value
can be used as a symbol, field name, or annotation, it *must* be added to the symbol table first.

This constraint incurs a number of expenses:

* Writers must examine each top-level value that they intend to emit (however deeply nested) to
  determine which of its symbols, field names, and annotations are not yet in the symbol table.
* If any such elements are found, a new Local Symbol Table (LST) or LST-append must be written
  to the stream establishing a new symbol ID for each of those elements.
* Writing the top-level value itself must be deferred until the new symbols are added to the table, 
  necessitating additional buffering of encoded output.
* Both readers and writers must hold the complete symbol table in memory. The more entries there
  are in the symbol table, the more memory it will consume.
* Symbol IDs are encoded as variable-length unsigned integers. The more symbol IDs there are, the
  more bytes it will take to encode the newest symbol IDs.
  
The symbol ID encoding requirement is designed to amortize the cost of writing out the complete text
of recurring text elements over the lifetime of the Ion stream; by paying an up-front cost to
detect and define new symbols, all future references to the same text element can be made
substantially cheaper to write. These overhead costs are worthwhile for symbols that are frequently
referenced. However, there are a variety of use cases for which the costs are never recouped.

### Short-lived streams

Consider this short-lived Ion text stream representing data collected from a weather station:

```js
{
  sensorId: 12345,
  type: sensorData,
  reading: {
    temperature: celsius::12.5,
    time: 2020-10-22T16:00:00Z
  }
}
```

When the same data is re-encoded in binary, all of the symbols, struct field names, and annotations
must be added to a local symbol table definition that appears at the beginning of the stream.

```js
$ion_1_0
$ion_symbol_table::{ // Add all of our symbols, field names, and annotations to the symbol table
  symbols: [
    "sensorId",   // $10
    "type",       // $11
    "sensorData", // $12
    "reading",    // $13
    "temperature",// $14
    "celsius",    // $15
    "time",       // $16
  ]
}
{
  $10: 12345, // Then encode our symbols, field names, and annotations as symbol IDs
  $11: $12,
  $13: {
    $14: $15::12.5,
	$16: 2020-10-22T16:00:00Z
  }
}
```

The symbol ID encoding requirement forces us to process our sensor data twice: once to detect any
symbols, annotations, and field names that needed to be added to the symbol table and once to write
the sensor data itself. However, because none of the values being added to the symbol table appear
more than once, we do not benefit from the compactness of the symbol ID encodings. The overhead
associated with adding each of them to the symbol table slows down the writing process and inflates
the overall size of the data.

| Format | Size in Bytes |
|:--|:--:|
| Text | 94 |
| Binary | 100 |

In some cases, this can be partially addressed by using a Shared Symbol Table at the cost of
complexity. See the section [*Inline symbols' relationship to Shared Symbol
Tables*](#inline-symbols-relationship-to-shared-symbol-tables) for more information.

### Long-lived streams

In long-lived Ion streams, the symbol ID encoding mandate can cause the symbol table to become quite
large.  This causes two problems:

1. Both Readers and Writers are required to hold the entire symbol table in memory. The larger it
   becomes, the more memory it consumes. Left unchecked, this can lead to program crashes, making it
   a potential denial-of-service vector.
2. Symbol IDs are encoded as variable-length unsigned integers; higher ID numbers require more bytes
   to encode. Adding infrequently referenced text to the symbol table means that more valuable
   symbols will be costlier to write out.
   
The only way to remove entries from the active symbol table is to reset it or import a different one.
In either case, we are likely to discard very valuable symbols along with those that are infrequently
referenced. Re-adding the valuable symbols later wastes processing time and adds to the size of the
stream. Being more selective about which symbols are added to the symbol table would mitigate these
issues.

### Serializing maps, dictionaries, and associative arrays

Ion's `struct` data type closely resembles the classes, records, and structs found in a variety
of programming languages. This makes it a natural choice as a serialized representation for such
values.

Consider this example of a Java class:

```java
public class Quux {
  public String foo;
  public String bar;
  public int baz;

  // ... rest of the class
}
```

In Ion streams that contain several serialized instances of this class, we are guaranteed to recoup
the data size cost of adding `foo`, `bar`, and `baz` to the symbol table. The fields in the class
are a fixed set, so every serialized instance will need to reference each field.

Ion's `struct` data type also acts as a mapping from text keys to values of any data type. This
closely (though often imperfectly) aligns with common data types available in a variety of
programming languages, including Java's `Map<String, Object>`, JavaScript's `Object`, and so on.

Consider this example of a Python dictionary:

```python
logins_by_user_id = {
  'f354c586' : ["2020-11-05T12:01:17.900Z", "2020-11-06T21:08:16.965Z"],
  'd3f712ea' : ["2019-07-21T11:24:55.000Z", "2020-05-11T19:44:01.044Z"],
  '467cba51' : ["2020-10-03T01:51:30.011Z", "2020-10-29T22:40:40.331Z"],
}
```

Unlike classes and their analogs, the keys used in a series of maps written to an Ion stream are not
guaranteed to be the same over time. Maps using high-cardinality values like UUIDs and datetimes as
keys will have keys that never repeat.

In these cases, creating symbol IDs for these keys pollutes the symbol table; it creates additional
entries that readers and writers must store in memory but which do not provide any data size
savings. Once added, the only way to remove these values from the symbol table is to reset it. This
discards valuable symbols in the process, requiring them to be detected again downstream.

## Inline symbols

Inline symbols are an optional encoding which allow the text of a symbol, annotation, or field name to
be specified within the value itself rather than as an entry in the active symbol table. Conceptually,
they are analogous to the way symbols are encoded in text Ion.

Inline symbols give writers the flexibility to decide whether and when to add a given string to the
symbol table, allowing them to make trade-offs in data size, throughput, and memory consumption.

### Text encoding

*This RFC does not propose any syntax changes for Ion text. This description of Ion text is provided
for convenient comparison.*

In Ion text, symbols can be written out in full mid-stream without first adding them to the symbol table.

For example, in this Ion struct:

```js
{
    foo: [1, 2, 3],
    bar: true,
    baz: quux
}
```

the symbols `foo`, `bar`, `baz`, and `quux` are all defined at their usage site. These "inline"
symbols are not in the symbol table and do not have a symbol ID.

[`SymbolToken`](http://amzn.github.io/ion-docs/guides/symbols-guide.html#structures)
representations of such symbols
[contain the inline text and an undefined import
location](http://amzn.github.io/ion-docs/guides/symbols-guide.html#reading-symboltokens).

### Binary encoding

The following sections describe how an inline symbol would be encoded in each of the following use
cases:

1. Symbol values
2. Struct field names
3. Annotations
   1. Sequences of annotations on a value
   2. A single annotation on a value

#### `0xF3`: Inline symbol values

This encoding is identical to 
[the `VarUInt`-length encoding for string values](http://amzn.github.io/ion-docs/docs/binary.html#8-string)
with the exception of the leading type descriptor byte (`0x8E` vs `0xF3`).

A `Length` field containing the number of bytes in the UTF8 representation must always be provided.
If the `Length` is zero, the symbol's text is the empty string. It is not possible to encode
`symbol.null` using type descriptor `0xF3`.

```
        7       4 3       0
        +---------+---------+
        |   15    |    3    |
        +---------+---------+======+
        |     Length [VarUInt]     |
        +--------------------------+
        |     UTF8 Representation  |
        +--------------------------+
```

While many applications simply treat strings and symbols as different encoding options for text,
others rely on the distinction between the types for their business logic. Providing this encoding
ensures that a symbol value can be written as cheaply as a string value in any use case.

#### `0xF4`: Structs with inlineable field names

Structs with inlineable field names can encode their field names as either symbol IDs or
inline text. The encoding need not be homogenous; some fields can use symbol IDs while
others use inline text.

Inline symbol structs have a type descriptor byte of `0xF4`. A `Length` field containing the number
of bytes in the struct's representation must always follow the type descriptor byte. Because
non-empty structs must have at least one field and one value, a `Length` of 1 is illegal. (This
constrasts with Ion 1.0's `0xC1` struct encoding, which guarantees that fields are ordered by symbol
ID. For more details, see the section [*Structs with ordered fields*](#structs-with-ordered-fields).

Inlineable field names are encoded as a `VarInt` (not a `VarUInt`). The sign bit is used
to indicate whether the field name has been encoded as a symbol ID or as inline text.


```
        7       4 3       0
        +---------+---------+
        |   15    |    4    |
        +---------+---------+======+
        :     length [VarUInt]     :
        +==========================+=================================================+
        : field name [VarInt + optional UTF8 representation]  :        value         :
        +============================================================================+
                    ⋮                     ⋮
```

If the `VarInt` is positive, then its magnitude represents a symbol ID. Its text can be found in
the active symbol table.

If the `VarInt` is negative, then its magnitude represents the length of the field name's UTF8
representation, which follows immediately after the `Length`.

For example, this struct:
```js
{
    $37: 5,
    foo: 9
} 
```
could be encoded as:
```
                   f  o  o
F4 89 A5 21 05 C3 66 6f 6f 21 09
 ^  ^  ^  ^  ^  ^           ^  ^---- Value for "foo": 9
 |  |  |  |  |  |           +------- 1-byte positive integer
 |  |  |  |  |  +------------------- 0b1100_0011 / VarInt -3 / a 3-byte inline text field name ("foo")
 |  |  |  |  +---------------------- Value for $37: 5
 |  |  |  +------------------------- 1-byte positive integer
 |  |  +---------------------------- 0b1010_0101 / VarInt 37 / symbol ID field name ($37)
 |  +------------------------------- VarUInt Length: 9 bytes
 +---------------------------------- Type descriptor: inline symbol struct
```

If the sign bit is positive and the magnitude is zero, the field name is symbol ID `0`.

If the sign bit is negative and the magnitude is zero, the field name is the empty string.

The [existing rules for NOP padding in struct
fields](http://amzn.github.io/ion-docs/docs/binary.html#nop-padding-in-struct-fields) also apply to
this representation.

#### Inlineable annotations

This RFC adds two new encodings for annotations:
1. An encoding that (like [Ion 1.0's
   encoding](http://amzn.github.io/ion-docs/docs/binary.html#annotations)) supports annotation
   sequences of arbitrary size.
2. An encoding that is optimized for the most common case, in which there is a single annotation.

Both encodings support inline symbol definitions using the `VarInt` encoding scheme described in
the section [*Structs with inlineable field names*](#0xf4-structs-with-inlineable-field-names).

Because Ion 1.0's wrapper encoding cannot be shorter than 3 bytes, `0xE1` and `0xE2` were not legal
type descriptor bytes. We use them in Ion 1.1 to represent our new encodings.

##### `0xE2`: Multiple inlineable annotations

[Ion 1.0's annotations encoding](http://amzn.github.io/ion-docs/docs/binary.html#annotations) uses a
'wrapper' to associate a set of annotations with a given value. The wrapper contains a sequence of
annotation symbol IDs followed by the value being annotated. The wrapper's header provides separate
length fields for both:

1. **The total size of the encoded symbol ID sequence and the encoded value.** This allows the
   reader to skip over the entire wrapper if needed, moving to the next value in the Ion stream.
2. **The size of the encoded symbol ID sequence.** This allows the reader to skip over the
   annotations, moving to the annotated value inside the wrapper.

For example, this value:
```js
Author::"Ernest Hemingway"
```
would be encoded in binary Ion as:
```
                   E  r  n  e  s  t     H  e  m  i  n  g  w  a  y
EE 94 81 8A 8E 90 45 72 6E 65 73 74 20 48 65 6D 69 6E 67 77 61 79 
 ^  ^  ^  ^  ^  +---- Length: 16 bytes
 |  |  |  |  +------- String w/VarUInt Length
 |  |  |  +---------- Annotation symbol ID $10
 |  |  +------------- Annotations Length: 1 byte
 |  +---------------- Annotations+Value Length: 20 bytes 
 +------------------- Annotation wrapper w/VarUInt Length
```
*(The above assumes that 'Author' is already in the active symbol table as `$10`.)*

In practice, few readers leverage the ability to skip the entire wrapper due in part to their need
to read the wrapped value's type descriptor byte before deciding whether the value can be skipped.
Additionally, the wrapped values themselves already specify their encoded size. This means that two
of the four annotation header bytes in the above example are of dubious value.

In contrast, Ion 1.1's `0xE2` encoding includes a single `length` field containing the number of
bytes used to encode the annotation sequence. This field not include the length of the value itself,
which provides a length encoding of its own.

```
            7       4 3       0
            +---------+---------+
Value with  |   14    |    2    |
multiple    +---------+---------+=======================================+
annotations :     length [VarUInt]                                      :
            +-----------------------------------------------------------+
            :     annotation [VarInt + optional UTF8 representation]    : ...
            +-----------------------------------------------------------+
            :     value                                                 :
            +-----------------------------------------------------------+
```

To skip an annotation sequence, the reader must read the `VarUInt` `length` and skip that number of
bytes. The reader will then be positioned over the annotated value, which it can read or skip as
needed.

Annotations are written using the `VarInt`-based encoding described in the section [*Structs with
inlineable field names*](#0xf4-structs-with-inlineable-field-names). They do not need to be encoded
homogenously; writers can write some annotations in the sequence as symbol IDs and others as inline
text.

##### `0xE1`: Single inlineable annotation

An unscientific review of sample Ion 1.0 data found that values that have annotations at all most
commonly have a single annotation. Our `0xE1` encoding is optimized for this use case by not
requiring a `Length` field at all.

```
            7       4 3       0
            +---------+---------+
Value with  |   14    |    1    |
singleton   +---------+---------+=======================================+
annotation  :     annotation [VarInt + optional UTF8 representation]    :
            +-----------------------------------------------------------+
            |                           value                           |
            +-----------------------------------------------------------+
```

When a `0xE1` type descriptor byte is encountered, it is always followed by a single `VarInt`-based
encoding of the necessary annotation symbol, either as an ID or as inline UTF-8 text. (See the
section [*Inline symbol structs*](#0xf4-structs-with-inlineable-field-names) for more detail.)

Returning to our earlier example, this value:

```js
Author::"Ernest Hemingway"
```

could be encoded either using inline text:

```
       A  u  t  h  o  r        E  r  n  e  s  t     H  e  m  i  n  g  w  a  y
E1 C6 41 75 74 68 6f 72 8E 90 45 72 6E 65 73 74 20 48 65 6D 69 6E 67 77 61 79 
 |  |                    |  +--- VarUInt Length: 16 bytes
 |  |                    +------ String w/VarUInt Length
 |  +--------------------------- VarInt -6: 6 bytes of inline text
 +------------------------------ Singleton annotation	
```

or using a symbol ID:

```
             E  r  n  e  s  t     H  e  m  i  n  g  w  a  y
E1 CA 8E 90 45 72 6E 65 73 74 20 48 65 6D 69 6E 67 77 61 79 
 |  |  |  +---- VarUInt Length: 16 bytes
 |  |  +------- String w/VarUInt Length
 |  +---- VarInt 10: symbol ID $10
 +------- Singleton annotation
```

To skip a `0xE1`-encoded annotation, the reader must read the annotation's `VarInt`. If it is negative, the
reader must skip that number of bytes to move beyond the UTF8 bytes that follow it. The reader will
then be positioned over the annotated value, which it can read or skip as needed.

### Inline symbols' relationship to Shared Symbol Tables

Ion 1.0 provides [Shared Symbol
Tables](http://amzn.github.io/ion-docs/docs/symbols.html#shared-symbol-tables) (SSTs)
as a mechanism for reducing the overhead of defining a set of symbols in a stream.

Here we revisit our example weather station data from the [Short-lived
streams](#short-lived-streams) section, which used a Local Symbol Table to define all of the symbols
it needed at the beginning of the stream:

```js
$ion_1_0
$ion_symbol_table::{ // Add all of our symbols, field names, and annotations to the symbol table
  symbols: [
    "sensorId",   // $10
    "type",       // $11
    "sensorData", // $12
    "reading",    // $13
    "temperature",// $14
    "celsius",    // $15
    "time",       // $16
  ]
}
{
  $10: 12345, // Then encode our symbols, field names, and annotations as symbol IDs
  $11: $12,
  $13: {
    $14: $15::12.5,
	$16: 2020-10-22T16:00:00Z
  }
}
```

Because this struct layout is going to be reused frequently, the weather service could have instead
created an SST with all of the necessary symbols:

```js
$ion_1_0
$ion_shared_symbol_table::{
  name: "com.example.weather.symbols",
  version: 1,
  symbols: [ // Create a Shared Symbol Table with the necessary symbols
    "sensorId"",
    "type",
    "sensorData",
    "reading",
    "temperature",
    "celsius",
    "time",
  ]
}
```

and then imported it at the head of each datagram:

```js
$ion_1_0
$ion_symbol_table::{ // Import the SST that we defined above
  imports: [{name: "com.example.weather.symbols", version: 1}]
}
{
  $10: 12345, // Encode the weather data using the imported symbols
  $11: $12,
  $13: {
    $14: $15::12.5,
	$16: 2020-10-22T16:00:00Z
  }
}
```

This eliminates the need to write the UTF8 bytes of each expected symbol's text in the datagram
itself, shrinking the total size of the data. This benefit comes at the cost of complexity; the
stream is no longer self-contained. Readers and writers must coordinate to ensure that they both
have access to the same SSTs. If the set of symbols changes, the writer will need to
ensure that a new version of the SST is made available.

In the case of *expected symbols*--symbols which a writer is likely to reference in a given
stream--SSTs and inline symbols can offer similar benefits. Both allow the writer to avoid writing a
Local Symbol Table definition at the beginning of an Ion stream. Streams that repeatedly reference
the same symbols and systems that reuse symbols across many streams will both benefit more from an
SST than from inline symbols if the complexity cost is acceptable.

In the case of *unexpected symbols*--symbols which a writer did not anticipate referencing but must
emit anyway--SSTs offer no benefit. Common sources of unexpected symbols might include timestamps,
generated identifiers like UUIDs, or content authored by a third party over which a writer has no
authority. Such values cannot be enumerated in advance and so cannot be added to an SST; in Ion 1.0,
writing them to the stream requires a Local Symbol Table definition. Using inline symbols, however,
writers can avoid emitting a symbol table definition no matter what symbols, field names, and
annotations they encounter in the stream.

Writers have no way of knowing in advance whether the active symbol table contains *all* of the
symbols, field names, and annotations that they will be asked to write. As such, the full symbol
discovery phase of writing still has to happen for every value, even if no new symbols will ever be
found. Inline symbols make it possible to eliminate some of this processing overhead. For example, a
writer leveraging inline symbols may opt to perform lookups to see if a value is already in the
symbol table, but avoid the work of adding it to the table if it is not. Alternatively, a writer
could avoid *all* symbol table lookups for portions of a stream by always writing the text of any
symbols, field names, and annotations inline.

### Combining inline symbols with Ion templates

When combined with [Ion
Templates](https://github.com/amzn/ion-docs/blob/ion-templates-rfc/rfcs/ion_templates.md#rfc-ion-templates),
inline symbols can further reduce the number of symbol IDs that must be added to the symbol table.
	
Consider a template representing a class called `com.example.project.Quux`:

```js
$ion_1_1

// Define a template composed of several symbols:

$ion_symbol_table::{
  templates: [
    com.example.project.Quux::{ // Template 1, a struct with 3 blanks
	  foo: {#0},
	  bar: {#0},
	  baz: {#0}
	}
  ]
}

// Invoke template 1 with various different parameters

{#1 1 2 3}
{#1 4 5 6}
{#1 7 8 9}

// The above invocations are equivalent to:

com.example.project.Quux::{
  foo: 1,
  bar: 2,
  baz: 3,
}
com.example.project.Quux::{
  foo: 4,
  bar: 5,
  baz: 6,
}
com.example.project.Quux::{
  foo: 7,
  bar: 8,
  baz: 9,
}
```

If we use inline symbol definitions for `foo`, `bar`, `baz`, and `com.example.project.Quux` in our
template definition, we do not need to add them to the symbol table. By allocating a single template
ID, we can produce a compact representation of a struct composed of several symbols without growing
the symbol table.

If the template is frequently used, it can be placed in a Shared Symbol Table.

## Alternatives considered

### Add some new encodings, but not others

For example, add inline symbol structs but not inline symbol values. This would conserve type
descriptor values and reduce the scope of the changes needed for Ion 1.1. However, it would
eliminate a key feature for writers.

Inline symbol definitions make it possible for writers to serialize a number of values without
having to modify the active symbol table. This makes it possible to:
1. Enforce restrictions on the size of the active symbol table (either by number of entries or data
size) without having to resort to resetting it.
2. Batch changes to the symbol table to avoid frequent LST appends.
3. Guarantee that all changes to the symbol table happen at particular offsets. (For example,
symbol table appends only appear every 8MB in a stream.) This makes it possible to skip-scan
over huge streams while only checking at each 8MB offset to see if there are symbol table changes
that need to be processed.

### Encode maps, dicts, etc as something other than a struct

For example, write maps out as lists of key/value pairs:

```js
[(foo, 1), (bar, 2), (baz, 3)]
```

or lists in which even-indexed entries are keys and odd-indexed entries are their associated
values:

```js
[foo, 1, bar, 2, baz, 3]
```

Such solutions are implemented as a layer on top of the Ion data model itself, which presents
additional challenges. All applications relying on a custom representation of a map must perform
their own validation to guarantee that every key has an associated value and that each key is a
string or symbol value. Tools such as [PartiQL](https://partiql.org/) that are designed to work with
Ion will not recognize custom representations as maps, meaning that convenient syntax meant to work
with key/value data will not function as expected.

### Structs with ordered fields

Structs cannot have a length of one byte. An empty struct will occupy zero bytes while a struct with
a single field will have a minimum of two bytes (one for the field name and one for the value). Ion
1.0 uses a length code of 1 to instead indicate that the struct's fields appear in ascending order
by symbol ID. The Ion 1.0 [struct encoding spec](amzn.github.io/ion-docs/docs/binary.html#13-struct)
states:

> Binary-encoded structs support a special case where the fields are known to be sorted such that
> the field-name integers are increasing. This state exists when L is one.

We cannot trivially offer the same special case for [structs with inlineable field
names](#0xf4-structs-with-inlineable-field-names). Field names which are defined as inline text will
not have a symbol ID by which they can be ordered. While other encodings could be substituted (for
example: "fields appear ordered lexicographically by their text"), the value proposition of such
alternatives is unknown. As such, Ion 1.1 reserves the `Length=1` encoding for a future version of
Ion to leverage.

### Disallow inline symbols in symbol tables

The Ion 1.0 spec describes system-level values like symbol tables in terms of high-level constructs.
For example: a local symbol table is a top-level struct whose first annotation is
`$ion_symbol_table`. If present, the `imports` and `symbols` fields of such structs have special
meaning.

Because binary Ion 1.0 only had one way to encode these constructs, reader implementations would
often hardcode low-level, encoding-specific checks for symbol table processing. For example:

* Checking for type code `13` to test for a struct.
* Checking whether the annotations list started with symbol ID `3` (`$ion_symbol_table`).
* Looking for a struct field with symbol ID `6` (`imports`) or `7` (`symbols`).

Allowing inlineable encodings to be used in symbol tables requires that readers check for higher-level
constructs in the stream, which can involve multiple low-level checks:

* Checking for type code `13` (a struct) OR type descriptor byte `0xF4` (struct with inlineable field names).
* Checking whether the annotations list started with a symbol with text `$ion_symbol_table`,
  regardless of its encoding.
* Looking for struct fields with the name `imports` or `symbols` regardless of their encoding.

This adds a modest amount of flexibility at the expense of implementation complexity. It may be
tempting to instead forbid the use of the new inlineable encodings within system-level values.
However, doing so would present complexities of its own.

Mandating a single encoding for system-level constructs requires usages of the disallowed encodings
lead to one of the following behaviors:

1. [The symbol table is treated as user-level data
   instead.](#invalid-symbol-table-encodings-are-treated-as-user-data)
2. [The symbol table is ignored.](#the-symbol-table-is-ignored)
3. [An error is raised by the reader.](#an-error-is-raised-by-the-reader)

None of these alternatives are particularly appealing. Given the costs involved, the format symmetry
offered by allowing inlineable encodings everywhere seems like a worthwhile benefit.

#### Invalid symbol table encodings are treated as user data

Data written in binary Ion must be able to survive 'round-tripping' (re-writing it in text, then
once again in binary) without data loss. If some encodings can cause symbol tables to be treated as
user-level data instead, an analogous encoding must exist in text that allows this distinction to be
maintained during round-tripping. However, Ion text writers can already opt to use inline encodings
when writing out a symbol table. We would need to invent a new text syntax to support this low-value
special case, allowing text writers to represent it losslessly.

#### The symbol table is ignored

Consider as precedent: the [Ion 1.0
specification](http://amzn.github.io/ion-docs/docs/symbols.html#ion-version-markers) states that at
the top level, any encoding of the Ion Version Marker other than the unquoted, unannotated literal
`$ion_1_0` is "a system value that has no processing semantics (a NOP)."

This behavior exists because it is not possible to distinguish between an Ion Version Marker and a
symbol with the same text during round-tripping. It is a special case that was codified to resolve
an ambiguity that arose after the initial 1.0 spec was published.

Disallowing inlineable encodings in system values would create a similar problem, which might make
re-using this solution attractive. However, ignoring values in the stream offers substantial
downsides. Writing data that will be ignored by all parties is worse than writing nothing at all; it
takes resources to write, resources to read, and bloats the size of the data stream for no benefit.
It also risks confusing the writer, who was able to go through the motions of writing a symbol table
without an error being raised only to see no benefit.

#### An error is raised by the reader

In this scenario, writers are prevented from writing symbol tables that leverage structs with
inlineable field names, annotations with inlineable text, or inline symbols.

This is the most pragmatic of the available options. Unfortunately, it conflicts with one of the
primary benefits of inline symbols: defining templates without first defining symbols that will
appear in the template. For example:

```js
$ion_1_1
$ion_symbol_table::{
  templates: [
    {
      foo: {#0}, // Using a struct with inlineable field names allows us to avoid defining 
      bar: {#0}, // foo, bar, and baz as distinct symbol IDs.
      baz: {#0},
    }
  ]
}
```

Supporting this use case means carving out an exception for the `templates` field in our ban on
inlineable encodings. Similar exceptions might be needed for open content as well as future Ion
version features.
