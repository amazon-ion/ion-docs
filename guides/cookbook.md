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
  ['C', 'C#', 'Go', 'Java', 'JavaScript', 'Python'].forEach(lang => {
    var tabName = lang == 'C#' ? 'C-sharp' : lang;
    document.write('<button class="tab ' + tabName + '"' + ' onclick="openTab(\'' + tabName + '\')">' + lang + '</button>')
  });
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

<div class="tabpane C-sharp" markdown="1">
Implementations of the IIonReader and IIonWriter interfaces are responsible for reading and writing
Ion data in both text and binary forms.

The following example shows how text Ion data can be read from a string:
```c#
using IonDotnet;
using IonDotnet.Builders;
using System;

class ReadIonData
{
    static void Main(string[] args)
    {
        using IIonReader reader = IonReaderBuilder.Build("{hello: \"world\"}");
        reader.MoveNext();                           // position the reader at the first value, a struct
        reader.StepIn();                             // step into the struct
        reader.MoveNext();                           // position the reader at the first value in the struct
        string fieldName = reader.CurrentFieldName;  // retrieve the current value's field name
        string value = reader.StringValue();         // retrieve the current value's string value
        reader.StepOut();                            // step out of the struct
        Console.WriteLine(fieldName + " " + value);  // prints:  hello world
    }
}
```

In the above example, the text Ion `{hello: "world"}` was probably typed by a human using a text
editor. The following example illustrates how it could have been generated using an `IIonWriter`:

```c#
using IonDotnet;
using IonDotnet.Builders;
using System;
using System.IO;

class WriteIonText
{
    static void Main(string[] args)
    {
        using TextWriter tw = new StringWriter();
        using IIonWriter writer = IonTextWriterBuilder.Build(tw);
        writer.StepIn(IonType.Struct);     // step into a struct
        writer.SetFieldName("hello");      // set the field name for the next value to be written
        writer.WriteString("world");       // write the next value
        writer.StepOut();                  // step out of the struct
        writer.Finish();
        Console.WriteLine(tw.ToString());  // prints:  {hello:"world"}
    }
}
```

If Ion binary encoding is desired, use `IonBinaryWriterBuilder` (instead of `IonTextWriterBuilder`).
</div>

<div class="tabpane Go" markdown="1">
Implementations of the [`Reader`][22] and [`Writer`][23] interfaces are responsible for reading and writing Ion data in both text and binary forms.

In order to make and use a text reader, we can use `NewReaderString()`. The following example demonstrates how to read Ion data from a string:
```Go
package main

import (
	"fmt"
	"github.com/amzn/ion-go/ion"
)

func main() {
	reader := ion.NewReaderString("{hello:\"world\"}")
	if reader.Next() {                                           // position the reader at the first value
		currentType := reader.Type()                             // the first value in the reader is a struct
		fmt.Println("Current type is:\t" + currentType.String()) // Current type is:   struct
		reader.StepIn()                                          // step into the struct
		reader.Next()                                            // position the reader at the first value in the struct
		currentType = reader.Type()                              // the first value in the struct is of type string
		fmt.Println("Current type, after stepping in the struct:\t" +
			currentType.String())          // Current type, after stepping in the struct:   string
		fieldName := reader.FieldName()    // retrieve the current value's field name
		value, err := reader.StringValue() // retrieve the current value's string value
		if err != nil {
			panic("Reading string value failed.")
		}
		reader.StepOut()                    // step out of the struct
		fmt.Println(*fieldName, " ", value) // hello world
	}
}
```
If we have a binary Ion, `NewReaderBytes()` can be used in the same fashion.

To write the the same struct as above, `{hello:"world"}`, we can use `NewTextWriter()` as shown below:
```Go
package main

import (
	"fmt"
	"strings"

	"github.com/amzn/ion-go/ion"
)

func main() {
	str := strings.Builder{}
	writer := ion.NewTextWriter(&str)
	err := writer.BeginStruct() // start and step into a struct
	if err != nil {
		panic(err)
	}
	err = writer.FieldName("hello") // set the field name for the next value to be written
	if err != nil {
		panic(err)
	}
	err = writer.WriteString("world") // write the next value
	if err != nil {
		panic(err)
	}
	err = writer.EndStruct() // step out of the struct
	if err != nil {
		panic(err)
	}
	err = writer.Finish()
	if err != nil {
		panic(err) 
	}
	fmt.Println(str.String()) // {hello:"world"}
}
```
To write binary Ion, we can use `NewBinaryWriter()` and pass an instance of an `io.Writer` to it: 
```Go
	buf := bytes.Buffer{}
	writer := NewBinaryWriter(&buf)
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
String helloWorld = "{hello: \"world\"}";
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

If Ion binary encoding is desired, use `ion.makeBinaryWriter()` instead of `ion.makeTextWriter()`.
The result of `getBytes()` from a text or binary writer can subsequently
be passed as the parameter to `makeReader()` in order to read the Ion data.
</div>

<div class="tabpane Python" markdown="1">
Two distict APIs for reading and writing Ion are available in Python: a non-blocking event-based API
and a blocking `dump/load` API called `simpleion`, which is reminiscent of the popular `simplejson`
JSON processing API. This cookbook will illustrate how to implement the examples using both APIs.

The following examples show how Ion data can be read and written.

#### Using simpleion

```python
from amazon.ion import simpleion

data = u'{hello: "world"}'
value = simpleion.loads(data)
print(u'hello %s' % value[u'hello'])
```

Result: `hello world`.

To read data from a file-like object instead of a string or unicode object, use `load` instead.

```python
from io import BytesIO
from amazon.ion import simpleion

data = BytesIO(b'{hello: "world"}')
value = simpleion.load(data)
print(u'hello %s' % value[u'hello'])
```

To re-write `value` from above, use `dump` or `dumps`.

```python
from amazon.ion import simpleion

print(simpleion.dumps(value, binary=False))
```

Result: `$ion_1_0 {hello:"world"}`

To write binary Ion instead of text, use the `binary=True` option.

```python
from io import BytesIO
from amazon.ion import simpleion

ion = BytesIO()
simpleion.dump(value, ion, binary=True)
print(ion.getvalue())
```

Result: `b'\xe0\x01\x00\xea\xec\x81\x83\xde\x88\x87\xb6\x85hello\xde\x87\x8a\x85world'`

When reading Ion streams that contain multiple top-level values, provide the `single_value=False`
option to `load/loads` to receive all of the values within a Python `list`.

```python
from amazon.ion import simpleion

data = u'1 2 3'
value = simpleion.loads(data, single_value=False)
print(value)
```

Result: `[1, 2, 3]`

To write a sequence type as a stream of top-level values, provide the `sequence_as_stream=True`
option to `dump/dumps`.

```python
from amazon.ion import simpleion

print(simpleion.dumps(value, sequence_as_stream=True, binary=False))
```

Result: `$ion_1_0 1 2 3`

The `simpleion` [API documentation](https://ion-python.readthedocs.io/en/latest/amazon.ion.html#module-amazon.ion.simpleion)
enumerates the complete set of options available.

#### Using events

The non-blocking event-based APIs are useful for streaming reading and writing of Ion data. This
enables use cases where data becomes available incrementally or only needs to be sparsely parsed.

```python
from amazon.ion.core import IonEventType, IonType
from amazon.ion.reader import NEXT_EVENT, read_data_event
from amazon.ion.reader_managed import managed_reader
from amazon.ion.reader_text import text_reader

# Create a text reader coroutine that manages symbol tables
# automatically.
reader = managed_reader(text_reader())
event = reader.send(NEXT_EVENT)
# No data has been provided, so the reader is at STREAM_END
# and will wait for data.
assert event.event_type == IonEventType.STREAM_END
# Send an incomplete Ion value.
event = reader.send(read_data_event(b'{hello:'))
# Enough data was available for the reader to determine that
# the start of a struct value has been encountered.
assert event.event_type == IonEventType.CONTAINER_START
assert event.ion_type == IonType.STRUCT
# Advancing the reader causes it to step into the struct.
event = reader.send(NEXT_EVENT)
# The reader reached the end of the data before completing
# a value. Therefore, an INCOMPLETE event is returned.
assert event.event_type == IonEventType.INCOMPLETE
# Send the rest of the value.
event = reader.send(read_data_event(b'"world"}'))
# The reader now finishes parsing the value within the struct.
assert event.event_type == IonEventType.SCALAR
assert event.ion_type == IonType.STRING
hello = event.field_name.text
world = event.value
# Advance the reader past the string value.
event = reader.send(NEXT_EVENT)
# The reader has reached the end of the struct.
assert event.event_type == IonEventType.CONTAINER_END
# Advancing the reader causes it to step out of the struct.
event = reader.send(NEXT_EVENT)
# There is no more data and a value has been completed.
# Therefore, the reader conveys STREAM_END.
assert event.event_type == IonEventType.STREAM_END
print(u'%s %s' % (hello, world))
```

Result: `hello world`

To read binary Ion data instead, provide the `binary_reader` coroutine to `managed_reader`.

To write this value using binary Ion, use the `binary_writer` coroutine.

```python
from amazon.ion.core import IonEventType, IonType, IonEvent, ION_STREAM_END_EVENT
from amazon.ion.writer import WriteEventType
from amazon.ion.writer_binary import binary_writer

def drain_data(incremental_event):
    incremental_data = b''
    while incremental_event.type == WriteEventType.HAS_PENDING:
        # The writer has data available. Retrieve it.
        incremental_data += incremental_event.data
        # Send `None` to signal that the data has been retrieved. Continue
        # retrieving data until no more data is pending.
        incremental_event = writer.send(None)
    return incremental_data

writer = binary_writer()
event = writer.send(IonEvent(IonEventType.CONTAINER_START, IonType.STRUCT))
data = drain_data(event)
event = writer.send(IonEvent(IonEventType.SCALAR, IonType.STRING, field_name=u'hello', value=u'world'))
data += drain_data(event)
event = writer.send(IonEvent(IonEventType.CONTAINER_END))
data += drain_data(event)
event = writer.send(ION_STREAM_END_EVENT)
data += drain_data(event)
print(data)
```

Result: `b'\xe0\x01\x00\xea\xec\x81\x83\xde\x88\x87\xb6\x85hello\xde\x87\x8a\x85world'`

To write text Ion data instead, create a `text_writer` coroutine.

It is often desirable, and easier, to use blocking file-like objects with the event-based APIs.
Ion-Python provides the `blocking_reader` and `blocking_writer` helper coroutines for this purpose.

For blocking reads:

```python
from io import BytesIO
from amazon.ion.core import IonEventType, IonType
from amazon.ion.reader import blocking_reader, NEXT_EVENT
from amazon.ion.reader_managed import managed_reader
from amazon.ion.reader_text import text_reader

data = BytesIO(b'{hello: "world"}')
reader = blocking_reader(managed_reader(text_reader()), data)
event = reader.send(NEXT_EVENT)
assert event.event_type == IonEventType.CONTAINER_START
assert event.ion_type == IonType.STRUCT
# Advancing the reader causes it to step into the struct.
event = reader.send(NEXT_EVENT)
assert event.event_type == IonEventType.SCALAR
assert event.ion_type == IonType.STRING
hello = event.field_name.text
world = event.value
# Advance the reader past the string value.
event = reader.send(NEXT_EVENT)
# The reader has reached the end of the struct.
assert event.event_type == IonEventType.CONTAINER_END
# Advancing the reader causes it to step out of the struct.
event = reader.send(NEXT_EVENT)
# There is no more data and a value has been completed.
# Therefore, the reader conveys STREAM_END.
assert event.event_type == IonEventType.STREAM_END
print(u'%s %s' % (hello, world))
```

Result: `hello world`

For blocking writes:

```python
from io import BytesIO
from amazon.ion.core import IonEventType, IonType, IonEvent, ION_STREAM_END_EVENT
from amazon.ion.writer import blocking_writer, WriteEventType
from amazon.ion.writer_binary import binary_writer

data = BytesIO()
writer = blocking_writer(binary_writer(), data)
event_type = writer.send(IonEvent(IonEventType.CONTAINER_START, IonType.STRUCT))
# The value is not complete, so more events are required.
assert event_type == WriteEventType.NEEDS_INPUT
event_type = writer.send(IonEvent(IonEventType.SCALAR, IonType.STRING, field_name=u'hello', value=u'world'))
# The value is not complete, so more events are required.
assert event_type == WriteEventType.NEEDS_INPUT
event_type = writer.send(IonEvent(IonEventType.CONTAINER_END))
# The value is not complete, so more events are required.
assert event_type == WriteEventType.NEEDS_INPUT
event_type = writer.send(ION_STREAM_END_EVENT)
# The end of the stream was signaled, so the data has been flushed.
assert event_type == WriteEventType.COMPLETE
print(data.getvalue())
```

Result: `b'\xe0\x01\x00\xea\xec\x81\x83\xde\x88\x87\xb6\x85hello\xde\x87\x8a\x85world'`
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
   level1: {
     level2: {
       level3: "foo"
     },
     x: 2
   },
   y: [
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

<div class="tabpane C-sharp" markdown="1">
Ion data can be pretty-printed using an `IIonWriter` constructed by an `IonTextWriterBuilder` configured as follows:
```c#
using IonDotnet;
using IonDotnet.Builders;
using System;
using System.IO;

class PrettyPrint
{
    static void Main(string[] args)
    {
        using IIonReader reader = IonReaderBuilder.Build("{level1: {level2: {level3: \"foo\"}, x: 2}, y: [a,b,c]}");

        using TextWriter tw = new StringWriter();
        using IIonWriter writer = IonTextWriterBuilder.Build(tw, new IonTextOptions {PrettyPrint = true});
        writer.WriteValues(reader);
        writer.Finish();
        Console.WriteLine(tw.ToString());
    }
}
```
</div>

<div class="tabpane Go" markdown="1">
Ion data can be pretty-printed using `NewTextWriterOpts` and by passing the `TextWriterPretty` option to it:
```Go
package main

import (
	"fmt"
	"strings"

	"github.com/amzn/ion-go/ion"
)

type l3 struct {
	Level3 string `ion:"level3"`
}
type l2 struct {
	Level2 l3 `ion:"level2"`
	X      int `ion:"x"`
}
type l1 struct {
	Level1 l2 `ion:"level1"`
	Y      []string `ion:"y"`
}

func main() {
	l3Val := l3{"foo"}
	l2Val := l2{l3Val, 2}
	l1Val := l1{l2Val, []string{"a", "b", "c"}}

	buf := strings.Builder{}
	writer := ion.NewTextWriterOpts(&buf, ion.TextWriterPretty)

	err := ion.MarshalTo(writer, l1Val)
	if err != nil {
		panic(err)
	}

	if err := writer.Finish(); err != nil {
		panic(err)
	}

	fmt.Println(buf.String())
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

<div class="tabpane Python" markdown="1">
#### Using simpleion
`dump/dumps` allow the user to provide the whitespace that will make up each
indentation level via the `indent` parameter. Providing any amount of
whitespace will cause text Ion to be pretty-printed.

```python
from amazon.ion import simpleion

unformatted = u'{level1: {level2: {level3: "foo"}, x: 2}, y: [a,b,c]}'
value = simpleion.loads(unformatted)
pretty = simpleion.dumps(value, binary=False, indent=u'  ')
```

#### Using events
The `text_writer` coroutine allows the user to provide the whitespace that will
make up each indentation level via the `indent` parameter. Providing any amount
of whitespace will cause text Ion to be pretty-printed.

```python
from io import BytesIO
from amazon.ion.writer import blocking_writer
from amazon.ion.writer_text import text_writer

pretty = BytesIO()
writer = blocking_writer(text_writer(indent=u'  '), pretty)
... # Send events to the writer.
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

<div class="tabpane C-sharp" markdown="1">
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
Any `Value` object returned by `load()` may be converted by a JSON string by passing it to `JSON.stringify()`:

```javascript
let ion = require('ion-js');

let value = ion.load('{data: annot::{foo: null.string, bar: (2 + 2)}, time: 1969-07-20T20:18Z}');
console.log(JSON.stringify(value));
```
</div>

<div class="tabpane Python" markdown="1">
Not currently supported. See [ion-python#107](https://github.com/amzn/ion-python/issues/107).
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

<div class="tabpane C-sharp" markdown="1">
The following example illustrates the use of `IIonReader` with numeric values:
```c#
using IonDotnet;
using IonDotnet.Builders;
using System;
using System.Diagnostics;
using System.Numerics;

class ReadNumericValues
{
    static void Main(string[] args)
    {
        string numberList = "1.23456 1.2345e6 123456 12345678901234567890";

        BigDecimal first = BigDecimal.Parse("1.23456");
        double second = 1.2345e6;
        BigInteger third = BigInteger.Parse("123456");
        BigInteger fourth = BigInteger.Parse("12345678901234567890");

        using IIonReader reader = IonReaderBuilder.Build(numberList);
        Debug.Assert(reader.MoveNext() == IonType.Decimal);
        Debug.Assert(first == reader.DecimalValue());
        Debug.Assert(first.ToDecimal() == reader.DecimalValue().ToDecimal());

        Debug.Assert(reader.MoveNext() == IonType.Float);
        Debug.Assert(Math.Abs(second - reader.DoubleValue()) <= 1e-9);

        Debug.Assert(reader.MoveNext() == IonType.Int);
        Debug.Assert(third.Equals(reader.BigIntegerValue()));
        Debug.Assert(123456 == reader.LongValue());
        Debug.Assert(123456 == reader.IntValue());

        Debug.Assert(reader.MoveNext() == IonType.Int);
        Debug.Assert(fourth.Equals(reader.BigIntegerValue()));
    }
}
```
</div>

<div class="tabpane Go" markdown="1">

A reader can have various types of numeric values:
  - Int32
  - Int64
  - Uint64
  - BigInt
  - Float
  - Decimal

The following example illustrates how to read different numeric values in a reader:
```Go
package main

import (
	"fmt"
	"math/big"

	"github.com/amzn/ion-go/ion"
)

func main() {
	int32Value := 2147483646
	var int64Value int64 = 9223372036854775807
	floatValue := 123.4
	bigIntValue := new(big.Int).Neg(new(big.Int).SetUint64(18446744073709551615))
	decimalValue := ion.MustParseDecimal("123.4d-2")

	reader := ion.NewReaderString("[2147483646, 9223372036854775807,  1.234e2, -18446744073709551615, 1.234]")
	reader.Next()
	if err := reader.StepIn(); err != nil {
		panic(err)
	}

	for reader.Next() {
		switch reader.Type() {
		case ion.IntType:
			intSize, err := reader.IntSize()
			if err != nil {
				panic(err)
			}

			switch intSize {
			case ion.Int32:
				val, err := reader.IntValue()
				if err != nil {
					panic(err)
				}
				if int32Value != val {
					fmt.Println("Problem with Int32 value equivalency")
				}
			case ion.Int64:
				val, err := reader.Int64Value()
				if err != nil {
					panic(err)
				}
				if int64Value != val {
					fmt.Println("Problem with Int64 value equivalency")
				}
			case ion.BigInt:
				val, err := reader.BigIntValue()
				if err != nil {
					panic(err)
				}
				if bigIntValue.Cmp(val) != 0 {
					fmt.Println("Problem with big.Int value equivalency")
				}
			}

		case ion.FloatType:
			val, err := reader.FloatValue()
			if err != nil {
				panic(err)
			}
			if floatValue != val {
				fmt.Println("Problem with float value equivalency")
			}

		case ion.DecimalType:
			val, err := reader.DecimalValue()
			if err != nil {
				panic(err)
			}
			if !decimalValue.Equal(val) {
				fmt.Println("Problem with decimal value equivalency")
			}
		}
	}
	if err := reader.StepOut(); err != nil {
		panic(err)
	}
}
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
    String numberList = "1.23456 1.2345e6 123456 12345678901234567890";

    // expected values
    BigDecimal first = new BigDecimal("1.23456");
    double second = 1.2345e6;
    BigInteger third = new BigInteger("123456");
    BigInteger fourth = new BigInteger("12345678901234567890");

    IonReader reader = IonReaderBuilder.standard().build(numberList);

    assertEquals(IonType.DECIMAL, reader.next());
    assertEquals(first, reader.bigDecimalValue());
    assertEquals(first.doubleValue(), reader.doubleValue(), 1e-9);

    assertEquals(IonType.FLOAT, reader.next());
    assertEquals(second, reader.doubleValue(), 1e-9);

    assertEquals(IonType.INT, reader.next());
    assertEquals(third, reader.bigIntegerValue());
    assertEquals(third.longValue(), reader.longValue());
    assertEquals(third.intValue(), reader.intValue());

    assertEquals(IonType.INT, reader.next());
    assertEquals(fourth, reader.bigIntegerValue());
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

<div class="tabpane Python" markdown="1">
Use of separate APIs to read different numeric types is not necessary in Python. Via both
simpleion and the event-based API, Ion int will be read as Python `int`, Ion decimal will be
read as Python `Decimal`, and Ion float will be read as Python `float`. When necessary, these
values can be differentiated via introspection.

#### Using simpleion

```python
from decimal import Decimal
from amazon.ion import simpleion

data = u'1.23456 1.2345e6 123456 12345678901234567890'
values = simpleion.loads(data, single_value=False)
assert isinstance(values[0], Decimal)
assert isinstance(values[1], float)
assert isinstance(values[2], int)
assert isinstance(values[3], int)
```

When re-written using `dump/dumps`, these values will retain their original Ion types. To
force a particular type to be written, or to add annotation(s), use the `from_value` method
provided by all [simple_types](https://ion-python.readthedocs.io/en/latest/amazon.ion.html#module-amazon.ion.simple_types)
implementations. For example:

```python
from amazon.ion import simpleion
from amazon.ion.core import IonType
from amazon.ion.simple_types import IonPyFloat

value = IonPyFloat.from_value(IonType.FLOAT, 123, (u'abc',))
data = simpleion.dumps(value, binary=False)
print(data)
```

Result: `$ion_1_0 abc::123.0e0`

#### Using events

```python
from decimal import Decimal
from io import BytesIO
from amazon.ion.core import IonType
from amazon.ion.reader import blocking_reader, NEXT_EVENT
from amazon.ion.reader_managed import managed_reader
from amazon.ion.reader_text import text_reader

data = BytesIO(b'1.23456 1.2345e6 123456 12345678901234567890')
reader = blocking_reader(managed_reader(text_reader()), data)
event = reader.send(NEXT_EVENT)
assert event.ion_type == IonType.DECIMAL
assert isinstance(event.value, Decimal)
event = reader.send(NEXT_EVENT)
assert event.ion_type == IonType.FLOAT
assert isinstance(event.value, float)
event = reader.send(NEXT_EVENT)
assert event.ion_type == IonType.INT
assert isinstance(event.value, int)
event = reader.send(NEXT_EVENT)
assert event.ion_type == IonType.INT
assert isinstance(event.value, int)
```

When re-written, these values will retain their original Ion types. To add annotation(s), construct
an [IonEvent](https://ion-python.readthedocs.io/en/latest/amazon.ion.html#amazon.ion.core.IonEvent)
accordingly.

```python
from io import BytesIO
from amazon.ion.core import IonEvent, IonEventType, IonType, ION_STREAM_END_EVENT
from amazon.ion.writer import blocking_writer
from amazon.ion.writer_text import text_writer

event = IonEvent(IonEventType.SCALAR, IonType.FLOAT, annotations=(u'abc',), value=123.0)
data = BytesIO()
writer = blocking_writer(text_writer(), data)
writer.send(event)
writer.send(ION_STREAM_END_EVENT)
print(data.getvalue().decode(u'utf-8'))
```

Result: `abc::123.0e0`
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
   items: ["thing1", "thing2"]
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

<div class="tabpane C-sharp" markdown="1">
```c#
using IonDotnet;
using IonDotnet.Builders;
using System;
using System.Collections.Generic;

class SparseReads
{
    static void Main(string[] args)
    {
        byte[] bytes = {
            0xe0, 0x01, 0x00, 0xea,
            0xee, 0xa5, 0x81, 0x83, 0xde, 0xa1, 0x87, 0xbe, 0x9e, 0x83, 0x66, 0x6f, 0x6f, 0x88,
            0x71, 0x75, 0x61, 0x6e, 0x74, 0x69, 0x74, 0x79, 0x83, 0x62, 0x61, 0x72, 0x82, 0x69,
            0x64, 0x83, 0x62, 0x61, 0x7a, 0x85, 0x69, 0x74, 0x65, 0x6d, 0x73, 0xe6, 0x81, 0x8a,
            0xd3, 0x8b, 0x21, 0x01, 0xe9, 0x81, 0x8c, 0xd6, 0x84, 0x81, 0x78, 0x8d, 0x21, 0x07,
            0xee, 0x95, 0x81, 0x8e, 0xde, 0x91, 0x8f, 0xbe, 0x8e, 0x86, 0x74, 0x68, 0x69, 0x6e,
            0x67, 0x31, 0x86, 0x74, 0x68, 0x69, 0x6e, 0x67, 0x32, 0xe6, 0x81, 0x8a, 0xd3, 0x8b,
            0x21, 0x13, 0xe9, 0x81, 0x8c, 0xd6, 0x84, 0x81, 0x79, 0x8d, 0x21, 0x08 };

        using IIonReader reader = IonReaderBuilder.Build(bytes);
        int sum = 0;
        IonType type;
        while ((type = reader.MoveNext()) != IonType.None)
        {
            if (type == IonType.Struct && reader.HasAnnotation("foo"))
            {
                reader.StepIn();
                while ((type = reader.MoveNext()) != IonType.None)
                {
                    if (reader.CurrentFieldName.Equals("quantity"))
                    {
                        sum += reader.IntValue();
                        break;
                    }
                }
                reader.StepOut();
            }
        }
        Console.WriteLine("sum: " + sum);
    }
}
```
</div>

<div class="tabpane Go" markdown="1">

```Go
package main

import (
	"fmt"
	"github.com/amzn/ion-go/ion"
)

func main() {
	bytes := []byte{0xe0, 0x01, 0x00, 0xea,
		0xee, 0xa5, 0x81, 0x83, 0xde, 0xa1, 0x87, 0xbe, 0x9e, 0x83, 0x66, 0x6f, 0x6f, 0x88,
		0x71, 0x75, 0x61, 0x6e, 0x74, 0x69, 0x74, 0x79, 0x83, 0x62, 0x61, 0x72, 0x82, 0x69,
		0x64, 0x83, 0x62, 0x61, 0x7a, 0x85, 0x69, 0x74, 0x65, 0x6d, 0x73, 0xe6, 0x81, 0x8a,
		0xd3, 0x8b, 0x21, 0x01, 0xe9, 0x81, 0x8c, 0xd6, 0x84, 0x81, 0x78, 0x8d, 0x21, 0x07,
		0xee, 0x95, 0x81, 0x8e, 0xde, 0x91, 0x8f, 0xbe, 0x8e, 0x86, 0x74, 0x68, 0x69, 0x6e,
		0x67, 0x31, 0x86, 0x74, 0x68, 0x69, 0x6e, 0x67, 0x32, 0xe6, 0x81, 0x8a, 0xd3, 0x8b,
		0x21, 0x13, 0xe9, 0x81, 0x8c, 0xd6, 0x84, 0x81, 0x79, 0x8d, 0x21, 0x08}
	reader := ion.NewReaderBytes(bytes)
	sum := 0

	for reader.Next() {
		if reader.Type() == ion.StructType && hasFooAnnotation(reader.Annotations()) {
			if err := reader.StepIn(); err != nil {
				panic(err)
			}
			for reader.Next() {
				if *reader.FieldName() == "quantity" {
					quantity, _ := reader.IntValue()
					sum += quantity
					break
				}
			}
			if err := reader.StepOut(); err != nil {
				panic(err)
			}
		}
	}

	fmt.Println(sum)
}

func hasFooAnnotation(annotations []string) bool {
	for _, an := range annotations {
		if an == "foo" {
			return true
		}
	}
	return false
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

<div class="tabpane Python" markdown="1">
#### Using simpleion
`load/loads` always fully materializes the entire stream. Hence, a sparse read that leverages the
efficiencies of binary Ion is not possible via this API. With that in mind, it is possible to
sparsely access the fully-materialized values.

```python
from amazon.ion import simpleion

# The binary Ion equivalent of the above data:
data = b'\xe0\x01\x00\xea' \
    b'\xee\xa5\x81\x83\xde\xa1\x87\xbe\x9e\x83foo\x88quantity\x83' \
    b'bar\x82id\x83baz\x85items\xe7\x81\x8a\xde\x83\x8b!\x01\xea' \
    b'\x81\x8c\xde\x86\x84\x81x\x8d!\x07\xee\x95\x81\x8e\xde\x91' \
    b'\x8f\xbe\x8e\x86thing1\x86thing2\xe7\x81\x8a\xde\x83\x8b!' \
    b'\x13\xea\x81\x8c\xde\x86\x84\x81y\x8d!\x08'
values = simpleion.loads(data, single_value=False)
sum = 0
for value in values:
    if u'foo' == value.ion_annotations[0].text:
        sum += value[u'quantity']
```

#### Using events
Unlike `load/loads`, the event-based API does not fully materialize the entire stream and therefore
may be used for efficient sparse reads over binary Ion data.

```python
from io import BytesIO
from amazon.ion.core import IonEventType, IonType, ION_STREAM_END_EVENT
from amazon.ion.reader import blocking_reader, NEXT_EVENT, SKIP_EVENT
from amazon.ion.reader_binary import binary_reader
from amazon.ion.reader_managed import managed_reader

# The binary Ion equivalent of the above data:
data = BytesIO(b'\xe0\x01\x00\xea' \
    b'\xee\xa5\x81\x83\xde\xa1\x87\xbe\x9e\x83foo\x88quantity\x83' \
    b'bar\x82id\x83baz\x85items\xe7\x81\x8a\xde\x83\x8b!\x01\xea' \
    b'\x81\x8c\xde\x86\x84\x81x\x8d!\x07\xee\x95\x81\x8e\xde\x91' \
    b'\x8f\xbe\x8e\x86thing1\x86thing2\xe7\x81\x8a\xde\x83\x8b!' \
    b'\x13\xea\x81\x8c\xde\x86\x84\x81y\x8d!\x08')
reader = blocking_reader(managed_reader(binary_reader()), data)
sum = 0
event = reader.send(NEXT_EVENT)
while event != ION_STREAM_END_EVENT:
    assert event.event_type == IonEventType.CONTAINER_START
    assert event.ion_type == IonType.STRUCT
    if u'foo' == event.annotations[0].text:
        # Step into the struct.
        event = reader.send(NEXT_EVENT)
        while event.event_type != IonEventType.CONTAINER_END:
            if u'quantity' == event.field_name.text:
                sum += event.value
            event = reader.send(NEXT_EVENT)
        # Step out of the struct.
        event = reader.send(NEXT_EVENT)
    else:
        # Skip over the struct without parsing its values.
        event = reader.send(SKIP_EVENT)
        assert event.event_type == IonEventType.CONTAINER_END
        # Position the reader at the start of the next value.
        event = reader.send(NEXT_EVENT)
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

<div class="tabpane C-sharp" markdown="1">
```c#
using IonDotnet;
using IonDotnet.Builders;
using System;
using System.IO;

class CsvToIon
{
    public static void Main(string[] args)
    {
        using TextWriter tw = new StringWriter();
        using IIonWriter writer = IonTextWriterBuilder.Build(tw);

        using StreamReader reader = new StreamReader("test.csv");
        reader.ReadLine();    // skip the header row
        while (!reader.EndOfStream)
        {
            string[] values = reader.ReadLine().Split(",");
            writer.StepIn(IonType.Struct);
            writer.SetFieldName("id");
            writer.WriteInt(long.Parse(values[0]));
            writer.SetFieldName("type");
            writer.WriteString(values[1]);
            writer.SetFieldName("state");
            writer.WriteBool(bool.Parse(values[2]));
            writer.StepOut();
        }
        writer.Finish();
        Console.WriteLine(tw.ToString());
    }
}
```
</div>

<div class="tabpane Go" markdown="1">

```Go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	
	"github.com/amzn/ion-go/ion"
)

func main() {
	file, er := os.Open("c://values.cvs")
	if er != nil {
		panic(er)
	}
	defer file.Close()

	buf := strings.Builder{}
	writer := ion.NewTextWriter(&buf)

	scanner := bufio.NewScanner(file)
	scanner.Scan() // to skip the first row (header line)
	for scanner.Scan() {
		data := strings.Split(scanner.Text(), ",")
		writer.BeginStruct()
		writer.FieldName("id")
		val, _ := strconv.Atoi(data[0])
		writer.WriteInt(int64(val))

		writer.FieldName("type")
		writer.WriteString(data[1])
		b1, _ := strconv.ParseBool(data[2])

		writer.FieldName("state")
		writer.WriteBool(b1)
		writer.EndStruct()
	}
	writer.Finish()

	fmt.Println(buf.String())
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

<div class="tabpane Python" markdown="1">
The CSV conversion method below is used for both APIs.

```python
from io import StringIO

data = StringIO(
    u'''id,type,state
    1,foo,false
    2,bar,true
    3,baz,true'''
)
lines = data.readlines()[1:]

def split_line(line):
    tokens = line.split(u',')
    mapping = (
        (u'id', int(tokens[0])),
        (u'type', tokens[1]),
        (u'state', u'true' == tokens[2].strip())
    )
    return dict(mapping)

structs = [split_line(line) for line in lines]
```

#### Using simpleion
```python
from amazon.ion import simpleion

ion = simpleion.dumps(structs, sequence_as_stream=True)
```

#### Using events
```python
from io import BytesIO
from amazon.ion.core import IonEventType, IonType, IonEvent, ION_STREAM_END_EVENT
from amazon.ion.writer import blocking_writer
from amazon.ion.writer_binary import binary_writer

ion = BytesIO()
writer = blocking_writer(binary_writer(), ion)
for struct in structs:
    writer.send(IonEvent(IonEventType.CONTAINER_START, IonType.STRUCT))
    writer.send(IonEvent(IonEventType.SCALAR, IonType.INT, field_name=u'id', value=struct[u'id']))
    writer.send(IonEvent(IonEventType.SCALAR, IonType.STRING, field_name=u'type', value=struct[u'type']))
    writer.send(IonEvent(IonEventType.SCALAR, IonType.BOOL, field_name=u'state', value=struct[u'state']))
    writer.send(IonEvent(IonEventType.CONTAINER_END))

writer.send(ION_STREAM_END_EVENT)
```
</div>


### Using a local symbol table

Local symbol tables are managed internally by Ion readers and writers. No
application configuration is required to tell Ion readers or writers that local
symbol tables should be used.


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

<div class="tabpane C-sharp" markdown="1">
Not currently supported.
</div>

<div class="tabpane Go" markdown="1">
Not currently supported.
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

<div class="tabpane Python" markdown="1">
Shared symbol tables may be constructed via the
[shared_symbol_table](https://ion-python.readthedocs.io/en/latest/amazon.ion.html#amazon.ion.symbols.shared_symbol_table)
function.

```python
from amazon.ion.symbols import shared_symbol_table

table = shared_symbol_table(u'test.csv.columns', 1, (u'id', u'type', u'state'))
```

Recall the `structs` sequence from the previous Python example:

```python
from io import StringIO

data = StringIO(
    u'''id,type,state
    1,foo,false
    2,bar,true
    3,baz,true'''
)
lines = data.readlines()[1:]

def split_line(line):
    tokens = line.split(u',')
    mapping = (
        (u'id', int(tokens[0])),
        (u'type', tokens[1]),
        (u'state', u'true' == tokens[2].strip())
    )
    return dict(mapping)

structs = [split_line(line) for line in lines]
```

This sequence may be written with a shared symbol table as follows.

#### Using simpleion

`dump/dumps` accept a sequence of shared symbol tables via the `imports` parameter.

```python
from amazon.ion import simpleion

data = simpleion.dumps(structs, imports=(table,), sequence_as_stream=True)
```

#### Using events
The `binary_writer` coroutine accepts a sequence of shared symbol tables via the `imports`
parameter. Once the writer coroutine is constructed, the events are written in the same
way as in the example in the previous section.

```python
from io import BytesIO
from amazon.ion.writer import blocking_writer
from amazon.ion.writer_binary import binary_writer

data = BytesIO()
writer = blocking_writer(binary_writer(imports=(table,)), data)
```
</div>


#### Reading

Because the value stream written using the shared symbol table does not contain
the symbol mappings, a reader of the stream needs to access the shared symbol
table using a catalog.

<script>writeTabs()</script>
<div class="tabpane C" markdown="1">
Example not yet implemented.
</div>

<div class="tabpane C-sharp" markdown="1">
Not currently supported.
</div>

<div class="tabpane Go" markdown="1">
Not currently supported.
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

<div class="tabpane Python" markdown="1">
Instances of [SymbolTableCatalog](https://ion-python.readthedocs.io/en/latest/amazon.ion.html#amazon.ion.symbols.SymbolTableCatalog)
are used by readers to resolve shared symbol table imports encountered in Ion data. Any
shared symbol tables that are expected to be encountered in the stream should be registered
with the `SymbolTableCatalog` that is provided to the reader.

```python
from amazon.ion.symbols import shared_symbol_table, SymbolTableCatalog

table = shared_symbol_table(u'test.csv.columns', 1, (u'id', u'type', u'state'))
catalog = SymbolTableCatalog()
catalog.register(table)
```

#### Using simpleion
`load/loads` accept a catalog via the `catalog` parameter.

```python
from amazon.ion import simpleion

# The Ion representation of the CSV data containing a shared symbol table import:
data = b'\xe0\x01\x00\xea' \
    b'\xee\xa4\x81\x83\xde\xa0\x86\xbe\x9b\xde\x99\x84\x8e\x90' \
    b'test.csv.columns\x85!\x01\x88!\x03\x87\xb0\xde\x8a\x8a!' \
    b'\x01\x8b\x83foo\x8c\x10\xde\x8a\x8a!\x02\x8b\x83bar\x8c' \
    b'\x11\xde\x8a\x8a!\x03\x8b\x83baz\x8c\x11'
values = simpleion.loads(data, catalog=catalog, single_value=False)
assert values[2][u'id'] == 3
```

#### Using events
The `managed_reader` coroutine accepts a catalog via the `catalog` parameter.

```python
from io import BytesIO
from amazon.ion.core import IonEventType, IonType, ION_STREAM_END_EVENT
from amazon.ion.reader import blocking_reader, NEXT_EVENT, SKIP_EVENT
from amazon.ion.reader_binary import binary_reader
from amazon.ion.reader_managed import managed_reader

# The Ion representation of the CSV data containing a shared symbol table import:
data = BytesIO(b'\xe0\x01\x00\xea' \
    b'\xee\xa4\x81\x83\xde\xa0\x86\xbe\x9b\xde\x99\x84\x8e\x90' \
    b'test.csv.columns\x85!\x01\x88!\x03\x87\xb0\xde\x8a\x8a!' \
    b'\x01\x8b\x83foo\x8c\x10\xde\x8a\x8a!\x02\x8b\x83bar\x8c' \
    b'\x11\xde\x8a\x8a!\x03\x8b\x83baz\x8c\x11')
reader = blocking_reader(managed_reader(binary_reader(), catalog=catalog), data)
# Position the reader at the first struct.
reader.send(NEXT_EVENT)
# Skip over the struct.
reader.send(SKIP_EVENT)
# Position the reader at the second struct.
reader.send(NEXT_EVENT)
# Skip over the struct.
reader.send(SKIP_EVENT)
# Position the reader at the third struct.
event = reader.send(NEXT_EVENT)
assert event.ion_type == IonType.STRUCT
# Step into the struct
event = reader.send(NEXT_EVENT)
assert u'id' == event.field_name.text
assert 3 == event.value
```
</div>


## See also

* [The ion-c API Documentation][14]
* The ion-dotnet API Documentation
* [The ion-go API Documentation][24]
* [The ion-java API Documentation][2]
* [The ion-js API Documentation][18]
* [The ion-python API Documentation][21]

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
[21]: https://ion-python.readthedocs.io/en/latest/index.html
[22]: https://github.com/amzn/ion-go/blob/master/ion/reader.go
[23]: https://github.com/amzn/ion-go/blob/master/ion/writer.go
[24]: https://pkg.go.dev/github.com/amzn/ion-go/ion
