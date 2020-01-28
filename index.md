---
title: Amazon Ion
description: "Amazon Ion is a richly-typed, self-describing, hierarchical data serialization format offering interchangeable binary and text representations. Ion was built to address rapid development, decoupling, and efficiency challenges faced every day while engineering large-scale, service-oriented architectures. Ion has been addressing these challenges within Amazon for nearly a decade, and we believe others will benefit as well."
---

<div style="float:right; width:200px" markdown="block">

| [News][7] |
|------|{% for post in site.posts limit:5 %}
|<a href="{{site.baseurl}}{{post.url}}">{{ post.title }}</a>|{% endfor %}

</div>

**<font size="+1">Amazon Ion</font>** is a [richly-typed][13], [self-describing][15], hierarchical data serialization
format offering [interchangeable binary and text][14] representations. The [text format][10]
(a superset of [JSON][1]) is easy to read and author, supporting rapid
prototyping. The [binary representation][11] is [efficient to store, transmit, and
skip-scan parse][16].  The rich type system provides unambiguous semantics for
long-term preservation of data which can survive multiple generations
of software evolution.

Ion was built to address rapid development, decoupling, and efficiency
challenges faced every day while engineering large-scale, service-oriented
architectures. It has been addressing these challenges within Amazon for nearly
a decade, and we believe others will benefit as well.

**Available Libraries:** [Ion Java][3] -- [Ion C][4] -- [Ion Python][5] -- [Ion JavaScript][6]<br>
**Related Projects:** [Ion Hash][19] -- [Ion Schema][17]<br>
**Tools:** [Hive SerDe][18]<br>

<br>

### Getting Started {#gettingstarted}

All JSON values are valid Ion values, and while any value can be encoded in JSON (e.g., a timestamp value can be converted to a string), such approaches require extra effort, obscure the actual type of the data, and tend to be error-prone.

In contrast, Ion's rich type system enables unambiguous semantics for data (e.g., a timestamp value can be encoded using the timestamp type).  The following illustrates some of the features of the Ion type system:

* **timestamp:**  arbitrary precision date / timestamps
```
2003-12-01T
2010-03-22T18:00:00Z
2019-05-01T18:12:53.472-0800
```

* **int:**  arbitrary size integers
```
0
-1
12345678901234567890...
```

* **decimal:**  arbitrary precision, base-10 encoded real numbers
```
0.
-1.2
3.141592653589793238...
6.62607015d-34
```

* **float:**  32-/64-bit IEEE-754 floating-point values
```
0e0
-1.2e0
6.02e23
-inf
```

* **symbol:**  provides efficient encoding for frequently occurring strings
```
inches
dollars
'high-priority'    // symbols with special characters ('-' in this example)
                     // are enclosed in single-quotes
```

* **blob:**  binary data
```
{{"{{"}} aGVsbG8= {{}}}}
```

* **annotation:**  metadata associated with a value
```
dollars::100.0
height::inches::72
lotto_numbers::[7, 9, 19, 40, 42, 44]
```

The [Specification][10] provides an overview of the full set of Ion types.

### Binary Encoding

Ion provides two encodings:  human-readable text (as shown above), and a space- and read-efficient binary encoding.  When binary-encoded, every Ion value is prefixed with the value's type and length.  The following illustrates a few of the efficiences provided by Ion's binary encoding:

* The following timestamp encoded as a JSON string requires 26 bytes:  "2017-07-26T16:30:04.076Z".  This timestamp requires just 11 bytes when encoded in Ion binary:
```
6a 80 0f e1 87 9a 90 9e 84 c3 4c
```
That first byte `6a` indicates the value is a timestamp (type `6`) represented by the subsequent 10 bytes (that's what the `a` represents).  If this particular timestamp value is not of interest, a reader can jump over the value by skipping 10 bytes.  This ability to skip over a value enables faster navigation over Ion data.

* Binary encoding of a symbol replaces the text of a symbol with an integer that can be resolved to the original text via a symbol table.  This can result in substantial space savings for symbols that occur frequently!

* While blob data is base-64 encoded in text (which produces 4 bytes for every 3 bytes of the original data), a blob encoded as Ion binary is simply encoded as is&mdash;no base-64 expansion required!

Similar space efficiencies are found in other aspects of Ion's binary encoding.

### Give Ion a Try!

<div class="ion-source">
/* Ion supports comments. */
// Here is a struct, which is similar to a JSON object
{
  // Field names don't always have to be quoted
  name: "Fido",

  // This is an integer with a 'years' annotation
  age: years::4,

  // This is a timestamp with day precision
  birthday: 2012-03-01T,

  // Here is a list, which is like a JSON array
  toys: [
    // These are symbol values, which are like strings,
    // but get encoded as integers in binary
    ball,
    rope,
  ],

  // This is a decimal -- a base-10 floating point value
  weight: pounds::41.2,

  // Here is a blob -- binary data, which is
  // base64-encoded in Ion text encoding
  buzz: {{'{{'}}VG8gaW5maW5pdHkuLi4gYW5kIGJleW9uZCE=}},
}
</div>
<script async src="assets/ion-widget.js"></script>

### More Information

To learn more, check out the [Docs][8] page, or see [Libs][12] for the officially supported libraries as well as community supported tools.  For information on how to contribute, how to contact the Ion Team, and answers to the frequently asked questions, see [Help][9].

<!-- References -->
[1]: http://json.org
[2]: guides/why.html
[3]: https://github.com/amzn/ion-java
[4]: https://github.com/amzn/ion-c
[5]: https://github.com/amzn/ion-python
[6]: https://github.com/amzn/ion-js
[7]: news.html
[8]: docs.html
[9]: help.html
[10]: docs/spec.html
[11]: docs/binary.html
[12]: libs.html
[13]: guides/why.html#rich-type-system
[14]: guides/why.html#dual-format-interoperability
[15]: guides/why.html#self-describing
[16]: guides/why.html#read-optimized-binary-format
[17]: https://amzn.github.io/ion-schema
[18]: https://github.com/amzn/ion-hive-serde
[19]: https://amzn.github.io/ion-hash
