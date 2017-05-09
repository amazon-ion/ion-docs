---
title: Amazon Ion Cookbook
---

# {{ page.title }}

This cookbook provides code samples for some simple Amazon Ion use cases.

## How to use this cookbook

For readability, all examples of Ion data used in this cookbook will be
represented in the text Ion format, even examples intended to represent binary
Ion data. To make clear which format is represented by the example, each Ion
snippet will begin with a comment that denotes either `TEXT` or `BINARY`.

For brevity, this cookbook will make use of methods and global variables.
Variables declared inside methods are in scope only within that method.
Variables declared outside of methods, and methods themselves, are in scope
until the next horizontal rule (such as the one that follows this section).
Within the same scope, variables with the same name and type or methods with the
same signature should be considered interchangeable.

In some cases, the examples herein depend on code external to Ion (e.g.
constructing input streams to read files), which is out of scope for this
cookbook. Code such as this will be replaced by a method with an empty (but
implied) implementation.

### Java

Import statements for classes internal to the Ion library or to `java.lang`
are omitted. Other external classes will either be first referenced by their
fully-qualified names, or will be preceded by an import statement. Import
statements have global scope.

* * *

## Getting started

### Java

[`IonSystem`][3] is the central interface to ion-java. Generally, a single
`IonSystem` instance should be constructed and used throughout the
application.

Below, an `IonSystem` instance that will be reused throughout this cookbook 
will be constructed.

```java
    static final IonSystem SYSTEM = IonSystemBuilder.standard().build();
```

## Reading and Writing Ion Data

### Java

Implementations of the [`IonReader`][4] and [`IonWriter`][5] interfaces are
responsible for reading and writing Ion data in both its text and binary forms.

`IonReader`s and `IonWriter`s may be constructed through the `IonSystem`.

Consider the following text Ion data, which has been materialized as a Java
String.

```java
    String helloWorld = "{ hello:\"world\" }";
```

An `IonReader` for this data may be constructed as follows.

```java
    IonReader reader = SYSTEM.newReader(helloWorld);
```

Reading the data requires leveraging the `IonReader`'s APIs.

```java
    void readHelloWorld() {
        reader.next();                            // position the reader at the first value, a struct
        reader.stepIn();                          // step in to the struct
        reader.next();                            // position the reader at the first value in the struct
        String hello = reader.getFieldName();     // retrieve the current value's field name
        String world = reader.stringValue();      // retrieve the current value's String value
        reader.stepOut();                         // step out of the struct
        System.out.println(hello + " " + world);  // prints "hello world"
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

A text `IonWriter` can be constructed as follows.

```java
    IonWriter writer = SYSTEM.newTextWriter(out);
```

Similarly, a binary `IonWriter` can be constructed as follows.

```java
    IonWriter writer = SYSTEM.newBinaryWriter(out);
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
        try (IonWriter textWriter = SYSTEM.newTextWriter(out)) {
            writeHelloWorld(textWriter);
        }
    }
```

Regardless of whether `out` was written with text or binary Ion data, it may
now be read using an `IonReader`. `IonSystem.newReader()` will return an
instance of an `IonReader` implementation capable of reading Ion data in the
given format.

```java    
    import java.io.ByteArrayInputStream;
    import java.io.InputStream;

    void readHelloWorldAgain() {
        byte[] data = out.toByteArray();                    // may contain either text or binary Ion data
        InputStream in = new ByteArrayInputStream(data);
        reader = SYSTEM.newReader(in);
        readHelloWorld();                                   // prints "hello world"
    }
```

## Formatting Ion text output

### Pretty-printing

To aid human-readability, Ion text supports "pretty" output. Consider the
following un-formatted text Ion:

```
    { level1:{ level2:{ level3:"foo" }, x:2 }, y:[a,b,c] }
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

#### Java

Ion data can be pretty-printed by configuring an IonWriter via an [`IonTextWriterBuilder`][6]:

```java

    String unformatted = "{ level1:{ level2:{ level3:\"foo\" }, x:2 }, y:[a,b,c] }";

    void rewrite(String textIon, IonWriter writer) throws IOException {
        IonReader reader = SYSTEM.newReader(textIon);
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
    { data:annot::{ foo:null.string, bar:(2 + 2) }, time:1969-07-20T20:18Z }
```

Down-converting into JSON results in output similar to the following:

```
    {
      "data":{
        "foo":null,
        "bar":[
          2,
          "+",
          2
        ]
      },
      "time":"1969-07-20T20:18Z"
    }
```

For JSON compatibility, all field names were converted to JSON *string*, the
null `"foo"` field lost its type information, `"bar"` was converted into a
JSON *list* (losing its S-expression semantics), and `"time"` was represented
as a JSON *string*.

#### Java

Using the `rewrite` method from the previous example, the data can be
down-converted for JSON compatibility.

```java

    String textIon = "{ data:annot::{ foo:null.string, bar:(2 + 2) }, time:1969-07-20T20:18Z }";

    void downconvertToJson() throws IOException {
        StringBuilder stringBuilder = new StringBuilder();
        try (IonWriter jsonWriter = IonTextWriterBuilder.json().withPrettyPrinting().build(stringBuilder)) {
            rewrite(textIon, jsonWriter);
        }
        System.out.println(stringBuilder.toString());
    }
```

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

```
    // TEXT
    {
      "data":{
        "foo":null,
        "bar":[
          2,
          "+",
          2
        ]
      },
      "time":"1969-07-20T20:18Z"
    }
```

Converting this data to Ion (possibly via one of the pretty-printing examples)
results in the following:

```
    {
      data:{
        foo:null,
        bar:[
          2,
          "+",
          2
        ]
      },
      time:"1969-07-20T20:18Z"
    }
```

This is clearly valid Ion, but is no longer valid JSON (because field names
are unquoted). And, notably, it is **not** the same as the original Ion data
that was down-converted to JSON.

### Reading numeric types

Because Ion has richly defined numeric types, there are often multiple possible
representations of a numeric Ion value.

#### Java

Integer values that can fit into a Java `int` may be read as such using
`IonReader.intValue()`, or may be read into a `long` using
`IonReader.longValue()`, or a [`java.math.BigInteger`][12] using
`IonReader.bigIntegerValue()`.

Consider the following Ion list of numeric values, which has been materialized
into a Java String.

```java
    String numberList = "[ 1.23456, 123456, 1.2345e6, ]";
```

The following example illustrates the equivalence of using different
`IonReader` APIs to read the same numeric value.

```java
    import static org.junit.Assert.assertEquals;
    import java.math.BigDecimal;
    import java.math.BigInteger;

    void readNumericTypes() throws IOException {
    
        // expected values
        BigDecimal first = new BigDecimal("1.23456");
        BigInteger second = new BigInteger("123456");
        double third = 1.2345e6;

        IonReader reader = SYSTEM.newReader(numberList);
        reader.next();
        reader.stepIn();
        
        assertEquals(IonType.DECIMAL, reader.next());
        assertEquals(first, reader.bigDecimalValue());
        assertEquals(first.doubleValue(), reader.doubleValue(), 1e-9);
        
        assertEquals(IonType.INT, reader.next());
        assertEquals(second, reader.bigIntegerValue());
        assertEquals(second.longValue(), reader.longValue());
        assertEquals(second.intValue(), reader.intValue());
        
        assertEquals(IonType.FLOAT, reader.next());
        assertEquals(third, reader.doubleValue(), 1e-9);
        
        reader.stepOut();
    }
```

Note that care must be taken to avoid data loss. For example, reading an integer
value too large to fit in a Java `int` using `IonReader.intValue()` will
result in loss.

* * *

## Performing sparse reads

One of the major benefits of binary Ion is the ability to efficiently perform
sparse reads.

Consider the following stream of binary Ion data.

```
    // BINARY
    $ion_1_0
    foo::{
        quantity:1
    }
    bar::{
        name:"x",
        id:7
    }
    baz::{
        items:["thing1", "thing2"]
    }
    foo::{
        quantity:19
    }
    bar::{
        name:"y",
        id:8
    }
    // the stream continues...
```

The following examples simulate an application whose only purpose is to sum the
`quantity` fields of each `foo` struct in the stream. This is achieved by
examining the type annotations of each top-level struct and comparing against
`"foo"`. Because binary Ion is length-prefixed, when the struct's annotation does
not match `"foo"`, the reader can quickly skip to the start of the next value.

### Java

```java
    InputStream getStream() {
        // return an InputStream representation of the above data
    }

    int sumFooQuantities() {
        IonReader reader = SYSTEM.newReader(getStream());
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

* * *

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

#### Java

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
            String[] cells = row.split(",");
            writer.stepIn(IonType.STRUCT);
            writer.setFieldName("id");
            writer.writeInt(Integer.parseInt(cells[0]));
            writer.setFieldName("type");
            writer.writeString(cells[1]);
            writer.setFieldName("state");
            writer.writeBool(Boolean.parseBoolean(cells[2]));
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
        try (IonWriter writer = SYSTEM.newBinaryWriter(output)) {
            convertCsvToIon(writer);
        }
    }
```

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

##### Java

```java
    InputStream getSharedSymbolTableStream() {
        // get an InputStream over the 'test.csv.columns' shared symbol table.
    }
    
    SymbolTable getSharedSymbolTable() {
        IonReader symbolTableReader = SYSTEM.newReader(getSharedSymbolTableStream());
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
        try (IonWriter writer = SYSTEM.newBinaryWriter(output, shared)) {
            convertCsvToIon(writer);
        }
    }
```

Rather than writing a local symbol table that grows with the number of columns,
this technique simply includes a symbol table at the beginning of the stream
that imports the shared symbol table. (Note that, in addition, any symbols
written but not included in the shared symbol table will be declared in the
symbol table that begins the stream.)

#### Reading

Because the value stream written using the shared symbol table does not contain
the symbol mappings, a reader of the stream needs to access the shared symbol
table using a catalog.

##### Java

The [`IonCatalog`][8] interface may be implemented by applications to provide
customized shared symbol table retrieval logic, such as retrieval from an external
source.

ion-java includes an implementation of `IonCatalog` called [`SimpleCatalog`][9],
which stores shared symbol tables in memory and will be used here for
illustration purposes.

Creating `IonReaders` capable of parsing streams written with shared symbol
tables starts with correctly configuring an `IonSystem` instance. Reusing the
`getSharedSymbolTable` method from above, this can be done as follows.

```java
    IonSystem getSystemWithCatalog() {
        SimpleCatalog catalog = new SimpleCatalog();
        catalog.putTable(getSharedSymbolTable());
        return IonSystemBuilder.standard().withCatalog(catalog).build();
    }
```

The resulting `IonSystem` can be used to instantiate `IonReader`s capable of
interpreting the shared symbols encountered in the value stream written in the
previous sub-section.

## See also

  * [The ion-java 1.0 Code Documentation][2] 
  * [The ion-c Code Documentation][14]

<!-- References -->
[1]: https://github.com/amzn/ion-java
[2]: https://www.javadoc.io/doc/software.amazon.ion/ion-java/1.0.0
[3]: https://static.javadoc.io/software.amazon.ion/ion-java/1.0.0/software/amazon/ion/IonSystem.html
[4]: https://static.javadoc.io/software.amazon.ion/ion-java/1.0.0/software/amazon/ion/IonReader.html
[5]: https://static.javadoc.io/software.amazon.ion/ion-java/1.0.0/software/amazon/ion/IonWriter.html
[6]: https://static.javadoc.io/software.amazon.ion/ion-java/1.0.0/software/amazon/ion/system/IonTextWriterBuilder.html
[7]: https://static.javadoc.io/software.amazon.ion/ion-java/1.0.0/software/amazon/ion/SymbolTable.html
[8]: https://static.javadoc.io/software.amazon.ion/ion-java/1.0.0/software/amazon/ion/IonCatalog.html
[9]: https://static.javadoc.io/software.amazon.ion/ion-java/1.0.0/software/amazon/ion/system/SimpleCatalog.html
[10]: https://docs.oracle.com/javase/8/docs/api/java/io/OutputStream.html
[11]: https://docs.oracle.com/javase/8/docs/api/java/io/ByteArrayOutputStream.html
[12]: https://docs.oracle.com/javase/8/docs/api/java/math/BigInteger.html
[13]: https://docs.oracle.com/javase/8/docs/api/java/io/BufferedReader.html
[14]: https://amzn.github.io/ion-c/
