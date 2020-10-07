---
title: Why Ion?
description: "Amazon Ion is a richly-typed, self-describing, hierarchical data serialization
format offering interchangeable binary and text representations. Ion was built to address rapid development, decoupling, and efficiency challenges faced every day while engineering large-scale, service-oriented architectures. Ion has been addressing these challenges within Amazon for nearly
a decade, and we believe others will benefit as well."
---

# [Docs][15]/  {{ page.title }}
 
  * Ion provides **[dual-format interoperability](#dual-format-interoperability)**, which enables users to take
    advantage of the ease of use of the text format while capitalizing on the
    efficiency of the binary format. The text form is easy to prototype, test,
    and debug, while the binary format saves space and parsing effort.

  * Ion's **[rich type system](#rich-type-system)** extends JSON's, adding support for types that
    make Ion suitable for a wider variety of uses, including precision-sensitive
    applications and portability across languages and runtimes.
    
  * Ion is a **[self-describing](#self-describing)** format, giving its readers and writers the
    flexibility to exchange Ion data without needing to agree on a schema in
    advance. Ion's "open-content" supports discovery, deep component chaining,
    and schema evolution.
    
  * Because most data is read more often than it is written, Ion defines a 
    **[read-optimized binary format](#read-optimized-binary-format)**.

## Dual-format interoperability

Applications can seamlessly consume Ion data in either its text or binary forms
without loss of data fidelity. While the expectation is that most Ion data is in
binary form, the text form promotes human readability, simplifying discovery and
diagnosis. 

Notably, the text format is a superset of JSON, making all JSON data valid Ion
data.  You probably already know how to read and author Ion.

### Ease of use

Like JSON, Ion's text format is concise and clearly legible. It is intelligible
to humans and may be edited using familiar tools like a text editor. This makes
Ion well-suited to rapid prototyping: developers can quickly mock up the their
data in text Ion, knowing that their application will ultimately seamlessly
process the more efficient binary Ion format. Once the application is up and
running, the users can debug it by intercepting the binary Ion data and
converting it to text Ion with full fidelity. After analysis, hand-edited
records can be re-inserted into a processing pipeline as needed to support
debugging and prototyping.

Text-only formats are more expensive to parse, which is why Ion offers the
option of the length-prefixed binary format. This binary format supports rapid
skip-scanning of data to materialize only key values within Ion streams.

### Seamless transcoding

Ion's interoperable formats avoid the kinds of semantic mismatches encountered
when attempting to mix and match separate text and binary formats.

Standalone binary formats such as [CBOR][2] sacrifice human-readability in
favor of an encoding that is more compact and efficient to parse. Although CBOR
is based on JSON, transcoding between the two is not always straightforward
because CBOR's more expressive types do not necessarily map cleanly to JSON
types. For example, CBOR's `bignum` must be base-64 encoded and represented as
a JSON `string` in order to avoid numeric overflow when read by a JSON parser,
while a CBOR `map` may be directly converted to a JSON `object` only if all
its keys are UTF-8 strings.

## Rich type system

Ion's type system is a superset of JSON's: in addition to strings, Booleans,
arrays (lists), objects (structs), and nulls, Ion adds support for
arbitrary-precision timestamps, embedded binary values (blobs and clobs), and
symbolic expressions. Ion also expands JSON's `number` specification by
defining distinct types for arbitrary-size integers, IEEE-754 binary floating
point numbers, and infinite-precision decimals. Decimals are particularly useful
for precision-sensitive applications such as financial transaction
record-keeping. JSON's `number` type is underspecified; in practice, many
implementations represent all JSON numbers as fixed-precision base-2 floats,
which are subject to rounding errors and other loss of precision.

### Timestamps

Ion [timestamps][12] are W3C-compliant representations of calendar dates and
time, supporting variable precision including year, month, day, hours, minutes,
seconds, and fractional seconds.  Ion timestamps may optionally encode a time
zone offset.

By defining timestamps as a distinct type, Ion eliminated the ambiguity involved
with representing dates as strings, as the semantics are clearly defined. Unlike
a number, which counts from some "epoch", arbitrary precision timestamps also
allow applications to represent deliberate ambiguity.

### Blobs and Clobs

Ion's [`blob`][13] and [`clob`][14] types allow applications to tunnel binary
data through Ion. This allows such applications to transmit opaque binary
payloads (e.g. media, code, and non-UTF-8 text) in Ion without the need to apply
additional processing to the payloads to make them conform to a different Ion
type.

For example, a `blob` could be used to transmit a bitmap image, while a `clob`
could be used to transmit Shift JIS text or an XML payload.

### Symbolic expressions

The Ion specification defines a distinct syntax for [symbolic expression][10]s
(*S-expressions*), but does not define how they should be processed. This allows
applications to use S-expressions to convey domain-specific semantics in a
first-class Ion type.

Formats that lack S-expressions as a first-class type are often left to choose
between two imperfect options: adding a pre-processor (e.g. [Jsonnet][7] on top
of JSON) to work around the inability to represent expressions as data, or
tunneling domain-specific language text as opaque strings or binary payloads.

### Annotations

The Ion specification provides a formal mechanism for applications to annotate
any Ion value without the need to enclose the value in a container. These
*annotations* are not interpreted by Ion readers and may be used, for example,
to add type information to a `struct`, time units to an integer or decimal
value, or a description of the contents of a blob value.

## Self-describing

Like JSON and CBOR, Ion is a self-describing format, meaning that it does not
require external metadata (i.e. a schema) in order to interpret the structural
characteristics of data denoted by the format. Notably, Ion payloads are free
from build-time binding that inhibits independent innovation and evolution
across service boundaries. This provides greater flexibility over schema-based
formats such as [protocol buffers][3], [Thrift][4], and [Avro][5], as data may
be sparsely encoded and the implicit schema may be changed without explicit
renegotiation of the schema among all consumers. These benefits come at the cost
of a less compact encoding, but in our experience the positive impact on agility
has been more valuable than an efficient but brittle contract.

## Read-optimized binary format

Ion's binary format is optimized according to the following principles:

  * Most data is read far more often than it is written. Generally, with the
    exception of logs, any data which is written is read at least once.  Read
    multipliers are common in processing pipelines, workflows, and shared data
    marts.
  * Many reads are shallow or sparse, meaning that the application is focused on
    only a subset of the values in the stream, and that it can quickly determine
    if full materialization of a value is required.

In the spirit of these principles, the Ion specification includes features that
make Ion's binary encoding more efficient to read than other schema-free
formats. These features include length-prefixing of binary values and Ion's use
of symbol tables.

### Length-prefixing

Because most reads are sparse, binary Ion invests some encoding space to
length-prefix each value in a stream. This makes seeking to the next relevant
value for a particular application inexpensive, and enables efficient
skip-scanning of data. This allows applications to cherry-pick only the relevant
values from the stream for deeper parsing, and to economize parsing of
irrelevant values.

### Symbol tables

In binary Ion, common text tokens such as struct field names are automatically
stored in a symbol table. This allows these tokens to be efficiently encoded as
table offsets instead of repeated copies of the same text. As a further space
optimization, symbol tables can be pre-shared between producer and consumer so
that only the table name and version are included in the payload, eliminating
the overhead involved with repeatedly defining the same symbols across multiple
pieces of Ion data.

## See also

  * [The Amazon Ion 1.0 Specification][8]
  * [The Amazon Ion 1.0 Cookbook][9]
  * [The Amazon Ion 1.0 Glossary][11]

<!-- References -->
[1]: http://json.org
[2]: http://cbor.io
[3]: https://developers.google.com/protocol-buffers/
[4]: http://thrift.apache.org/
[5]: https://avro.apache.org/
[7]: http://jsonnet.org/
[8]: {{ site.baseurl }}/docs/spec.html
[9]: cookbook.html
[10]: {{ site.baseurl }}/docs/spec.html#sexp
[11]: {{ site.baseurl }}/docs/glossary.html
[12]: {{ site.baseurl }}/docs/spec.html#timestamp
[13]: {{ site.baseurl }}/docs/spec.html#blob
[14]: {{ site.baseurl }}/docs/spec.html#clob
[15]: {{ site.baseurl }}/docs.html
