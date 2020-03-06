# Ion 1.1 draft RFC

Ion `template`s generalize Ion 1.0’s concept of `symbol`s by:

1. Allowing any valid Ion value to be added to the table, not just `string`s.
2. Allowing containers stored in the table to have ‘blanks’ (denoted by `@_` in this document) in them that can be filled in when the template is referenced.

Unlike `symbol`s, `template`s are a system-level encoding detail, not a user-level type.

While `template`s offer a superset of `symbol`s’ functionality and could replace them wholesale, this document proposes adding them alongside `symbol`s to preserve backwards compatibility.


## New system symbols

Support for templates requires three new symbols.

Two for [defining a template](#defining-a-template):
* `$ion_template_table`
* `templates`

And one to support the templates' [text encoding within S-Expressions](#text-encoding-within-s-expressions):
* `$ion_template`



## Defining a template

Template tables are defined analogously to symbol tables, by adding an `$ion_template_table`-annotated struct to the value stream.

```js
$ion_template_table::{
  templates : [
    "sassafras", // template 0
    1970-01-01T00:00:00Z, // template 1
    3.14159265358979323846264338323 // template 2
  ]
}
```

Composite values (i.e. containers) can leave nested values unspecified by using the sentinel value, `@_`.

```js
$ion_template_table::{
  templates : [{ // template 0
    make: @_,
    model: @_,
    year: @_,
    frame: sedan,
    numberOfWheels: 4,
    transmission: automatic,
    hasAirbags: true
  }]
}
```

Template definitions can refer to other templates, but only those templates that have already been defined (i.e. templates with a lower ID) in order to cheaply avoid cycles.


## Invoking a template

### Invocation syntax

```js
// Invoke template 0 with the following parameters
@0("Toyota", "Camry", 2017)
```

Parameters to a template invocation can themselves be template invocations. There is no restriction on which templates can be invoked as parameters.

### Expanded data

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

In binary Ion, the template invocation requires 18 bytes to encode while the expanded data would require 42 bytes.

## Binary layout

See the [Ion 1.0 binary encoding spec](http://amzn.github.io/ion-docs/docs/binary.html#typed-value-formats) for a detailed explanation of the terms used in the diagram below.

```
            7       4 3       0
           +---------+---------+
Template   |   15    |    L    |
           +---------+---------+======+
           :     length [VarUInt]     :
           +--------------------------+
           |     template ID [VarUInt]|
           +--------------------------+
           :           value          :
           +==========================+
                         ⋮
```

* `L` values of `0` and `null` are available to be used as sentinels. 
* This document treats `L`=0 as a template blank: `@_`
* `L`=14 is a variable `length` encoding.
* `L`=15 is reserved for future specs to accommodate not-yet-designed template invocation methods. (e.g. “splicing”)
* Templates have a minimum length of 2 (1 byte type descriptor, 1 byte template ID)
* A template blank (`L`=0, `@_`) found outside of a template definition or template invocation is illegal and should be treated as an error.
* Template invocations with an ID that cannot be resolved are illegal and should be treated as an error. 
    * (This differs from `symbol`s with an ID that cannot be resolved. `symbol`s are values while `template`s are an encoding detail. If a `Reader` encounters an unresolvable `symbol`, it can still tell the user that it is positioned over a symbol and even provide the unresolvable ID number.)



## Text encoding within s-expressions

Because `@` is a valid operator character within an s-expression, template blanks in the text format must be annotated with the special `$ion_template` annotation. Per the spec, symbols starting with `$ion` are reserved and may not be used in user data.

### Blanks in a template definition s-expression

```js
$ion_template_table::{
  templates : [{ // template 0
    ($ion_template::@_)  
  }]
}  
```

### Template invocation inside an s-expression

```js
// Invoke template 0 from within an s-expression.
($ion_template::@0(123))
// ((123))
```



## Restrictions

* Ion templates perform simple expansions. They involve no branching, looping, or recursion. They are guaranteed to terminate.
* A template always expands to a single, complete Ion value.
* Template invocations can only appear in positions where an Ion value could appear. (e.g. You cannot use a template invocation as an annotation or field name: `@1("dollars")::21.95` is illegal.)
* Template definitions can refer to other templates, but only those templates that have already been defined (templates with a lower ID) in order to cheaply avoid cycles.



## Support for suppressing values

When `@_` appears as a parameter in a template invocation, the corresponding value in the template (and associated field name, if applicable) will be skipped over by the `Reader`.

```js
$ion_template_table::{
  templates: [{ // template 0
    name: @_,
    employeeId: @_,
    occupation: @_
  }]
}
@0("Zack", @_, "SDE") // Explicitly leave 'employeeId' blank with '@_'
```

expands to

```js
{
  name: "Zack",
  occupation: SDE
}
```

This feature, paired with [support for extending containers](#support-for-extending-containers) below, allows users to leverage existing template definitions to encode complex values rather than having to define a collection of very similar templates.


## Support for extending containers

If a template is a container type, invocations can provide enough values to fill in the template's blanks and then an extra parameter: a container of the same type as the template container. Values from this extra container will be appended to the end of the expanded container.

### Expanding a struct

```js
$ion_template_table::{
  templates: [{ // template 0
    name: @_,
    employeeId: @_,
    occupation: @_
  }]
}
@0("Zack", 12345, "SDE")
@0("Jon", 67890, "SDM", {number_of_reports: 6}) // Passes an extra struct
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



## Annotation Expansion

### In the template definition

Annotations can appear on blanks (`@_`) in a template definition.

**Template definition**

```js
$ion_template_table::{
  templates: [
    dollars::@_
  ]
}
```

**Template invocation**

```js
@0(99.5)
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
dollars::@0
```

**Expanded data**

```js
dollars::[99.95]
```



### In both the definition and the invocation

If annotations are present both on a template definition blankand on a template invocation that supplies a value for that blank, the two annotations lists will be concatenated in the expanded data. The annotations at the invocation site will appear first.

**Template definition**

```js
$ion_template_table::{
  templates: [
    dollars::@_
  ]
}
```

**Template invocation**

```js
US::@0(99.95)
```

**Expanded data**

```js
US::dollars::99.95
```



## Bigger Org-tree Example

```js
$ion_template_table::{
  templates: [{ // Template 0
    name: @_,
    employeeId: @_,
    occupation: @_
  },
  @0(@_, @_, SDE), // Template 1; template definitions can include invocations of templates with lower IDs
  @1("Zack", 12345), // Template 2
  @1("Fernando", 45673), // Template 3
  @1("Peter", 23678), // Template 4
  @1("Tyler", 11133), // Template 5
  @1("David", 73328), // Template 6
  @1("Wes", 19384), // Template 7
  [@2, @3, @4, @5, @6, @7] // Template 8
}
@0("Jon", 67890, SDM, {reports: @8})
@2({peers: @8})
@5({peers: @8})
```

expands to

```js
{
  name: "Jon",
  employeeId: 67890,
  occupation: SDM,
  reports: [{
      name: "Zack",
      employeeId: 12345,
      occupation: SDE
    }, {
      name: "Fernando",
      employeeId: 45673,
      occupation: SDE
    }, {
      name: "Peter",
      employeeId: 23678,
      occupation: SDE
    }, {
      name: "Tyler",
      employeeId: 11133,
      occupation: SDE
    }, {
      name: "David",
      employeeId: 73328,
      occupation: SDE
    }, {
      name: "Wes",
      employeeId: 19384,
      occupation: SDE
    }, 
  ]
}
{
  name: "Zack",
  employeeId: 12345,
  occupation: "SDE",
  peers: [{
      name: "Zack",
      employeeId: 12345,
      occupation: SDE
    }, {
      name: "Fernando",
      employeeId: 45673,
      occupation: SDE
    }, {
      name: "Peter",
      employeeId: 23678,
      occupation: SDE
    }, {
      name: "Tyler",
      employeeId: 11133,
      occupation: SDE
    }, {
      name: "David",
      employeeId: 73328,
      occupation: SDE
    }, {
      name: "Wes",
      employeeId: 19384,
      occupation: SDE
    }, 
  ]
}
{
  name: "Tyler",
  employeeId: 11133,
  occupation: "SDE",
  peers: [{
      name: "Zack",
      employeeId: 12345,
      occupation: SDE
    }, {
      name: "Fernando",
      employeeId: 45673,
      occupation: SDE
    }, {
      name: "Peter",
      employeeId: 23678,
      occupation: SDE
    }, {
      name: "Tyler",
      employeeId: 11133,
      occupation: SDE
    }, {
      name: "David",
      employeeId: 73328,
      occupation: SDE
    }, {
      name: "Wes",
      employeeId: 19384,
      occupation: SDE
    }, 
  ]
}
```

## ‘System’ Templates

Ion 1.0 provides [a ‘system’ symbol table](http://amzn.github.io/ion-docs/docs/symbols.html#system-symbols) with 9 pre-defined symbols. Ion 1.1 can introduce a system template table. This table could provide template definitions for common but surprisingly expensive expressions. Examples follow.

### Local Symbol/Template table appends

In its least expensive form, an LST append definition for a new symbol `new_symbol` looks like this:

```js
// Annotation type descriptor: 1 byte
// Annotations length: 1 byte
// Annotation #1 length: 1 byte
// Annotation #1 symbol ID: 1 byte
$ion_symbol_table::
// Struct type descriptor: 1 byte
// Struct length: 1 byte
{
  // Field name: 1 byte
  // Symbol type descriptor: 1 byte
  // Symbol: 1 byte
  imports: $ion_symbol_table,
  // Field name: 1 byte
  // List type descriptor: 1 byte
  // Symbol string: 11 bytes
  symbols: ["new_symbol"]
}

// Total bytes: 22 bytes
// Overhead: **10 bytes**
```


While the list of strings to intern (`["new symbol"]`) is itself only 12 bytes, we have to pay an additional 10 bytes of overhead to add it to the symbol table.

Using a macro invocation like this:

```js
// Macro type descriptor: 1 byte
// Macro ID: 1 byte
// List type descriptor: 1 byte
// Symbol string: 11 bytes
@0(["new_symbol"])

// Total bytes: 14 bytes
// Overhead: **2 bytes**
```

we can cut the overhead by 80%.

The same technique could be used for local template table appends.

## Shared Templates

Shared template table imports are handled in the same way as shared symbol table imports.

