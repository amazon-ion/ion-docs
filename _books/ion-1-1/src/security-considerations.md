# Security considerations

The Ion 1.1 data format is orthogonal to many classes of attacks, such as privilege escalation and phishing attacks.
Ion 1.1 is primarily susceptible to denial-of-service (DoS) attacks that attempt to cause an error condition in the receiving
system. As with many such attacks, the strongest defense is to not accept any untrusted input, but that defense is not
always compatible with the business requirements of the receiving application.

This document addresses various types of attacks, assuming that it is not possible to avoid accepting untrusted input.

_The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in RFC 2119._

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
An implementation _MAY_ allow limits to be configurable by an application that uses the Ion implementation.
Any limits imposed _SHOULD_ be described in the public documentation of an Ion implementation, unless the limits are
unknown and/or are dependent on the underlying runtime environment.
