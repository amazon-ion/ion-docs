## Macros

Like other self-describing formats, Ion 1.0 makes it possible to write a stream with truly arbitrary content--no formal schema required.
However, in practice all applications have a _de facto_ schema, with each stream sharing large amounts of predictable structure and recurring values.
This means that Ion readers and writers often spend substantial resources processing undifferentiated data.

Consider this example excerpt from a webserver's log file:

```ion
{
  method: GET,
  statusCode: 200,
  status: "OK",
  protocol: https,
  clientIp: ip_addr::"192.168.1.100",
  resource: "index.html"
}
{
  method: GET,
  statusCode: 200,
  status: "OK",
  protocol: https,
  clientIp:
  ip_addr::"192.168.1.100",
  resource: "images/funny.jpg"
}
{
  method: GET,
  statusCode: 200,
  status: "OK",
  protocol: https,
  clientIp: ip_addr::"192.168.1.101",
  resource: "index.html"
}
```

_Macros_ allow users to define fill-in-the-blank templates for their data. This enables applications to focus on encoding and decoding the parts of the data that are distinctive, eliding the work needed to encode the boilerplate.

Using this macro definition:
```ion
(macro getOk (clientIp resource)
  {
    method: GET,
    statusCode: 200,
    status: "OK",
    protocol: https,
    clientIp: (.annotate "ip_addr" (%clientIp)),
    resource: (%resource)
  })
```

The same webserver log file could be written like this:
```ion
(:getOk "192.168.1.100" "index.html")
(:getOk "192.168.1.100" "images/funny.jpg")
(:getOk "192.168.1.101" "index.html")
```

Macros are an encoding-level concern, and their use in the data stream is invisible to consuming applications. For writers, macros are always optional--a writer can always elect to write their data using value literals instead. 

For a guided walkthrough of what macros can do, see [Macros by example](macros/macros_by_example.md).
