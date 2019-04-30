---
layout: news_item
title: "Ion Java 1.4.0 Released"
date: 2019-04-24 14:30:00 -0800
categories: news
---

From version 1.4.0 forward ion-java has moved to a new maven group id and java package name: `com.amazon.ion`. This move was necessary to keep the publishing of Amazon libraries in maven consistent.

We'll keep supporting `software.amazon.ion` for the foreseeable future by publishing mirrored releases but users are strongly encouraged to migrate. The migration is trivial as the only differences are the group id and package names.

1.4.0 release notes:

* First release using `com.amazon.ion` as the java package name and groupId
* Fixed a gzipped related memory leak
* Performance fix for IonValueLite.clearSymbolIdValues()

| [Release Notes](https://github.com/amzn/ion-java/releases/tag/com_amazon_ion_v1.4.0) |
