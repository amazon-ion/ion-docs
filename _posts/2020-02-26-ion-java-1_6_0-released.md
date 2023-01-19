---
layout: news_item
title: "Ion Java 1.6.0 Released"
date: 2020-02-26
categories: news ion-java
---
This release includes:
* Opt-in support for local symbol table appends, which allow strings to be dynamically added to the symbol table. In many cases, this produces a more compact encoding and requires less in-memory buffering. To take advantage of this, use the [withLocalSymbolTableAppendEnabled()](https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/system/IonBinaryWriterBuilder.html) method on the IonBinaryWriterBuilder.
* Optimizations for reading and writing binary strings.
* A fix for a bug that could cause an infinite loop when an IonValue was modified while simultaneously being read with a TreeReader.

| [Release Notes](https://github.com/amazon-ion/ion-java/releases/tag/v1.6.0) | [Ion Java](https://github.com/amazon-ion/ion-java) |

