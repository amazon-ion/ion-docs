# Security considerations

The Ion 1.1 data format is orthogonal to many classes of attacks, such as privilege escalation and phishing attacks.
Ion 1.1 is primarily susceptible to denial-of-service (DoS) attacks that attempt to cause an error condition in the receiving
system or consume excessive system resources. As with many such attacks, the strongest defense is to not accept any 
untrusted input, but that defense is not always compatible with the business requirements of the receiving application.

This document addresses various types of attacks, assuming that it is not possible to avoid accepting untrusted input.

_The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in RFC 2119._

## Data expansion denial-of-service

An attacker could craft an input that is relatively small, but upon expansion, produces something thousands or millions
of times larger.

For many use cases, the expansion of a template macro will grow linearly with the size of its input. However, it is 
possible to create macros with expansions that grow at greater rates. Using [`for`](macros/special_forms.md#for) we can 
nest an arbitrary number of loops to create a macro expansion with a polynomial growth rate. Using the 
[`repeat`](macros/system_macros.md#repeat) macro, we can create classes of inputs with expansions that grow 
exponentially in relation to the input.

For example, this input is less than 250 characters when encoded as Ion text (and omitting all optional whitespace). 
In Ion binary, it requires only 74 bytes. For each additional level of nesting, only 20 additional characters (text) or
6 additional bytes (binary) are required, but it increases the number of expanded values by 2147483647 times.
```ion
$ion_1_1
(:repeat 2147483647
  (:repeat 2147483647
    (:repeat 2147483647
      (:repeat 2147483647
        (:repeat 2147483647
          (:repeat 2147483647
            (:repeat 2147483647
              (:repeat 2147483647
                (:repeat 2147483647
                  (:repeat 2147483647
                    (:repeat 2147483647 "abc")))))))))))
```
The expansion of these e-expressions results in a stream of ~450 [googol](https://en.wikipedia.org/wiki/Googol) string
values. Any attempt to hold all of this in memory or write it to disk will exhaust all available resources and 
eventually fail. Even an attempt to count the length of the stream, while it may theoretically succeed if using an 
appropriate `BigInteger` type, will require a considerable amount of CPU operations (over a googol), and even the 
fastest processors will require many millennia to completely count the number of values in the stream.

Even without using `repeat` or `for`, a [Billion laughs attack](https://en.wikipedia.org/wiki/Billion_laughs_attack)
could exist for any data format with macro expansion, and it is certainly possible with Ion 1.1.
```ion
$ion_1_1
(:add_macros (macro lol0 () "lol")
             (macro lol1 () (.values (.lol0) (.lol0) (.lol0) (.lol0) (.lol0) (.lol0) (.lol0) (.lol0) (.lol0) (.lol0)))
             (macro lol2 () (.values (.lol1) (.lol1) (.lol1) (.lol1) (.lol1) (.lol1) (.lol1) (.lol1) (.lol1) (.lol1)))
             (macro lol3 () (.values (.lol2) (.lol2) (.lol2) (.lol2) (.lol2) (.lol2) (.lol2) (.lol2) (.lol2) (.lol2)))
             (macro lol4 () (.values (.lol3) (.lol3) (.lol3) (.lol3) (.lol3) (.lol3) (.lol3) (.lol3) (.lol3) (.lol3)))
             (macro lol5 () (.values (.lol4) (.lol4) (.lol4) (.lol4) (.lol4) (.lol4) (.lol4) (.lol4) (.lol4) (.lol4)))
             (macro lol6 () (.values (.lol5) (.lol5) (.lol5) (.lol5) (.lol5) (.lol5) (.lol5) (.lol5) (.lol5) (.lol5)))
             (macro lol7 () (.values (.lol6) (.lol6) (.lol6) (.lol6) (.lol6) (.lol6) (.lol6) (.lol6) (.lol6) (.lol6)))
             (macro lol8 () (.values (.lol7) (.lol7) (.lol7) (.lol7) (.lol7) (.lol7) (.lol7) (.lol7) (.lol7) (.lol7)))
             (macro lol9 () (.values (.lol8) (.lol8) (.lol8) (.lol8) (.lol8) (.lol8) (.lol8) (.lol8) (.lol8) (.lol8)))
             (macro lolz () (.lol9)) )
(:lolz)
```

Implementations of Ion 1.1 _MUST_ have some mechanism by which to mitigate data expansion attacks.

The macro evaluator of Ion 1.1 implementations _SHOULD_ have a (possibly configurable) limit on the number of values 
produced by the expansion of a macro or e-expression. If the macro evaluator reaches that limit, evaluation should halt 
and the reader should signal an error. This is similar to the [Token Bucket Algorithm](https://en.wikipedia.org/wiki/Token_bucket),
but instead of refilling the bucket, the bucket starts at the maximum capacity whenever the reader begins evaluating an
e-expression that is not nested in any other e-expression at any other depth.

```ion
$ion_1_1
// Fill bucket here
(:make_list
  [
    // Do not fill bucket here
    (:repeat 100 "foo")
  ]
  [
    "bar",
    "baz",
  ]
)
{
  // Fill bucket here
  foo: (:make_string "foo" "bar")
  // Fill bucket here
  bar: (:make_string "a" "b")
}
```


## Remote code execution

Remote code execution (RCE) attacks allow an attacker to remotely execute malicious code on a computer.

The template definition language (TDL) is a type of code, and by invoking e-expressions in the body of an Ion document, 
an attacker can cause the recipient to execute arbitrary TDL when reading the document.

This is unlikely to be a concern in practice because TDL is not arbitrary code.
TDL is intentionally not Turing complete, to make it impossible to perform arbitrary computation.
It also has a very limited domain—it can only transform/produce Ion data model values.

While it could be possible to attempt a denial-of-service attack using TDL, TDL expansion is guaranteed to terminate in
a finite number of steps, and implementations can additionally limit the expansion size (as described above).

## Embedded Documents

Ion 1.1 supports embedded documents using the [`parse_ion`](macros/system_macros.md#parse_ion) macro. Generally speaking,
systems that accept embedded documents should properly isolate and validate embedded documents to prevent attacks.

Ion 1.1 specifies that `parse_ion` must only accept a literal string or literal blob, and that the resulting values are
always user values (rather than system values). This ensures that the embedded document cannot be affected by any input
from the containing document, nor can it have any effect on the encoding context of the containing document.
The `parse_ion` macro uses an Ion reader, so it will be validated just as any other Ion document.

## Data injection via shared modules

Applications are not required to use [shared modules](modules/shared_modules.md). If an application does use shared 
modules, it should take steps to ensure that shared modules come from a trusted source and use appropriate measures to
prevent man-in-the-middle and other attacks that can compromise data while it is in transit.

In many cases, even if an application needs to accept Ion payloads from untrusted sources, it is possible to design a 
solution in which the shared modules are supplied by a trusted source. For example, in a service-oriented-architecture, 
the server can host shared modules so that the server does not have to trust the client. (However, this assumes that the
client trusts the server.)

If shared modules must come from an untrusted source, then applications should take steps to ensure that the shared
modules originate from the same source as the data that uses them, and they can be treated as if they are one composite
piece of data from that source.

## Arbitrary-sized values

The Ion specification places no limits on the size of Ion values, so an attacker could send a sufficiently large value,
it could consume enough system resources to disrupt the application reading the value.

Even though the Ion specification does not have limits on the size of values, all real computer systems have finite 
resources, so all implementations will have limits in practice.
Ion implementations _MAY_ set limits on the maximum size of any Ion value for any available metric, including (but not 
limited to) number of bytes, number of codepoints, number of child values, digits of precision, or number of annotations.
An implementation _MAY_ allow limits to be configurable by an application that uses the Ion implementation.
Any limits imposed _SHOULD_ be described in the public documentation of an Ion implementation, unless the limits are
unknown and/or are dependent on the underlying runtime environment.

## Symbol table and macro table inflation
 
An attacker could try to create an input that results in excessively large symbol and macro tables in the Ion reader 
that could exhaust the memory of the receiving system and lead to a denial of service.

Although Ion 1.1 does not specify a maximum size for symbol tables or macro tables, Ion implementations _MAY_ impose 
upper bounds on the size of symbol tables, macro tables, module bindings, and any other direct or indirect component of
the encoding context.
Any limits imposed _SHOULD_ be described in the public documentation of an Ion implementation, unless the limits are
unknown and/or are dependent on the underlying runtime environment.
