---
layout: news_item
title: "Ion 1.1 Final Comment Period"
date: 2025-02-26
categories: news specification
---

###  Ion 1.1 Final Comment Period

We are pleased to announce that [the Ion 1.1 draft specification](https://amazon-ion.github.io/ion-docs/books/ion-1-1/whats_new.html) is now entering its final public comment period, which runs from today, February 26th, **until Wednesday, March 12th**.

#### What's new

Ion 1.1 brings significant changes to the binary encoding, including:
* **Delimited containers.** Ion 1.0 required all containers to be length-prefixed, which forced the writer to buffer their serialized contents. In Ion 1.1, writers can choose to serialize child values or fields incrementally, optimizing write performance at the expense of slower skip-scanning on the read side.
* **Symbol tokens with inline text.** In binary Ion 1.0, it is not possible to write a symbol, annotation, or struct field name if it has not previously been added to the symbol table. This constraint that does not exist in text Ion 1.0, in which a writer can simply write the text at the usage site. Ion 1.1 adds a binary encoding for symbol tokens with inline text, allowing the writer to choose whether and when symbol token text should be interned.
* **Optimized encoding primitives.** Ion 1.1 switches to [Little-Endian](https://en.wikipedia.org/wiki/Endianness) encoding primitives and a more efficient representation for variable-width integers. Benchmarks found these to be 1.5-3x faster to read and write on both `x86_64` and `aarch64` systems.
* **Optimized timestamp encodings.** Timestamps no longer encode their sub-field components as octet-aligned fields. Instead, Ion 1.1 timestamps have a packed bit encoding which makes common timestamp precisions easily fit in a 64-bit word.

Ion 1.1 also introduces [_macros_](https://amazon-ion.github.io/ion-docs/books/ion-1-1/macros.html), which allow users to define fill-in-the-blank templates for their data. These templates can capture not only the structure/shape of one or more values, they can capture entire values as well. This feature enables applications to focus on encoding and decoding the parts of the data that are distinctive, skipping the work that would normally be needed to encode the boilerplate.

#### Submitting Feedback

Feedback may be submitted by:
* [Opening an issue](https://github.com/amazon-ion/ion-docs/issues/new) on the `ion-docs` GitHub repository
* Emailing ion-team@amazon.com

Please note that Ion 1.1 is a minor version bump, and as such cannot change the Ion data model. In particular, it cannot add or remove data types or otherwise make it impossible to represent legal Ion 1.0 data in Ion 1.1.

All comments will be reviewed and addressed before the specification is finalized.

Thank you for your continued interest in Ion's development!

Best,

The Ion Team


