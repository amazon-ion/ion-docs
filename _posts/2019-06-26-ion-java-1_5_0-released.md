---
layout: news_item
title: "Ion Java 1.5.0 Released"
date: 2019-06-26 14:30:00 -0800
categories: news
---

From version 1.4.0 forward ion-java moved to a new maven group id and java package name: `com.amazon.ion`. This move was necessary to keep the publishing of Amazon libraries in maven consistent.

We'll keep supporting `software.amazon.ion` by publishing mirrored releases but users are strongly encouraged to migrate. The migration is trivial, the only differences are the maven group id and Java package names.

1.5.0 release notes:

* Fixed a bug in IonReader.getTypeAnnotations when used with text data that contains a symbol table.
* Made the messages of certain IllegalStateExceptions more descriptive.
* Added an Equivalence option to specify an epsilon to use when comparing Ion float values.
* Reduced memory allocations and garbage collections required when stepping in and out of containers in the binary writer, resulting in a speedup (5%), heap size reduction (4%), GC count reduction (56%), GC time reduction (13%), and Eden Space churn reduction (71%) when writing a sample of container-heavy test data.
* Reduced memory allocations and garbage collections required when setting struct field names in the binary writer, resulting in a speedup (12.6%), reduction in heap usage (17%), and elimination of garbage collections when writing a sample of field-heavy test data.
* Cached the reference to the current container context in the binary writer to reduce repetitive List lookups, resulting in a speedup (10%) when writing a sample of container-heavy test data.


| [Release Notes](https://github.com/amazon-ion/ion-java/releases/tag/com_amazon_ion_v1.5.0) |
