---
title: Docs
description: "A collection of guides and reference materials for Amazon Ion."
---

# {{ page.title }}

## User Guides

<br/>

[Cookbook][9]

The cookbook contains samples for some simple Amazon Ion use cases with examples in Java. The samples include reading and writing Ion data, formatting Ion text, performing sparse reads, and converting non-hierarchical data to Ion.

---

[Why Ion][10]

Why Ion discusses features that differentiate Amazon Ion from other formats. Some of those features are Ion’s dual-format interoperability, rich type system, self-describing format, read-optimized binary format.

<br/>

## Developer Guides

<br/>

[Symbols][11]

The Developers' Guide to Ion Symbols provides developer-focused commentary on the [Symbols][8] section of the [specification][1] and discusses the implementation of symbol table, symbol token, and catalog APIs.

<br/>

[Path Extraction][12]

The Developers' Guide to Path Extraction APIs discusses how to implement an API which aims to combine the convenience of a DOM API with the speed of a streaming API.

<br/>

## References

<br/>

[Specification][1]

This document covers the Amazon Ion data model and the Ion text format.

---

[ANTLR grammar][3]

This grammar formally covers the text Ion format. It is intended to aid in understanding and provide a machine readable description that is mostly complete and correct. It is not considered authoritative, though that is a goal. Known gaps and ambiguities are documented as comments.

---

[Binary format][2]

This document covers the binary Ion format.

---

[Symbols][8]

This document defines the various concepts and data structures related to symbol management. Amazon Ion symbols are critical to the binary format performance and space-efficiency.

---

[Decimal support][4]

Amazon Ion supports a decimal numeric type to allow accurate representation of base-10 floating point values such as currency amounts. This representation preserves significant trailing zeros when converting between text and binary forms.

---

[Float support][5]

Amazon Ion supports IEEE-754 binary floating point values using the IEEE-754 32-bit (binary32) and 64-bit (binary64) encodings. In the data model, all floating point values are treated as though they are binary64 (all binary32 encoded values can be represented exactly in binary64).

---

[Strings and Clobs][7]

This document clarifies the semantics of the Amazon Ion string and clob data types with respect to escapes and the Unicode standard.

---

[Glossary][6]

These terms have particular definitions as it relates to their usage within the Amazon Ion Specification documents.


[1]: docs/spec.html
[2]: docs/binary.html
[3]: docs/text.html
[4]: docs/decimal.html
[5]: docs/float.html
[6]: docs/glossary.html
[7]: docs/stringclob.html
[8]: docs/symbols.html
[9]: guides/cookbook.html
[10]: guides/why.html
[11]: guides/symbols-guide.html
[12]: guides/path-extractor-guide.html
