 RFC: Inline Symbols

* [Summary](#summary)
* [Motivation](#motivation)
* [Inline symbols](#inline-symbols)
* [Usage with templates](#usage-with-templates)

## Summary

This RFC introduces syntax for defining *inline symbols* in binary Ion.

Inline symbols make it possible to write new struct field names, annotations, and symbols to a
binary Ion stream without first having to modify the active symbol table. This functionality is
already supported in Ion text, which has the option of either indexing into the symbol table
(e.g. `$10`) or defining the symbol inline (e.g. `foo` or `'foo'`).

This capability streamlines the writing process, reduces the memory footprint of both readers and
writers, and can shrink the overall size of the stream.

The changes described in this document are part of the larger Ion 1.1 RFC. TODO(add link)

## Motivation

All Ion streams have a *symbol table*. A symbol table is a list of known strings which can
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
* Both Readers and Writers must hold the complete symbol table in memory. The more entries there
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
  sensorId,   // $10
  type,       // $11
  sensorData, // $12
  reading,    // $13
  temperature,// $14
  celsius,    // $15
  time,       // $16
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

### Long-lived streams

In long Ion streams, the symbol ID encoding mandate can cause the symbol table to become quite large.
This causes two problems:

1. Both Readers and Writers are required to hold the entire symbol table in memory. The larger it
   becomes, the more memory this consumes.
2. Symbol IDs are encoded as variable-length unsigned integers; higher ID numbers require more bytes
   to encode.
   
The only way to remove entries from the active symbol table is to reset it or import a different one.
In either case, we are likely to discard very valuable symbols along with those that are infrequently
referenced. Re-adding the valuable symbols later wastes processing time and adds to the size of the
stream.

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
the data size cost of adding `foo`, `bar`, and `baz` to the symbol table. The class's fields are a
fixed set, so every serialized instance will need to reference each field.

Ion's `struct` data type also act as a mapping from text keys to values of any data type. This
closely (though often imperfectly) aligns with common data types available in a variety of
programming languages, including Java's `Map<String, Object>`, Javascript's `Object`, and so on.

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
keys will have keys that never repeat at all.

In these cases, creating symbol IDs for these keys pollutes the symbol table; it creates additional
entries that readers and writers must store in memory but which do not provide any data size
psavings. Once added, the only way to remove these values from the symbol table is to reset it
altogether. This discards valuable symbols in the process, requiring them to be detected again.


## Inline symbols

Inline symbols are an optional encoding which allow the text of a symbol, annotation, or field name to
be specified within the value itself rather than as an entry in the active symbol table. Conceptually,
they are analogous to the way symbols are encoded in text Ion.

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
  a. Singular annotation on a value
  b. Collections of annotations on a value

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

#### `0xF4`: Inline symbol structs

Inline symbol structs are structs whose field names can be encoded as either symbol IDs or
inline symbols. The encoding need not be homogenous; some fields can use symbol IDs while
others use inline symbols.

Inline symbol structs have a type descriptor byte of `0xF4`. A `Length` field containing the number
of bytes in the struct's representation must always follow the type descriptor byte.

Inline symbol structs' field names are encoded as a `VarInt` (not a `VarUInt`). The sign bit is used
to indicate whether the field name has been encoded as an inline symbol or as a symbol ID. 


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
 |  |  |  |  |  +------------------- 0b1100_0011 / VarInt -3 / a 3-byte inline symbol field name ("foo")
 |  |  |  |  +---------------------- Value for $37: 5
 |  |  |  +------------------------- 1-byte positive integer
 |  |  +---------------------------- 0b1010_0101 / VarInt 37 / symbol ID field name ($37)
 |  +------------------------------- VarUInt Length: 9 bytes
 +---------------------------------- Type descriptor: inline symbol struct
```

If the sign bit is positive and the magnitude is zero, the field name is the empty string.

If the sign bit is negative and the magnitude is zero, the field name is symbol ID `0`.

The [existing rules for NOP padding in struct
fields](http://amzn.github.io/ion-docs/docs/binary.html#nop-padding-in-struct-fields) also apply to
this representation.

#### Inline annotations

Ion 1.0's [existing encoding for
annotations](http://amzn.github.io/ion-docs/docs/binary.html#annotations) uses a 'wrapper' to
associate a set of annotations with a given value. The wrapper contains a sequence of annotation
symbol IDs followed by the value being annotated. The wrapper's header provides separate length
fields for both:

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
 |	|  |  +---------- Annotation symbol ID $10
 |	|  +------------- Annotations Length: 1 byte
 |	+---------------- Annotations+Value Length: 20 bytes 
 +------------------- Annotation wrapper w/VarUInt Length
```
*(The above assumes that 'Author' is already in the active symbol table as `$10`.)*


In practice, few readers leverage this capability due in part to their need to read the wrapped
value's type descriptor byte before deciding whether the value can be skipped. Additionally, the
wrapped values themselves already specify their encoded size. This means that two of the four
Annotation header bytes in the above example are of dubious value.

This RFC adds two new encodings for annotations:
1. An encoding that is optimized for the most common case, in which there is a single annotation.
2. An encoding that is optimized for the case in which a value has multiple annotations.

Both encodings support inline symbol definitions using the `VarInt` encoding scheeme described in
[Inline symbol structs](#inline-symbol-structs).

Because Ion 1.0's wrapper encoding cannot be shorter than 3 bytes, type descriptor bytes `0xE1` and
`0xE2` were not legal type descriptor bytes. We use them in Ion 1.1 to represent our new encodings.

##### `0xE1`: Single inline symbol annotation

```js
            7       4 3       0
            +---------+---------+
Value with  |   14    |    1    |
singleton   +---------+---------+=======================================+
annotation  :     annotation [VarInt + optional UTF8 representation]    :
            +-----------------------------------------------------------+
            |                           value                           |
            +-----------------------------------------------------------+
```

Unlike most encodings, singleton annotation encodings do not include an `L` or `Length` field. When
a `0xE1` type descriptor byte is encountered, it is always followed by a `VarInt`-based encoding of
the necessary annotation symbol, either as an ID or as inline UTF-8 text. (See [Inline symbol
structs](#inline-symbol-structs) for more detail.)

Returning to our earlier example, this value:

```js
Author::"Ernest Hemingway"
```

would be encoded either using inline symbol text:

```js
       A  u  t  h  o  r        E  r  n  e  s  t     H  e  m  i  n  g  w  a  y
E1 C6 41 75 74 68 6f 72 8E 90 45 72 6E 65 73 74 20 48 65 6D 69 6E 67 77 61 79 
 |  |                    |  +--- VarUInt Length: 16 bytes
 |	|					 +------ String w/VarUInt Length
 |	+--------------------------- VarInt -6: a 6-byte inline symbol
 +------------------------------ Singleton annotation	
```

or using a symbol ID:

```js
             E  r  n  e  s  t     H  e  m  i  n  g  w  a  y
E1 CA 8E 90 45 72 6E 65 73 74 20 48 65 6D 69 6E 67 77 61 79 
 |  |  |  +---- VarUInt Length: 16 bytes
 |  |  +------- String w/VarUInt Length
 |  +---- VarInt 10: symbol ID $10
 +------- Singleton annotation
```

To skip a singleton annotation, the reader must read the `VarInt`. If it is negative, the reader
must skip that number of bytes to move beyond the UTF8 bytes that follow it. The reader will then
be positioned over the annotated value, which it can read or skip as needed.

##### `0xE2`: Multiple inline symbol annotations

```js
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

Unlike the singleton annotation encoding, the encoding for a value with multiple annotations
includes a `length` field that indicates the number of bytes that will be used to represent
the sequence of annotations that follow. It does not include the length of the value itself,
which provides a length encoding of its own.

Annotations in the sequence do not need to be encoded homogenously; writers can write some
annotations as symbol IDs and others as inline text. (See [Inline symbol
structs](#inline-symbol-structs) for more detail.)

To skip an annotation sequence, the reader must read the `VarUInt` `length` and skip that number of
bytes. The reader will then be positioned over the annotated value, which it can read or skip as
needed.

### Combining inline symbols with Ion templates

When combined with 
[Ion Templates](https://github.com/amzn/ion-docs/blob/ion-templates-rfc/rfcs/ion_templates.md#rfc-ion-templates),
	inline symbols can further reduce the number of symbol IDs that must be added to the symbol
	table.
	
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
the symbol table at all.

## Alternatives considered

### Add some new encodings, but not others

For example, add inline symbol structs but not inline symbol values. This would conserve type
descriptor values and reduce the scope of the changes needed for Ion 1.1. However, it would
eliminate a key feature for writers.

Inline symbol definitions make it possible for writers to serialize a nunmber of values without
having to modify the active symbol table. This makes it possible to:
1. Enforce restrictions on the size of the active symbol table (either by number of entries or data
size) without having to resort to resetting it.
2. Batch changes to the symbol table to avoid frequent LST appends.
3. Guarantee that all changes to the symbol table happen on at particular offsets. (For example,
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
additional challenges. All applications relying on representation of a map must perform their
own validation to guarantee that every key has an associated value and that each key is a
string or symbol value. Tools such as [PartiQL](https://partiql.org/) that are designed to work
with Ion will not recognize custom representations as maps, meaning that convenient syntax meant
to work with key/value data will not function as expected.
