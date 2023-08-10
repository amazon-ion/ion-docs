---
redirect_from: "/catalog.html"
title: Catalog Best Practices
description: "The Catalog is user-implemented abstraction that allows Ion readers and writers to resolve shared symbol table imports. This page discusses best practices for Catalog implementers."
---

# [Docs][docs]/ {{ page.title }}

The Catalog is an abstraction, briefly described in the [specification][symbols], that allows Ion readers and writers to resolve shared symbol table imports. This page discusses best practices for Catalog implementers, and assumes that best practices for shared [symbol table versioning][versioning] are followed. In particular:

> A shared symbol table with version greater than one should usually be a strict extension of the immediately preceding version.

The first step to deciding what kind of Catalog implementation is right for a particular application is to understand that **shared symbol table usage is a contract between the application that produces Ion data and the application(s) that consume that data**. This contract is external to both the Ion specification and to the libraries that implement it. Producing data using shared symbol tables that are not part of the contract, or consuming data without being able to resolve all shared symbol tables included in the contract, may lead to errors in the consuming application.

The simplest way for data producers to ensure their consumers comply with the intended shared symbol table contract is to provide those consumers with a Catalog implementation that complies with that contract. Some example contracts are listed below, alongside a high-level description of the kind of Catalog needed to comply with that contract.

| Contract | Catalog|
|----------|--------|
| Data will only ever be encoded with shared symbol table "foo", version 1.| Returns a static view of "foo", version 1 when requested; raises an error if any other table or version is requested.|
| Data will only ever be encoded with shared symbol table "foo", but the version may change over time.| Contains logic to dynamically resolve different versions of "foo"; returns the version requested or any greater version. Raises an error if any other table is requested.
| Data may be encoded with any version of any shared symbol table.| Contains logic to dynamically resolve any shared symbol table; returns the version requested or any greater version. Raises an error if the requested table cannot be resolved.


<!-- references -->
[docs]: {{ site.baseurl }}/docs.html
[symbols]: symbols.html
[versioning]: symbols.html#versioning
