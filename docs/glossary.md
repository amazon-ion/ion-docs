---
redirect_from: "/glossary.html"
title: Glossary
description: "The following terms have particular definitions as it relates to their usage within the Amazon Ion Specification documents."
---

# [Docs][docs]/ {{ page.title }}

The following terms have particular definitions as it relates to their usage
within the [Amazon Ion Specification][spec] documents.

## Symbol Token
> A symbol token is a piece of text mapped to a integer symbol ID by a symbol table. In the binary format a symbol token is always encoded using the integer, not the text.
> 
> Such tokens occur in three distinct contexts within the data model: symbol values, annotations, and field names.

## Symbol Value
> A symbol value is a scalar value (like an integer or string) that is encoded as a symbol token.

## Value Stream {#value_stream}
> A (potentially unbounded) sequence of Ion values in either text or binary.

<!-- References -->
[docs]: {{ site.baseurl }}/docs.html
[spec]: spec.html