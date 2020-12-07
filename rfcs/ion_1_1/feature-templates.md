# RFC: Ion Templates

* [Summary](#summary)
* [Motivation](#motivation)
* [Changes to the system symbol table](#changes-to-the-system-symbol-table)
* [Ion templates](#ion-templates)
    * [Text encoding](#text-encoding)
    * [Template definitions](#template-definitions)
    * [Template blanks](#template-blanks)
    * [Templates of templates](#templates-of-templates)
* [Legal template invocation sites](#legal-template-invocation-sites)
* [Template invocation parameters](#template-invocation-parameters)
    * [Suppressing template values with `{#0}`](#suppressing-template-values-with-0)
    * [Suppressing trailing template values](#suppressing-trailing-template-values)
    *  [Support for extending containers](#support-for-extending-containers)
        * [Extending a struct](#extending-a-struct)
        * [Extending a list](#extending-a-list)
* [Annotation expansion](#annotation-expansion)
    * [In the template definition](#in-the-template-definition)
    * [At the invocation site](#at-the-invocation-site)
    * [In both the definition and the invocation](#in-both-the-definition-and-the-invocation)
* [Importing templates](#importing-templates)
* [Templates' relationship to symbols](#templates-relationship-to-symbols)
* [Binary encoding](#binary-encoding)
    * [`0xF0`: No-parameter invocations](#0xf0-no-parameter-invocations)
    * [`0xF1`: Single-parameter invocations](#0xf1-single-parameter-invocations)
    * [`0xF2`: Multi-parameter invocations](#0xf2-multi-parameter-invocations)
* [Skip-scanning over templates](#skip-scanning-over-templates)
* [Alternative encodings considered](#alternative-encodings-considered)
    * [Alternative text encodings](#alternative-text-encodings)
    * [Alternative binary encodings](#alternative-binary-encodings)

## Summary

This RFC introduces a new encoding mechanism called _Ion templates_ which generalize Ion 1.0’s concept of 
[symbols](http://amzn.github.io/ion-docs/docs/symbols.html) by:

1. Allowing any valid Ion value to be added to the symbol table, not just strings.
2. Allowing containers stored in the table to have ‘blanks’ in them that can be filled in when the template is referenced.

This will allow applications to elide not only the structure of encoded values (as a traditional schema might), but also the
values themselves.

The changes proposed in this document are part of the larger [Ion 1.1 RFC](ion_1_1.md#rfc-ion-11).

-----

## Motivation

As a self-describing format, Ion is able to encode streams of arbitrary, heterogeneous values with no 
formal schema. Readers of these streams can parse the values therein without relying on any external 
resources (modulo shared symbol tables, where used), inspecting each value as it's encountered to discover its structure.

**Example stream of heterogeneous values**

```js
USD::221.95
2020-06-01T12:03:10+00:00
"Brevity is the soul of wit."
(fn1 p1 (fn2 p2 p3))
null.list
{name: {first: "Albert", last: "Einstein"}, occupation: "Patent Clerk"}
foo
{{SSBhcHBsYXVkIHlvdXIgY3VyaW9zaXR5}}
false
```

In practice, however, it is uncommon for applications to produce truly heterogeneous data. Many Ion streams adhere to a
de-facto schema, with values in the stream closely resembling one another. In such cases, the cost of repeatedly
describing each individual value's structure is a substantial overhead, inflating the size of the encoded data and
requiring additional computation during serialization and deserialization.

**Example stream with a de-facto schema**

```js
{
  title: "Moby Dick",
  author: "Herman Melville",
  index: {
    class: "fiction",
    keywords: ["whaling", "Ishmael", "Ahab", "Queequeg"],
  }
  publication: {
    isbn: "0553213113",
    publisher: "Bantam Classics",
    year: 1981,
  },
  library: {
    name: "New York Public Library",
    branch: "96th Street",
    address: {
      street: "112 E 96th Street",
      city: "New York City",
      state: "NY"
    }
  }
}
{
  title: "Little Women",
  author: "Louisa May Alcott",
  index: {
    class: "fiction",
    keywords: ["March", "sisters", "Meg", "Jo", "Beth", "Amy"],
    sequels: ["Little Men", "Jo's Boys"]
  },
  publication: {
    isbn: "0147514010",
    publisher: "Puffin Books",
    year: 2014,
  },
  library: {
    name: "New York Public Library",
    branch: "Grand Central Library",
    address: {
      street: "135 East 46th Street",
      city: "New York City",
      state: "NY"
    }
  },
}
{
  title: "The Prince",
  author: "Niccolo Machiavelli",
  index: {
    class: "nonfiction",
    keywords: ["politics", "conquer", "Medici", "princedom"],
  },  
  publication: {
    isbn: "0872203166"
    publisher: "Hackett Classics",
    year: 1995,
  },
  library: {
    name: "New York Public Library",
    branch: "96th Street",
    address: {
      street: "112 E 96th Street",
      city: "New York City",
      state: "NY"
    }
  },
}
```

Each of the books described in the above stream is an Ion struct with a nearly identical structure, but significant portions of the encoded output are dedicated to redefining that structure in full for each value. Not only does this inflate the size of the encoded data, it imposes additional overhead to both reading and writing. 

When writing each value in binary Ion, the application must perform symbol table lookups to map the field name to the appropriate symbol ID. Containers nested inside the top level value (like `index` and `publication`, for example) require additional buffering to be performed so their encoded size can be included in their representation's prefix.

When reading, each symbol being read must be mapped back to the corresponding text, no matter how many times it's been processed before. Ion struct fields can appear in any order, so logic is required to dispatch the value of each field to the appropriate handler logic.

In both reading and writing, repetition in the data leads to larger data sizes, which in turn causes more I/O operations to be required when loading, storing, or transmitting the stream.

-----

## Changes to the system symbol table

The changes in this RFC require 2 new symbols to be added to the system symbol table:

1. `templates` (used in symbol tables to define a list of templates)
2. `max_template_id` (used in shared symbol tables to cap the number of templates imported from a given table)

The complete system symbol table for Ion 1.1 can be found [here](ion_1_1.md#system-symbol-table).

## Ion Templates

### Text encoding

The text syntax for template definitions and invocations is described in the following sections.

While this RFC includes a proposed syntax for defining and invoking templates in Ion text, templates are primarily intended to
benefit the more performance-oriented binary format. As with the text encoding syntax for symbols (e.g. `$ion_symbol_table`, `$14`, etc), 
a text encoding syntax for templates is specified to allow for human-readable illustrations of system behavior and to maintain
isomorphism between the binary and text encodings. It is expected that applications writing Ion text will write out the expanded
form of any templates because the Ion text format prioritizes readability over compactness.

To read about the binary representation, see the [Binary encoding](#binary-encoding) section.

### Template definitions

Templates are defined using a new `templates` field in 
[Ion 1.0's existing symbol table construct](http://amzn.github.io/ion-docs/docs/symbols.html#processing-of-symbol-tables). (This is
explored in greater detail in the section [Importing Templates](#importing-templates).)

The `templates` field is a list of template definitions. A template definition is comprised of a single Ion value of any type
and that value's annotations, if any.

In this example, the local symbol table  defines a template whose value is a highly-precise decimal approximation of the mathematical 
constant Pi:

```js
$ion_symbol_table::{
  templates: [
    3.1415926535897932384626433832795028842 // Template #1: Pi
  ]
}
```

Defining a template assigns it a template identifier (TID) starting with 1. Template ID 0 is reserved, 
as explained in the section [Template Blanks](#template-blanks) below.

With this template defined, we may now refer to it downstream by its TID. The text notation for invoking a template is:
```js
{#ID}
```
where `ID` is the identifier of the desired template.

Here is a complete example, which shows both the template definition and several invocations:
```js
$ion_1_1
$ion_symbol_table::{
  templates: [
    3.1415926535897932384626433832795028842
  ]
}
{#1}
{#1}
{#1}
{#1}
{#1}
```

This is equivalent to the following stream that does not use templates:
```js
$ion_1_1
3.1415926535897932384626433832795028842
3.1415926535897932384626433832795028842
3.1415926535897932384626433832795028842
3.1415926535897932384626433832795028842
3.1415926535897932384626433832795028842
```

As this illustrates, templates are convenient for cheaply referring to large, frequently repeated values. In binary Ion, the 
non-templated stream is 99 bytes long and requires readers to parse and validate PI five times. In contrast, the templated 
stream is only 37 bytes (a savings of 62.62%), and a reader would only have to parse and validate PI once.

### Template blanks

Definitions may partially specify composite values by leaving 'blanks' in the provided template. The text notation for a template 
blank is an invocation of template ID `0`, which is reserved for this purpose:

```js
{#0}
```

In this example, we want define a template that expands to a struct holding vehicle information, like this:

```js
{ 
  make: "Toyota",
  model: "Camry",
  year: 2017,
  frame: "sedan",
  numberOfWheels: 4,
  transmission: "automatic",
  hasAirbags: true
}
```

To achieve this, we need to do two things:

1. Add all of the struct's field names to the symbol table.
2. Define a new template that uses those field names and which leaves the associated field values blank (`{#0}`).

```js
$ion_1_1
$ion_symbol_table::{
  // Symbol IDs $0-$9 are defined in the Ion 1.0 spec:
  //     http://amzn.github.io/ion-docs/docs/symbols.html#system-symbols
  // Symbol ID $10 is the string "templates", and is added by this RFC.
  // Symbol ID $11 is the string "max_template_id" and is added by this RFC.
  
  // Define symbols for each of the field names:

  symbols : [
    "make",           // $12
    "model",          // $13
    "year",           // $14
    "frame",          // $15
    "numberOfWheels", // $16
    "transmission",   // $17
    "airbags",        // $18
  ],

  // Define a template for our vehicle information struct:

  templates : [
    { // This struct and its contents comprise template ID 1
      $12: {#0}, // make
      $13: {#0}, // model
      $14: {#0}, // year
      $15: {#0}, // frame
      $16: {#0}, // numberOfWheels
      $17: {#0}, // transmission
      $18: {#0}, // airbags
    }
  ]
}
```

Now that template #1 has been defined, we can invoke it downstream and provide a list of values to fill in those blanks using this notation:

```js
{#ID param1 param2 param3 ... paramN}
```

Here are some concrete examples:

```js
{#1 "Toyota" "Camry" 2017 "sedan" 4 "automatic" true}
{#1 "Toyota" "Corolla" 2011 "sedan" 4 "automatic" true}
{#1 "Toyota" "Avalon" 2018 "sedan" 4 "automatic" true}
```

During expansion, the reader will apply each invocation parameter to the blanks it encounters as it traverses the template definition.

```js
{#1 "Toyota" "Camry" 2017 "sedan" 4 "automatic" true}
//     ^        ^     ^      ^    ^     ^         ^-- airbags
//     |        |     |      |    |     +------------ transmission
//     |        |     |      |    +------------------ numberOfWheels
//     |        |     |      +----------------------- frame
//     |        |     +------------------------------ year
//     |        +------------------------------------ model
//     +--------------------------------------------- make
``` 

A reader processing the above stream would interpret it as:
```js
{ 
  make: "Toyota",
  model: "Camry",
  year: 2017,
  frame: "sedan",
  numberOfWheels: 4,
  transmission: "automatic",
  hasAirbags: true
}
{ 
  make: "Toyota",
  model: "Corolla",
  year: 2011,
  frame: "sedan",
  numberOfWheels: 4,
  transmission: "automatic",
  hasAirbags: true
}
{ 
  make: "Toyota",
  model: "Avalon",
  year: 2018,
  frame: "sedan",
  numberOfWheels: 4,
  transmission: "automatic",
  hasAirbags: true
}
```

Importantly, the data in the stream is still self-describing. Each value still declares its Ion type and its
encoded size while taking substantially fewer bytes to encode.

### Templates of templates

Using templates to encode the structure of containers eliminates quite a bit of repetition. However, our example
stream (reproduced below) still contains a number of recurring values:

```js
{#1 "Toyota" "Camry" 2017 "sedan" 4 "automatic" true}
{#1 "Toyota" "Corolla" 2011 "sedan" 4 "automatic" true}
{#1 "Toyota" "Avalon" 2018 "sedan" 4 "automatic" true}
```

We can leverage templates again to go a step further, by defining a new template whose definition invokes template #1.
Template definitions can only include invocations of templates with a *lower* ID. That is, templates that have already
been defined.

Templates *cannot* include invocations for their own ID or higher (not-yet-defined) IDs. This eliminates the need for 
cycle detection and guarantees that template expansion will always terminate.

```js
$ion_symbol_table::{
  imports: $ion_symbol_table, // The new templates below are appended to the existing table
  templates: [
    // Template #2 invokes template #1, passing fixed values for the frame, numberOfWheels,
    // transmission, and airbags fields.
    {#1 {#0} {#0} {#0} "sedan" 4 "automatic" true}
  ]
}
```

Downstream, we can now represent most modern 4-door sedans using invocations of template #2:

```js
{#2 "Toyota" "Camry" 2017}
{#2 "Toyota" "Corolla" 2011}
{#2 "Toyota" "Avalon" 2018}
```

Since there are likely to be relatively few car companies in the data, you could choose to 
define a template for Toyota sedans:

```js
$ion_symbol_table::{
  imports: $ion_symbol_table, // The new templates below are appended to the existing table
  templates: [
    // Template #3 invokes template #2
    {#2 "Toyota" {#0} {#0}}
  ]
}
```

Now invocations only need to specify the model and year:

```js
{#3 "Camry" 2017}
{#3 "Corolla" 2011}
{#3 "Avalon" 2018}
```

When interpreting the stream, the reader must recursively expand any template invocations encountered. In this example,
that means that expanding `{#3}` will involve expanding `{#2}`, which will in turn involve expanding `{#1}`.

 Thus, a reader processing the above stream would interpret it as:
```js
{ 
  make: "Toyota",
  model: "Camry",
  year: 2017,
  frame: "sedan",
  numberOfWheels: 4,
  transmission: "automatic",
  hasAirbags: true
}
{ 
  make: "Toyota",
  model: "Corolla",
  year: 2011,
  frame: "sedan",
  numberOfWheels: 4,
  transmission: "automatic",
  hasAirbags: true
}
{ 
  make: "Toyota",
  model: "Avalon",
  year: 2018,
  frame: "sedan",
  numberOfWheels: 4,
  transmission: "automatic",
  hasAirbags: true
}
```

Vehicles that don't conform to template #2 or #3 can still be encoded using template #1:

```js
{#1 "Ford" "F150" 2006 "pickup" 2 "manual" true}
```

and new templates can be defined dynamically mid-stream using the symbol table append syntax shown 
in examples above.

-----

## Legal template invocation sites

While all of the examples above show template invocations appearing at the top level, they can be used
anywhere it is legal for an Ion value to appear.

Inside a struct:
```js
{
  driver_name: "Gilbert Barron",
  license_no: 481746611,
  vehicle: {#2 "Porsche" "Cayenne" 2014}
}
```

Inside a list:
```js
[{#3 "Camry" 2009}, {#2 "Honda" "Accord" 2015}, {#2 "Subaru" "Legacy" 2019}]
```

Inside an s-expression:
```js
(set car {#3 "Camry" 2009})
```

And inside other template invocations:
```js
$ion_symbol_table::{
  imports: $ion_symbol_table, // The new templates below are appended to the existing table
  templates: [
    "Camry" // Template #4
  ]
}
{#3 {#4} 2018} // Equivalent to {#3 "Camry" 2018}
```

You *cannot* use template invocations in the place of a struct field name or annotation.
```js
$ion_symbol_table::{
  templates: [
    "dollars" // Template #1
  ]
}
{#1}::99.5   // Illegal
{{#1}: 99.5} // Illegal
```

## Template invocation parameters

The Ion writer can influence the way that a template invocation is expanded by passing different numbers and types of
values in the parameter list.

### Suppressing template values with `{#0}`

When `{#0}` appears as a parameter in a template invocation, the corresponding value in the template (and associated field name/annotations, if applicable) will be skipped over by the Reader during expansion.

For example, in this stream we define a template to encode employee information:

```js
$ion_1_1
$ion_symbol_table::{
  symbols: [
    "name",       // $12
    "employeeId", // $13
    "occupation", // $14
  ],
  templates: [
    { // Template #1
      $12: {#0}, // name
      $13: {#0}, // employeeId
      $14: {#0}, // occupation
    }
  ]
}
```

These two invocations:

```js
{#1 "Zack" 12345 'Software Engineer'}
{#1 "Zack" {#0} 'Software Engineer'} // Suppress the second value in the template
```

would expand to:

```js
{
  name: "Zack",
  employeeId: 12345,
  occupation: SDE
}
{ // The 'employeeId' field is omitted.
  name: "Zack",
  occupation: SDE
}
```

When `{#0}` is used as a template invocation parameter in the context of a template definition, it is 
*always* considered a template blank.

```js
$ion_1_1
$ion_symbol_table::{
  symbols: [
    "name",       // $12
    "employeeId", // $13
    "occupation", // $14
  ],
  templates: [
    { // Template #1
      $12: {#0}, // name
      $13: {#0}, // employeeId
      $14: {#0}, // occupation
    }
    // The definition of template #2 invokes template #1, so the {#0} passed as the second parameter
    // is considered a template blank, not a field suppression.
    {#1 "Bernard" {#0} "Accountant"}
  ]
}
```

As the [Binary encoding](#binary-encoding) notes, `{#0}` takes two bytes to encode, making it more expensive
than a single-byte `null` of any type.

### Suppressing trailing template values

Trailing values in the template definition can be suppressed by not passing enough parameters to define them at the 
invocation site:

```js
{#1 "Zack" 12345} // Provides 2 parameter values.
{#1 "Zack"}       // Provides 1 parameter value.
```

expands to

```js
{
  name: "Zack",
  employeeId: 12345,
  // The 'occupation' field is omitted.
}
{
  name: "Zack",
  // The 'employeeId' field is omitted.
  // The 'occupation' field is omitted.
}
```

This feature, paired with [support for extending containers](#support-for-extending-containers) below, allows users to leverage existing template definitions to encode similar composite values rather than having to define a collection of nearly identical templates.

### Support for extending containers

If a template is a container type (i.e. `struct`, `list`, or `sexp`), invocations can provide enough values to fill in the template's blanks and then an extra parameter: a container of the same type as the template container. Values from this extra container will be appended to the end of the expanded container. We will refer to this extra parameter as an "extension parameter".

The extension parameter _must_ be the same Ion type as the template definition's outermost Ion value. This allows structs to specify field names for the values being added to the expanded value (`number_of_reports` in the example above). Passing any other type of value is illegal.

Extension parameters can only be used with template definitions whose outermost Ion value is a container type. It is always illegal to pass a scalar value (int, string, etc) as an extension parameter.

Passing additional parameters beyond the optional extension parameter is illegal.

#### Extending a list

```js
$ion_1_1
$ion_symbol_table::{
  templates: [
    ["Vanilla", "Chocolate Chip"] // Template 1
  ]
}
{#1 ["Rocky Road", "Cookie Dough"]} // Passes a list as an extension paramameter
```

expands to

```js
["Vanilla", "Chocolate Chip", "Rocky Road", "Cookie Dough"]
```

#### Extending a struct

```js
$ion_1_1
$ion_symbol_table::{
  symbols: [
    "name",       // $12
    "employeeId", // $13
    "occupation", // $14
  ],
  templates: [
    { // Template #1
      $12: {#0}, // name
      $13: {#0}, // employeeId
      $14: {#0}, // occupation
    }
  ]
}
{#1 "Zack" 12345 "Software Engineer"}
{#1 "Jon" 67890 "Manager" {number_of_reports: 6}} // Passes a struct as an extension parameter
```

expands to

```js
{
  name: "Zack",
  employeeId: 12345,
  occupation: SDE
}
{
  name: "Jon",
  employeeId: 67890,
  occupation: SDM,
  number_of_reports: 6
}
```

Extension parameters can be used in template invocations inside of template definitions. They can also contain template invocations. This stream:

```js
$ion_1_1
$ion_symbol_table::{
  symbols: [
    "name",       // $12
    "employeeId", // $13
    "occupation", // $14
  ],
  templates: [
    { // Template #1
      $12: {#0}, // name
      $13: {#0}, // employeeId
      $14: {#0}, // occupation
    },
    // Template #2 invokes template #1 and passes an extension parameter
    {#1 "Jon" 67890 "Manager" {number_of_reports: 6}}
  ]
}
 // Passes an extension parameter that invokes template #2
{#1 "Zack" 12345 "Software Engineer" {manager: {#2}}}
```

expands to

```js
{
  name: "Zack",
  employeeId: 12345,
  occupation: SDE,
  manager: {
    name: "Jon",
    employeeId: 67890,
    occupation: SDM,
    number_of_reports: 6
  }
}
```

## Annotation Expansion

### In the template definition

Annotations can appear on blanks (`{#0}`) in a template definition.

**Template definition**

```js
$ion_template_table::{
  templates: [
    dollars::{#0}
  ]
}
```

**Template invocation**

```js
{#1 99.5}
```

**Expanded data**

```js
dollars::99.95
```

### At the invocation site

Annotations can also appear on directly on template invocations.

**Template definition**

```js
$ion_template_table::{
  templates: [
    [99.95]
  ]
}
```

**Template invocation**

```js
dollars::{#1}
```

**Expanded data**

```js
dollars::[99.95]
```

### In both the definition and the invocation

If annotations are present both on a template definition blank *and* on a template invocation that supplies a value for that blank, the two annotations lists will be concatenated in the expanded data. The annotations at the invocation site will appear first.

**Template definition**

```js
$ion_template_table::{
  templates: [
    dollars::{#0}
  ]
}
```

**Template invocation**

```js
US::{#1 99.95}
```

**Expanded data**

```js
US::dollars::99.95
```
-----

## Importing templates

Ion templates piggy-back on [the Ion 1.0 spec's existing symbol table import process](http://amzn.github.io/ion-docs/docs/symbols.html#processing-of-symbol-tables).

Templates can be defined by:
1. Adding them to a [local symbol table](http://amzn.github.io/ion-docs/docs/symbols.html#local-symbol-tables), 
   as demonstrated in the [Template Definitions](#template-definitions) section.
2. Importing them from a [shared symbol table](http://amzn.github.io/ion-docs/docs/symbols.html#shared-symbol-tables).

Symbol tables can include a `symbols` field, a `templates` field, neither, or both. If both are present, the `templates` field
must always be processed *after* the `symbols` field. This allows templates to be defined which leverage symbols defined in 
the same table. For example:
```js
$ion_template_table::{
  symbols: [
    "name", // $12
    "age",  // $13
  ],
  templates: [
    { // Template #1 uses symbols 13 and 14, defined above.
      $12: {#0},
      $13: {#0},
    }
  ]
}
```

When importing a shared symbol table, the number of definitions being imported from the `templates` list is capped by
the `max_template_id` field. (This is analagous to `max_id` limiting the number of symbols imported from the `symbols` list.)

```js
$ion_template_table::{
  imports: [
    {
      name: "my_table",
      version: 1,
      max_id: 16, // Only 16 symbols will be imported from `my_table` v1
      max_template_id: 32 // but 32 template definitions will be imported.
    }
  ]
}
```

## Templates' relationship to symbols

Although templates offer a superset of symbols’ functionality and could replace them wholesale, this document proposes adding them
alongside symbols to preserve backwards compatibility and simplify implementating the new functionality.

Unlike symbols, templates are a system-level encoding detail, not a user-level type.

If a symbol ID cannot be resolved, readers can still report that the value is of type `symbol` and provide its symbol ID.
In contrast, if a template invocation refers to a template ID that cannot be resolved (e.g. due to a missing shared symbol table), 
no type information is available to the user. Reader implementations should raise an error.

Templates and template invocations *cannot* be used in places where one would expect to find a symbol token, including struct
field names and annotations.

## Binary encoding 

See the [Ion 1.0 binary encoding spec](http://amzn.github.io/ion-docs/docs/binary.html#typed-value-formats) for a detailed explanation of the terms used in the diagrams below.

This RFC proposes using three of the (previously reserved) [type code `15`](http://amzn.github.io/ion-docs/docs/binary.html#15-reserved)
values to represent template invocations:

* `0xF0`: an invocation with no parameters
* `0xF1`: an invocation with a single parameter
* `0xF2`: an invocation with two or more a parameters

Not all template invocation encodings include a length prefix, but all of them can be skip-scanned. (See
[Skip-scanning over templates](#skip-scanning-over-templates) for more information.) This approach keeps
the invocation representation compact while preserving the majority of type code 15 for future use cases.

### `0xF0`: No-parameter invocations

When invoking a template whose definition does not include any blanks (`{#0}`), callers will use `0xF0`.

```
            7       4 3       0
           +---------+---------+
Template   |   15    |    0    |
           +---------+---------+======+
           |     template ID [VarUInt]|
           +--------------------------+
```

#### Example of a no-parameters template
```js
$ion_1_1
$ion_symbol_table::{
  symbols: [
    "last_modified" // $12
    "ntp-server-3a" // $13
  ],
  templates: [
    $12::$13::2020-07-09T15:30:00.000-11:00 // Template #1 has no blanks
  ]
}
{#1} // Invoking this requires no parameters
```

Note that `{#0}` itself is a no-parameters template invocation, and would be encoded as: 
```js
    0xF0 0x80
//    ^    ^--- The VarUInt encoding of a zero: 0b1000_0000
//    +-------- A no-parameters template invocation
```

In the common case, no-parameters template invocations will require 2 to 3 bytes to encode.

### `0xF1` Single-parameter invocations

```
            7       4 3       0
           +---------+---------+
Template   |   15    |    1    |
           +---------+---------+======+
           |     template ID [VarUInt]|
           +--------------------------+
           |     Parameter Value      |
           +--------------------------+
```

#### Example of a single-parameter template

```js
$ion_1_1
$ion_symbol_table::{
  symbols: [
    "last_modified" // $12
    "ntp-server-3a" // $13
  ],
  templates: [
    $12::$13::{#0} // Template #1 has a single blank
  ]
}
{#1 2020-07-09T15:30:00.000-11:00} // Single-parameter invocation
```

The invocation's binary encoding would be:
```js
    0xF1 0x81 0x6a 0x45 0x94 0x0f 0xe4 0x87 0x8a 0x82 0x9e 0x80 0xc3
//    ^    ^    ^------- 10 byte encoding of the timestamp value: 2020-07-09T15:30:00.000-11:00
//    |    +------------ VarUInt encoding of the template ID: 1
//    +----------------- Single-parameter template invocation
```

### `0xF2` Multi-parameter invocations

```
            7       4 3       0
           +---------+---------+
Template   |   15    |    2    |
           +---------+---------+======+
           |     template ID [VarUInt]|
           +--------------------------+
           |     Length [VarUInt]     |
           +--------------------------+
           |     Parameter 1          |
           +--------------------------+
           |     Parameter 2          |
           +--------------------------+
           |     ...                  |
           +--------------------------+
           |     Parameter N          |
           +--------------------------+
```

#### Example of a multi-parameter template

```js
$ion_1_1
$ion_symbol_table::{
  symbols: [
    "name",            // $12
    "age",             // $13
    "favoriteDessert", // $14
  ],
  templates: [
    { // Template #1 has multiple blanks
      $12: {#0},
      $13: {#0},
      $14: {#0},
    }
  ]
}
{#1 "Gary" 46 "Brownies"} // Single-parameter invocation
```

The invocation's binary encoding would be:
```js
//                         G    a    r    y        46         B    r    o    w    n    i    e    s
    0xF2 0x81 0x90 0x84 0x47 0x61 0x72 0x79 0x21 0x2e 0x88 0x42 0x72 0x6f 0x77 0x6e 0x69 0x65 0x73
//    ^    ^     ^        ^                   ^         ^----- 8-byte string: "Brownies"
//    |    |     |        |                   +--------------- 1-byte positive integer: 46
//    |    |     |        +----------------------------------- 4-byte string: "Gary"
//    |    |     +-------------------------------------------- VarUInt encoding of the length: 16 bytes
//    |    +-------------------------------------------------- VarUInt encoding of the template ID: 1
//    +------------------------------------------------------- Multi-parameter template invocation
```

## Skip-scanning over templates

In order to be able to report the Ion type of the next value in the stream, readers must read the
template ID that follows the type descriptor byte to look up the corresponding template definition.

Each invocation encoding type makes it possible to skip over the remaining bytes:

* `0xF0`: There are no further bytes after the template ID.
* `0xF1`: The single parameter that follows the template ID has a length prefix of its own.
* `0xF2`: A `VarUInt` length encoding follows the template ID, allowing the entire parameter list to be skipped.

-----
## Alternative encodings considered

### Alternative text encodings

#### `@`-based

Earlier versions of this proposal used an `@`-based syntax for templates to parallel the system-level
syntax `$`-based syntax for symbols:

```js
@_              // A template blank
@1              // Invoke template #1 without parameters
@2(foo bar baz) // Invoke template #2 with multiple parameters 
```

However, the [Ion 1.0 specification `Symbols` section](https://amzn.github.io/ion-docs/docs/spec.html#symbol) 
states that:

> Within S-expressions, the rules for unquoted symbols include another set of tokens: operators. An operator is an unquoted sequence of one or more of the following nineteen ASCII characters: !#%&*+-./;<=>?@^`|~ Operators and identifiers can be juxtaposed without whitespace ....

This broad parsing rule meant that the `@` in a template invocation like `@1` would be interpreted as an operator. An alternative syntax would be necessary for invoking templates or using template blanks (`@0`) inside of an s-expression. Unfortunately, several other syntax options were eliminated by the same rule.

`{#ID}` works because curly braces are not an operator and it can be unambiguously parsed because
the contents of a struct cannot begin with `#` in Ion 1.0.

#### Annotation-based

To sidestep the operator problem described above, a more verbose syntax was considered that relied on
a system annotation called `$ion_template` that would be used to mark s-expressions as template invocations
or blanks.

```js
$ion_template::(0) // A template blanks
$ion_template::(1) // Invoke template #1 without parameters
$ion_template::(2 foo bar baz) // Invoke template #2 with multiple parameters.
```

This ended up touching a larger surface area of the existing spec than simply introducing new syntax. Any usage
of s-expressions would require logic to detect whether it was actually a template invocation. Parameters being
passed to the template would be subject to s-expression parsing rules, meaning that careful escaping would be
required. Corner cases in the spec would need to be carefully considered; for example: if a user creates a new
annotation with the text `$ion_template` but which uses a different symbol ID, is the annotated s-expression a
template invocation or not?

### Alternative binary encodings

The initial draft of this spec modeled templates' encoding after 
[that of the user-level types](http://amzn.github.io/ion-docs/docs/binary.html#typed-value-formats).
Templates had a type descriptor byte with a type code of `15` and a lower nibble that would encode the 
length of the invocation, using `14` to indicate a `VarUInt` length was necessary. The primary drawback of this approach was that it consumed the entire `typecode=15` space, which was reserved in Ion 1.0 for future functionality.
