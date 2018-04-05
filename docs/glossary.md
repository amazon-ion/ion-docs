---
redirect_from: "/glossary.html"
title: Glossary
description: "The following terms have particular definitions as it relates to their usage within the Amazon Ion Specification documents."
---

# [Docs][1]/ {{ page.title }}

The following terms have particular definitions as it relates to their usage
within the [Amazon Ion Specification][2] documents.

## Symbol Token
> A symbol token is a piece of text mapped to a integer symbol ID by a symbol table. In the binary format a symbol token is always encoded using the integer, not the text.
> 
> Such tokens occur in three distinct contexts within the data model: symbol values, annotations, and field names.

## Symbol Value
> A symbol value is a scalar value (like an integer or string) that is encoded as a symbol token.

## Value Stream {#value_stream}
> A (potentially unbounded) sequence of Ion values in either text or binary.

<!-- References -->
[1]: {{ site.baseurl }}/docs.html
[2]: spec.html