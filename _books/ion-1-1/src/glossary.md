# Glossary

**active encoding module**<br/>
The _encoding module_ whose symbol table and macro table are available in the current _segment_ of an Ion _document_.
The active encoding module is set by a _directive_.

**argument**<br/>
The sub-expression(s) within a macro invocation, corresponding to exactly one of the macro's parameters.

**cardinality**<br/>
Describes the number of values that a parameter will accept when the macro is invoked.
One of zero-or-one, exactly-one, zero-or-more, or one-or-more.
Specified in a signature by one of the modifiers `?`, `!`, `*`, or `+`.

**declaration**<br/>
The association of a name with an entity (for example, a module or macro). See also _definition_. 
Not all declarations are definitions: some introduce new names for existing entities.

**definition**<br/>
The specification of a new entity.

**directive**<br/>
A keyword or unit of data in an Ion document that affects the encoding environment, and thus the way the document's data is decoded.
In Ion 1.0 there are two directives: _Ion version markers_, and the _symbol table directives_.
Ion 1.1 adds _encoding directives_.

**document**<br/>
A stream of octets conforming to either the Ion text or binary specification.
Can consist of multiple _segments_, perhaps using varying versions of the Ion specification.
A document does not necessarily exist as a file, and is not necessarily finite.

**E-expression**<br/>
See _encoding expression_.

**encoding directive**<br/>
In an Ion 1.1 segment, a top-level S-Expression annotated with `$ion_encoding`.
Defines a new encoding module for the segment immediately following it.
At the end of the encoding directive, the new _encoding module_ is promoted to be the _active encoding module_.
The _symbol table directive_ is effectively a less capable alternative syntax.

**encoding environment**<br/>
The context-specific data maintained by an Ion implementation while encoding or decoding data. In
Ion 1.0 this consists of the current symbol table; in Ion 1.1 this is expanded to also include the Ion
spec version, the current macro table, and a collection of available modules.

**encoding expression**<br/>
The invocation of a macro in encoded data, aka E-expression.
Starts with a macro reference denoting the function to invoke.
The Ion text format uses "smile syntax" `(:macro ...)` to denote E-expressions. 
Ion binary devotes a large number of opcodes to E-expressions, so they can be compact.

**encoding module**<br/>
A _module_ whose symbol table and macro table can be used directly in the user data stream.

**expression**<br/>
A serialized syntax element that may produce values.
_Encoding expressions_ and values are both considered expressions, whereas NOP, comments, and IVMs, for example, are not. 

**expression group**<br/>
A grouping of zero or more _expressions_ that together form one _argument_.
The concrete syntax for passing a stream of expressions to a macro parameter.
In a text _E-expression_, a group starts with the trigraph `(::` and ends with `)`, similar to an S-expression.
In _template definition language_, a group is written as an S-expression starting with `..` (two dots).

**inner module**<br/>
A _module_ that is defined inside another module and only visible inside the definition of that module.

**Ion version marker**<br/>
A keyword directive that denotes the start of a new segment encoded with a specific Ion version.
Also known as "IVM".

**macro**<br/>
A transformation function that accepts some number of streams of values, and produces a stream of values.

**macro definition**<br/>
Specifies a macro in terms of a _signature_ and a _template_.

**macro reference**<br/>
Identifies a macro for invocation or exporting. Must always be unambiguous. Lexically
scoped, and never a "forward reference" to a macro that is declared later in the document.

**module**<br/>
The data entity that defines and exports both symbols and macros.

**opcode**<br/>
A 1-byte, unsigned integer that tells the reader what the next expression represents
and how the bytes that follow should be interpreted.

**optional parameter**<br/>
A parameter that can have its corresponding subform(s) omitted when the macro is invoked.
A parameter is optional if it is _voidable_ and all following arguments are also voidable.

**parameter**<br/>
A named input to a macro, as defined by its signature.
At expansion time a parameter produces a stream of values.

**qualified macro reference**<br/>
A macro reference that consists of a module name and either a macro name exported by that module,
or a numeric address within the range of the module's exported macro table. In TDL, these look
like _module-name_::_name-or-address_.

**required parameter**<br/>
A macro parameter that is not _optional_ and therefore requires an argument at each invocation.

**rest parameter**<br/>
A macro parameter—always the final parameter—declared with `*` or `+` cardinality,
that accepts all remaining individual arguments to the macro as if they were in an implicit _argument group_.
Similar to "varargs" parameters in Java and other languages.

**segment**<br/>
A contiguous partition of a _document_ that uses the same _active encoding module_. Segment boundaries
are caused by directives: an IVM starts a new segment, while `$ion_symbol_table` and `$ion_encoding`
directives end segments (with a new one starting immediately afterward).

**shared module**<br/>
A module that exists independent of the data stream of an Ion document. It is identified by a
name and version so that it can be imported by other modules.

**signature**<br/>
The part of a macro definition that specifies its "calling convention", in terms of the shape,
type, and cardinality of arguments it accepts, and the type and cardinality of the results it
produces.

**symbol table directive**<br/>
A top-level struct annotated with `$ion_symbol_table`.  Defines a new encoding environment
without any macros.  Valid in Ion 1.0 and 1.1.

**system E-Expression**<br/>
An _E-Expression_ that invokes a _macro_ from the _system-module_ rather than from the _active encoding module_.

**system macro**<br/>
A macro provided by the Ion implementation via the system module `$ion`.
System macros are available at all points within Ion 1.1 segments.

**system module**<br/>
A standard module named `$ion` that is provided by the Ion implementation, implicitly installed so
that the system symbols and system macros are available at all points within a document.
Subsumes the functionality of the Ion 1.0 system symbol table.

**system symbol**<br/>
A symbol provided by the Ion implementation via the system module `$ion`.
System symbols are available at all points within an Ion document, though the selection of symbols
varies by segment according to its Ion version.

**TDL**<br/>
See _template definition language_.

**template**<br/>
The part of a macro definition that expresses its transformation of inputs to results.

**template definition language**<br/>
An Ion-based, domain-specific language that declaratively specifies the output produced by a _macro_.

**unqualified macro reference**<br/>
A macro reference that consists of either a macro name or numeric address, without a qualifying module name. 
These are resolved using lexical scope and must always be unambiguous.

**variable expansion**<br/>
In _TDL_, a special form that causes the expanded _arguments_ for the given _parameter_ to be substituted into the _template_.
