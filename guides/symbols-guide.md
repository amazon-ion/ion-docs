---
title: Developers' Guide to Ion Symbols
description: "A developer-focused discussion of symbol tables, symbol tokens, and catalogs."
---

# [Docs][3]/ {{ page.title }}

This document provides provides developer-focused commentary on the [Symbols][1]
section of the [specification][2] and discusses the implementation of symbol
table, symbol token, and catalog APIs.

## Definitions

### Terms

-   **Local symbol ID** – an integer index into a local symbol table's list
    of symbols. Assigned according to the algorithm defined by the
    specification.

-   **Current symbol table** - the symbol table (either the system symbol
    table or a local symbol table) which is used to resolve local symbol IDs
    at a particular location in the stream.

-   **Symbol Identifier** – the text representation of a local symbol ID (e.g.
    \$10).

-   **ImportSID** – a static integer index into a shared symbol table’s list 
    of symbols.

-   **SymbolToken** - refers both to the SymbolToken structure, as defined below,
    and to a symbol token within an Ion stream (i.e. a field name, annotation,
    or symbol value). The representations are interchangeable.

-   **Unknown text** - the result of the lookup of a valid symbol ID in a
    symbol table where the text representing the symbol ID cannot be found
    (either because its import location is not present in the catalog, or
    because the symbol ID maps to a `null` slot).

-   **Undefined text** - text in a SymbolToken structure which is undefined,
    e.g. `null`. SymbolTokens with undefined text do not necessarily refer
    to symbols with unknown text because the text may be resolvable through
    the SymbolToken's importLocation.

### Structures

**ImportLocation** = `<importName:String, importSID:Int>`

**SymbolToken** = `<text:String, importLocation:ImportLocation>`

**ImportDescriptor** = `<importName:String, version:Int, max_id:Int>`

Where `Int` may be any integer and `String` may be any string.

## Symbol tables

There are three types of symbol tables: local, shared, and system (which
is a special shared symbol table). Implementations should be able to
determine the type of a given symbol table, as not all fields are valid
for all types, and not all types are valid input to all APIs. For
example, local symbol tables do not have names, while shared symbol
tables require them; only shared symbol tables may be added to a Catalog
or to a writer’s list of imports.

Symbol tables should support being in more than one Catalog
simultaneously. Otherwise, piping data from a reader through a writer
with a different Catalog would require a copy of the symbol tables the
two Catalogs have in common.

A local symbol table is the current symbol table for the subset of values
in the stream that occur between the end of its struct and either the next
Ion version marker (IVM) or the end of the next local symbol table struct
(whichever comes first). This way, a local symbol table struct may contain
SymbolTokens from the current symbol table.

### Fundamental symbol table APIs

-   Allow the user to look up a SymbolToken by its text.

-   Allow the user to look up a SymbolToken by its symbol ID.

### Advanced symbol table APIs

-   Allow the user to construct symbol tables (shared and local)

    -   Through language-idiomatic construction APIs.

    -   From serialized Ion representations.

-   Allow the user to add new symbols the symbol table.

## Catalogs

Catalogs should enable users to define the logic used to look up a shared
symbol table given an ImportDescriptor. This allows users the flexibility
to, for example, lazily query shared tables from a centralized store. A
basic implementation, which stores the mappings in memory, should be
provided.

### Fundamental Catalog APIs

-   Allow the user to look up the best match (as defined by
    the specification) to a shared symbol table given an
    ImportDescriptor. The source of the shared symbol tables may
    be user-defined. Failure to find a match should be conveyed,
    but should not raise an error.

## SymbolToken equivalence

In order to fully support the equivalence semantics defined by the
specification, SymbolToken equivalence must be implemented as follows.
When text is

-   *Defined*, SymbolTokens with the same text are equivalent;
    importLocation is ignored.

-   *Undefined*, if importLocation is

    -   *Defined*, SymbolTokens are equivalent if and only if their
        importLocations' importName and importSID are equivalent.

    -   *Undefined*, the SymbolToken represents the special symbol zero,
        which is used to denote that a SymbolToken has unknown text in
        any symbol table. SymbolTokens representing symbol zero are
        equivalent only to other SymbolTokens representing symbol zero.

## Reading SymbolTokens

Ion readers must support being provided with an optional Catalog to use
for resolving shared symbol table imports declared within local symbol
tables encountered in the stream. If a declared import is not found in
the Catalog, all of the symbol IDs in its max\_id range will have unknown
text.

Generally, Ion readers provide two kinds of SymbolToken reading APIs:
those that return raw text (for convenience), and those that return
complete SymbolTokens (for full fidelity). For

-   *Binary readers*, note that IVM semantics will never be applied to
    SymbolTokens encountered along this path<sup>[1](#fn1)</sup>. If the
    local symbol ID is

    -   *Within the current local symbol table’s max\_id range*, if the
        local symbol ID maps to text which is

        -   *Known*, for

            -   *Raw text APIs*, return that text.

            -   *SymbolToken APIs*, return a SymbolToken with that text and
                with an undefined importLocation (it is irrelevant).

        -   *Unknown*, if the local symbol ID is

            -   *Less than the current local symbol table's min\_local\_id
                (as defined by the specification)*,
                for

                -   *Raw text APIs*, the implementation should raise an
                    error<sup>[7](#fn7)</sup>.

                -   *SymbolToken APIs*, return a SymbolToken with undefined
                    text and with importLocation set<sup>[2](#fn2)</sup>.

            -   *At least min\_local\_id*, then this symbol ID maps to a null
                (or non-string) slot in the local symbol table <sup>[3](#fn3)</sup>,
                and is treated as symbol zero. For

                -   *Raw text APIs*, return undefined text (e.g. a `null`
                    string).

                -   *SymbolToken APIs*, return a SymbolToken with undefined
                    text and an undefined importLocation.

    -   *Greater than the current local symbol table’s max\_id, or less
        than zero*, an error must be raised.

-   *Text readers*, if the text is

    -   *Single-quoted*, and is

        -   *The top-level unannotated, symbol value \$ion\_1\_0*,
            ignore it and skip to the next value<sup>[1](#fn1)</sup>.
        
        -   *Anything else*<sup>[8](#fn8)</sup>, for

            -   *Raw text APIs*, return that text.

            -   *SymbolToken APIs*, return a SymbolToken with that text and
                with an undefined importLocation (it is irrelevant).

    -   *Unquoted*, and is

        -   *The top-level unannotated, symbol value \$ion\_1\_0*,
            treat this as the IVM; reset the current symbol table to the
            system symbol table and skip to the next value.
        
        -   *A Symbol Identifier*, first determine the local symbol ID by
            parsing the Symbol Identifier. Follow the steps for binary
            readers, described above, using that local symbol ID.

        -   *Anything else*, for

            -   *Raw text APIs*, return that text.

            -   *SymbolToken APIs*, return a SymbolToken with that text and
                with an undefined importLocation (it is irrelevant).

### Fundamental symbol-related reader APIs

-   Allow the user to configure the reader to use an optional Catalog to
    resolve ImportDescriptors declared by local symbol tables (described
    above).

-   Allow the user to get the following as both raw text and complete
    SymbolTokens:

    -   Field names

    -   Annotations

    -   Symbol values

### Advanced symbol-related reader APIs (not exhaustive)

-   Allow the user to get the reader’s current symbol table.

-   Allow the user to register to be notified by the reader when the
    current symbol table changes. This notification needs to include all
    necessary information required to correctly roundtrip any symbols
    with unknown text that occur within the new symbol table's max\_id
    range; namely, the list of shared symbol tables imported by the new
    symbol table. The user may then provide these shared symbol tables
    to a writer to guarantee that all SymbolTokens provided by the reader
    can be written.

## Writing symbol tables

Ion writers must accept an optional list of imports to be used during
writing. These imports, which may be either fully-materialized shared
symbol tables or ImportDescriptors, will be added to each new local symbol
table the writer creates. If the implementation allows its writer imports
to be specified as ImportDescriptors, its Ion writers must also support
being provided with an optional Catalog, which will be used to resolve
these imports. In this case, the implementation should specify that the
imported tables must be present in the Catalog if the user intends for
the symbol IDs in range of those shared tables to map to known text.
For

-   *Text writers*, serializing the local symbol table is only required
    when the stream contains symbols with unknown text from one of the
    shared symbol tables<sup>[4](#fn4)</sup>. In other cases, the text writer MAY
    serialize the local symbol table; doing so provides no benefit to
    encoding size or future read performance.

-   *Binary writers*, serializing the local symbol table is always
    required unless no SymbolTokens have occurred in the stream since
    the last occurrence of the IVM. In this case, the current symbol table
    is, implicitly, the system symbol table.

Ion writers MAY allow users to use writer APIs to manually construct a
valid local symbol table struct. If the implementation chooses

-   *Not to support this*, it MUST raise an error when trying to write a
    top-level struct annotated with \$ion\_symbol\_table<sup>[5](#fn5)</sup>.

-   *To support this*, its writers must

    -   Support being provided with an optional Catalog. This is used to
        resolve shared symbol table imports declared by manually-written local
        symbol tables.
    
    -   Ascribe all relevant symbol table semantics to any manually-written local
        symbol table, which becomes the current symbol table as soon as the symbol
        table struct is complete. Subsequently, the user should be able to use
        SymbolToken writing APIs to serialize any symbol within the max\_id
        range of the new local symbol table.
    
    -   Intercept, and not write out directly, manually-written local symbol
        tables while they are in progress. Once complete, writers should
        verify that the symbol table is valid. Like all local symbol tables,
        binary writers should buffer while the symbol table is the current
        symbol table and has not been flushed, as additional symbols may need
        to be appended; the local symbol table that is eventually written may
        contain more local symbols than were manually written, or may not need
        to be written at all.
    
    -   Follow the rules described above to determine whether the
        manually-written local symbol table is required to be written to the
        stream.

## Writing SymbolTokens

Generally, Ion writers provide two kinds of SymbolToken-writing APIs:
those that accept raw text, and those that accept a complete SymbolToken.
For APIs that accept

-   *Raw text*, and the text is
    
    -   *Undefined*, treat this as a SymbolToken which represents symbol
        zero (described below).
    
    -   *Defined*, if

        -   *The writer is at the top level, has no pending annotations,
            and the text is the same as the IVM (i.e. \$ion\_1\_0)*, ignore
            it; nothing is written.

        -   *The text does not resemble an IVM*, for

            -   *Text writers*, the SymbolToken is never assigned a local
                symbol ID, and the current local symbol table’s max\_id is
                never increased. If the text

                -   *Is an identifier (but NOT a Symbol Identifier) or
                    an operator within an S-expression*, it should be
                    written as-is. These SymbolTokens MAY be surrounded
                    with single-quote characters.

                -   *Has the same form as a Symbol Identifier*, it must be
                    surrounded with single-quote characters<sup>[8](#fn8)</sup>.
                
                -   *Is neither an identifier nor an operator within an
                    S-expression*, it must be surrounded with single-quote
                    characters.

            -   *Binary writers*, if the text

                -   *Already exists in the current symbol table*, the writer
                    writes the lowest local symbol ID that maps to that
                    text<sup>[6](#fn6)</sup>.

                -   *Does not exist in the current symbol table*, the
                    text is added to the symbols list of the current local
                    symbol table, increasing its max\_id by
                    one<sup>[9](#fn9)</sup>. This new max\_id is written as
                    the SymbolToken’s local symbol ID.

-   *SymbolTokens*, if the text is

    -   *Defined*, the behavior is the same as calling a raw text API, as
        described above, with that text<sup>[6](#fn6)</sup>.

    -   *Undefined*, and the importLocation is

        -   *Defined*, and a match to the importLocation in the system
            symbol table or the writer's imports list is

            -   *Found*, and the resolved SymbolToken has

                -   *Known text*, the behavior is the same as calling a
                    raw text API, as described above, with that text.

                -   *Unknown text*, calculate the local symbol ID of the
                    resolved SymbolToken’s importLocation in the current
                    local symbol table. For
                    
                    -   *Text writers*, write this local symbol ID as a
                        Symbol Identifier. This is the only case that
                        requires a text writer to serialize a local
                        symbol table<sup>[4](#fn4)</sup>.
                    
                    -   *Binary writers*, write this local symbol ID
                        as-is.

            -   *Not found*, and a match to the importLocation in the
                writer's Catalog (if present) is

                -   *Found*, and the resolved SymbolToken has

                    -   *Known text*, the behavior is the same as
                        calling a raw text API, as described above,
                        with that text.

                    -   *Unknown text*, an error must be raised.

                -   *Not found*, an error must be raised.

        -   *Undefined*, then this SymbolToken represents symbol zero.
            For

            -   *Text writers*, write the Symbol Identifier \$0.

            -   *Binary writers*, write the symbol ID 0.

### Fundamental symbol-related writer APIs

-   Allow the user to configure the writer to write with a list of
    shared symbol table imports. These imports will be used in each new
    local symbol table (as described above).

-   Allow the user to write the following from both raw text and complete
    SymbolTokens:

    -   Field names

    -   Annotations

    -   Symbol values

-   Allow the user to finish the current symbol table, flush any buffered data,
    and reset the current symbol table. The user must be able to continue writing
    to the stream with this writer. If the writer was configured with a list of
    shared symbol tables, the new symbol table must include these imports
    (requiring it to be written to the stream before the next value); otherwise,
    the current symbol table will be reset to the system symbol table (requiring
    the Ion version marker to be written to the stream before the next value).

### Advanced symbol-related writer APIs (not exhaustive)

-   Allow the user to configure the writer to use a Catalog to match
    ImportDescriptors and ImportLocations to shared symbol tables. If
    the writer allows the user to manually write local symbol tables, or
    if the user allows its configured list of imports to be
    ImportDescriptors, this API is required.

-   Allow the user to get the writer's current symbol table.

-   Allow the user to set the writer's current symbol table when the writer
    is positioned between top-level values. This must force the writer to
    write the previous symbol table (if necessary) and flush any buffered
    data before writing the new symbol table (or IVM, if the new symbol table
    is the system symbol table).

-   Allow the user to add shared symbol tables to the writer’s list
    of imports mid-stream when the writer is positioned between top-level
    values. In addition to allowing the user to construct a writer which adds
    the same list of shared symbol table imports to each local symbol table
    it creates, the implementation may choose to allow the user to add
    particular shared symbol table imports to certain local symbol tables within
    the stream. This can be desirable, for example, in response to a change in a
    reader's current symbol table when that reader is acting as the source of
    the data to write. Using this API would cause the writer to create a new
    symbol table which appends the given shared symbol tables to the
    writer’s configured list of shared symbol tables (if any). This would
    require the writer to serialize the previous local symbol table (if
    necessary) and flush any buffered data before writing the new symbol table.

-   Allow the user to flush any writer between any two top-level values
    without resetting the current symbol table. Calling this API would
    cause the writer to serialize the current symbol table; upon the next
    flush, the writer would use local symbol table append syntax (as defined
    by the specification) to write a symbol table that appends any symbols
    that were added after the last flush.

## Appendix

<a name="fn1">1</a>:
When using

-   *Text readers*, the ONLY SymbolToken that carries IVM semantics is
    the unquoted and unannotated symbol value with text \$ion\_1\_0 at
    the top level. Other top-level unannotated symbol values with the same
    text as the IVM, including ‘\$ion\_1\_0’, \$2, and any Symbol
    Identifiers that refer to local symbols with the text \$ion\_1\_0,
    are ignored; the value is skipped. When such symbol values
    are annotated, or occur below the top-level, they are treated as
    user symbols.

-   *Binary readers*, the ONLY byte sequence that carries IVM semantics is
    \\xE0\\x01\\x00\\xEA at the top level. No symbol value may be used
    to represent the IVM. Any unannotated symbol IDs that map to the
    text \$ion\_1\_0 at the top-level are ignored and skipped; in all
    other cases, such symbol values are treated as user symbols.

<a name="fn2">2</a>:
The ImportLocation can be determined by applying the symbol ID
assignment algorithm defined by the specification, where the system
symbol table starts at symbol ID 1.

<a name="fn3">3</a>:
Unlike symbols with unknown text resolved from shared symbol
tables, symbols with with unknown text resolved from local symbol
tables can NEVER have defined text because the local symbol table is
included in the encoding and its symbol ID mappings are immutable.
Therefore, there is no need to preserve the local symbol IDs of
SymbolTokens representing such symbols. Treating them equivalently
to symbol zero simplifies writing symbol tables because it obviates
the need for writers to keep track of null slots in local symbol
tables.

<a name="fn4">4</a>:
This case requires that the text writer serialize a local symbol
table containing the imports mapped to by Symbol Identifier tokens
within the stream. Note that imports that have no unknown mappings in
the stream do NOT need to be included (nor do any local symbols), but if
only a subset of the imports are included, the Symbol Identifiers need
to refer to the same slot in the same import as before any shared
symbol tables were excluded (this can be computed by translating the
SymbolToken’s importLocation to a local symbol ID in the new symbol
table using the algorithm defined by the specification).

Although this is the only case that REQUIRES a text writer to serialize
a local symbol table, it should be noted that serializing a local symbol
table in other cases is only wasteful, never harmful. Accordingly, it
is simpler to serialize a local symbol table which includes all shared
imports whenever a writer is provided with shared imports. Otherwise,
when the writer has shared imports, it needs to buffer the entire stream
while that symbol table is the current symbol table (similar to the binary
writer), because it can’t determine ahead of time that the user won’t
specify a symbol with unknown text (unless all of the imports are found
in the Catalog and none of them have null slots, which can be checked
ahead of time in return for some additional preprocessing time).

It may be tempting for an implementation to try to wait until a
SymbolToken with unknown text is written before serializing a local symbol
table. However, this is problematic because symbol tables may only occur
at the top level, but the first SymbolToken with unknown text can occur
at any depth.

<a name="fn5">5</a>:
This is to avoid writing invalid Ion. Consider a writer whose
current symbol table contains two symbols, \$10 = abc and \$11 =
def. A user manually writes a local symbol table with only one symbol,
\$10 = foo. If the writer simply writes this manually-written table to
the stream without internally changing its current symbol table, it would
allow the user to write symbol ID 11 (with “def” in mind), while a reader
of the data would process the new local symbol table and subsequently
consider \$11 to be out of range, raising an error.

<a name="fn6">6</a>:
Note that this means that SymbolTokens are not guaranteed to
have the same import location on roundtrip, but they are guaranteed to
have the same text representation, which is sufficient to maintain
equivalence.

<a name="fn7">7</a>:
This is a potentially a lossy operation, as it does not convey
import location. There are two reasons why implementations may choose
not to raise an error in this case:

-   For legacy reasons. Existing implementations may find it
    impractical to raise an error under this condition. In this
    case, if possible, the API should be deprecated in favor of
    one that handles this case correctly; at the very least,
    documentation should be added to convey the risk of data
    loss.
    
-   If there is demand for an API which lossily treats all
    SymbolTokens with unknown text as symbol zero. New
    implementations should relax the constraint only if it
    is proven necessary, and should take care to make sure
    users understand the risk of data loss.

<a name="fn8">8</a>:
No special semantics are ascribed to text Ion symbol tokens which
have the same form as Symbol Identifiers but are quoted. Readers must
pass along the text as-is, and writers must never write user-provided
text with the same form as a Symbol Identifier as an unquoted symbol
token. This maintains the user's ability to write symbol tokens with any
text without experiencing surprising side-effects on roundtrip.

<a name="fn9">9</a>: If the implementation uses a singleton system symbol table directly
as the current symbol table, appending a new symbol will first require
creating a mutable local symbol table which implicitly extends the system
symbol table. In other words, care should be taken never to mutate the
system symbol table.

[1]: {{ site.baseurl }}/docs/symbols.html
[2]: {{ site.baseurl }}/docs/spec.html
[3]: {{ site.baseurl }}/docs.html
