---
redirect_from: "/symbols.html"
title: Symbols
description: "Amazon Ion symbols are critical to the notation's performance and space-efficiency. This page defines the various concepts and data structures related to symbol management."
---

# [Docs][docs]/ {{ page.title }}

Amazon Ion symbols are critical to the notation's performance and
space-efficiency. This page defines the various concepts and data
structures related to symbol management.

* TOC
{:toc}

Symbol Representations
----------------------

In Ion binary, all symbols are represented as integers. These integers
are *symbol IDs* whose corresponding text forms are defined by a 
*symbol table*.

In Ion text, symbols are represented in three ways:

  * __Quoted symbol__: a sequence of zero or more characters between
    single-quotes, *e.g.*, `'hello'`, `'a symbol'`, `'123'`, `''`.
    This representation can denote any symbol text.
  * __Identifier__: an unquoted sequence of one or more ASCII letters, digits, 
    or the characters `$` (dollar sign) or `_` (underscore), not starting with
    a digit and not including the keywords `null`, `nan`, `true`, and `false`.
  * __Operator__: an unquoted sequence of one or more of the following nineteen 
    ASCII characters: `` !#%&*+-./;<=>?@^`|~ ``
    Operators can only be used as (direct) elements of an S-expression.
    In any other context those characters require single-quotes.

A subset of identifiers have special meaning:

  * __Symbol Identifier__: an identifier that starts with `$` (dollar sign)
    followed by one or more digits. These identifiers directly represent the
    symbol's integer symbol ID, not the symbol's text.
    This form is not typically visible to users, but they should be aware of
    the reserved notation so they don't attempt to use it for other purposes.

By convention, symbols starting with `$` should be reserved for system
tools, processing frameworks, and the like, and should be avoided by
applications and end users. In particular, the symbol `$ion` and all symbols
starting with `$ion_` are reserved for use by the Ion notation and by related
standards.

Processing of Symbol Tables
---------------------------

There are two kinds of symbol tables: shared and local.

A *shared symbol table* is intended for use from multiple data sources.
Each shared table is uniquely identified by a (string) name and (int)
version number. Shared symbol tables are key to the compactness of Ion
binary data, extracting the text of frequently used symbols (field
names, enumerations, keywords, *etc.*) out of individual documents and
into a common data structure.

A *system symbol table* is a shared table with the name `"$ion"`. Every version
of the Ion notation maps to a specific version of the system symbol
table.

A *local symbol table* is for the sole use of a well-defined scope of
Ion data. Since it does not need to be referenced from other contexts,
it has no name or version number. Local tables may *import* symbols defined
in one or more shared tables **or** import the symbols in the previously defined
local symbol table (but **not** both). Local tables also accumulate any
other symbols encountered within their scoped data, such as when encoding
Ion text into binary.

At any point during processing, there is a *current symbol table*, which
is either a local symbol table or a system symbol table. At the start of
input, the current symbol table is initialized to be the system symbol
table for Ion 1.0. The current symbol table is only changed in two
circumstances: (1) encountering a system identifier at the top-level, or
(2) encountering a local symbol table at the top-level.

### The Catalog

This specification refers to a "catalog". That's simply an abstraction
for the set of available Ion shared symbol tables. It's not necessarily
a static set: one could implement a catalog that pulls symbol tables
from a network repository, or one that has application symbol tables "compiled
in", or (very likely) some composition of these techniques. The
mechanism by which shared symbol tables are acquired is irrelevant to this
specification, but is discussed in [Catalog Best Practices][catalog].

### Top-Level Semantics

Symbol tables only (meaningfully) occur at the top level of a data
stream or datagram. An Ion data stream is structured as follows:

-   An initial *Ion Version Marker* is required in binary data, and
    optional (but *highly recommended*) in text. All Ion text implicitly
    starts with `$ion_1_0` when not explicitly provided. Every (top-level) IVM
    switches the parser to the indicated Ion version and sets the
    current symbol table to the indicated Ion system symbol table.
-   Every top-level value (and all the hierarchical data within it) is
    interpreted with respect to the current symbol table at the point
    where the value starts.
-   Every top-level *local symbol table* becomes the current symbol table
    for the value(s) following it. A local table may be injected or
    extended by the implementation during processing of the rest of
    the stream.

Certain top-level values such as IVMs and local symbol tables are
referred to as *system values*; all other values are referred to as
*user values*. An Ion implementation may give applications the ability
to "skip over" the system values, since they are generally irrelevant
to the semantics of the user data.

Ion Version Markers
-------------------
In Ion text, the Ion Version Marker (IVM) is represented by the following
symbol.

`$ion_1_0`

This stand-alone symbol is recommended at the start of Ion text data.
It identifies a specific major/minor version of the Ion notation. It
resets the current symbol table to be the corresponding system symbol
table, and simultaneously switches the parser into the appropriate mode
for parsing the right version of Ion notation.

A version marker can also occur at non-initial positions at the top
level, and it will have the same effect; when encountered below
top-level, it has no processing effect and is treated as an ordinary *user
value*.

IVMs do not have annotations. The input `ann::$ion_1_0` is not a version marker,
it's a symbol with an annotation.

In Ion binary, there is a special sequence of bytes that represent the IVM.

`E0 01 00 EA`

This sequence of bytes can only appear at the top-level, much like the text
IVM, and can occur at non-initial positions as well.  Note that this particular
form is equivalent to its textual counterpart `$ion_1_0` and has the
same processing semantics, but is a special encoding artifact in the
binary format.

At the top-level, any encoding of `$ion_1_0` that does not match the forms
specified above are *system values* that have no processing semantics (a NOP).

Below are examples of the symbol `$ion_1_0` that are not interpreted as IVMs:

    // explicitly quoted
    '$ion_1_0'
    
    // explicitly quoted with some newline escapes
    '$ion_\
    1\
    _\
    0'
    
    // symbol ID mapping $ion_1_0 declared in the system symbol table
    $2
    
    $ion_symbol_table::
    {
      symbols:["$ion_1_0"]
    }
    // a locally declared symbol ID mapping to $ion_1_0
    $10

It is important to round-trip the forms above correctly, here is an example
of IVMs mixed with these NOP encodings:

    // IVM
    $ion_1_0
    $ion_symbol_table::
    {
      symbols:["a"]
    }
    // not the IVM
    '$ion_1_0'
    // also not the IVM
    $2
    // maps to "a"
    $10

The above is equivalent to the following, more concise Ion:

    $ion_1_0
    a

Here is a bad example of re-encoding the previous example in a naive way:

    // IVM
    $ion_1_0
    $ion_symbol_table::
    {
      symbols:["a"]
    }
    // quoted form improperly got converted to an IVM
    $ion_1_0
    // ERROR! the following symbol ID is not defined
    $10

The problem with the above example is that the conversion of `'$ion_1_0'`
to `$ion_1_0` changed it from being a NOP to an IVM which resets the
current symbol table to the system symbol table.

Shared Symbol Tables
--------------------

This section defines the serialized form of shared symbol tables. Unlike
local symbol tables, the Ion parser does not intrinsically recognize or
process this data; it is up to higher-level specifications or
conventions to define how shared symbol tables are communicated.

    $ion_shared_symbol_table::
    {
      name: "com.amazon.ols.symbols.offer",
      version: 1,
      imports: // For informational purposes only.
      [
        { name:"..." , version:1 }, 
        // ...
      ],
      symbols:
      [
        "fee", "fie", "foe", /* ... */ "hooligan"
      ]
    }

A shared symbol table is serialized as a struct with the annotation
`$ion_shared_symbol_table`.

The `name` field should be a string with length at least one. If the field has
any other value, then materialization of this symbol table must fail.

The `version` field should be an int and at least 1. If the field is missing or
has any other value, it is treated as if it were 1.

The `imports` field is for informational purposes only in shared tables. They
assert that this table contains a superset of the strings in each of
these named tables. It makes no assertion about any relationship between
symbol IDs in this table and the imports, only that the symbols' text
occurs here. An implementation MAY issue a warning if these claims don’t
match what’s in the `symbols` field.

The `symbols` field should be a list of strings. If the field is 
missing or has any other type, it is treated as if it were an empty list.

Null elements declare undefined symbol IDs ("gaps") within the sequence;
implementations must handle requests for such symbols the same as if the
requested ID beyond the end of the list. Any element of the list that is
not a string must be interpreted as if it were null.

A few things worth noting:

  * Shared symbol tables do not make use of a `max_id` field since the largest
    SID is implicit in the `symbols` list. If a `max_id` field exists, it must
    be ignored.
  * A shared table isn’t coupled to any particular system table, so it
    can be used in any context.
  * The algorithm for SID assignment differs between shared and
    local tables. Sids in shared tables always start at one. Sids in
    local tables are always offset by the sum of the sizes of the system
    symbol table and all imported tables.

### Semantics

Symbol IDs are assigned to the `symbols` strings in order of their appearance in
the list: the first element has symbol ID 1 (aka `$1`), the last has the
symbol ID equal to the length of the list.

When mapping from symbol ID to string, a simple index into the list is
all that's needed.

When mapping from string to symbol ID, there may be multiple associated
IDs (the same string could appear twice as children of the `symbols` field).
Implementations MUST select the lowest known ID, and all other
associated IDs MUST be handled as if undefined.

### Versioning

A shared symbol table with version greater than one should usually be a
strict extension of the immediately preceding version, but Ion does not
(and in reality cannot) enforce this. Symbols may be removed, but they
cannot be renumbered or given different text. This ensures that when
version N is requested, any version larger than N can be used without
changing semantics. However, if symbols become undefined then some
extant data may become unreadable when an exact-match import cannot be
found.

The use of symbol tables that violate these restriction will lead to
undefined and potentially incorrect interpretation of Ion data.
Therefore implementations should enforce these restrictions at
appropriate points.

Version N+1 of a table MAY be the same as version N.


Local Symbol Tables
-------------------

A local symbol table defines symbols through two mechanisms, both of which are
optional.

First, it imports the symbols from one or more shared symbol
tables, offsetting symbol IDs appropriately so they do not overlap.
Instead of importing the symbols from shared symbol tables,
a local symbol table may import the current symbol table.

Second, it defines local symbols similarly to shared
tables. The latter aspect is generally not managed by users: the system uses
this form in the binary encoding to record local symbols encountered during parsing.

    // a local symbol table that resets the context, imports some shared symbol tables
    // and adds three local symbols
    $ion_symbol_table::
    {
      imports:[ { name: "com.amazon.ols.symbols.offer",
                  version: 1,
                  max_id: 75 },
                // ...
      ],
      symbols:[ "rock", "paper", "scissors" ]
    }
    
    // a local symbol table that adds two local symbols to the context
    $ion_symbol_table::
    {
      imports:$ion_symbol_table,
      symbols:[ "lizard", "spock" ]
    }

When immediately following an explicit system ID, a top-level struct
whose first annotation is `$ion_symbol_table` is interpreted as a 
*local symbol table*. If the struct is null (`null.struct`) then it is 
treated as if it were an empty struct.

The `imports` field should be the symbol `$ion_symbol_table` or a list
as specified in the following section.

The `symbols` field should be a list of strings. If the field is
missing or has any other type, it is treated as if it were an empty list.

Null elements in the symbols list declare unknown symbol text ("gaps")
for its SID within the sequence. Any element of the list that is
not a string must be interpreted as if it were null. Any SIDs that
refer to null slots in a local symbol table are equivalent to symbol
zero.

Any other field (including, for example, `name` or `version`) is ignored.

### Imports

A local symbol table implicitly imports the system symbol table that is
active at the point where the local table is encountered.

If the value of the `imports` field is the symbol `$ion_symbol_table`,
then the all of the symbol ID assignments in the current symbol table
are imported into the new local table.  Thus, if the current
symbol table was the system symbol table, then processing is
identical to having no `imports` field value.

If the value of the `imports` field is a list, each element of the list must
be a struct; each element that is null or is not a struct is ignored.

Each import (including the implicit system table import) allocates a
contiguous, non-overlapping sequence of symbol IDs. The system symbols
start at 1, each import starts one past the end of the previous import,
and the local symbols start immediately after the last import. The size
of each import's subsequence is defined by the `max_id` on the import
statement, regardless of the actual size of the referenced table.

Import structs in an `import` list are processed in order as follows:

  * If no `name` field is defined, or if it is not a non-empty string, the
    import clause is ignored.
  * If the `name` field is `"$ion"`, the import clause is ignored.
  * If no `version` field is defined, or if it is null, not an int, or less
    than 1, act as if it is 1.
  * If a `max_id` field is defined but is null, not an int, or less than zero,
    act as if it is undefined.
  * Select a shared symbol table instance as follows:
    * Query the catalog to retrieve the specified table by `name` and `version`.
    * If an exact match is not found:
      * If `max_id` is undefined, implementations MUST raise an error and
        halt processing.
      * Otherwise query the catalog to retrieve the table with the
            given `name` and the greatest version available.
    * If no table has been selected, substitute a dummy table
      containing `max_id` undefined symbols.
  * If `max_id` is undefined, set it to the largest symbol ID of the selected
    table (which will necessarily be an exact match).
  * Allocate the next `max_id` symbol IDs to this imported symbol table.

After processing imports, a number of symbol IDs will have been
allocated, including at least those of a system symbol table. This
number is always well-defined, and any local symbols will be numbered
immediately beyond that point. We refer to the smallest local symbol ID
as the *local min\_id*.

**Note:** This specification allows a local table to declare multiple imports
with the same name, perhaps even the same version. Such a situation provides
redundant data and allocates unnecessary symbol IDs but is otherwise harmless.

### Semantics

When mapping from symbol ID to string, there is no ambiguity. However,
due to unavailable imports, certain IDs may appear to be undefined when
binary data is decoded.  Any symbol ID outside of the range of the local symbol
table (or system symbol table if no local symbol table is defined)
for which it is encoded under MUST raise an error.

When mapping from string to symbol ID, there may be multiple assigned
IDs; implementations MUST select the lowest known ID. If an imported
table is unavailable, this may cause selection of a greater ID than
would be the case otherwise. This restriction ensures that symbols
defined by system symbol tables can never be mapped to other IDs.

Put another way, string-to-SID mappings have the following precedence:

-   The system table is always consulted first.
-   Each imported table is consulted in the order of import.
-   Local symbols are last.

System Symbols
--------------

The version included in the system identifier is independent of the
version of the implied system symbol table (named `"$ion"`). Each version of
the Ion specification defines the corresponding system symbol table version.
Ion 1.0 uses the `"$ion"` symbol table, version 1, and future versions of Ion
will use larger versions of the `"$ion"` symbol table. `$ion_1_1` will probably
use version 2, while `$ion_2_0` might use version 5.

Applications and users should never have to care about these symbol
table versions, since they are never explicit in user data: this
specification disallows (by ignoring) imports named `"$ion"`.

Here are the system symbols for Ion 1.0.

<table>
<thead>
<tr class="header">
<th align="left">Symbol ID</th>
<th align="left">Symbol Name</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">1</td>
<td align="left">$ion</td>
</tr>
<tr class="even">
<td align="left">2</td>
<td align="left">$ion_1_0</td>
</tr>
<tr class="odd">
<td align="left">3</td>
<td align="left">$ion_symbol_table</td>
</tr>
<tr class="even">
<td align="left">4</td>
<td align="left">name</td>
</tr>
<tr class="odd">
<td align="left">5</td>
<td align="left">version</td>
</tr>
<tr class="even">
<td align="left">6</td>
<td align="left">imports</td>
</tr>
<tr class="odd">
<td align="left">7</td>
<td align="left">symbols</td>
</tr>
<tr class="even">
<td align="left">8</td>
<td align="left">max_id</td>
</tr>
<tr class="odd">
<td align="left">9</td>
<td align="left">$ion_shared_symbol_table</td>
</tr>
</tbody>
</table>

Equivalently:

    $ion_shared_symbol_table::
    {
      name: "$ion", version: 1,
      symbols:
      [ "$ion", "$ion_1_0", "$ion_symbol_table", "name", "version",
        "imports", "symbols", "max_id", "$ion_shared_symbol_table"
      ]
    }

Symbol Zero
-----------
SID zero (i.e. `$0`) is a special symbol that is not assigned text by any symbol
table, even the system symbol table. Symbol zero always has unknown text, and can
be useful in synthesizing symbol identifiers where the text image of the symbol is
not known in a particular operating context.

It is important to note that `$0` is only semantically equivalent to itself and to
locally-declared SIDs with unknown text. It is not semantically equivalent to SIDs
with unknown text from shared symbol tables, so replacing such SIDs with `$0` is a
destructive operation to the semantics of the data.

Data Model
----------
An important consideration for symbols is what semantics they have in the
Ion data model.  Any symbol which has the same text image as another symbol
irrespective of the ID integer or the shared symbol table (if applicable)
used to encode it is considered to be equivalent.

Ion symbols may have text that is *unknown*.  That is, there is no binding
to a (potentially empty) sequence of text.  This can happen as a result
of not having access to a shared symbol table being imported,
or having a symbol table (shared or local) that contains a `null` slot.

When operating on data that contains symbols with *unknown* text,
it is important to not treat them as equivalent unless any of the following
hold:

* Symbols with *unknown* text declared in a local symbol table are all
  equivalent to one another and to SID 0.
* For symbols defined from shared symbol table imports, symbols are
  equivalent only if *all* of the following hold:
  * The name of the table that the symbols were imported from is the same string.
  * The position in the table that the symbols were imported from is the same
    spot.  Note that this is not the same as the local SID value, but can be
    calculated from the SIDs by the allocation algorithm above.

A processor encountering a symbol with *unknown* text *and* a valid SID other
than `$0` MAY produce an error because this means that the context of the data is
missing, however any implementation that chooses not to MUST conform to the above
semantics with respect to round-tripping data.

Examples
--------

A typical text document looks like:

    $ion_1_0
    $ion_symbol_table::
    {
      imports:[{ name:"com.amazon.ols.symbols.offer", version:1 },
               { name:"com.amazon.ims3.symbols.submission", version:1 }]
    }

    // Here’s the user data, one or more top-level values.
    submission::{ /* ... */ local_symbol  /* ... */ }
    submission::{ /* ... */ 'another one' /* ... */ }

The example above shows a local table with imports but no symbols. This
is a typical scenario for human-authored data. When parsing this text,
the local table will be extended on the fly to contain any new symbols.

Here’s the same data printed after parsing, in which the local table has
been extended with symbols encountered in the user data.

    $ion_1_0
    $ion_symbol_table::
    {
      imports:[{ name:"com.amazon.ols.symbols.offer", version:1, max_id:75 },
               { name:"com.amazon.ims3.symbols.submission", version:1, max_id:100 }],
      symbols:["local_symbol", "another one"]
    }
    submission::{ /* ... */ local_symbol  /* ... */ }
    submission::{ /* ... */ 'another one' /* ... */ }

Since the `$ion_1_0` defines eight symbols ($1 through $9), the offer table
covers ids $10 through $84, the submission table covers ids $85 through $184,
and local symbols start at $185.

Here's the same data as above serialized with a local symbol table being
"flushed" between each top-level value.

    $ion_1_0
    $ion_symbol_table::
    {
      imports:[{ name:"com.amazon.ols.symbols.offer", version:1, max_id:75 },
               { name:"com.amazon.ims3.symbols.submission", version:1, max_id:100 }],
      symbols:["local_symbol"]
    }
    submission::{ /* ... */ local_symbol  /* ... */ }
    $ion_symbol_table::
    {
      imports:$ion_symbol_table,
      symbols:["another one"]
    }
    submission::{ /* ... */ 'another one' /* ... */ }

In this case, the first local symbol table generated only needs to add one
new local symbol for the top-level value being serialized in its context.
The second symbol table adds a subsequent symbol to the context for the value
immediately following it.  This pattern of local symbol tables allows top-level
values to be written to a stream without knowing all symbols ahead of time.

### Annotating local symbol tables

Although a local symbol table struct may have multiple annotations, its first
annotation *must* be `$ion_symbol_table` in order to be interpreted as a
local symbol table.

The following will be interpreted as a valid local symbol table:

    $ion_symbol_table::annotated::
    {
      symbols:["a", "b"]
    }

The example below, however, will be interpreted as a simple struct with two 
annotations:
    
    annotated::$ion_symbol_table::
    {
      symbols:["a", "b"]
    }

<!-- references -->
[docs]: {{ site.baseurl }}/docs.html
[catalog]: catalog.html
