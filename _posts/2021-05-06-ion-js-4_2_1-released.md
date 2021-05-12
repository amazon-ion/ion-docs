---
layout: news_item
title: "Ion JS 4.2.0 and 4.2.1 Released"
date: 2021-05-06
categories: news ion-js
---

API Changes:

* Added position() API to Reader.
* Added an equals() API for the DOM.
* Timestamp’s constructor can now accept a Date instead of requiring individual time unit fields.
* Reader.byteValue is now deprecated in favor of the new alias: Reader.uInt8ArrayValue, which is more descriptive.
* Added support for duplicate fields in Struct for the DOM.

Bug Fixes:

* Fix length calculation for annotated containers.
* Change how container type information is stored on the stepIn stack.
* Fixed bug in the text parser that allowed unclosed structs at the end of a stream.
* Fixes the elements() method for Struct to preserve 4.1.0 behavior. (Fixed with v4.2.1)

Tweaks:

* Generate the ES6 module correctly.
* Performance improvements in unicode decoding.
* Use number instead of BigInt for smaller values. (Performance optimization)


| [Release Notes v4.2.0](https://github.com/amzn/ion-js/releases/tag/v4.2.0) | [Release Notes v4.2.1](https://github.com/amzn/ion-js/releases/tag/v4.2.1) | [Ion JS](https://github.com/amzn/ion-js) |