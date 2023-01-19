---
layout: news_item
title: "Ion C 1.4.0 Released"
date: 2021-02-09
categories: news ion-c
---
New features:

* Added support for writing 32-bit floats via existing APIs.

Bug fixes:

* Fixed long strings concatenation failures when components were separated by comments.
* Correctly interpret newline characters within text clob literals.
* Allowed text writer to write timestamps with high-precision fractional seconds.
* Fixed ion_timestamp_to_time_t on Windows.
* Changed globals to use thread-local storage (TLS).
* Fixed an issue causing lobs to skip some bytes when doing partial reads of ion-text.
* Fail early when a numeric value is terminated by an invalid character.
* Made ion_reader_get_type behavior consistent between text and binary writers.
* Fixed an infinite loop that occurred when writing to a fixed-size buffer with insufficient space.
* Fixed integer overflow bugs in `ion_int_from_long` and `ion_int_to_int64`.

Tweaks:

* Removed the CLI's dependency on docopt in favor of argtable3.
* Added a space after a field name's colon when pretty-printing.
* Added static build targets.
* Removed `googletest` from all target.
* Various CLI fixes and improvements.
* Integrated [ion-test-driver](https://github.com/amazon-ion/ion-test-driver) support into GitHub Actions.

| [Release Notes v1.4.0](https://github.com/amazon-ion/ion-c/releases/tag/v1.4.0) | [Ion C](https://github.com/amazon-ion/ion-c) |
