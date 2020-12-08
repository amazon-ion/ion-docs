# RFC: Ion 1.1

<!-- markdown-toc start - Don't edit this section. -->

- [RFC: Ion 1.1](#rfc-ion-11)
    - [Summary](#summary)
    - [Inline Symbols](#inline-symbols)
    - [Templates](#templates)
    - [System Symbol Table](#system-symbol-table)

<!-- markdown-toc end -->

## Summary

This RFC proposes a new minor version of the Ion data format: **Ion 1.1**.

Ion 1.1 adds two features: [inline symbols](#inline-symbols) and [templates](#templates). These
features are optional encodings for existing constructs; they do not modify the Ion type system.

## Status

This RFC is in development. Once it reaches maturity, a final comment period will be announced.

Please subscribe to the [pull request](https://github.com/amzn/ion-docs/pull/104) or check the [Ion
news page](http://amzn.github.io/ion-docs/news.html) periodically for updates.

## Inline Symbols

*Inline symbols* make it possible to write new struct field names, annotations, and symbols to a
binary Ion stream without first having to modify the active symbol table. This functionality is
already supported in Ion text, which has the option of either indexing into the symbol table (e.g.
`$10`) or defining the symbol inline (e.g. `foo` or `'foo'`).

Inline symbols give binary Ion writers the flexibility to decide whether and when to add a given
string to the symbol table, allowing them to make trade-offs in data size, throughput, and memory
consumption.

For the complete details of this feature, see the document [*Inline
symbols*](feature-inline_symbols.md#rfc-inline-symbols).

## Templates

*Templates* generalize Ion 1.0’s concept of symbols by:

1. Allowing any valid Ion value to be added to the symbol table, not just strings.
2. Allowing containers stored in the table to have ‘blanks’ in them that can be filled in when the
   template is referenced.

Templates allow applications to elide not only the structure of encoded values (as a traditional
schema might), but also the values themselves.

Although templates offer a superset of symbols’ functionality and could replace them wholesale, this
document proposes adding them alongside symbols to preserve backwards compatibility and simplify
implementating the new functionality.

For the complete details of this feature, see the document
[*Templates*](feature-templates.md#rfc-ion-templates).

## System Symbol Table

Ion 1.1 carries over the Ion 1.0 symbol table and appends two new symbols of its own: `templates`
and `max_template_id`. Their usage is detailed in the document
[*Templates*](feature-templates.md#rfc-ion-templates).

| ID | Text |
|:--:|:-----|
|  1 | $ion |
|  2 | $ion_1_0 |
|  3 | $ion_symbol_table |
|  4 | name |
|  5 | version |
|  6 | imports |
|  7 | symbols |
|  8 | max_id |
|  9 | $ion_shared_symbol_table |
| 10 | templates |
| 11 | max_template_id |

Note that Ion 1.1 does *not* add a symbol for the text `$ion_1_1`. Symbol `$2`, which maps to the
text `$ion_1_0`, [cannot be used as an Ion Version
Marker](http://amzn.github.io/ion-docs/docs/symbols.html#ion-version-markers) in Ion 1.0 and
therefore serves no practical purpose. There is no need for an analogous symbol in Ion 1.1.
