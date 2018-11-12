---
title: Developers' Guide to Path Extraction APIs
description: "A guide to implementing path extraction APIs."
---

# [Docs][0]/ {{ page.title }}

This document provides a guide to implementing a path extraction API as
an alternative to the traditional streaming and DOM APIs. A reference
implementation exists in ion-c (see
[1](https://github.com/amzn/ion-c/blob/master/ionc/inc/ion_extractor.h),
[2](https://github.com/amzn/ion-c/blob/master/ionc/ion_extractor_impl.h),
and
[3](https://github.com/amzn/ion-c/blob/master/ionc/ion_extractor.c)) and
it's also available as an
[extension to ion-java](https://github.com/amzn/ion-java-path-extraction).

Motivation
----------

The traditional streaming and DOM APIs force the user to choose between
speed and convenience, respectively. Path extraction APIs aim to combine
the two by allowing the user to register paths into the data using just
a few lines of code and receive callbacks during stream processing when
any of those paths is matched. This allows the Ion reader to plan the
most efficient traversal over the data without requiring further manual
interaction from the user. For example, there is no reason to step in to
containers which could not possibly match one of the search paths.
When encoded in binary Ion, the resulting skip is a seek forward in the
input stream, which is inexpensive relative to the cost of parsing (and
in the case of a DOM, materializing) the skipped value.

Terms
-----

**Search path** - a path which is provided to the extractor for matching.

**Partial match** - a value whose path matches the first N elements in a
search path (where N is less than the search path's total length).

**Terminal match** - a value whose path exactly matches a search path.

**Active path** - a search path that has at least one partial match
at depth N, where N is the extractor's current depth minus one.

Phases
------

Interacting with a path extraction API typically occurs in three phases:

1. configuration,
2. path registration, and
3. notification.

### Configuration

The configuration phase involves readying an extractor instance for path
registration by setting its options. It should be noted that an Ion
reader should *not* be provided to the extractor during configuration;
it should be provided as an argument to the function that begins the
notification phase, as described below. This allows the extractor itself
to be stateless, immutable, long-lived, and reusable.

#### Common Options

-   *Maximum path depth* - The maximum depth of any search path. May
    be used to limit the amount of memory used by the path extractor. If
    the reader places its own limits on maximum depth, it should be
    treated as an error to exceed that number. Recommended default:
    unlimited.
-   *Maximum number of paths* - The maximum number of search paths that
    may be registered to a single extractor. May be used to limit the
    amount of memory used by the path extractor. Recommended default:
    unlimited.
-   *Match relative paths* - If disabled, it is an error to provide the
    extractor with an Ion reader positioned at a depth other than zero.
    If enabled, the extractor will accept a reader positioned at any
    valid depth within the data and will match paths relative to the
    initial depth of the reader. For example, if a reader is positioned
    at depth 2 at the field 'foo' in the data `{abc:{foo:{bar:baz}}}` and
    is provided to an extractor with this option enabled and the search
    path `(bar)`, the extractor would match on the value `baz`. This
    extractor would finish matching once it exhausted all sibling values
    (none in this case) at depth 2. Recommended default: `false`.
-   *Case-insensitive matching* - If enabled, the extractor will treat
    paths as case-insensitive. Recommended default: `false`.

#### Public API Example

```python
# Do not bind a reader to the extractor at construction.
extractor = Extractor(max_path_depth=10, max_num_paths=100, match_relative_paths=false, case_insensitive=true)
```

### Registration

The registration phase begins once the user has a path extractor
instance configured with the desired options. The user may now register
search paths. Path registration APIs may be entirely programmatic, and/or
may parse path information from a string. Both techniques require the
following information to register a path:

-   the path's elements, which may be wildcards, indices, or text;
-   the callback to be invoked when the search path is matched; and
-   optional untyped user context to be provided to the callback when it
    is invoked.

At the discretion of the implementor, paths may either be standalone
(i.e. objects), or may be contained internally to the extractor. The
latter strategy may be most useful when memory and performance concerns
are important. In these cases, implementors may consider designing the
layout of the paths in memory for efficient traversal.

The callback function signature should include parameters for the
matching value (likely represented by an Ion reader positioned at the
value, but this may be implementation-defined) and the user context; and
a return value which indicates to the extractor how it should proceed.
This return value can be described as a 'step-out-N' instruction. The
most common value is zero, which tells the extractor to continue with
the next value at the same depth. A return value greater than zero may
be useful to users who only care about the first match at a particular
depth.

When the callback function is invoked with an Ion reader positioned at
the matching value, and that reader is the same one used internally by
the extractor, one of two steps must be taken:

-   The following contract must be documented: the user must return from
    the callback with the reader positioned at the end of the
    matched value. Failure to do so may result in missed and/or
    inaccurate matches. In this case, the extractor cannot support
    registration of multiple paths along the same hierarchy (e.g. both
    `(foo)` and `(foo bar)`). Or,
-   The extractor must seek the reader back to the start of the matched
    value after each callback return. This allows the user to operate on
    the reader however they wish, and enables the extractor to support
    registration of multiple paths along the same hierarchy.

An alternative is to avoid exposing the Ion reader to the user, and
instead provide a DOM-like representation of the matching value to the
user through the callback. This may be more convenient for the user
(especially those already comfortable with the DOM), but is potentially
less flexible and less performant.

#### Programmatic Registration

Programmatic registration involves allowing the user to manually
construct a path by chaining path elements. This should be implemented
in a language-idiomatic way.

#### String Registration

Users may find it simpler to create a path in one line by using a string
representation. It is possible to accept a wide variety of different
syntaxes (e.g. XPath, JSONPath, etc.), but the following stripped-down
Ion-based syntax should be supported by all implementations.

This syntax calls for a string of text Ion data which must contain
exactly one top-level ordered sequence (either list or s-expression)
containing a number of elements less than or equal to the extractor's
*maximum path depth*. The elements (if any) must be either text types
(string or symbol), representing fields or wildcards, or integers,
representing indices. A non-wildcard field element with the same text as
a wildcard must be annotated with the special annotation
`$ion_extractor_field` as its first annotation.

For example, `()` represents a path of length zero, which will match all
top-level values when the extractor's initial depth is zero, while
`(abc * 2 $ion_extractor_field::*)` represents a path of length 4
consisting of a field named `abc`, a wildcard, an index of 2, and a
field named `*`.

#### Public API Example

```python
def pathCallback(reader, userContext):
    ... # Retrieve the matching value from the reader and do something.
    return 0

path = Path("(foo * bar 0)")
pathContext = ... # Create some user context to pass to the callback when matched, if desired.
extractor.register(path, pathContext, pathCallback)
```

### Notification

The notification phase begins when the user finishes registering paths
and invokes a function which causes the path extractor to begin
processing the given Ion stream. As previously discussed, this function
should accept an Ion reader (positioned at depth zero, unless the
extractor is configured to *match relative paths*) over the stream to be
processed.

Each time the reader encounters a value, the extractor must evaluate
whether the value is a partial and/or terminal match to at least one of
the active paths at the current depth.

If the value is a

-   *terminal match*, then the callback registered to the matching search
    path must be invoked. If a non-zero value N is returned by the
    callback, the extractor must step out N (or throw if that is impossible,
    which occurs when N is greater than the Ion reader's initial depth).
    When a value is both a terminal match and a partial match, the callback
    for the terminal match should be invoked before processing the value
    as a partial match as described below.
-   *partial match* then if it is a
    -   *container*, step in, mark the path(s) for which the value is a
        partial match as active at the new depth, and continue.
    -   *scalar*, skip the value, as it can not possibly be a terminal
        match to that path.
-   *not a match*, it should be skipped (and not stepped into, if it is
    a container value).

When the end of a container is reached, and the container's depth is
greater than the reader's initial depth, step out of the container and
resume processing with the active paths at the stepped-out depth.

#### Determining a match

Search path elements which are

-   *wildcards* match all values
-   *indices* match the value at that index
-   *text* match all values whose field names are equivalent to that
    text

at the element's depth.

#### Performance considerations

Observing a few characteristics of the matching algorithm may reveal
opportunities to design for performance.

-   The extractor needs to keep track of which search paths are active at
    a particular depth. Paths which are inactive at that depth need not be
    evaluated for matches. This can be conceptualized as a stack of
    collections of active depths, but need not necessarily be
    implemented that way. ion-c, for example, uses a stack of bit maps
    for a smaller memory footprint and quicker lookups.
-   The extractor never iterates over all elements in a path, so
    organizing a particular path's elements in contiguous memory is
    unlikely to be beneficial. However, depending on the implementation,
    the extractor *may* iterate over all path *elements* at a
    particular depth. In that case, organizing elements sharing the same
    depth in contiguous memory may be beneficial (ion-c does this).
    Another option is to use an associative data structure for efficient
    lookups by depth.

#### Public API Example

```python
reader1 = ... # Create an Ion reader in the typical way.
extractor.match(reader1)
reader2 = ...
extractor.match(reader2)
```

[0]: {{ site.baseurl }}/docs.html
