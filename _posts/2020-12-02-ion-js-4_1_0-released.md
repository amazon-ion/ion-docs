---
layout: news_item
title: "Ion JS 4.1.0 Released"
date: 2020-12-02
categories: news ion-js
---

API Changes:
* Added deleteField method for deleting Struct fields.

Bug Fixes:
* Shared symbol tables no longer treat Object properties as symbols.
* Local symbol tables no longer use Objects with default properties to index symbols.
* Local symbol tables no longer discard duplicate symbols during initialization.

Tweaks:
* Improved performance when reading binary UInt subfields.

Testing improvements:
* Migrated from Travis CI to Github Actions.
* Integrated with ion-test-driver.

| [Release Notes](https://github.com/amazon-ion/ion-js/releases/tag/v4.1.0) | [Ion JS](https://github.com/amazon-ion/ion-js) |
