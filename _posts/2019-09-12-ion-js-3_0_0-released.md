---
layout: news_item
title: "Ion JS 3.0.0 Released"
date: 2019-09-12 17:30:00 -0700
categories: news ion-js
---
This release includes many changes to the ion-js API, many of them are not backwards-compatible. See the release notes for more information.

The following are known limitations:

* int values are restricted to 32 bits: [-2147483648, 2147483647]
* character escape sequences are not fully supported in strings, symbols, and clobs
* no support for:
  * ints denoted in binary
  * underscore characters in ints, decimals, or floats
  * shared symbol tables
  * symboltokens
  * SID0 ($0)

Note: this release targets Node environments only and has not been verified to work in any browsers

| [Release Notes](https://github.com/amazon-ion/ion-js/releases/tag/v3.0.0) |
