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
> A symbol value is a symbol token plus optional annotations. The content of the value is encoded as a symbol token. Any annotations are also encoded as a symbol token. So are field names. But a symbol token doesn't have annotations. You can't annotate an annotation, nor can you annotate a field name. That's why a symbol token is distinct from a symbol value.

## Value Stream {#value_stream}
> A (potentially unbounded) sequence of Ion values in either text or binary.

<!-- References -->
[1]: {{ site.baseurl }}/docs.html
[2]: spec.html