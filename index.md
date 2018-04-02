---
title: Amazon Ion
description: "Amazon Ion is a richly-typed, self-describing, hierarchical data serialization
format offering interchangeable binary and text representations. Ion was built to address rapid development, decoupling, and efficiency challenges faced every day while engineering large-scale, service-oriented architectures. Ion has been addressing these challenges within Amazon for nearly
a decade, and we believe others will benefit as well."
---

Amazon Ion is a richly-typed, self-describing, hierarchical data serialization
format offering interchangeable binary and text representations. The text format
(a superset of [JSON][1]) is easy to read and author, supporting rapid
prototyping. The binary representation is efficient to store, transmit, and
skip-scan parse.  The rich type system provides unambiguous semantics for
long-term preservation of business data which can survive multiple generations
of software evolution.

Ion was built to address rapid development, decoupling, and efficiency
challenges faced every day while engineering large-scale, service-oriented
architectures. Ion has been addressing these challenges within Amazon for nearly
a decade, and we believe others will benefit as well.

For more information on why you should use Ion, we have a prepared a
[Why Ion?][2] guide.

**Available Libraries:** [Java][3], [C][4], [Python][5], [JavaScript][6].

### Example {#example}

To illustrate Ion's syntax, here is an example.

```json-doc
/* Ion supports comments. */
// Here is a struct, which is similar to a JSON object.
{
  // Field names don't always have to be quoted.
  name: "fido",

  // This is an integer with a user annotation of 'years'.
  age: years::4,

  // This is a timestamp with day precision.
  birthday: 2012-03-01T,

  // Here is a list, which is like a JSON array.
  toys: [
    // These are symbol values, which are like strings,
    // but get encoded as integers in binary.
    ball,
    rope
  ],
}
```

### More Information:

To find out more about how to use Ion, check out the [Guides][7] page. The [Docs][8] pages contain documentation on the Ion format. And finally, the [FAQs][9] page contains answers to the frequently asked questions.

<!-- References -->
[1]: http://json.org
[2]: guides/why.html
[3]: https://github.com/amzn/ion-java
[4]: https://github.com/amzn/ion-c
[5]: https://github.com/amzn/ion-python
[6]: https://github.com/amzn/ion-js
[7]: guides.html
[8]: docs.html
[9]: faqs.html