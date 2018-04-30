---
title: Help
description: "Describes the best practices when contributing to Ion projects, how to contact the Ion Team, and answers Frequently Asked Questions (FAQs) about Amazon Ion."
---

# {{ page.title }}

If you need help with Ion or want to help by contibuting back to Ion, the information on this page should guide you in the right direction.

* TOC
{:toc}

<br/>

## Contributing

Each [library](libs.html) repo has a contributing file that provides instructions for how to contribute to that library. Also note that all Amazon Ion open source projects adhere to the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct.html).

<br/>

## FAQs

### What are the Ion file extensions?

> By convention, Ion text data files use the extension `.ion` and Ion binary data files use the extension `.10n`.
> 
> Ion implementations should generally auto-detect the format, so applications shouldn't have to worry about the difference.

### Does Ion have schemas?

> The Ion notation itself does not support schema validation; we intend for that to be supported by higher-level standards and tools.

### How can I concatenate streams of Ion data?

> Ion was designed to support easy concatenation of files or streams. There are three things to know:
> 
> 1. Text can be concatenated with text, and binary with binary, but you cannot mix text and binary.
> 1. Ion binary streams can be concatenated as-is because the binary format requires that the stream begin with the binary IVM byte sequence.
> 1. When concatenating Ion text streams, the concatenation tool MUST inject the IVM that represents the version of the Ion format for the stream that follows, ensuring appropriate whitespace. Failure to do so may lead to misinterpretation of the data.

### Why do Ion structs support duplicate field names?

> The simplest answer is that it's because JSON objects support having multiple values for the same field name, so Ion must too in order to be a superset of JSON. The more detailed answer involves the impracticality of prohibiting duplicate field names. Consider:
> ```{a:5, /*... tons of data...*/, a:6}```
>
> If Ion and JSON prohibited duplicate field names, they would have two options for the "a" field: pick one of them, or raise an error. Either way, in the pathological case, this would require O(N) space for a parser/serializer to perform the specified behavior--each field name in the struct would have to be buffered until the end of the struct.
> 
> That said, even though duplicate field names are supported, they SHOULD be unique. This was clarified in [JSON RFC7159](https://tools.ietf.org/html/rfc7159#section-4). Consequently, users of Ion are strongly encouraged to design their data such that structs contain unique field names.

### How does Ion interoperate with JSON?

> The Ion text format is a superset of JSON, so JSON data is Ion data. This means that you can read JSON data as-is using the Ion libraries, with one caveat:
>
> JSON numbers with exponents are decoded as Ion float, while those with fractions (but not exponents) are decoded as Ion decimal, other numbers are decoded as Ion integer. 
> 
> Conversely, a subset of Ion text can be interpreted by JSON parsers. Some aspects of Ion cannot. These include some decimal values (using the d exponent syntax), S-expressions, blobs, clobs, symbols, and annotations. In addition, field names need to be double quoted for JSON and are not quoted in the default Ion text serialization. 

### Is Ion serialization guaranteed to be bit-wise equal across multiple serializations?

> Ion libraries do not guarantee bitwise equivalence of serialized data. The concept runs contrary to one of Ion's central tenets: that applications should depend upon a data model, not a serialized form. Almost any instance of Ion data has multiple valid and equivalent serialized forms, text vs binary, pretty-printed vs compact, shared vs local symbol tables, symbol text vs symbol IDs, and then there's the unordered nature of structs.

### Why is the binary serialization for small payloads sometimes larger than text serialization?

> In short, the investment Ion binary made by including a local symbol table has not yet paid off. In the binary format, symbol tokens (field names, annotations, and symbol values) are always added to a symbol table and referred to by an integer symbol ID (index into the symbol table) within the data. Depending on your data, you may not see the benefits of this until you've serialized multiple instances. The local symbol table is an amortized cost.

### Why does Ion Decimal differentiate between decimal numbers with trailing zeroes?

> `10.` and `10.0` are not equivalent in the Ion data model. They are not equivalent in the data model because they have different precision, i.e., a different number of significant digits. Retaining precision is critical to many statistical and numerical applications.

### What is the actual number of bytes occupied by an integer in a binary ion file?

> The minimum size of a non-zero value is 2 bytes, because for all Ion values "[If the representation is less than 14 bytes long, then L is set to the length, and the length field is omitted.](docs/binary.html#typed-value-formats)" As such for most values the "length" field will be omitted (its value will be in L),
>
>Zero and null both use 1 byte:
>
> * 0: "[If the value is zero then T must be 2, L is zero, and there are no length or magnitude subfields.](docs/binary.html#2-and-3-int)"
> * null.int: "[With either type code 2 or 3, if L is 15, then the value is null.int and the magnitude is empty. Note that this implies there are two equivalent binary representations of null integer values.](docs/binary.html#2-and-3-int)"
>
> In both of these cases there will be no length or magnitude fields.

### What are 'symbol tokens'?

> See the glossary items for [symbol token](docs/glossary.html#symbol-token) and [symbol value](docs/glossary.html#symbol-value).
>
> At the data model level a symbol token is a triple: <symbol_text, symbol_id, symbol_table> meaning it's a mapping between the symbol's text, its numeric encoding, and the symbol table doing the mapping. Note that there are situations in which one or two parts of the triple are undefined; for example when parsing text there's usually no symbol ID or symbol table.
