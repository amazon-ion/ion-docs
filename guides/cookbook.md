---
redirect_from: "/cookbook.html"
title: Cookbook
description: "This cookbook provides code samples for some simple Amazon Ion use cases."
---
<style>
/* Style the tab */
.tabs {
  overflow: hidden;
  border: 1px solid #ccc;
  background-color: #f1f1f1;
}

/* Style the buttons that are used to open the tab content */
.tabs button {
  background-color: inherit;
  float: left;
  border: none;
  outline: none;
  cursor: pointer;
  padding: 14px 16px;
  transition: 0.3s;
}

/* Change background color of buttons on hover */
.tabs button:hover {
  background-color: #ddd;
}

/* Create an active/current tablink class */
.tabs button.active {
  background-color: #ccc;
}

/* Style the tab content */
.tabpane {
  display: none;
  padding: 6px 12px;
  border: 1px solid #ccc;
  border-top: none;
  margin-bottom: 30px;
}
</style>

<script language="JavaScript">
<!--
function writeTabs() {
  document.write('<div class="tabs">');
  ['C', 'Java', 'JavaScript'].forEach(lang =>
    document.write('<button class="tab ' + lang + '"' + ' onclick="openTab(\'' + lang + '\')">' + lang + '</button>')
  );
  document.write('</div>');
}
// -->
</script>

# [Docs][17]/ {{ page.title }}

* TOC
{:toc}

This cookbook provides code samples for some simple Amazon Ion use cases.

## How to use this cookbook

For readability, all examples of Ion data used in this cookbook will be
represented in the text Ion format, even examples intended to represent binary
Ion data. To make clear which format is represented by the example, each Ion
snippet will begin with a comment that denotes either `TEXT` or `BINARY`.

For brevity, this cookbook will make use of methods and global variables.
Variables declared inside methods are in scope only within that method.
Variables declared outside of methods, and methods themselves, are in scope
until the next section.  Within the same scope, variables with the same name
and type or methods with the same signature should be considered interchangeable.

In some cases, the examples herein depend on code external to Ion (e.g.
constructing input streams to read files), which is out of scope for this
cookbook. Code such as this will be replaced by a method with an empty (but
implied) implementation.

## Reading and Writing Ion Data

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
The following example shows how text Ion data can be read from a string:
```c
#include <stdlib.h>
#include "ionc/ion.h"

#define ION_OK(x) if (x) { printf("Error: %s\n", ion_error_to_str(x)); return x; }

int main(int argc, char **argv) {
    const char* ion_text = "{hello: \"world\"}";

    hREADER reader;
    ION_READER_OPTIONS options;

    memset(&options, 0, sizeof(ION_READER_OPTIONS));

    ION_OK(ion_reader_open_buffer(&reader,
                                  (BYTE *)ion_text,
                                  (SIZE)strlen(ion_text),
                                  &options));

    ION_TYPE ion_type;
    ION_OK(ion_reader_next(reader, &ion_type));     // position the reader at the first value, a struct
    ION_OK(ion_reader_step_in(reader));             // step into the struct
    ION_OK(ion_reader_next(reader, &ion_type));     // position the reader at the first value in the struct

    ION_STRING ion_string;
    ION_OK(ion_reader_get_field_name(reader, &ion_string));  // retrieve the current value's field name
    char *field_name = ion_string_strdup(&ion_string);

    ION_OK(ion_reader_read_string(reader, &ion_string));     // retrieve the current value's string value
    char *value = ion_string_strdup(&ion_string);

    ION_OK(ion_reader_step_out(reader));            // step out of the struct
    ION_OK(ion_reader_close(reader));               // close the reader

    printf("%s %s\n", field_name, value);           // prints:  hello world

    free(field_name);
    free(value);

    return 0;
}
```

The following example shows how data can be written to a buffer as Ion text:
```c
#include <stdlib.h>
#include "ionc/ion.h"

#define ION_OK(x) if (x) { printf("Error: %s\n", ion_error_to_str(x)); return x; }

int main(int argc, char **argv) {
    char ion_text[200];
    hWRITER writer;
    ION_WRITER_OPTIONS options;

    memset(&options, 0, sizeof(ION_WRITER_OPTIONS));
    options.output_as_binary = false;                                 // text output is the default behavior;
                                                                      // set to true if binary output is desired

    ION_OK(ion_writer_open_buffer(&writer,
                                  (BYTE *)ion_text,
                                  (SIZE)200,
                                  &options));

    ION_OK(ion_writer_start_container(writer, tid_STRUCT));           // step into a struct

    ION_STRING field_name_string;
    ion_string_assign_cstr(&field_name_string, "hello", strlen("hello"));
    ION_OK(ion_writer_write_field_name(writer, &field_name_string));  // set the field name for the next value to be written

    ION_STRING value_string;
    ion_string_assign_cstr(&value_string, "world", strlen("world"));
    ION_OK(ion_writer_write_string(writer, &value_string));           // write the next value

    ION_OK(ion_writer_finish_container(writer));                      // step out of the struct

    ION_OK(ion_writer_close(writer));                                 // close the writer

    printf("%s\n", ion_text);                                         // prints {hello:"world"}

    return 0;
}
```
</div>


<div class="tabpane Java" markdown="1">
Implementations of the [`IonReader`][4] and [`IonWriter`][5] interfaces are
responsible for reading and writing Ion data in both text and binary forms.

`IonReader`s and `IonWriter`s may be constructed through builders.

An [`IonReaderBuilder`][16] with the default configuration may be constructed as
follows. This builder will construct `IonReader` instances which can read
both text and binary Ion data.

```java
IonReaderBuilder readerBuilder = IonReaderBuilder.standard();
```

An [`IonTextWriterBuilder`][6] with the default configuration may be constructed
as follows. This builder will construct `IonWriter` instances which output data
in the text Ion format.

```java
IonTextWriterBuilder textWriterBuilder = IonTextWriterBuilder.standard();
```

To construct a builder that constructs `IonWriter` instances which output data
in the binary Ion format, use an [`IonBinaryWriterBuilder`][15].

```java
IonBinaryWriterBuilder binaryWriterBuilder = IonBinaryWriterBuilder.standard();
```

Each of the aforementioned builders may be used to construct multiple `IonReader`
or `IonWriter` instances with the same configuration.

Consider the following text Ion data, which has been materialized as a Java
String.

```java
String helloWorld = "{ hello:\"world\" }";
```

An `IonReader` for this data may be constructed as follows.

```java
IonReader reader = readerBuilder.build(helloWorld);
```

Reading the data requires leveraging the `IonReader`'s APIs.

```java
void readHelloWorld() {
    reader.next();                                // position the reader at the first value, a struct
    reader.stepIn();                              // step into the struct
    reader.next();                                // position the reader at the first value in the struct
    String fieldName = reader.getFieldName();     // retrieve the current value's field name
    String value = reader.stringValue();          // retrieve the current value's String value
    reader.stepOut();                             // step out of the struct
    System.out.println(fieldName + " " + value);  // prints "hello world"
}
```

In the above example, the `helloWorld` text Ion was probably typed by a human
using a text editor. The following example will illustrate how it could have
been generated using an `IonWriter`.

Assume the desired sink for the generated Ion data is a
[`java.io.OutputStream`][10], e.g. a [`java.io.ByteArrayOutputStream`][11].

```java
ByteArrayOutputStream out = new ByteArrayOutputStream();
```

The first step when creating an `IonWriter` is to decide whether it should
emit text Ion or binary Ion.

As mentioned above, text `IonWriter`s are constructed by `IonTextWriterBuilder`s.

```java
IonWriter writer = textWriterBuilder.build(out);
```

Similarly, binary `IonWriter`s are constructed by `IonBinaryWriterBuilder`s.

```java
IonWriter writer = binaryWriterBuilder.build(out);
```

Since both text and binary `IonWriter`s conform to the same interface, the
same APIs are used for both.

```java
import java.io.IOException;

void writeHelloWorld(IonWriter writer) throws IOException {
    writer.stepIn(IonType.STRUCT);  // step into a struct
    writer.setFieldName("hello");   // set the field name for the next value to be written
    writer.writeString("world");    // write the next value
    writer.stepOut();               // step out of the struct
}
```

The following demonstrates using `writeHelloWorld` with a text `IonWriter`.

```java
void writeHelloWorldText() throws IOException {
    try (IonWriter textWriter = textWriterBuilder.build(out)) {
        writeHelloWorld(textWriter);
    }
}
```

Regardless of whether `out` was written with text or binary Ion data, it may
now be read using an `IonReader`.

```java
import java.io.ByteArrayInputStream;
import java.io.InputStream;

void readHelloWorldAgain() {
    byte[] data = out.toByteArray();                // may contain either text or binary Ion data
    InputStream in = new ByteArrayInputStream(data);
    reader = readerBuilder.build(in);
    readHelloWorld();                               // prints "hello world"
}
```
</div>


<div class="tabpane JavaScript" markdown="1">
Implementations of the [`Reader`][19] and [`Writer`][20] interfaces are
responsible for reading and writing Ion data in both text and binary forms.

The following example shows how text Ion data can be read from a string:
```javascript
let ion = require('ion-js');

let reader = ion.makeReader('{hello: "world"}');
reader.next();                         // position the reader at the first value, a struct
reader.stepIn();                       // step into the struct
reader.next();                         // position the reader at the first value in the struct
let fieldName = reader.fieldName();    // retrieve the current value's field name
let value = reader.stringValue();      // retrieve the current value's string value
reader.stepOut();                      // step out of the struct
console.log(fieldName + ' ' + value);  // prints:  hello world
```

In the above example, the text Ion `{hello: "world"}` was probably typed by a human
using a text editor. The following example will illustrate how it could have
been generated using a `Writer`.

The following example shows how Ion data can be written:

```javascript
let ion = require('ion-js');
let IonTypes = require('ion-js').IonTypes;

let writer = ion.makeTextWriter();
writer.stepIn(IonTypes.STRUCT);      // step into a struct
writer.writeFieldName("hello");      // set the field name for the next value to be written
writer.writeString("world");         // write the next value
writer.stepOut();                    // step out of the struct
writer.close();                      // close the writer
console.log(String.fromCharCode.apply(null, writer.getBytes()));  // prints:  {hello:"world"}
```

If the desired output is pretty text or binary, `ion.makeBinaryWriter()`
or `ion.makePrettyWriter()` should be used instead of `ion.makeTextWriter()`.
The result of `getBytes()` from a text, pretty, or binary writer can subsequently
be passed as the parameter to `makeReader()` in order to read the Ion data.
</div>


## Formatting Ion text output

### Pretty-printing

To aid human-readability, Ion text supports "pretty" output. Consider the
following un-formatted text Ion:

```
 {level1: {level2: {level3: "foo"}, x: 2}, y: [a,b,c]}
```

Pretty-printing results in output similar to the following:

```
 {
   level1:{
     level2:{
       level3:"foo"
     },
     x:2
   },
   y:[
     a,
     b,
     c
   ]
 }
```

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
Ion data can be pretty-printed by setting `ION_WRITER_OPTIONS.pretty_print` to `true` as follows:

```c
#include <stdlib.h>
#include "ionc/ion.h"

#define ION_OK(x) if (x) { printf("Error: %s\n", ion_error_to_str(x)); return x; }

int main(int argc, char **argv) {
    const char* ion_text = "{level1: {level2: {level3: \"foo\"}, x: 2}, y: [a,b,c]}";

    hREADER reader;
    ION_READER_OPTIONS reader_options;

    memset(&reader_options, 0, sizeof(ION_READER_OPTIONS));

    ION_OK(ion_reader_open_buffer(&reader,
                                  (BYTE *)ion_text,
                                  (SIZE)strlen(ion_text),
                                  &reader_options));


    char *pretty_text = (char *)malloc(200);

    hWRITER writer;
    ION_WRITER_OPTIONS writer_options;

    memset(&writer_options, 0, sizeof(ION_WRITER_OPTIONS));
    writer_options.pretty_print = true;                      // turns on pretty-printing

    ION_OK(ion_writer_open_buffer(&writer,
                                  (BYTE *)pretty_text,
                                  (SIZE)200,
                                  &writer_options));
    ION_OK(ion_writer_write_all_values(writer, reader));
    ION_OK(ion_writer_close(writer));

    ION_OK(ion_reader_close(reader));

    printf("%s\n", pretty_text);

    free(pretty_text);

    return 0;
}
```
</div>


<div class="tabpane Java" markdown="1">
Ion data can be pretty-printed using an `IonWriter` constructed by a specially-configured
`IonTextWriterBuilder`.

```java
String unformatted = "{level1: {level2: {level3: \"foo\"}, x: 2}, y: [a,b,c]}";

void rewrite(String textIon, IonWriter writer) throws IOException {
    IonReader reader = IonReaderBuilder.standard().build(textIon);
    writer.writeValues(reader);
}

void prettyPrint() throws IOException {
    StringBuilder stringBuilder = new StringBuilder();
    try (IonWriter prettyWriter = IonTextWriterBuilder.pretty().build(stringBuilder)) {
        rewrite(unformatted, prettyWriter);
    }
    System.out.println(stringBuilder.toString());
}
```
</div>


<div class="tabpane JavaScript" markdown="1">
Ion data can be pretty-printed using a `Writer` returned by `makePrettyWriter()`.  For example:

```javascript
let ion = require('ion-js');

let unformatted = '{level1: {level2: {level3: "foo"}, x: 2}, y: [a,b,c]}';

let reader = ion.makeReader(unformatted);
let writer = ion.makePrettyWriter();
writer.writeValues(reader);
writer.close();
console.log(String.fromCharCode.apply(null, writer.getBytes()));
```
</div>


### Down-converting to JSON

Because Ion has a richer type system than JSON, converting Ion to JSON is lossy.
Nevertheless, applications may have use cases that require them to
down-convert Ion data for JSON compatibility.

During this conversion, the following rules are applied:

  1. Nulls of any type are converted to JSON *null*
  2. Arbitrary precision integers are printed as JSON *number* with precision
     preserved
  3. Floats are printed as JSON *number* with `nan` and `+-inf` converted to
     JSON *null*
  4. Decimals are printed as JSON *number* with precision preserved
  5. Timestamps are printed as JSON *string*
  6. Symbols are printed as JSON *string*
  7. Strings are printed as JSON *string*
  8. Clobs are ASCII-encoded for characters between 32 (`0x20`) and 126
     (`0x7e`), inclusive. Characters from 0 (`0x00`) to 31 (`0x1f`) and from
     127 (`0x7f`) to 255 (`0xff`) are escaped as Unicode code points `U+00XX`
     (e.g. `0x7f` is `U+007f`, represented by `\u007f` in JSON)
  9. Blobs are printed as Base64-encoded JSON *string*s
  10. Structs are printed as JSON *object*
  11. Lists are printed as JSON *array*
  12. S-expressions are printed as JSON *array*
  13. Annotations are suppressed
  14. All struct field names are printed as JSON *string*s (i.e. they are
      quoted)
  15. Any trailing commas in container values are removed

Consider the following text Ion:

```
 {data: annot::{foo: null.string, bar: (2 + 2)}, time: 1969-07-20T20:18Z}
```

Down-converting into JSON results in output similar to the following:

```json
 {
   "data": {
     "foo": null,
     "bar": [
       2,
       "+",
       2
     ]
   },
   "time": "1969-07-20T20:18Z"
 }
```

For JSON compatibility, all field names were converted to JSON *string*, the
null `"foo"` field lost its type information, `"bar"` was converted into a
JSON *list* (losing its S-expression semantics), and `"time"` was represented
as a JSON *string*.

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
Not currently supported.
</div>

<div class="tabpane Java" markdown="1">
Using the `rewrite` method from the previous example, the data can be
down-converted for JSON compatibility.

```java
String textIon = "{data: annot::{foo: null.string, bar: (2 + 2)}, time: 1969-07-20T20:18Z}";

void downconvertToJson() throws IOException {
    StringBuilder stringBuilder = new StringBuilder();
    try (IonWriter jsonWriter = IonTextWriterBuilder.json().withPrettyPrinting().build(stringBuilder)) {
        rewrite(textIon, jsonWriter);
    }
    System.out.println(stringBuilder.toString());
}
```
</div>

<div class="tabpane JavaScript" markdown="1">
Not currently supported.
</div>


### Migrating JSON data to Ion

Because Ion is a superset of JSON, valid JSON data is valid Ion data. As such, 
Ion readers are capable of reading JSON data without any special
configuration. When reading data that was encoded by a JSON writer, the
following Ion text parsing rules should be kept in mind:

  1. Field names are interpreted as Ion symbols (i.e. quotes are removed when
     possible)
  2. Numeric values without a decimal point are interpreted as Ion integers
  3. Numeric values with a decimal point but without an exponent are interpreted
     as Ion decimals
  4. Numeric values with exponents are interpreted as Ion floats
  
Consider the following JSON data:

```json-doc
 // TEXT
 {
   "data": {
     "foo": null,
     "bar": [
       2,
       "+",
       2
      ]
   },
   "time": "1969-07-20T20:18Z"
 }
```

Converting this data to Ion (possibly via one of the pretty-printing examples)
results in the following:

```
 {
   data: {
     foo: null,
     bar: [
       2,
       "+",
       2
     ]
   },
   time: "1969-07-20T20:18Z"
 }
```

This is clearly valid Ion, but is no longer valid JSON (because field names
are unquoted). And, notably, it is **not** the same as the original Ion data
that was down-converted to JSON.

### Reading numeric types

Because Ion has richly defined numeric types, there are often multiple possible
representations of a numeric Ion value.

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
```c
#include <stdlib.h>
#include "ionc/ion.h"

#define ION_OK(x) if (x) { printf("Error: %s\n", ion_error_to_str(x)); return x; }

#define ION_ASSERT_TYPE(type, x) if ((x) != (type)) { ION_OK(IERR_INVALID_STATE); }

int main(int argc, char **argv) {
    const char* ion_text = "1.23456 1.2345e6 123456 12345678901234567890";

    hREADER reader;
    ION_READER_OPTIONS options;

    memset(&options, 0, sizeof(ION_READER_OPTIONS));

    ION_OK(ion_reader_open_buffer(&reader,
                                  (BYTE *)ion_text,
                                  (SIZE)strlen(ion_text),
                                  &options));

    ION_TYPE ion_type;

    ION_OK(ion_reader_next(reader, &ion_type));
    ION_ASSERT_TYPE(ion_type, tid_DECIMAL);
    ION_DECIMAL value_ion_decimal;
    ION_OK(ion_reader_read_ion_decimal(reader, &value_ion_decimal));
    char string[50];
    ION_OK(ion_decimal_to_string(&value_ion_decimal, string));
    printf("ion_decimal: %s\n", string);
    ION_OK(ion_decimal_free(&value_ion_decimal));

    ION_OK(ion_reader_next(reader, &ion_type));
    ION_ASSERT_TYPE(ion_type, tid_FLOAT);
    double value_double;
    ION_OK(ion_reader_read_double(reader, &value_double));
    printf("     double: %f\n", value_double);

    ION_OK(ion_reader_next(reader, &ion_type));
    ION_ASSERT_TYPE(ion_type, tid_INT);
    int value_int;
    ION_OK(ion_reader_read_int(reader, &value_int));
    printf("        int: %d\n", value_int);

    ION_OK(ion_reader_next(reader, &ion_type));
    ION_ASSERT_TYPE(ion_type, tid_INT);
    ION_INT *value_ion_int;
    ION_OK(ion_int_alloc(NULL, &value_ion_int));
    ION_OK(ion_reader_read_ion_int(reader, value_ion_int));
    ION_STRING istring;
    ION_OK(ion_int_to_string(value_ion_int, NULL, &istring));
    char *string_int = ion_string_strdup(&istring);
    printf("    ion_int: %s\n", string_int);
    free(string_int);
    ion_int_free(value_ion_int);

    return 0;
}
```

When executed, the code above outputs:
```
ion_decimal: 1.23456
     double: 1234500.000000
        int: 123456
    ion_int: 12345678901234567890
```
</div>

<div class="tabpane Java" markdown="1">
Integer values that can fit into a Java `int` may be read as such using
`IonReader.intValue()`, or may be read into a `long` using
`IonReader.longValue()`, or a [`java.math.BigInteger`][12] using
`IonReader.bigIntegerValue()`.

The following example illustrates the equivalence of using different
`IonReader` APIs to read the same numeric value.

```java
import static org.junit.Assert.assertEquals;
import java.math.BigDecimal;
import java.math.BigInteger;

void readNumericTypes() throws IOException {
    String numberList = "1.23456 1.2345e6 123456";

    // expected values
    BigDecimal first = new BigDecimal("1.23456");
    BigInteger second = new BigInteger("123456");
    double third = 1.2345e6;

    IonReader reader = IonReaderBuilder.standard().build(numberList);

    assertEquals(IonType.DECIMAL, reader.next());
    assertEquals(first, reader.bigDecimalValue());
    assertEquals(first.doubleValue(), reader.doubleValue(), 1e-9);

    assertEquals(IonType.FLOAT, reader.next());
    assertEquals(third, reader.doubleValue(), 1e-9);

    assertEquals(IonType.INT, reader.next());
    assertEquals(second, reader.bigIntegerValue());
    assertEquals(second.longValue(), reader.longValue());
    assertEquals(second.intValue(), reader.intValue());
}
```

**Note:**  care must be taken to avoid data loss. For example, reading an integer
value too large to fit in a Java `int` using `IonReader.intValue()` will
result in loss.
</div>

<div class="tabpane JavaScript" markdown="1">
The following example illustrates the equivalence of using different
`Reader` APIs to read the same numeric value.

```javascript
let ion = require('ion-js');
let IntSize = require('ion-js').IntSize;
let IonTypes = require('ion-js').IonTypes;
let jsbi = require('jsbi');
let assert = require('chai').assert;

let reader = ion.makeReader('1.23456 1.2345e6 123456 12345678901234567890');

let expected = ion.Decimal.parse('1.23456');
assert.equal(reader.next(), IonTypes.DECIMAL);
assert.deepEqual(reader.decimalValue(), expected);

expected = 1.2345e6;
assert.equal(reader.next(), IonTypes.FLOAT);
assert.equal(reader.numberValue(), expected);

expected = jsbi.BigInt('123456');
assert.equal(reader.next(), IonTypes.INT);
assert.equal(reader.intSize(), IntSize.Number);
assert.deepEqual(reader.bigIntValue(), expected);
assert.equal(reader.numberValue(), jsbi.toNumber(expected));

let intStr = '12345678901234567890';
expected = jsbi.BigInt(intStr);
assert.equal(reader.next(), IonTypes.INT);
assert.equal(reader.intSize(), IntSize.BigInt);
assert.deepEqual(reader.bigIntValue(), expected);
assert.notEqual(reader.numberValue()+'', intStr);  // precision loss, as the int can't be fully represented as a number
```

**Note**:  care must be taken to avoid loss of precision. For example, calling
`Reader.numberValue()` to read an Ion `int` too large to be represented by a
JavaScript `number` will result in loss of precision.  `Reader.intSize()` can
be used to determine whether an Ion `int` can be fully represented as a `number`;
if not, call `Reader.bigIntValue()` to avoid loss of precision.
</div>

## Performing sparse reads

One of the major benefits of binary Ion is the ability to efficiently perform
sparse reads.

Consider the following stream of binary Ion data.

```
 // BINARY
 $ion_1_0
 foo::{
   quantity: 1
 }
 bar::{
   name: "x",
   id: 7
 }
 baz::{
   items:["thing1", "thing2"]
 }
 foo::{
   quantity: 19
 }
 bar::{
   name: "y",
   id: 8
 }
 // the stream continues...
```

The following examples simulate an application whose only purpose is to sum the
`quantity` fields of each `foo` struct in the stream. This is achieved by
examining the type annotations of each top-level struct and comparing against
`"foo"`. Because binary Ion is length-prefixed, when the struct's annotation does
not match `"foo"`, the reader can quickly skip to the start of the next value.

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
```c
#include <stdlib.h>
#include "ionc/ion.h"

#define ION_OK(x) if (x) { printf("Error: %s\n", ion_error_to_str(x)); return x; }

int main(int argc, char **argv) {
    const BYTE ion_binary[] = {
            0xe0, 0x01, 0x00, 0xea,
            0xee, 0xa5, 0x81, 0x83, 0xde, 0xa1, 0x87, 0xbe, 0x9e, 0x83, 0x66, 0x6f, 0x6f, 0x88,
            0x71, 0x75, 0x61, 0x6e, 0x74, 0x69, 0x74, 0x79, 0x83, 0x62, 0x61, 0x72, 0x82, 0x69,
            0x64, 0x83, 0x62, 0x61, 0x7a, 0x85, 0x69, 0x74, 0x65, 0x6d, 0x73, 0xe6, 0x81, 0x8a,
            0xd3, 0x8b, 0x21, 0x01, 0xe9, 0x81, 0x8c, 0xd6, 0x84, 0x81, 0x78, 0x8d, 0x21, 0x07,
            0xee, 0x95, 0x81, 0x8e, 0xde, 0x91, 0x8f, 0xbe, 0x8e, 0x86, 0x74, 0x68, 0x69, 0x6e,
            0x67, 0x31, 0x86, 0x74, 0x68, 0x69, 0x6e, 0x67, 0x32, 0xe6, 0x81, 0x8a, 0xd3, 0x8b,
            0x21, 0x13, 0xe9, 0x81, 0x8c, 0xd6, 0x84, 0x81, 0x79, 0x8d, 0x21, 0x08 };

    const int ion_binary_length = 100;

    hREADER reader;
    ION_READER_OPTIONS options;

    memset(&options, 0, sizeof(ION_READER_OPTIONS));

    ION_OK(ion_reader_open_buffer(&reader,
                                  (BYTE *)ion_binary,
                                  ion_binary_length,
                                  &options));

    ION_STRING foo;
    ion_string_assign_cstr(&foo, "foo", strlen("foo"));
    ION_STRING quantity;
    ion_string_assign_cstr(&quantity, "quantity", strlen("quantity"));

    int sum = 0;

    ION_TYPE ion_type;
    ION_OK(ion_reader_next(reader, &ion_type));

    while (ion_type != tid_EOF) {
        if (ion_type == tid_STRUCT) {
            BOOL annotation_found;
            ION_OK(ion_reader_has_annotation(reader, &foo, &annotation_found));
            if (annotation_found) {
                ION_OK(ion_reader_step_in(reader));
                ION_OK(ion_reader_next(reader, &ion_type));
                while (ion_type != tid_EOF) {
                    ION_STRING field_name;
                    ION_OK(ion_reader_get_field_name(reader, &field_name));
                    if (ION_STRING_EQUALS(&field_name, &quantity)) {
                        int quantity;
                        ION_OK(ion_reader_read_int(reader, &quantity));
                        sum += quantity;
                    }
                    ION_OK(ion_reader_next(reader, &ion_type));
                }
                ION_OK(ion_reader_step_out(reader));
            }
        }
        ION_OK(ion_reader_next(reader, &ion_type));
    }

    ION_OK(ion_reader_close(reader));

    return sum;
}
```
</div>

<div class="tabpane Java" markdown="1">
```java
InputStream getStream() {
    // return an InputStream representation of the above data
}

int sumFooQuantities() {
    IonReader reader = IonReaderBuilder.standard().build(getStream());
    int sum = 0;
    IonType type;
    while ((type = reader.next()) != null) {
        if (type == IonType.STRUCT) {
            String[] annotations = reader.getTypeAnnotations();
            if (annotations.length > 0 && annotations[0].equals("foo")) {
                reader.stepIn();
                while ((type = reader.next()) != null) {
                    if (reader.getFieldName().equals("quantity")) {
                        sum += reader.intValue();
                        break;
                    }
                }
                reader.stepOut();
            }
        }
    }
    return sum;
}
```
</div>

<div class="tabpane JavaScript" markdown="1">
```javascript
let ion = require('ion-js');
let IonTypes = require('ion-js').IonTypes;

let reader = ion.makeReader(bytes);   // where bytes is the Ion binary representation of the above data
let sum = 0;
let type;
while (type = reader.next()) {
    if (type === IonTypes.STRUCT) {
        let annotations = reader.annotations();
        if (annotations.length > 0 && annotations[0] === 'foo') {
            reader.stepIn();
            while (type = reader.next()) {
                if (reader.fieldName() === 'quantity') {
                    sum += reader.numberValue();
                    break;
                }
            }
            reader.stepOut();
        }
    }
}
```
</div>


## Converting non-hierarchical data to Ion

Although Ion is a hierarchical format, it can be used to represent
non-hierarchical data in a more efficient way than many other hierarchical
formats, notably JSON.

Consider a use case that requires converting CSV data to Ion. Performing this
conversion to JSON or XML results in an inefficient encoding due to repetitive
duplication of column names. Ion can mitigate this drawback through use of
symbol tables.

Consider the following CSV in a file called `test.csv`.

```
 id,type,state
 1,foo,false
 2,bar,true
 3,baz,true
 ...
```
    
An application that wishes to convert this data into the Ion format can
generate a symbol table containing the column names. This reduces encoding size
and improves read efficiency.

### Using a local symbol table

Local symbol tables are managed internally by Ion readers and writers. No
application configuration is required to tell Ion readers or writers that local
symbol tables should be used.

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
```c
#include <stdlib.h>
#include "ionc/ion.h"

#define ION_OK(x) if (x) { printf("Error: %s\n", ion_error_to_str(x)); return x; }

int main(int argc, char **argv) {
    char *out = (char *)malloc(200);

    hWRITER writer;
    ION_WRITER_OPTIONS writer_options;

    memset(&writer_options, 0, sizeof(ION_WRITER_OPTIONS));

    ION_OK(ion_writer_open_buffer(&writer,
                                  (BYTE *)out,
                                  (SIZE)200,
                                  &writer_options));

    FILE *fp = fopen("test.csv", "r");

    char line[1024];
    fgets(line, 1024, fp);            // skip the header row
    while (fgets(line, 1024, fp)) {
        ION_OK(ion_writer_start_container(writer, tid_STRUCT));

        ION_STRING field_name;
        char *value;

        ion_string_assign_cstr(&field_name, "id", strlen("id"));
        ION_OK(ion_writer_write_field_name(writer, &field_name));
        value = strtok(line, ",");
        ION_OK(ion_writer_write_int(writer, atoi(value)));

        ion_string_assign_cstr(&field_name, "type", strlen("type"));
        ION_OK(ion_writer_write_field_name(writer, &field_name));
        value = strtok(NULL, ",");
        ION_STRING type_string;
        ion_string_assign_cstr(&type_string, value, strlen(value));
        ION_OK(ion_writer_write_string(writer, &type_string));

        ion_string_assign_cstr(&field_name, "state", strlen("state"));
        ION_OK(ion_writer_write_field_name(writer, &field_name));
        value = strtok(NULL, "\n");
        ION_OK(ion_writer_write_bool(writer, strcmp(value, "true") == 0));

        ION_OK(ion_writer_finish_container(writer));
    }

    ION_OK(ion_writer_close(writer));

    printf("output: %s", out);

    free(out);
    fclose(fp);

    return 0;
}
```
</div>

<div class="tabpane Java" markdown="1">
Start by retrieving an object that can parse `test.csv` line-by-line, e.g. a
[`java.io.BufferedReader`][13].

```java
BufferedReader getCsvReader() { /*...*/ }
```

The code that actually performs the conversion will use this to parse each line
of the CSV and write its components to an IonWriter.

```java
void convertCsvToIon(IonWriter writer) throws IOException {
    BufferedReader reader = getCsvReader();
    reader.readLine(); // skip over the column labels
    String row;
    while ((row = reader.readLine()) != null) {
        String[] values = row.split(",");
        writer.stepIn(IonType.STRUCT);
        writer.setFieldName("id");
        writer.writeInt(Integer.parseInt(values[0]));
        writer.setFieldName("type");
        writer.writeString(values[1]);
        writer.setFieldName("state");
        writer.writeBool(Boolean.parseBoolean(values[2]));
        writer.stepOut();
    }
}
```

Writing the CSV data as Ion using a local symbol table is as simple as using one
of the techniques exhibited earlier in this cookbook to construct an
`IonWriter`, passing it to the `convertCsvToIon` method, and closing
it when finished.

```java
void convertCsvToIonUsingLocalSymbolTable(OutputStream output) throws IOException {
    try (IonWriter writer = IonBinaryWriterBuilder.standard().build(output)) {
        convertCsvToIon(writer);
    }
}
```
</div>

<div class="tabpane JavaScript" markdown="1">
```javascript
let ion = require('ion-js');
let IonTypes = require('ion-js').IonTypes;
let fs = require('fs');

let writer = ion.makePrettyWriter();
fs.readFileSync('data.csv', 'utf-8')
    .trim()
    .split(/\r?\n/)
    .forEach((line, index) => {
        if (index > 0) {
            let values = line.split(',');
            writer.stepIn(IonTypes.STRUCT);
            writer.writeFieldName('id');
            writer.writeInt(parseInt(values[0]));
            writer.writeFieldName('type');
            writer.writeString(values[1]);
            writer.writeFieldName('state');
            writer.writeBoolean(values[2] === 'true');
            writer.stepOut();
        }
    });
writer.close();
```
</div>


### Using a shared symbol table

Using local symbol tables requires the local symbol table (including all of its
symbols) to be written at the beginning of the value stream. Consider an Ion
stream that represents CSV data with many columns. Although local symbol tables
will optimize writing and reading each value, including the entire symbol
table itself in the value stream adds overhead that increases with the number
of columns.

If it is feasible for the writers and readers of the stream to agree on a
pre-defined shared symbol table, this overhead can be reduced.

#### Writing

Consider the following shared symbol table that declares the column names of
`test.csv` as symbols. Note that the shared symbol table may have been
generated by hand or programmatically.

```
 // TEXT
 $ion_shared_symbol_table::{
     name: "test.csv.columns"
     version: 1
     symbols: ["id", "type", "state"]
 }
```

This shared symbol table can be stored in a file (or in a database) to be
resurrected into a symbol table at runtime.

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
Example not yet implemented.
</div>

<div class="tabpane Java" markdown="1">
The [`IonSystem`][3] interface provides many utilities in ion-java,
including construction of shared `SymbolTable`s. When an `IonSystem` is
required, a single instance generally should be constructed and used
throughout the application.

An `IonSystem` with the standard configuration may be constructed as
follows.

```java
static final IonSystem SYSTEM = IonSystemBuilder.standard().build();
```

Below, this `IonSystem` instance is used to create a shared `SymbolTable`.

```java
InputStream getSharedSymbolTableStream() {
    // get an InputStream over the 'test.csv.columns' shared symbol table.
}

SymbolTable getSharedSymbolTable() {
    IonReader symbolTableReader = IonReaderBuilder.standard().build(getSharedSymbolTableStream());
    return SYSTEM.newSharedSymbolTable(symbolTableReader);
}
```

Note that an equivalent shared symbol table could be constructed
programmatically.

```java
SymbolTable getSharedSymbolTable() {
    Iterator<String> symbols = Arrays.asList("id", "type", "state").iterator();
    return SYSTEM.newSharedSymbolTable("test.csv.columns", 1, symbols);
}
```

Now, an `IonWriter` that is configured to use the symbols from the shared
symbol table is constructed, passed to the `convertCsvToIon` method from
above, and closed when finished.

```java
void convertCsvToIonUsingSharedSymbolTable(OutputStream output) throws IOException {
    SymbolTable shared = getSharedSymbolTable();
    try (IonWriter writer = IonBinaryWriterBuilder.standard().withImports(shared).build(output)) {
        convertCsvToIon(writer);
    }
}
```

Rather than writing a local symbol table that grows with the number of columns,
this technique simply includes a symbol table at the beginning of the stream
that imports the shared symbol table. (Note that, in addition, any symbols
written but not included in the shared symbol table will be declared in the
symbol table that begins the stream.)
</div>

<div class="tabpane JavaScript" markdown="1">
Not currently supported.
</div>


#### Reading

Because the value stream written using the shared symbol table does not contain
the symbol mappings, a reader of the stream needs to access the shared symbol
table using a catalog.

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
Example not yet implemented.
</div>

<div class="tabpane Java" markdown="1">
The [`IonCatalog`][8] interface may be implemented by applications to provide
customized shared symbol table retrieval logic, such as retrieval from an external
source.

ion-java includes an implementation of `IonCatalog` called [`SimpleCatalog`][9],
which stores shared symbol tables in memory and will be used here for
illustration purposes.

Creating `IonReader`s capable of parsing streams written with shared symbol
tables starts with correctly configuring an `IonReaderBuilder`. Reusing the
`getSharedSymbolTable` method from above, this can be done as follows.

```java
IonReaderBuilder getReaderBuilderWithCatalog() {
    SimpleCatalog catalog = new SimpleCatalog();
    catalog.putTable(getSharedSymbolTable());
    return IonReaderBuilder.standard().withCatalog(catalog);
}
```

The resulting `IonReaderBuilder` may be used to instantiate `IonReader`s capable
of interpreting the shared symbols encountered in the value stream written in the
previous sub-section.
</div>

<div class="tabpane JavaScript" markdown="1">
Not currently supported.
</div>


## See also

* [The ion-c API Documentation][14]
* [The ion-java API Documentation][2]
* [The ion-js API Documentation][18]

<script language="JavaScript">
<!--
function openTab(tabName) {
  document.querySelectorAll('.tab').forEach(e => e.className = e.className.replace(' active', ''));
  document.querySelectorAll('.tabpane').forEach(e => e.style.display = 'none');

  // mark new tab as 'active', and display corresponding content
  document.querySelectorAll('.tab.' + tabName).forEach(e => e.className += ' active');
  document.querySelectorAll('.tabpane.' + tabName).forEach(e => e.style.display = 'block');
}
openTab('Java');  // default tab
// -->
</script>

<!-- References -->
[1]: https://github.com/amzn/ion-java
[2]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/
[3]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/IonSystem.html
[4]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/IonReader.html
[5]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/IonWriter.html
[6]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/system/IonTextWriterBuilder.html
[7]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/SymbolTable.html
[8]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/IonCatalog.html
[9]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/system/SimpleCatalog.html
[10]: https://docs.oracle.com/javase/8/docs/api/java/io/OutputStream.html
[11]: https://docs.oracle.com/javase/8/docs/api/java/io/ByteArrayOutputStream.html
[12]: https://docs.oracle.com/javase/8/docs/api/java/math/BigInteger.html
[13]: https://docs.oracle.com/javase/8/docs/api/java/io/BufferedReader.html
[14]: https://amzn.github.io/ion-c/
[15]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/system/IonBinaryWriterBuilder.html
[16]: https://www.javadoc.io/doc/com.amazon.ion/ion-java/latest/com/amazon/ion/system/IonReaderBuilder.html
[17]: {{ site.baseurl }}/docs.html
[18]: https://amzn.github.io/ion-js/api/
[19]: https://amzn.github.io/ion-js/api/interfaces/_ionreader_.reader.html
[20]: https://amzn.github.io/ion-js/api/interfaces/_ionwriter_.writer.html

